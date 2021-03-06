import Vapor
import SpotifyWebAPI

func routes(_ app: Application) throws {
    
    // MARK: - Constants -

    guard let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"] else {
        fatalError("could not find 'CLIENT_ID' in environment variables")
    }
    
    guard let clientSecret = ProcessInfo.processInfo
            .environment["CLIENT_SECRET"] else {
        fatalError("could not find 'CLIENT_SECRET' in environment variables")
    }

    let redirectURI: URL? = {
        if let redirectURIString = ProcessInfo.processInfo
                .environment["REDIRECT_URI"] {
            if let redirectURI = URL(string: redirectURIString) {
                return redirectURI
            }
            fatalError(
                "could not convert redirect URI to URL: '\(redirectURIString)'"
            )
        }
        return nil
    }()

    guard let credentialsHeader = Headers.basicBase64Encoded(
        clientId: clientId,
        clientSecret: clientSecret
    ) else {
        fatalError(
            "could not create credentialsHeader from client id and client " +
            "secret"
        )
    }
       
    // MARK: - Helpers -

    /// Sends a request to Spotify for the authorization information, encrypts
    /// the received refresh token, and forwards along the response from Spotify
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

            request.logger.info(
                """
                \(routeString): sending request to Spotify:
                headers: \(tokensRequest.headers)
                body: \(bodyString)
                """
            )
            
        }
        .flatMapThrowing { clientResponse -> ClientResponse in

            // Only try to decode into `AuthInfo` if the status code is 200. If
            // Spotify returns an error object, then let the client handle that.
            guard clientResponse.status == .ok else {
                return clientResponse
            }

            let authInfo = try clientResponse.content.decode(AuthInfo.self)

            request.logger.info(
                """
                \(routeString): received auth info:
                \(authInfo)
                """
            )

            // We only need to encrypt the refresh token. If this request did
            // not return a refresh token (e.g., the
            // /client-credentials-flow/retrieve-tokens endpoint), then there's
            // no encryption to do.
            guard let refreshToken = authInfo.refreshToken else {
                return clientResponse
            }

            // Could throw an `Abort` error.
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

        }
        
    }
    
    // Used for testing if the server is online.
    app.get { request -> String in
        return "success"
    }

    // MARK: - Client Credentials Flow: Retrieve Tokens -
    app.post(
        "client-credentials-flow", "retrieve-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        // The body should be the following in "x-www-form-urlencoded" format:
        // "grant_type=client_credentials".
        let body = try request.content.decode(
            ClientCredentialsTokensRequest.self
        )
        request.logger.info(
            "client-credentials-flow/retrieve-tokens: body: \(body)"
        )

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
    
        let proxyTokensRequest = try request.content.decode(
            ProxyTokensRequest.self
        )
        request.logger.info(
            """
            authorization-code-flow/retrieve-tokens: request body: \
            \(proxyTokensRequest)
            """
        )
    
        guard let redirectURI = proxyTokensRequest.redirectURI ?? redirectURI else {
            throw Abort(
                .badRequest,
                reason: """
                    the redirect URI must be present in either the body of \
                    this request or the 'REDIRECT_URI' environment variable
                    """
            )
        }
        
        let body = TokensRequest(
            code: proxyTokensRequest.code,
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
        request.logger.info(
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
        
        let proxyPKCETokensRequest = try request.content.decode(
            ProxyPKCETokensRequest.self
        )
        request.logger.info(
            """
            authorization-code-flow-pkce/retrieve-tokens: request body: \
            \(proxyPKCETokensRequest)
            """
        )
        
        guard let redirectURI = proxyPKCETokensRequest.redirectURI ?? redirectURI else {
            throw Abort(
                .badRequest,
                reason: """
                    the redirect URI must be present in either the body of \
                    this request or the 'REDIRECT_URI' environment variable
                    """
            )
        }
        
        let body = PKCETokensRequest(
            code: proxyPKCETokensRequest.code,
            codeVerifier: proxyPKCETokensRequest.codeVerifier,
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
        request.logger.info(
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
