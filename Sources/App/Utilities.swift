import Foundation
import NIOHTTP1
import SpotifyWebAPI
import Vapor

extension NIOHTTP1.HTTPHeaders {
    
    static let formURLEncoded: Self = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    static let contentTypeJSON: Self = [
        "Content-Type": "application/json"
    ]
    
    /// Creates an instance from a standard Swift dictionary.
    ///
    /// - Parameter dictionary: A dictionary of headers.
    init(dictionary: [String: String]) {
        self.init(dictionary.map { $0 })
    }
    
}

extension Endpoints {
    
    /**
     The URL for retrieving refresh and access tokens, and refreshing the
     access token.
     
     This URL is represented using Vapor's `URI` type.

     ```
     "https://accounts.spotify.com/api/token"
     ```
     */
    static let getTokensURI = URI(string: Self.getTokens.absoluteString)

}

extension Data {
    
    /*
     func base64URLEncodedString() -> String {
         return self.base64EncodedString()
             .replacingOccurrences(of: "+", with: "-")
             .replacingOccurrences(of: "/", with: "_")
             .replacingOccurrences(of: "=", with: "")
     }
     */

    init?(
        base64URLEncoded string: String,
        options: Data.Base64DecodingOptions = []
    ) {
        let base64String = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "", with: "=")
        
        self.init(base64Encoded: base64String, options: options)

    }

}

struct GenericError: Error, AbortError {
    
    let message: String
    let status: HTTPResponseStatus
    
    init(_ message: String, status: HTTPResponseStatus = .badRequest) {
        self.message = message
        self.status = status
    }

}

extension GenericError: CustomStringConvertible {
    var description: String {
        return """
            GenericError("\(self.message)")
            """
    }
}

extension ClientCredentialsTokensRequest: Content {
    
    // This property tells vapor to encode instances of this type
    // using the "x-www-form-urlencoded" format by default.
    public static let defaultContentType = HTTPMediaType.urlEncodedForm
    
}

extension TokensRequest: Content {
    public static let defaultContentType = HTTPMediaType.urlEncodedForm
}

extension RefreshAccessTokenRequest: Content {
    public static let defaultContentType = HTTPMediaType.urlEncodedForm
}

extension PKCETokensRequest: Content {
    public static let defaultContentType = HTTPMediaType.urlEncodedForm
}

extension PKCERefreshAccessTokenRequest: Content {
    public static let defaultContentType = HTTPMediaType.urlEncodedForm
}

extension AuthInfo: Content {
    public static let defaultContentType = HTTPMediaType.json
}

/*
 extension <#T#>: Content {
     public static let defaultContentType = HTTPMediaType.urlEncodedForm
 }
 */
