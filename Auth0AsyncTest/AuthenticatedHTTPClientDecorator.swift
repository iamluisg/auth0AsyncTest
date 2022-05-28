//
//  AuthenticatedHTTPClientDecorator.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

public class AuthenticatedHTTPClientDecorator: HTTPClient {
    private let decoratee: HTTPClient
    private let authService: AuthService
    private var pendingRequests: [URLRequest] = []
    
    init(decoratee: HTTPClient, authService: AuthService) {
        self.decoratee = decoratee
        self.authService = authService
    }
 
    public func asyncLoad(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            // first try to get token from store
            let token = try self.authService.retrieveAccessToken()
            var signedRequest = urlRequest
            signedRequest.addValue(token, forHTTPHeaderField: "Authorization")
            
            // token was able to be retrieved from store so we try to make the call with the signed request
            let (data, response) = try await decoratee.asyncLoad(from: signedRequest)
            
            // ensure we can get a status code from the response
            guard let httpURLResponse = response as? HTTPURLResponse else {
                throw NetworkError.nonHTTPURLResponse
            }
            
            // if we get a 401 back it is because we need to refresh the access token
            if httpURLResponse.statusCode == 401 {
                #warning("I honestly don't know if it is better to prevent multiple calls being made from here, or if that should be done within the class that implements the TokenProvider protocol. I feel like it should be here but am not sure.")
                // make call to attempt to refresh the access token
                let refreshedAccessToken = try await authService.refreshAccessToken()
                // try to store the updated token
                try authService.storeAccessToken(refreshedAccessToken)
                // if access token update is successful retry the request
                return try await asyncLoad(from: urlRequest)
                // if status code is within 200-299 return the result
            } else if (200..<300) ~= httpURLResponse.statusCode {
                return (data, response)
            } else {
                throw NetworkError.non200
            }
        } catch {
            throw error
        }
    }
}
