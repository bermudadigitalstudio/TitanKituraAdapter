import TitanCore
import KituraNet
import Foundation

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
    return Request(self.method, path, body, headers: self.headers.toHeadersArray())
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
    try response.end(text: body)
  }
}
