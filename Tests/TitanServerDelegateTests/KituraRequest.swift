//@testable import KituraNet
//import struct Foundation.Data
//import struct Foundation.URLComponents
//import struct Foundation.URL
//import TitanCore
//
///// A class for mocking Kitura requests. Assumes UTF-8 encoding of body. Many parts of this are not implemented.
//final class KituraRequest: ServerRequest {
//  var body: String
//  var data: Data {
//    let b = self.body.data(using: .utf8) ?? Data()
//    return b
//  }
//  public init(body: String, method: String, headers: [Header], url: String) {
//    self.body = body
//    self.method = method
//    self.urlURL = URL(string: url)!
//    for (key, value) in headers {
//      self.headers.append(key, value: value)
//    }
//  }
//  /// Read all of the data in the body of the request
//  ///
//  /// - Parameter data: A Data struct to hold the data read in.
//  ///
//  /// - Throws: Socket.error if an error occurred while reading from the socket
//  /// - Returns: The number of bytes read
//  public func readAllData(into data: inout Data) throws -> Int {
//    data = self.data
//    return self.data.count
//  }
//
//  /// Read a string from the body of the request.
//  ///
//  /// - Throws: Socket.error if an error occurred while reading from the socket
//  /// - Returns: An Optional string
//  public func readString() throws -> String? {
//    return body
//  }
//
//  /// Read data from the body of the request
//  ///
//  /// - Parameter data: A Data struct to hold the data read in.
//  ///
//  /// - Throws: Socket.error if an error occurred while reading from the socket
//  /// - Returns: The number of bytes read
//  public func read(into data: inout Data) throws -> Int {
//    data = self.data
//    return self.data.count
//  }
//
//  /// The HTTP Method specified in the request
//  public var method: String
//
//  /// Minor version of HTTP of the request
//  public var httpVersionMinor: UInt16? { fatalError("Not implemented") }
//
//  /// Major version of HTTP of the request
//  public var httpVersionMajor: UInt16? { fatalError("Not implemented") }
//
//  /// The IP address of the client
//  public var remoteAddress: String { fatalError("Not implemented") }
//
//  /// The URL from the request
//  public var urlURL: URL
//
//  /// The URL from the request as URLComponents
//  /// URLComponents has a memory leak on linux as of swift 3.0.1. Use 'urlURL' instead
//  @available(*, deprecated, message: "URLComponents has a memory leak on linux as of swift 3.0.1. use 'urlURL' instead")
//  public var urlComponents: URLComponents { fatalError("Not implemented") }
//
//  /// The URL from the request in UTF-8 form
//  /// This contains just the path and query parameters starting with '/'
//  /// Use 'urlURL' for the full URL
//  public var url: Data { fatalError("Not implemented") }
//
//  /// The URL from the request in string form
//  /// This contains just the path and query parameters starting with '/'
//  /// Use 'urlURL' for the full URL
//  @available(*, deprecated, message: "This contains just the path and query parameters starting with '/'. use 'urlURL' instead")
//  public var urlString: String { fatalError("Not implemented") }
//
//  /// The set of headers received with the incoming request
//  public var headers: HeadersContainer = HeadersContainer()
//  
//}
