//
//  AuthService.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

actor AuthService {
    // local variables
    private let refreshTokenRetries = 1
    private var refreshTask: Task<String, Error>?
    
    // TokenProvider will be implemented by Auth0SDK and do the work of retrieving tokens
    private let tokenProvider: TokenProvider
    private let tokenStore: TokenStore
    
    init(tokenProvider: TokenProvider, tokenStore: TokenStore) {
        self.tokenProvider = tokenProvider
        self.tokenStore = tokenStore
    }
    
    /// Retrieve the access token from the local TokenStore. Access tokens are short-lived tokens that are sent along via headers to the API to access endpoints that require a user to be authorized
    nonisolated func retrieveAccessToken() throws -> String {
        return try tokenStore.retrieveAccessToken()
    }
    
    /// Retrieve the refresh token from the local TokenStore. Refresh tokens are long-lived tokens that are used to retrieve new access tokens from the TokenProvider
    nonisolated func retrieveRefreshToken() throws -> String {
        return try tokenStore.retrieveRefreshToken()
    }
    
    /// Function that uses the refresh token to retrieve an updated access token from the TokenProvider. If a serverUnavailable is returned upon attempting to retrieve a token from the token provider, it attempts one retry before throwing an error. All other errors will not be retried
    func refreshAccessToken() async throws -> String {
        // if a refreshTask is not nil then it is currently refreshing and we should just return the same value that the pre-existing task returns
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }
        
        // retrieve the refresh token
        let refreshToken = try retrieveRefreshToken()
        
        // a for loop is used here to attempt a single retry in the case that a serverUnavailable error is returned. By changing the refreshTokenRetries constant more retries can be attempted if needed.
        let task = Task { () throws -> String in
            // we want to make sure that refreshTask is set to nil just before the task is exited
            defer { refreshTask = nil }
            
            // this for loop allows retries to be made for a refresh token call to the token provider that fails
            for _ in 0..<refreshTokenRetries {
                do {
                    let credentials = try await tokenProvider.updateAccessToken(refreshToken: refreshToken)
                    return credentials.accessToken
                } catch {
                    if let authError = error as? TokenProviderError {
                        // if the token provider server is unavailable we retry the call, else we throw the error
                        if authError == .serverUnavailable {
                            continue
                        } else {
                            throw error
                        }
                    }
                    throw error
                }
            }
            
            // after exiting the retry loop we have one more try, the retry loop is specifically for retries only. We can think of it as, retry loop count + this call as the total number of calls made.
            let credentials = try await tokenProvider.updateAccessToken(refreshToken: refreshToken)
            return credentials.accessToken
        }
        
        // save a reference to the task created above
        self.refreshTask = task
        
        // await and return the task value
        return try await task.value
    }
    
    nonisolated func storeAccessToken(_ token: String) throws {
        return try tokenStore.storeAccessToken(token)
    }
    
    nonisolated func storeRefreshToken(_ token: String) throws {
        return try tokenStore.storeRefreshToken(token)
    }
}
