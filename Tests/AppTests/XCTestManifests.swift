#if !canImport(ObjectiveC)
import XCTest

extension AuthorizationCodeFlowPKCETests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AuthorizationCodeFlowPKCETests = [
        ("testRefreshTokenInvalidBody", testRefreshTokenInvalidBody),
        ("testRefreshTokenInvalidEncryption", testRefreshTokenInvalidEncryption),
        ("testRefreshTokensInvalidRefreshToken", testRefreshTokensInvalidRefreshToken),
        ("testRetrieveTokensInvalidBody", testRetrieveTokensInvalidBody),
        ("testRetrieveTokensInvalidCredentials", testRetrieveTokensInvalidCredentials),
        ("testRetrieveTokensWithBodyAndEnvironmentRedirectURI", testRetrieveTokensWithBodyAndEnvironmentRedirectURI),
        ("testRetrieveTokensWithBodyNoEnvironmentRedirectURI", testRetrieveTokensWithBodyNoEnvironmentRedirectURI),
        ("testRetrieveTokensWithEnvironmentNoBodyRedirectURI", testRetrieveTokensWithEnvironmentNoBodyRedirectURI),
        ("testRetrieveTokensWithNoRedirectURI", testRetrieveTokensWithNoRedirectURI),
    ]
}

extension AuthorizationCodeFlowTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AuthorizationCodeFlowTests = [
        ("testRefreshTokenInvalidBody", testRefreshTokenInvalidBody),
        ("testRefreshTokenInvalidEncryption", testRefreshTokenInvalidEncryption),
        ("testRefreshTokensInvalidRefreshToken", testRefreshTokensInvalidRefreshToken),
        ("testRetrieveTokensInvalidBody", testRetrieveTokensInvalidBody),
        ("testRetrieveTokensInvalidCredentials", testRetrieveTokensInvalidCredentials),
        ("testRetrieveTokensWithBodyAndEnvironmentRedirectURI", testRetrieveTokensWithBodyAndEnvironmentRedirectURI),
        ("testRetrieveTokensWithBodyNoEnvironmentRedirectURI", testRetrieveTokensWithBodyNoEnvironmentRedirectURI),
        ("testRetrieveTokensWithEnvironmentNoBodyRedirectURI", testRetrieveTokensWithEnvironmentNoBodyRedirectURI),
        ("testRetrieveTokensWithNoRedirectURI", testRetrieveTokensWithNoRedirectURI),
    ]
}

extension ClientCredentialsFlowTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ClientCredentialsFlowTests = [
        ("testInvalidCredentials", testInvalidCredentials),
        ("testMissingBodyAndInvalidHeader", testMissingBodyAndInvalidHeader),
        ("testRetrieveTokens", testRetrieveTokens),
    ]
}

extension GeneralTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__GeneralTests = [
        ("testRootEndpoint", testRootEndpoint),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AuthorizationCodeFlowPKCETests.__allTests__AuthorizationCodeFlowPKCETests),
        testCase(AuthorizationCodeFlowTests.__allTests__AuthorizationCodeFlowTests),
        testCase(ClientCredentialsFlowTests.__allTests__ClientCredentialsFlowTests),
        testCase(GeneralTests.__allTests__GeneralTests),
    ]
}
#endif
