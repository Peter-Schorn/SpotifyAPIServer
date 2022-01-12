import Foundation
import Vapor
import XCTVapor
import NIO
import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyExampleContent
@testable import App

final class AuthorizationCodeFlowPKCETests: XCTestCase {
    
    static let spotify = SpotifyAPI<AuthorizationCodeFlowPKCEManager>.sharedTest

    var app: Application!
    
    override func setUp() {
        self.app = Application(.testing)
    }
    
    override func tearDown() {
        self.app.shutdown()
    }
    
    // MARK: - Retrieve Tokens -
    
    /// Successfully refresh the tokens.
    func retrieveTokens(_ proxyTokensRequest: ProxyPKCETokensRequest) throws {
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(proxyTokensRequest)
            },
            afterResponse: { response in
                
                XCTAssertEqual(
                    response.status, .ok,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
                
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
                
                let authInfo = try response.content.decode(AuthInfo.self)
                
                let accessToken = try XCTUnwrap(
                    authInfo.accessToken, "access token was nil"
                )
                let refreshToken = try XCTUnwrap(
                    authInfo.refreshToken, "refreshToken token was nil"
                )
                let expirationDate = try XCTUnwrap(
                    authInfo.expirationDate, "expiration date was nil"
                )
                XCTAssertEqual(
                    authInfo.scopes,
                    AuthorizationCodeFlowPKCEManager.getRedirectURLScopes
                )
                
                XCTAssertDateIsOneHourFromNow(
                    expirationDate, "invalid expiration date"
                )
                
                let spotifyAPI = SpotifyAPI(
                    authorizationManager: AuthorizationCodeFlowPKCEManager(
                        clientId: spotifyCredentials.clientId,
                        accessToken: accessToken,
                        expirationDate: expirationDate,
                        refreshToken: nil,
                        scopes: authInfo.scopes
                    )
                )
                
                spotifyAPI.retrieveCurrentUserProfileTest()
                
                let refreshTokensRequest = ProxyPKCERefreshTokensRequest(
                    refreshToken: refreshToken
                )
                // ensure that the refresh token is valid and can be decrypted
                try self.refreshTokens(refreshTokensRequest)
                
            }
        )
        
    }
    
    /// Redirect URI in the body and environment.
    func testRetrieveTokensWithBodyAndEnvironmentRedirectURI() throws {
    
        try configure(self.app)
        
        let (baseRedirectURI, code, codeVerifier) = try XCTUnwrap(
            Self.spotify.authorizationManager.getBaseRedirectURIAndCode(),
            "couldn't get base redirect URI"
        )
        
        let proxyTokensRequest = ProxyPKCETokensRequest(
            code: code,
            codeVerifier: codeVerifier,
            redirectURI: baseRedirectURI
        )
        
        try self.retrieveTokens(proxyTokensRequest)
    
    }
    
    /// Redirect URI in the body but not in the environment.
    func testRetrieveTokensWithBodyNoEnvironmentRedirectURI() throws {
        
        try withNoRedirectURI {
            try configure(self.app)
        }
        
        let (baseRedirectURI, code, codeVerifier) = try XCTUnwrap(
            Self.spotify.authorizationManager.getBaseRedirectURIAndCode(),
            "couldn't get base redirect URI"
        )
        
        let proxyTokensRequest = ProxyPKCETokensRequest(
            code: code,
            codeVerifier: codeVerifier,
            redirectURI: baseRedirectURI
        )
        
        try self.retrieveTokens(proxyTokensRequest)
        
    }
    
    /// Redirect URI in the environment but not the body.
    func testRetrieveTokensWithEnvironmentNoBodyRedirectURI() throws {
        
        try configure(self.app)
        
        let (_, code, codeVerifier) = try XCTUnwrap(
            Self.spotify.authorizationManager.getBaseRedirectURIAndCode(),
            "couldn't get base redirect URI"
        )
        
        let proxyTokensRequest = ProxyPKCETokensRequest(
            code: code,
            codeVerifier: codeVerifier,
            redirectURI: nil
        )
        
        try self.retrieveTokens(proxyTokensRequest)
        
    }
    
    /// No redirect URI in either the environment or body of the request.
    func testRetrieveTokensWithNoRedirectURI() throws {
        
        try withNoRedirectURI {
            try configure(self.app)
        }
        
        let fakeAuthorizationCode = "fakeAuthorizationCode"
        let fakeCoderVerifier = "fakeCoderVerifier"

        let proxyTokensRequest = ProxyPKCETokensRequest(
            code: fakeAuthorizationCode,
            codeVerifier: fakeCoderVerifier,
            redirectURI: nil
        )
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(proxyTokensRequest)
            },
            afterResponse: { response in
        
                XCTAssertEqual(
                    response.status, .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                let vaporError = try response.content.decode(
                    VaporServerError.self
                )
        
                XCTAssertEqual(vaporError.error, true)
                XCTAssertEqual(
                    vaporError.reason,
                    "the redirect URI must be present in either the body of " +
                    "this request or the 'REDIRECT_URI' environment variable"
                )
        
            }
        )
        
    }
    
    /// Invalid client id and client secret.
    func testRetrieveTokensInvalidCredentials() throws {
    
        try withInvalidCredentials {
            try configure(self.app)
        }
        
        let (baseRedirectURI, code, codeVerifier) = try XCTUnwrap(
            Self.spotify.authorizationManager.getBaseRedirectURIAndCode(),
            "couldn't get base redirect URI"
        )
        
        let proxyTokensRequest = ProxyPKCETokensRequest(
            code: code,
            codeVerifier: codeVerifier,
            redirectURI: baseRedirectURI
        )
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(proxyTokensRequest)
            },
            afterResponse: { response in
        
                XCTAssertEqual(
                    response.status,
                    .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
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
    
    /// Invalid body.
    func testRetrieveTokensInvalidBody() throws {
        
        try configure(self.app)
        
        let invalidBody = ByteBuffer(string: "{}")
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERetrieveTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                request.body = invalidBody
            },
            afterResponse: { response in
        
                XCTAssertEqual(
                    response.status,
                    .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                let vaporError = try response.content.decode(
                    VaporServerError.self
                )
                XCTAssertEqual(vaporError.error, true)
                XCTAssertEqual(
                    vaporError.reason,
                    "Value of type 'String' required for key 'code'."
                )
        
            }
        )
        
    }
    
    // MARK: - Refresh Tokens -
    
    func refreshTokens(_ refreshTokensRequest: ProxyPKCERefreshTokensRequest) throws {
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERefreshTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(refreshTokensRequest)
            },
            afterResponse: { response in
                
                XCTAssertEqual(
                    response.status, .ok,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
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
                XCTAssertNotNil(
                    authInfo.refreshToken, "refresh token was nil"
                )
                let expirationDate = try XCTUnwrap(
                    authInfo.expirationDate, "expiration date was nil"
                )
                
                XCTAssertDateIsOneHourFromNow(
                    expirationDate, "invalid expiration date"
                )
                
                let spotifyAPI = SpotifyAPI(
                    authorizationManager: AuthorizationCodeFlowPKCEManager(
                        clientId: spotifyCredentials.clientId,
                        accessToken: accessToken,
                        expirationDate: expirationDate,
                        refreshToken: nil,
                        scopes: authInfo.scopes
                    )
                )
                
                spotifyAPI.retrieveCurrentUserProfileTest()
                
            }
        )
        
    }
    
    /// Invalid refresh token, but encrypted correctly.
    func testRefreshTokensInvalidRefreshToken() throws {
        
        try configure(self.app)
        
        let invalidRefreshToken = "invalidRefreshToken"
        let encryptedInvalidRefreshToken = try encrypt(
            string: invalidRefreshToken
        )
        
        let refreshTokensRequest = ProxyPKCERefreshTokensRequest(
            refreshToken: encryptedInvalidRefreshToken
        )
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERefreshTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(refreshTokensRequest)
            },
            afterResponse: { response in
                XCTAssertEqual(
                    response.status, .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                let authError = try response.content.decode(
                    SpotifyAuthenticationError.self
                )
        
                XCTAssertEqual(authError.error, "invalid_grant")
                XCTAssertEqual(
                    authError.errorDescription,
                    "Invalid refresh token"
                )
        
            }
        )
        
    }
    
    /// Invalidly encrypted refresh token.
    func testRefreshTokenInvalidEncryption() throws {
        
        try configure(self.app)
        
        let invalidRefreshToken = "invalidRefreshToken"
        
        let refreshTokensRequest = ProxyPKCERefreshTokensRequest(
            refreshToken: invalidRefreshToken
        )
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERefreshTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                try request.content.encode(refreshTokensRequest)
            },
            afterResponse: { response in
                XCTAssertEqual(
                    response.status, .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                let vaporServerError = try response.content.decode(
                    VaporServerError.self
                )
        
                XCTAssertEqual(vaporServerError.error, true)
                XCTAssertEqual(
                    vaporServerError.reason,
                    "could not decrypt refresh token"
                )
        
            }
        )
        
    }
    
    /// Invalid body.
    func testRefreshTokenInvalidBody() throws {
        
        try configure(self.app)
        
        let invalidBody = ByteBuffer(
            // missing refresh token
            string: #"{ "grant_type": "refresh token" }"#
        )
        
        try self.app.test(
            .POST, ServerEndpoints.authorizationCodeFlowPKCERefreshTokens,
            headers: .formURLEncoded,
            beforeRequest: { request in
                request.body = invalidBody
            },
            afterResponse: { response in
        
                XCTAssertEqual(
                    response.status, .badRequest,
                    """
                    unexpected status code:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                XCTAssert(
                    response.headers.contains(.contentTypeJSON),
                    """
                    response headers should contain content-type: \
                    application/json header:
                    response: \(response)
                    body: \(String(buffer: response.body))
                    """
                )
        
                let vaporServerError = try response.content.decode(
                    VaporServerError.self
                )
        
                XCTAssertEqual(vaporServerError.error, true)
                XCTAssertEqual(
                    vaporServerError.reason,
                    "Value of type 'String' required for key 'refresh_token'."
                )
        
            }
        )
        
    }
    
}
