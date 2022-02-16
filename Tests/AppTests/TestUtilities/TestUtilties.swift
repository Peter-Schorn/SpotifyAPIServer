import Foundation
import XCTest
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Vapor
import XCTVapor
@testable import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyExampleContent

/// The endpoints for this server.
enum ServerEndpoints {
    
    /**
     GET /
    
     The root endpoint. Returns the text "success". Used to indicate that the
     server is online.
     */
    static let root = ""
    
    /**
     POST client-credentials-flow/retrieve-tokens
     
     Retrieves the authorization information for the [Client Credentials
     Flow][1].
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization/client-credentials/
     */
    static let clientCredentialsFlowRetrieveTokens =
            "client-credentials-flow/retrieve-tokens"
    
    /**
     POST authorization-code-flow/retrieve-tokens

     Retrieves the authorization information for the [Authorization Code
     Flow][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization/code-flow/
     */
    static let authorizationCodeFlowRetrieveTokens =
            "authorization-code-flow/retrieve-tokens"
    
    /**
     POST /authorization-code-flow/refresh-tokens

     Refreshes the access token for the [Authorization Code Flow][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization/code-flow/
     */
    static let authorizationCodeFlowRefreshTokens =
            "authorization-code-flow/refresh-tokens"
    
    /**
     POST authorization-code-flow-pkce/retrieve-tokens
     
     Retrieves the authorization information for the [Authorization Code Flow
     with Proof Key for Code Exchange][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization/code-flow/
     */
    static let authorizationCodeFlowPKCERetrieveTokens =
        "authorization-code-flow-pkce/retrieve-tokens"
    
    /**
     POST /authorization-code-flow-pkce/refresh-tokens
     
     Refreshes the access token for the [Authorization Code Flow with Proof Key
     for Code Exchange][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization/code-flow/
     */
    static let authorizationCodeFlowPKCERefreshTokens =
        "authorization-code-flow-pkce/refresh-tokens"

}

extension HTTPHeaders {
    
    /**
     Returns whether or not these headers contains all of the specified headers.
     
     Header names are compared in a case-insensitive manner. Tests whether each
     value in `self` **starts with** each header value in `headers`.
     
     - Parameter headers: Another instance of `HTTPHeaders`.
     */
    func contains(_ headers: HTTPHeaders) -> Bool {
        
        for header in headers {
            if let value = self.first(name: header.name) {
                return value.starts(with: header.value)
            }
            return false
        }
        return true
    }


}

/// Assert the given date is equal to one hour from now using a tolerance of 60
/// seconds.
func XCTAssertDateIsOneHourFromNow(
    _ date: Date,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
 
    let oneHourFromNow = Date(timeIntervalSinceNow: 3600)
    XCTAssertEqual(
        date.timeIntervalSince1970,
        oneHourFromNow.timeIntervalSince1970,
        accuracy: 60,
        message, file: file, line: line
    )

}

/// The client id and client secret, retrieved from the "CLIENT_ID" and
/// "CLIENT_SECRET" environment variables, respectively.
let spotifyCredentials: (clientId: String, clientSecret: String) = {
    guard let clientId = ProcessInfo.processInfo
            .environment["CLIENT_ID"] else {
        fatalError("could not find 'CLIENT_ID' in the environment variables")
    }
    guard let clientSecret = ProcessInfo.processInfo
            .environment["CLIENT_SECRET"] else {
        fatalError("could not find 'CLIENT_SECRET' in the environment variables")
    }
    return (clientId: clientId, clientSecret: clientSecret)
}()

/// Sets invalid values for the "CLIENT_ID" and "CLIENT_SECRET" environment
/// variables before `body` and then restores them to their previous values
/// afterwards.
func withInvalidCredentials<T>(
    _ body: () throws -> T
) rethrows -> T {
    
    let credentials = spotifyCredentials

    let invalidClientId = "invalidClientId"
    let invalidClientSecret = "invalidClientSecret"

    setenv("CLIENT_ID", invalidClientId, 1)
    setenv("CLIENT_SECRET", invalidClientSecret, 1)
    
    let result = try body()
    
    setenv("CLIENT_ID", credentials.clientId, 1)
    setenv("CLIENT_SECRET", credentials.clientSecret, 1)
    
    XCTAssertNotEqual(
        credentials.clientId, invalidClientId,
        "credentials.clientId should not be invalid"
    )
    XCTAssertNotEqual(
        credentials.clientSecret,
        invalidClientSecret,
        "credentials.clientSecret should not be invalid"
    )

    return result
    
}

/// Removes the "REDIRECT_URI" environment variable for the duration of `body`.
func withNoRedirectURI<T>(
    _ body: () throws -> T
) rethrows -> T {
    
    guard let redirectURI = ProcessInfo.processInfo
            .environment["REDIRECT_URI"] else {
        fatalError("could not find 'REDIRECT_URI' in the environment variables")
    }
    
    unsetenv("REDIRECT_URI")
    
    let result = try body()
    
    setenv("REDIRECT_URI", redirectURI, 1)
    
    return result
    
}


