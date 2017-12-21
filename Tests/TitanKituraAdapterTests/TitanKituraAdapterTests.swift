import XCTest
import TitanKituraAdapter
import TitanCore
import KituraNet
import Foundation

final class TitanKituraAdapterTests: XCTestCase {

    var titanInstance: Titan!
    var server: HTTPServer!
    let port: Int = 12345

    override func setUp() {

        titanInstance = Titan()
        // Configure Kitura server
        let serverStartedExpectation = expectation(description: "Server started")
        let kituraServerDelegate = TitanServerDelegate(titanInstance.app, defaultResponse: Response(code: 404, body: nil), metrics: { httpMetric in
            XCTAssertNotNil(httpMetric)
        })
        server = HTTP.createServer().started {
            serverStartedExpectation.fulfill()
        }

        do {
            try server.listen(on: port)
        } catch {
            XCTFail("Can't listen")
        }

        waitForExpectations(timeout: 1, handler: nil)
        // Configure Titan integration
        server.delegate = kituraServerDelegate
    }

    override func tearDown() {
        server.stop()
        server = nil
    }

    func testConvertingKituraRequestToTitanRequest() {
        let body = "Some body goes here"
        let length = "\(body.utf8.count)"
        let session = URLSession(configuration: .default)

        let requestExp = expectation(description: "requestReceived")
        var titanRequestConvertedFromKitura: TitanCore.RequestType!
        titanInstance.addFunction { (request, response) -> (TitanCore.RequestType, TitanCore.ResponseType) in
            titanRequestConvertedFromKitura = request
            requestExp.fulfill()
            return (request, response)
        }

        // Make the request

        guard let url = URL(string: "http://localhost:\(port)/complexPath/with/comps?query=string&value=stuff") else {
            XCTFail("Can't create URL")
            return
        }
        var r = URLRequest(url: url)
        r.httpMethod = "PATCH"
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        r.setValue(length, forHTTPHeaderField: "Content-Length")
        r.httpBody = body.data(using: .utf8)

        session.dataTask(with: r).resume()

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(titanRequestConvertedFromKitura)
        XCTAssertEqual(titanRequestConvertedFromKitura.path, "/complexPath/with/comps?query=string&value=stuff")
        XCTAssertEqual(titanRequestConvertedFromKitura.body, "Some body goes here")
        XCTAssertEqual(titanRequestConvertedFromKitura.method, .patch)
        XCTAssertEqual(titanRequestConvertedFromKitura.headers["Accept"], "application/json")
        XCTAssertEqual(titanRequestConvertedFromKitura.headers["Content-Length"], "\(length)")
    }

    func testConvertingTitanResponseToKituraResponse() throws {
        let titanResponse = try TitanCore.Response(code: 501, body: "Not implemented; developer is exceedingly lazy",
                                                   headers: HTTPHeaders(dictionaryLiteral: ("Cache-Control", "private")))

        titanInstance.addFunction { (request, _) -> (TitanCore.RequestType, TitanCore.ResponseType) in
            return (request, titanResponse)
        }

        let session = URLSession(configuration: .default)
        var data: Data!, resp: HTTPURLResponse!, err: Swift.Error!
        let x = expectation(description: "Response received")
        session.dataTask(with: URL(string: "http://localhost:\(port)/")!) { (respdata, response, error) in
            data = respdata
            resp = response as? HTTPURLResponse
            err = error
            x.fulfill()
            }.resume()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(err)
        XCTAssertNotNil(data)
        XCTAssertNotNil(resp)

        XCTAssertEqual(resp.statusCode, 501)
        XCTAssertEqual(resp.allHeaderFields["Cache-Control"] as? String, "private")
        XCTAssertEqual(data, "Not implemented; developer is exceedingly lazy".data(using: .utf8)!)
    }

    func testDefaultResponse() {
        let session = URLSession(configuration: .default)
        var data: Data!, resp: HTTPURLResponse!, err: Swift.Error!
        let x = expectation(description: "Response received")
        session.dataTask(with: URL(string: "http://localhost:\(port)/HelloNotFound")!) { (respdata, response, error) in
            data = respdata
            resp = response as? HTTPURLResponse
            err = error
            x.fulfill()
            }.resume()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(err)
        XCTAssertNotNil(data)
        XCTAssertNotNil(resp)

        XCTAssertEqual(resp.statusCode, 404)
    }

    static var allTests: [(String, (TitanKituraAdapterTests) -> () throws -> Void)] {
        return [
            ("testConvertingKituraRequestToTitanRequest", testConvertingKituraRequestToTitanRequest),
            ("testConvertingTitanResponseToKituraResponse", testConvertingTitanResponseToKituraResponse)
        ]
    }
}
