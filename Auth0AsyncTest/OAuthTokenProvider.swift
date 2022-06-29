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
        let updateAccessTokenRequest = self.auth0.renew(withRefreshToken: refreshToken,
                                                        scope: "")
        
        do {
            let credentials = try await updateAccessTokenRequest.start()
            let authToken = AuthToken(accessToken: credentials.accessToken,
                                      refreshToken: credentials.refreshToken)
            return authToken
        } catch {
            throw self.resolveError(error)
        }
    }
    
    func loginWith(email: String, password: String) async throws -> (AuthToken) {
        // Call to Auth0 SDK would be made here
        return AuthToken(accessToken: "", refreshToken: "")
    }
    
    func revokeRefreshToken(refreshToken: String) async throws {
        // Call to Auth0 SDK would be made here
    }
    
    private func resolveError(_ error: Error) -> TokenProviderError {
        guard let auth0Error = error as? AuthenticationError else {
            #if DEBUG_DEV
            print(error)
            #endif
            return TokenProviderError.unknown
        }
        
        #if DEBUG_DEV
        print(auth0Error)
        #endif
        
        if auth0Error.statusCode == 500 {
            return TokenProviderError.serverUnavailable
        } else if auth0Error.isRuleError {
            return TokenProviderError.unauthorized
        } else if auth0Error.isRefreshTokenDeleted {
            return TokenProviderError.userDeleted
        } else if auth0Error.isAccessDenied {
            return TokenProviderError.accessDenied
        } else if auth0Error.isInvalidCredentials {
            return TokenProviderError.invalidCredentials
        } else if auth0Error.isTooManyAttempts {
            return TokenProviderError.tooManyAttemps
        } else {
            return TokenProviderError.unknown
        }
    }
}


enum TokenProviderError: Error {
    case serverUnavailable
    case unauthorized
    case invalidCredentials
    case userDeleted
    case accessDenied
    case tooManyAttemps
    case unknown
}
