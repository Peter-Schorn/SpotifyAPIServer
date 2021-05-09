import Vapor
import SpotifyWebAPI

// MARK: TODO: move somewhere else
let redirectURIString = ProcessInfo.processInfo
    .environment["REDIRECT_URI"]!
let redirectURI = URL(string: redirectURIString)!

let clientId = ProcessInfo.processInfo
    .environment["SPOTIFY_SWIFT_TESTING_CLIENT_ID"]!
let clientSecret = ProcessInfo.processInfo
    .environment["SPOTIFY_SWIFT_TESTING_CLIENT_SECRET"]!

func routes(_ app: Application) throws {
    
    // MARK: - Helpers -
    
    let credentialsHeader = Headers.basicBase64Encoded(
        clientId: clientId,
        clientSecret: clientSecret
    )!

    /// Sends a request to Spotify for the authorization information, encrypts
    /// the recieved refresh token, and forwards along the response from Spotify
    /// as the response from this server.
    func retrieveAuthInfo<C: Content>(
        request: Request,
        additionalHeaders: [String: String],
        body: C
    ) -> EventLoopFuture<ClientResponse> {
        
        let routeString = request.route.flatMap(String.init) ?? "nil"

        return request.client.post(
            Endpoints.getTokensURI,
            headers: HTTPHeaders(dictionary: additionalHeaders)
        ) { tokensRequest in
            
            try tokensRequest.content.encode(body)
            
            let bodyString = tokensRequest.body.map(String.init(buffer:))
                ?? "nil"

            request.logger.debug(
                "\(routeString): sending request to Spotify: \(bodyString)"
            )
            
        }
        .map { clientResponse -> ClientResponse in

            // Only try to decode into `AuthInfo` if the status code is 200. If
            // Spotify returns an error object, then let the client handle that.
            guard clientResponse.status == .ok else {
                return clientResponse
            }

            do {
                
                let authInfo = try clientResponse.content.decode(AuthInfo.self)
                
                // We only need to encrypt the refresh token. If this request
                // did not return a refresh token (e.g.,
                // the 'client-credentials-tokens' endpoint), then there's no
                // encryption to do.
                guard let refreshToken = authInfo.refreshToken else {
                    return clientResponse
                }
                
                let encryptedRefreshToken = try encrypt(string: refreshToken)
                let encryptedAuthInfo = AuthInfo(
                    accessToken: authInfo.accessToken,
                    refreshToken: encryptedRefreshToken,
                    expirationDate: authInfo.expirationDate,
                    scopes: authInfo.scopes
                )
                
                // Only the refresh token is encrypted.
                var encryptedClientResponse = clientResponse

                try encryptedClientResponse.content.encode(
                    encryptedAuthInfo
                )
                
                request.logger.info(
                    "\(routeString): returning encrypted authInfo"
                )

                return encryptedClientResponse
                
            } catch {
                request.logger.error(
                    """
                    \(routeString): couldn't decode `AuthInfo` or encrypt \
                    refresh token: \(error)
                    """
                )
                // Don't return the error. Return the response from Spotify.
                return clientResponse
            }

        }
        
    }
    
    // Used for testing if the server is online.
    app.post { request -> String in
        return "success"
    }

    // MARK: - Client Credentials Flow: Retrieve Tokens -
    app.post(
        "client-credentials-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        // The body should be the following in "x-www-form-urlencoded" format:
        // "grant_type=client_credentials".
        let body = try request.content.decode(
            ClientCredentialsTokensRequest.self
        )
        request.logger.debug("client-credentials-tokens: body: \(body)")

        return retrieveAuthInfo(
            request: request,
            additionalHeaders: credentialsHeader,
            body: body
        )

    }

    // MARK: - Authorization Code Flow: Retrieve Tokens -
    app.post(
        "authorization-code-flow", "retrieve-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
    
        let remoteTokensRequest = try request.content.decode(
            ProxyTokensRequest.self
        )
        request.logger.debug(
            """
            authorization-code-flow/retrieve-tokens: request body: \
            \(remoteTokensRequest)
            """
        )
    
        let body = TokensRequest(
            code: remoteTokensRequest.code,
            redirectURI: redirectURI,
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        return retrieveAuthInfo(
            request: request,
            additionalHeaders: [:],
            body: body
        )
    
    }

    // MARK: - Authorization Code Flow: Refresh Tokens -
    app.post(
        "authorization-code-flow", "refresh-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        let refreshTokensRequest = try request.content.decode(
            RefreshTokensRequest.self
        )
        request.logger.debug(
            """
            authorization-code-flow/refresh-tokens: request body: \
            \(refreshTokensRequest)
            """
        )
        
        let decryptedRefreshToken = try decrypt(
            string: refreshTokensRequest.refreshToken
        )
        let decryptedPKCERefreshTokensRequest = RefreshTokensRequest(
            refreshToken: decryptedRefreshToken
        )

        return retrieveAuthInfo(
            request: request,
            additionalHeaders: credentialsHeader,
            body: decryptedPKCERefreshTokensRequest
        )
        
    }
    
    // MARK: - Authorization Code Flow PKCE: Retrieve Tokens -
    app.post(
        "authorization-code-flow-pkce", "retrieve-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        let remotePKCETokensRequest = try request.content.decode(
            ProxyPKCETokensRequest.self
        )
        request.logger.debug(
            """
            authorization-code-flow-pkce/retrieve-tokens: request body: \
            \(remotePKCETokensRequest)
            """
        )
        
        let body = PKCETokensRequest(
            code: remotePKCETokensRequest.code,
            codeVerifier: remotePKCETokensRequest.codeVerifier,
            redirectURI: redirectURI,
            clientId: clientId
        )
        
        return retrieveAuthInfo(
            request: request,
            additionalHeaders: [:],
            body: body
        )
        
    }

    // MARK: - Authorization Code Flow PKCE: Refresh Tokens -
    app.post(
        "authorization-code-flow-pkce", "refresh-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        let refreshTokensRequest = try request.content.decode(
            ProxyPKCERefreshTokensRequest.self
        )
        request.logger.debug(
            """
            authorization-code-flow-pkce/refresh-tokens: request body: \
            \(refreshTokensRequest)
            """
        )
        
        let decryptedRefreshToken = try decrypt(
            string: refreshTokensRequest.refreshToken
        )
        let body = PKCERefreshTokensRequest(
            refreshToken: decryptedRefreshToken,
            clientId: clientId
        )

        return retrieveAuthInfo(
            request: request,
            additionalHeaders: credentialsHeader,
            body: body
        )
        
    }
    
}

