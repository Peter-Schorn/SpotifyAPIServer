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

    /// Sends a request to Spotify for the authorization information and
    /// forwards along the response from Spotify as the response from this
    /// server.
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
                "\(routeString): sending request to Spotify: \(bodyString)"
            )
            
        }
        .always { result in
            let resultString: String
            switch result {
                case .success(let response):
                    resultString = String(describing: response)
                case .failure(let error):
                    resultString = String(describing: error)
            }
            request.logger.info(
                "\(routeString): response from Spotify: \(resultString)"
            )
        }
        
    }
    
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
        request.logger.info("client-credentials-tokens: body: \(body)")

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
            RemoteTokensRequest.self
        )
        request.logger.info(
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
        
        let refreshAccessTokenRequest = try request.content.decode(
            RefreshAccessTokenRequest.self
        )
        request.logger.info(
            """
            authorization-code-flow/refresh-tokens: request body: \
            \(refreshAccessTokenRequest)
            """
        )
        
        return retrieveAuthInfo(
            request: request,
            additionalHeaders: credentialsHeader,
            body: refreshAccessTokenRequest
        )
        
    }
    
    // MARK: - Authorization Code Flow PKCE: Retrieve Tokens -
    app.post(
        "authorization-code-flow-pkce", "retrieve-tokens"
    ) { request -> EventLoopFuture<ClientResponse> in
        
        let remotePKCETokensRequest = try request.content.decode(
            RemotePKCETokensRequest.self
        )
        request.logger.info(
            """
            authorization-code-flow-pkce/retrieve-tokens: request body: \
            \(remotePKCETokensRequest)
            """
        )
        
        let body = PKCETokensRequest(
            code: remotePKCETokensRequest.code,
            redirectURI: redirectURI,
            clientId: clientId,
            codeVerifier: remotePKCETokensRequest.codeVerifier
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
        
        let refreshAccessTokenRequest = try request.content.decode(
            RemotePKCERefreshAccessTokenRequest.self
        )
        request.logger.info(
            """
            authorization-code-flow-pkce/refresh-tokens: request body: \
            \(refreshAccessTokenRequest)
            """
        )
        
        let body = PKCERefreshAccessTokenRequest(
            refreshToken: refreshAccessTokenRequest.refreshToken,
            clientId: clientId
        )

        return retrieveAuthInfo(
            request: request,
            additionalHeaders: credentialsHeader,
            body: body
        )
        
    }
    
}

