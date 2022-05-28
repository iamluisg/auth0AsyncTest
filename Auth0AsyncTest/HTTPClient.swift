//
//  HTTPClient.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

/// HTTPClient is a protocol for interfacing with a networking layer
public protocol HTTPClient {
    func asyncLoad(from urlRequest: URLRequest) async throws -> (Data, URLResponse)
}
