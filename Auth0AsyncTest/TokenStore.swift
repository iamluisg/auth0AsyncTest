//
//  TokenStore.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

protocol TokenStore {
    func storeAccessToken(_ token: String) throws
    func storeRefreshToken(_ token: String) throws
    func retrieveAccessToken() throws -> String
    func retrieveRefreshToken() throws -> String
}
