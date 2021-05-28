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
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow
     */
    static let clientCredentialsFlowRetrieveTokens =
            "client-credentials-flow/retrieve-tokens"
    
    /**
     POST authorization-code-flow/retrieve-tokens

     Retrieves the authorization information for the [Authorization Code
     Flow][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
     */
    static let authorizationCodeFlowRetrieveTokens =
            "authorization-code-flow/retrieve-tokens"
    
    /**
     POST /authorization-code-flow/refresh-tokens

     Refreshes the access token for the [Authorization Code Flow][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
     */
    static let authorizationCodeFlowRefreshTokens =
            "authorization-code-flow/refresh-tokens"
    
    /**
     POST authorization-code-flow-pkce/retrieve-tokens
     
     Retrieves the authorization information for the [Authorization Code Flow
     with Proof Key for Code Exchange][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce
     */
    static let authorizationCodeFlowPKCERetrieveTokens =
        "authorization-code-flow-pkce/retrieve-tokens"
    
    /**
     POST /authorization-code-flow-pkce/refresh-tokens
     
     Refreshes the access token for the [Authorization Code Flow with Proof Key
     for Code Exchange][1]
     
     [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce
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
    
    setenv("CLIENT_ID", "invalidClientId", 1)
    setenv("CLIENT_SECRET", "invalidClientSecret", 1)
    
    let result = try body()
    
    setenv("CLIENT_ID", credentials.clientId, 1)
    setenv("CLIENT_SECRET", credentials.clientSecret, 1)
    
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

// MARK: - Spotify API -

extension SpotifyAPI {
    
    /// Retrieves an artist to ensure that the access token is valid.
    func retrieveArtistTest(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let expectation = XCTestExpectation(
            description: "artist"
        )
        
        var cancellables: Set<AnyCancellable> = []

        self.networkAdaptor = URLSession.shared.noCacheNetworkAdaptor(request:)

        let artist = URIs.Artists.crumb

        var receivedArtist = false

        self.artist(artist)
            .XCTAssertNoFailure(file: file, line: line)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { artist in
                    receivedArtist = true
                    XCTAssertEqual(artist.name, "Crumb")
                }
            )
            .store(in: &cancellables)
        
        let waiter = XCTWaiter()
        waiter.wait(for: [expectation], timeout: 60)

        XCTAssertTrue(receivedArtist, "never received artist")

        self.networkAdaptor = URLSession._defaultNetworkAdaptor
        
    }
    
}

extension SpotifyAPI where AuthorizationManager == AuthorizationCodeFlowManager {

    /// A shared instance used for testing purposes.
    static let sharedTest = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: spotifyCredentials.clientId,
            clientSecret: spotifyCredentials.clientSecret
        )
    )

    /// Retrieves the user's followed artists to ensure that the access token
    /// is valid and authorized for the `userFollowRead` scope.
    func retrieveFollowedArtistsTest(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let expectation = XCTestExpectation(
            description: "followed artists"
        )
        
        var cancellables: Set<AnyCancellable> = []
        
        self.networkAdaptor = URLSession.shared.noCacheNetworkAdaptor(request:)
        
        var receivedFollowedArtists = false
        
        self.currentUserFollowedArtists()
            .XCTAssertNoFailure(file: file, line: line)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in
                    receivedFollowedArtists = true
                }
            )
            .store(in: &cancellables)
        
        let waiter = XCTWaiter()
        waiter.wait(for: [expectation], timeout: 60)
        
        XCTAssertTrue(
            receivedFollowedArtists,
            "never received followed artists"
        )
        
        self.networkAdaptor = URLSession._defaultNetworkAdaptor
        
    }

}

extension SpotifyAPI where AuthorizationManager == AuthorizationCodeFlowPKCEManager {
    
    /// A shared instance used for testing purposes.
    static let sharedTest = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowPKCEManager(
            clientId: spotifyCredentials.clientId
        )
    )

    /// Retrieves the current user and asserts that
    /// `explicitContentSettingIsLocked` and `allowsExplicitContent` are not
    /// `nil` to ensure the access token is valid and authorized for the
    /// `userReadPrivate` scope.
    func retrieveCurrentUserProfileTest(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let expectation = XCTestExpectation(
            description: "current user"
        )
        
        var cancellables: Set<AnyCancellable> = []
        
        self.networkAdaptor = URLSession.shared.noCacheNetworkAdaptor(request:)
        
        var receivedCurrentUser = false
        
        self.currentUserProfile()
            .XCTAssertNoFailure(file: file, line: line)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { user in
                    XCTAssertNotNil(
                        user.explicitContentSettingIsLocked,
                        "user.explicitContentSettingIsLocked should not be nil"
                    )
                    XCTAssertNotNil(
                        user.allowsExplicitContent,
                        "user.allowsExplicitContent should not be nil"
                    )
                    receivedCurrentUser = true
                }
            )
            .store(in: &cancellables)
        
        let waiter = XCTWaiter()
        waiter.wait(for: [expectation], timeout: 60)
        
        XCTAssertTrue(
            receivedCurrentUser,
            "never received current user profile"
        )
        
        self.networkAdaptor = URLSession._defaultNetworkAdaptor
        
    }
    
}

// MARK: - Authorization

extension AuthorizationCodeFlowManager {
    
    /// The scopes used in `self.getRedirectURL`.
    static var getRedirectURLScopes: Set<Scope> {
        [
            .userFollowRead,
            .streaming
        ]
    }
    
    /// Calls through to `makeAuthorizationURL` then
    /// `openAuthorizationURLAndWaitForRedirect`.
    func getRedirectURI() -> URL? {
        
        let authorizationURL = self.makeAuthorizationURL(
            redirectURI: localHostURL,
            showDialog: false,
            scopes: Self.getRedirectURLScopes
        )!
        
        if let redirectURI = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) {
            return redirectURI
        }
        return nil

    }

    /// Calls through to `getRedirectURI` and parses the base redirect URI and
    /// authorization code.
    func getBaseRedirectURIAndCode(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (baseRedirectURI: URL, code: String) {
        
        let redirectURI = try XCTUnwrap(
            self.getRedirectURI(),
            "couldn't get redirectURL",
            file: file, line: line
        )
        
        let code = try XCTUnwrap(
            redirectURI.queryItemsDict["code"],
            "couldn't get authorization code from redirect URL: \(redirectURI)",
            file: file, line: line
        )
        
        let baseRedirectURI = redirectURI
            .removingQueryItems()
            .removingTrailingSlashInPath()
     
        
        return (baseRedirectURI: baseRedirectURI, code: code)

    }

}

extension AuthorizationCodeFlowPKCEManager {
    
    /// The scopes used in `self.getRedirectURL`.
    static var getRedirectURLScopes: Set<Scope> {
        [
            .userLibraryRead,
            .userReadPrivate
        ]
    }

    
    /// Calls through to `makeAuthorizationURL` then
    /// `openAuthorizationURLAndWaitForRedirect`.
    func getRedirectURI() -> (redirectURI: URL, codeVerifier: String)? {
        
        let codeVerifier = String.randomURLSafe(length: 43)
        let codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)

        let authorizationURL = self.makeAuthorizationURL(
            redirectURI: localHostURL,
            codeChallenge: codeChallenge,
            state: nil,
            scopes: Self.getRedirectURLScopes
        )!
        
        if let redirectURI = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) {
            return (redirectURI: redirectURI, codeVerifier: codeVerifier)
        }
        return nil
        
    }
    
    /// Calls through to `getRedirectURI` and parses the base redirect URI and
    /// authorization code. Also returns the code verifier.
    func getBaseRedirectURIAndCode(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (baseRedirectURI: URL, code: String, codeVerifier: String) {
        
        let (redirectURI, codeVerifier) = try XCTUnwrap(
            self.getRedirectURI(),
            "couldn't get redirectURL",
            file: file, line: line
        )
        
        let code = try XCTUnwrap(
            redirectURI.queryItemsDict["code"],
            "couldn't get authorization code from redirect URL: \(redirectURI)",
            file: file, line: line
        )
        
        let baseRedirectURI = redirectURI
            .removingQueryItems()
            .removingTrailingSlashInPath()
        
        return (
            baseRedirectURI: baseRedirectURI,
            code: code,
            codeVerifier: codeVerifier
        )
        
    }
    
}
