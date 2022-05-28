//
//  TokenProvider.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

// The token provider protocol is the interface for any service that provides the tokens that we use for authentication. This can be OAuth or even our own server if need be.
protocol TokenProvider {
    func loginWith(email: String, password: String) async throws -> (AuthToken)
    func updateAccessToken(refreshToken: String) async throws -> (AuthToken)
    func revokeRefreshToken(refreshToken: String) async throws
}
