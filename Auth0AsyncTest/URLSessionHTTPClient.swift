//
//  URLSessionHTTPClient.swift
//  Auth0AsyncTest
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

/// URLSessionProtocol allows us to easily mock only the methods we use from URLSession
public protocol URLSessionProtocol {
    func loadData(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Conforming URLSession to URLSessionProtocol simply passes the functions from URLSessionProtocol to the actual URLSession functions. There is no manipulation done to ensure that URLSession is working as expected.
extension URLSession: URLSessionProtocol {
    public func loadData(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await self.data(for: request)
    }
}

/// URLSessionHTTPClient is a URLSession-based implementation of HTTPClient
class URLSessionHTTPClient: HTTPClient {
    let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func asyncLoad(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, urlResponse) = try await session.loadData(for: urlRequest)
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                 throw NetworkError.nonHTTPURLResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.non200
            }
            
            return (data, urlResponse)
        } catch {
            throw error
        }
    }
}

enum NetworkError: Error {
    case non200
    case nonHTTPURLResponse
}
