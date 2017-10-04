import TitanCore
import KituraNet
import Foundation
import Dispatch

public typealias MetricHandler = (HTTPMetric) -> Void

public struct HTTPMetric {
    public let startAt: Double
    public let endAt: Double
    public let duration: Double
    public let responseStatusCode: Int
    public let requestUrl: String
    public let requestMethod: String
    public let requestRemoteAddress: String
}

public func serve(_ app: @escaping (RequestType) -> (ResponseType),
                  on port: Int, metrics: MetricHandler? = nil) -> Never {

    let server = HTTP.createServer()
    server.delegate = TitanServerDelegate(app, metrics: metrics)

    do {
        try server.listen(on: port)
    } catch {
        print("Error listening on port \(port): \(error). Use server.failed(callback:) to handle")
    }

    ListenerGroup.waitForListeners()
    fatalError("Done")
}

public final class TitanServerDelegate: ServerDelegate {

    let app: (RequestType) -> (ResponseType)
    let metricQueue: DispatchQueue?
    let metricHandler: MetricHandler?

    public init(_ titanApp: @escaping (RequestType) -> (ResponseType), metrics: MetricHandler?) {
        self.app = titanApp
        self.metricHandler = metrics
        if metricHandler != nil {
            metricQueue = DispatchQueue(label: "titan.metrics")
        } else {
            metricQueue = nil
        }
    }

    public func handle(request: ServerRequest, response: ServerResponse) {
        let start = Date().timeIntervalSince1970
        let r = self.app(request.toRequest())
        try? r.write(toServerResponse: response)
        let end = Date().timeIntervalSince1970
        metricQueue?.async {
            let statusCode = response.statusCode?.rawValue ?? -1
            self.metricHandler?( HTTPMetric(startAt: start,
                                            endAt: end,
                                            duration: end - start,
                                            responseStatusCode: statusCode,
                                            requestUrl: request.urlURL.absoluteString,
                                            requestMethod: request.method,
                                            requestRemoteAddress: request.remoteAddress))
        }
    }
}

private extension ServerRequest {
    func toRequest() -> Request {
        let query = (self.urlURL.query.map { "?" + $0 } ?? "")
        let path = (self.urlURL.path + query)
        var bodyData = Data()
        let readCount = try? self.readAllData(into: &bodyData)
        let body: String
        if readCount != nil {
            body = String(data: bodyData, encoding: .utf8) ?? ""
        } else {
            body = "" // Error condition – server failed to read body data from request
        }
        return Request(method: self.method, path: path, body: body, headers: self.headers.toHeadersArray())
    }
}

extension HeadersContainer {
    func toHeadersArray() -> [Header] {
        let h = Array(self)
        let headers = h.map { (k, v) in
            return (k, v.joined(separator: ", "))
        }
        return headers
    }
}

private extension ResponseType {
    func write(toServerResponse response: ServerResponse) throws {
        response.statusCode = HTTPStatusCode(rawValue: code)
        var contentLengthIsSet = false
        for (key, value) in self.headers {
            response.headers.append(key, value: value)
            if key.lowercased() == "content-length" {
                contentLengthIsSet = true
            }
        }
        let data = self.body.data(using: .utf8) ?? Data()
        if !contentLengthIsSet {
            response.headers.append("Content-Length", value: "\(data.count)")
        }
        try response.write(from: data)
        try response.end()
    }
}
