import Foundation
import Vapor
import XCTVapor
@testable import App

final class GeneralTests: XCTestCase {
    
    /// Test GET /, which should unconditionally return the text "success".
    func testRootEndpoint() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, ServerEndpoints.root, afterResponse: { response in
            let bodyString = String(buffer: response.body)
            XCTAssertEqual(bodyString, "success")
        })
        
    }
    
}

