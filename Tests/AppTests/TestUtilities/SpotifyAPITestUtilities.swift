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

// MARK: - Spotify API -

extension SpotifyAPI where AuthorizationManager == ClientCredentialsFlowManager {
    
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

// MARK: - Authorization -

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
