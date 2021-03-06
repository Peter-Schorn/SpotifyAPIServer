import Foundation
import Crypto
import Vapor

private let symmetricKey: SymmetricKey = {
    let secretKeyString = ProcessInfo.processInfo
             .environment["SECRET_KEY"]!
    
    let keyStringData = secretKeyString.data(using: .utf8)!

    let hash = SHA256.hash(data: keyStringData)
    
    return SymmetricKey(data: hash)

}()

func encrypt(string: String) throws -> String {
    
    do {
        guard let stringData = string.data(using: .utf8) else {
            throw Abort(
                .badRequest,
                reason: "could not convert encrypted string to data"
            )
        }
        
        let sealedBox = try AES.GCM.seal(
            stringData, using: symmetricKey
        )
        
        guard let encryptedString = sealedBox.combined?
                .base64URLEncodedString() else {
            throw Abort(
                .badRequest,
                reason: "could not combine sealed box"
            )
        }
        return encryptedString
        
    } catch let abortError as Abort {
        throw abortError
    } catch {
        throw Abort(
            .badRequest,
            reason: "could not encrypt refresh token"
        )
    }

    
}

func decrypt(string: String) throws -> String {
    
    do {
        guard let stringData = Data(base64URLEncoded: string) else {
            throw Abort(
                .badRequest,
                reason: "could not create data from base64Encoded encrypted string"
            )
        }
        let box = try AES.GCM.SealedBox(combined: stringData)
        let decryptedData = try AES.GCM.open(box, using: symmetricKey)
        guard let decryptedDataString = String(
            data: decryptedData, encoding: .utf8
        ) else {
            throw Abort(
                .badRequest,
                reason: "could not convert decrypted data to string"
            )
        }
        return decryptedDataString
        
    } catch let abortError as Abort {
        throw abortError
    } catch {
        throw Abort(
            .badRequest,
            reason: "could not decrypt refresh token"
        )
    }

    
}

// prevent a request that returns this error from being retried
extension CryptoKitError: AbortError {
    public var status: HTTPResponseStatus { .badRequest }
}
