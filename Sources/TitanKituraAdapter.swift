import TitanCore
import KituraNet
import Foundation

public func serve(_ app: @escaping (RequestType) -> (ResponseType), on port: Int) -> Never {
  let server = HTTP.createServer()
  server.delegate = TitanServerDelegate(app)
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
  public init(_ titanApp: @escaping (RequestType) -> (ResponseType)) {
    self.app = titanApp
  }
  public func handle(request: ServerRequest, response: ServerResponse) {
    let r = self.app(request.toRequest())
    try? r.write(toServerResponse: response)
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
