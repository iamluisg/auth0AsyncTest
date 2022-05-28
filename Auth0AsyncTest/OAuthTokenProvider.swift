//
//  OAuthTokenProvider.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation
import Auth0

/// OAuthTokenProvider is the class implementation of the TokenProvider protocol that leverages the Auth0 SDK in order to login, retrieve access and refresh tokens, update access tokens, and revoke refresh tokens.
class OAuthTokenProvider: TokenProvider {
    
    private var refreshTask: Task<AuthToken, Error>?
    
    let auth0: Auth0.Authentication
    
    init(_ auth0: Auth0.Authentication = Auth0.authentication()) {
        self.auth0 = auth0
    }
    
    func updateAccessToken(refreshToken: String) async throws -> (AuthToken) {
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }
        
        let updateTask = Task { () -> AuthToken in
            defer { refreshTask = nil }
            
            let updateAccesTokenRequest = self.auth0.renew(withRefreshToken: refreshToken, scope: "")
            
            do {
                let credentials = try await updateAccesTokenRequest.start()
                // Map Auth0 Credentials type to interal AuthToken type
                let authToken = AuthToken(accessToken: credentials.accessToken,
                                          refreshToken: credentials.refreshToken)
                return authToken
            } catch {
                throw error
            }
        }
        
        self.refreshTask = updateTask
        return try await updateTask.value
    }
    
    func loginWith(email: String, password: String) async throws -> (AuthToken) {
        // Call to Auth0 SDK would be made here
        return AuthToken(accessToken: "", refreshToken: "")
    }
    
    func revokeRefreshToken(refreshToken: String) async throws {
        // Call to Auth0 SDK would be made here
    }
}
