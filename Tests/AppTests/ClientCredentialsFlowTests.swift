import Foundation
import Vapor
import XCTVapor
import NIO
import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyExampleContent
@testable import App

final class ClientCredentialsFlowTests: XCTestCase {

    var app: Application!

    override func setUp() {
        self.app = Application(.testing)
    }

    override func tearDown() {
        self.app.shutdown()
    }

    /// client-credentials-flow/retrieve-tokens.
    func testRetrieveTokens() throws {
        
        try configure(self.app)

        try self.app.test(
            .POST, ServerEndpoints.clientCredentialsFlowRetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(ClientCredentialsTokensRequest())
            },
            afterResponse: { response in
                
                XCTAssertEqual(
                    response.status, .ok,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))"
                    """
                )

                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    "response headers should contain " +
                    "Content-Type: application/json header: \(response.headers)"
                )

                let authInfo = try response.content.decode(AuthInfo.self)
                
                let accessToken = try XCTUnwrap(
                    authInfo.accessToken, "access token was nil"
                )
                let expirationDate = try XCTUnwrap(
                    authInfo.expirationDate, "expiration date was nil"
                )
                XCTAssertDateIsOneHourFromNow(
                    expirationDate, "invalid expiration date"
                )
                
                let spotifyAPI = SpotifyAPI(
                    authorizationManager: ClientCredentialsFlowManager(
                        clientId: spotifyCredentials.clientId,
                        clientSecret: spotifyCredentials.clientSecret,
                        accessToken: accessToken,
                        expirationDate: expirationDate
                    )
                )
                spotifyAPI.retrieveArtistTest()
                

            }
        )
        
    }
    
    /// Invalid client id and client secret.
    func testInvalidCredentials() throws {
     
        try withInvalidCredentials {
            try configure(self.app)
        }

        try self.app.test(
            .POST, ServerEndpoints.clientCredentialsFlowRetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(ClientCredentialsTokensRequest())
            },
            afterResponse: { response in
                
                XCTAssertEqual(
                    response.status,
                    .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))"
                    """
                )
                
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))"
                    """
                )
                
                let authError = try response.content.decode(
                    SpotifyAuthenticationError.self
                )
                XCTAssertEqual(authError.error, "invalid_client")
                XCTAssertEqual(authError.errorDescription, "Invalid client")
            }
        )

    }
    
    /// Missing the form-url-encoded Content-Type header and the body.
    func testMissingBodyAndInvalidHeader() throws {
        
        try configure(self.app)
        
        try self.app.test(
            .POST, ServerEndpoints.clientCredentialsFlowRetrieveTokens,
            afterResponse: { response in
                
                XCTAssertEqual(
                    response.status,
                    .unsupportedMediaType,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))"
                    """
                )
                
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))"
                    """
                )

                let vaporError = try response.content.decode(
                    VaporServerError.self
                )
                XCTAssertEqual(vaporError.error, true)
                XCTAssertEqual(
                    vaporError.reason,
                    HTTPStatus.unsupportedMediaType.reasonPhrase
                )
            }
        )
        
    }
    
}
