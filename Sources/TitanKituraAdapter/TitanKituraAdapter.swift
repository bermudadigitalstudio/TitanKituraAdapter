import TitanCore
import KituraNet
import Foundation
import Dispatch

/// Creates and start an HTTP server.
///
/// - parameters:
///   - app: The Titan function
///   - on: HTTP port to
///   - defaultResponse: The default Reponse if any route are found. HTTP 405 by default
///   - metrics: Metric Handler to collect Request/Response metrics.
public func serve(_ app: @escaping TitanFunc, on port: Int, defaultResponse: ResponseType = Response(code: 405, body: nil),
                  metrics: MetricHandler? = nil) -> Never {

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

public final class TitanServerDelegate {

    let defaultResponse: ResponseType
    let app: TitanFunc
    let metricQueue: DispatchQueue?
    let metricHandler: MetricHandler?

    public init(_ titanApp: @escaping TitanFunc, defaultResponse: ResponseType, metrics: MetricHandler?) {

        self.app = titanApp
        self.defaultResponse = defaultResponse
        self.metricHandler = metrics
        if metricHandler != nil {
            metricQueue = DispatchQueue(label: "titan.metrics")
        } else {
            metricQueue = nil
        }
    }

}

extension TitanServerDelegate: ServerDelegate {
    public func handle(request: ServerRequest, response: ServerResponse) {

        if metricQueue != nil {
            let start = Date().timeIntervalSince1970
            let headers = request.headers

            processRequest(request: request, response: response)

            let end = Date().timeIntervalSince1970

            metricQueue?.async {
                let statusCode = response.statusCode?.rawValue ?? -1
                self.metricHandler?( HTTPMetric(startAt: UInt64(start),
                                                endAt: UInt64(end),
                                                duration: (end - start),
                                                responseStatusCode: statusCode,
                                                requestUrl: request.urlURL.absoluteString,
                                                requestMethod: request.method,
                                                requestRemoteAddress: request.remoteAddress,
                                                requestHeader: headers.toDictionary()))
            }
        } else {
            processRequest(request: request, response: response)
        }

    }

    private func processRequest(request: ServerRequest, response: ServerResponse) {
        let result = self.app(request.toTitanRequest(), defaultResponse)
        try? result.response.write(toServerResponse: response)
    }
}

private extension ServerRequest {

    func toTitanRequest() -> Request {

        let query = (self.urlURL.query.map { "?" + $0 } ?? "")
        let path = (self.urlURL.path + query)

        var body = Data()
        _ = try? self.readAllData(into: &body)

        let httpMethod = HTTPMethod(rawValue: self.method) ?? .custom(named: self.method)

        return Request(method: httpMethod, path: path, body: body, headers: self.headers.toTitanHTTPHeaders())
    }
}

extension HeadersContainer {

    func toTitanHTTPHeaders() -> HTTPHeaders {

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
