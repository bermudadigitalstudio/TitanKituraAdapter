import XCTest
import TitanServerDelegate
import TitanCore
import KituraNet
import Foundation

final class TitanServerDelegateTests: XCTestCase {

  var titanInstance: Titan!
  override func setUp() {
    titanInstance = Titan()
  }

  func testConvertingKituraRequestToTitanRequest() {
    let port = arc4random_uniform(1000) + 8000
    let body = "Some body goes here"
    let length = "\(body.utf8.count)"
    let session = URLSession(configuration: .ephemeral)

    // Configure Kitura server
    let serverStartedExpectation = expectation(description: "Server started")
    let kituraServerDelegate = TitanServerDelegate(titanInstance.app)
    let s = HTTP.createServer().started {
      serverStartedExpectation.fulfill()
    }
    try! s.listen(on: Int(port))
    waitForExpectations(timeout: 1, handler: nil)

    // Configure Titan integration
    s.delegate = kituraServerDelegate
    let requestExp = expectation(description: "requestReceived")
    var titanRequestConvertedFromKitura: TitanCore.RequestType!
    titanInstance.middleware { (request, response) -> (TitanCore.RequestType, TitanCore.ResponseType) in
      titanRequestConvertedFromKitura = request
      requestExp.fulfill()
      return (request, response)
    }

    // Make the request
    var r = URLRequest(url: URL(string: "http://localhost:\(port)/complexPath/with/comps?query=string&value=stuff")!)
    r.httpMethod = "PATCH"
    r.setValue("application/json", forHTTPHeaderField: "Accept")
    r.setValue(length, forHTTPHeaderField: "Content-Length")
    r.httpBody = body.data(using: .utf8)

    session.dataTask(with: r) { (data, res, err) in
      dump(data)
      dump(res)
      dump(err)
    }.resume()

    waitForExpectations(timeout: 10, handler: nil)
    XCTAssertNotNil(titanRequestConvertedFromKitura)
    XCTAssertEqual(titanRequestConvertedFromKitura.path, "/complexPath/with/comps?query=string&value=stuff")
    XCTAssertEqual(titanRequestConvertedFromKitura.body, "Some body goes here")
//    XCTAssertEqual(titanRequestConvertedFromKitura.method, "PATCH")
//    XCTAssertEqual(titanRequestConvertedFromKitura.headers.first?.0, "Accept")
//    XCTAssertEqual(titanRequestConvertedFromKitura.headers.first?.1, "application/json")
  }
//
//  func testConvertingTitanResponseToKituraResponse() {
//    let titanResponse = TitanCore.Response(501, "Not implemented; developer is exceedingly lazy", headers: [("Cache-Control", "private")])
//    let KituraResponseConvertedFromTitan: Kitura.ResponseType
//    titanInstance.middleware { (request, response) -> (TitanCore.RequestType, TitanCore.ResponseType) in
//      return (request, titanResponse)
//    }
//    let app = toKituraApplication(titanInstance.app)
//    let request = Inquiline.Request(method: "GET", path: "/")
//    KituraResponseConvertedFromTitan = app(request)
//    XCTAssertNotNil(KituraResponseConvertedFromTitan.body)
//    XCTAssertTrue(KituraResponseConvertedFromTitan.statusLine.hasPrefix("501"))
//    XCTAssertEqual(KituraResponseConvertedFromTitan.headers.count, 1)
//    XCTAssertEqual(KituraResponseConvertedFromTitan.headers.first?.0, "Cache-Control")
//    XCTAssertEqual(KituraResponseConvertedFromTitan.headers.first?.1, "private")
//  }

  static var allTests: [(String, (TitanServerDelegateTests) -> () throws -> Void)] {
    return [

    ]
  }
}
