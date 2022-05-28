//
//  AuthService.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

class AuthService {
    // TokenProvider will be implemented by OAuthSDK and do the work of retrieving tokens
    private let tokenProvider: TokenProvider
    private let tokenStore: TokenStore
    
    init(tokenProvider: TokenProvider, tokenStore: TokenStore) {
        self.tokenProvider = tokenProvider
        self.tokenStore = tokenStore
    }
    
    // Access tokens are short-lived tokens that are sent along via headers to the API to access endpoints that require a user to be authorized
    func retrieveAccessToken() throws -> String {
        return try tokenStore.retrieveAccessToken()
    }
    
    // Refresh tokens are long-lived tokens that are used to retrieve new access tokens.
    func retrieveRefreshToken() throws -> String {
        return try tokenStore.retrieveRefreshToken()
    }
    
    // Function that uses the refresh token to retrieve an updated access token
    func refreshAccessToken() async throws -> String {
        let refreshToken = try retrieveRefreshToken()
        let credentials = try await tokenProvider.updateAccessToken(refreshToken: refreshToken)
        return credentials.accessToken
    }
    
    func storeAccessToken(_ token: String) throws {
        return try tokenStore.storeAccessToken(token)
    }
    
    func storeRefreshToken(_ token: String) throws {
        return try tokenStore.storeRefreshToken(token)
    }
}
