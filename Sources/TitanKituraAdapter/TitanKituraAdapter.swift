import TitanCore
import KituraNet
import Foundation
import Dispatch

public typealias MetricHandler = (HTTPMetric) -> Void

public struct HTTPMetric: Codable {
    public let startAt: Double
    public let endAt: Double
    public let duration: Double
    public let responseStatusCode: Int
    public let requestUrl: String
    public let requestMethod: String
    public let requestRemoteAddress: String
    public let requestHeader: [String: String]
}

public func serve(_ app: @escaping (RequestType, ResponseType) -> (RequestType, ResponseType),
                  on port: Int, defaultResponse: ResponseType = Response(code: 404, body: nil), metrics: MetricHandler? = nil) -> Never {

    let server = HTTP.createServer()
    server.delegate = TitanServerDelegate(app, defaultResponse: defaultResponse, metrics: metrics)

    do {
        try server.listen(on: port)
    } catch {
        print("Error listening on port \(port): \(error). Use server.failed(callback:) to handle")
    }

    ListenerGroup.waitForListeners()
    fatalError("Done")
}

public final class TitanServerDelegate: ServerDelegate {

    let defaultResponse: ResponseType
    let app: (RequestType, ResponseType) -> (RequestType, ResponseType)
    let metricQueue: DispatchQueue?
    let metricHandler: MetricHandler?

    public init(_ titanApp: @escaping (RequestType, ResponseType) -> (RequestType, ResponseType),
                defaultResponse: ResponseType, metrics: MetricHandler?) {

        self.app = titanApp
        self.defaultResponse = defaultResponse
        self.metricHandler = metrics
        if metricHandler != nil {
            metricQueue = DispatchQueue(label: "titan.metrics")
        } else {
            metricQueue = nil
        }
    }

    public func handle(request: ServerRequest, response: ServerResponse) {
        let start = Date().timeIntervalSince1970

        let r = self.app(request.toRequest(), defaultResponse)
        try? r.1.write(toServerResponse: response)
        let end = Date().timeIntervalSince1970
        metricQueue?.async {
            let statusCode = response.statusCode?.rawValue ?? -1
            self.metricHandler?( HTTPMetric(startAt: start,
                                            endAt: end,
                                            duration: end - start,
                                            responseStatusCode: statusCode,
                                            requestUrl: request.urlURL.absoluteString,
                                            requestMethod: request.method,
                                            requestRemoteAddress: request.remoteAddress,
                                            requestHeader: request.headers.toDictionary()))
        }
    }
}

private extension ServerRequest {
    func toRequest() -> Request {
        let query = (self.urlURL.query.map { "?" + $0 } ?? "")
        let path = (self.urlURL.path + query)
        var body = Data()
        _ = try? self.readAllData(into: &body)

        let httpMethod = HTTPMethod(rawValue: self.method) ?? .custom(named: self.method)

        return Request(method: httpMethod, path: path, body: body, headers: self.headers.toHTTPHeaders())
    }
}

extension HeadersContainer {
    func toHTTPHeaders() -> HTTPHeaders {

        var httpHeaders = HTTPHeaders()

        for (key, value) in self {
            httpHeaders[key] = value.joined(separator: ", ")
        }

        return httpHeaders
    }

    func toDictionary() -> [String: String] {
        var dictionary = [String: String]()
        for (key, value) in self {
            dictionary[key] = value.joined(separator: ", ")
        }

        return dictionary
    }
}

private extension ResponseType {

    func write(toServerResponse response: ServerResponse) throws {

        // HTTP Status
        response.statusCode = HTTPStatusCode(rawValue: code)

        // HTTP Headers
        var contentLengthIsSet = false

        for (key, value) in self.headers {
            response.headers.append(key, value: value)
            if key.lowercased() == "content-length" {
                contentLengthIsSet = true
            }
        }

        if !contentLengthIsSet {
            response.headers.append("Content-Length", value: "\(self.body.count)")
        }

        // HTTP Body
        try response.write(from: self.body)
        try response.end()
    }
}

extension HTTPMethod: RawRepresentable {

    public typealias RawValue = String

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "get":
            self = .get
        case "head":
            self = .head
        case "put":
            self = .put
        case "post":
            self = .post
        case "patch":
            self = .patch
        case "delete":
            self = .delete
        case "trace":
            self = .trace
        case "options":
            self = .options
        default :
            self = .custom(named: rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .get:
            return "get"
        case .head:
            return "head"
        case .put:
            return "put"
        case .post:
            return "post"
        case .patch:
            return "patch"
        case .delete:
            return "delete"
        case .trace:
            return "trace"
        case .options:
            return "options"
        case .custom(let named):
            return named
        }
    }
}
