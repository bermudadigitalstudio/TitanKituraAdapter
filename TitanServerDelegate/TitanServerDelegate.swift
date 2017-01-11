import TitanCore
import KituraNet

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
    return Request(self.method, "")
  }
}

private extension ResponseType {
  func write(toServerResponse response: ServerResponse) throws {
    response.statusCode = HTTPStatusCode(rawValue: code)
    try response.end(text: body)
  }
}
