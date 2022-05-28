//
//  AuthenticatedHTTPClientDecoratorTests.swift
//  Auth0AsyncTestTests
//
//  Created by Luis Garcia on 5/27/22.
//

import XCTest
@testable import Auth0AsyncTest

class AuthenticatedHTTPClientDecoratorTests: XCTestCase {

    func test_load_withFailedTokenRetrieval_fails() async throws {
        let client = HTTPClientSpy(response: (anyData(), anyHTTPURLResponse()))
        let unsignedRequest = anyRequest()
        
        // the error we want to simulate for the token store
        let expectedError = TokenError.missingToken
        // ensure token store doesn't return a token by passing in an error
        let tokenStore = TokenStoreSpy(expectedError)
        
        // token provider should never be called because the token store fails to retrieve a token, we can pass in an error or success here and it doesn't matter
        let tokenProvider = OAuthManagerSpy(result: .failure(anyNSError()))
        let authService = AuthService(tokenProvider: tokenProvider,
                                      tokenStore: tokenStore)
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, authService: authService)
        
        do {
            _ = try await sut.asyncLoad(from: unsignedRequest)
            XCTFail("Should receive an error")
        } catch {
            // client should not receive a request when token store fails to retrieve a token
            XCTAssertEqual(client.requests, [])
            // assert that the token store returns the expected error
            XCTAssertEqual(error as? TokenError, expectedError)
        }
    }
    
    func test_load_withFailedTokenRefresh_fails() async throws {
        
        let response401 = HTTPURLResponse(url: anyURL(),
                                          statusCode: 401,
                                          httpVersion: nil, headerFields: [:])!
        let client = HTTPClientSpy(response: (anyData(), response401))
        let unsignedRequest = anyRequest()
        
        let mockAccessToken = "mockAccessToken"
        let refreshAccessToken = "refreshAccessToken"
        let tokenStore = TokenStoreSpy(mockAccessToken,
                                       refreshAccessToken)
        
        var signedRequest = unsignedRequest
        signedRequest.addValue(mockAccessToken, forHTTPHeaderField: "Authorization")
        
        let expectedError = NetworkError.non200
        let tokenProvider = OAuthManagerSpy(result: .failure(expectedError))
        let authService = AuthService(tokenProvider: tokenProvider,
                                      tokenStore: tokenStore)
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, authService: authService)
        
        do {
            _ = try await sut.asyncLoad(from: unsignedRequest)
            XCTFail("Should receive an error")
        } catch {
            // client should receive a signed request with the now expired token
            XCTAssertEqual(client.requests, [signedRequest])
            // assert that the token provider is failing with the expected error
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
    
    func test_load_withSuccessfulTokenRequest_signsRequestWithToken() async throws {
        let client = HTTPClientSpy(response: (Data(), anyHTTPURLResponse()))
        let unsignedRequest = anyRequest()
        var signedRequest = unsignedRequest
        
        let mockAccessToken = "mockAccessToken"
        let refreshAccessToken = "refreshAccessToken"
        
        signedRequest.addValue(mockAccessToken, forHTTPHeaderField: "Authorization")
        let credentials = Credentials(accessToken: "access123", refreshToken: "refresh123")
        let authService = AuthService(tokenProvider: OAuthManagerSpy(result: .success(credentials)),
                                      tokenStore: TokenStoreSpy(mockAccessToken,
                                                                refreshAccessToken))
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, authService: authService)
        
        _ = try await sut.asyncLoad(from: unsignedRequest)
        
        XCTAssertEqual(client.requests, [signedRequest])
    }
    
    func test_load_withSuccessfulTokenRequest_signsRequestAndRetrievesExpectedData() async throws {
        let expectedData = anyData()
        let client = HTTPClientSpy(response: (expectedData, anyHTTPURLResponse()))
        
        let mockAccessToken = "mockAccessToken"
        let refreshAccessToken = "refreshAccessToken"
        
        let unsignedRequest = anyRequest()
        var signedRequest = unsignedRequest
        signedRequest.addValue(mockAccessToken, forHTTPHeaderField: "Authorization")
        let credentials = Credentials(accessToken: "access123", refreshToken: "refresh123")
        let authService = AuthService(tokenProvider: OAuthManagerSpy(result: .success(credentials)),
                                      tokenStore: TokenStoreSpy(mockAccessToken,
                                                                refreshAccessToken))
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, authService: authService)
        
        do {
            let (returnedData, _) = try await sut.asyncLoad(from: unsignedRequest)
            XCTAssertEqual(returnedData, expectedData)
        } catch {
            XCTFail("Expected successful response but received error: \(error)")
        }
    }
    
    #warning("I'm just lost exactly on how to write this test. At the moment I don't know how to change the httpResponse I pass in so that it doesn't continue to return with a 401 and stay in a loop in the HTTPClientDecorator after returning from refreshing the token, I don't know how to write a test to ensure that the call to refresh the token is only made once. I've tried several different approaches and have since deleted them. I believe at this moment the best approach would be to handle the refresh logic to not send multiple calls to the token provider service from the AuthenticatedHTTPDecorator, I previously had my logic to prevent multiple calls within the OAuth class that implements the token provider, but that means if we were to ever change the service it'd be necessary to rewrite the code to ensure that multiple calls aren't made and I decided it'd be better to put that in the HTTPDecorator class because that only needs to be written once.")
    func test_load_with401Response_requestsTokenRefreshOnlyOnce() async throws {
        let expectedData = anyData()
        let http401Response = httpResponse(statusCode: 401)
        let client = HTTPClientSpy(response: (expectedData, http401Response))
        
        let mockAccessToken = "mockAccessToken"
        let refreshAccessToken = "refreshAccessToken"
        
        let unsignedRequest = anyRequest()
        var signedRequest = unsignedRequest
        signedRequest.addValue(mockAccessToken,
                               forHTTPHeaderField: "Authorization")
        let credentials = Credentials(accessToken: mockAccessToken,
                                      refreshToken: refreshAccessToken)
        let authService = AuthService(tokenProvider: OAuthManagerSpy(result: .success(credentials)),
                                      tokenStore: TokenStoreSpy(mockAccessToken,
                                                                refreshAccessToken))
        
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, authService: authService)
            XCTFail("Need to write a test here")
        do {
            //
        } catch {
            XCTFail("Expected successful response but received error: \(error)")
        }
    }
    
    class HTTPClientSpy: HTTPClient {
        private(set) var requests: [URLRequest] = []
        private let response: (Data, URLResponse)
        
        init(response: (Data, URLResponse)) {
            self.response = response
        }
        
        func asyncLoad(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
            self.requests.append(urlRequest)
            return response
        }
    }
}


class TokenStoreSpy: TokenStore {
    private var accessToken: String?
    private var refreshToken: String?
    private var error: Error!
    
    init(_ accessToken: String?, _ refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    init(_ error: Error) {
        self.error = error
    }
    
    func storeAccessToken(_ token: String) throws {
        self.accessToken = token
    }
    
    func storeRefreshToken(_ token: String) throws {
        self.refreshToken = token
    }
    
    func retrieveAccessToken() throws -> String {
        guard let token = accessToken else {
            throw error
        }
        return token
    }
    
    func retrieveRefreshToken() throws -> String {
        guard let token = refreshToken else {
            throw error
        }
        return token
    }
}

enum TokenError: Error {
    case missingToken
}


struct Credentials {
    let accessToken: String
    let refreshToken: String
}

class OAuthManagerSpy: TokenProvider {
    let result: Result<(Credentials), Error>
    var refreshTask: Task<AuthToken, Error>?
    
    init(result: Result<(Credentials), Error>) {
        self.result = result
    }
    
    func loginWith(email: String, password: String) async throws -> (AuthToken) {
        switch result {
        case let .success(credentials):
            return AuthToken(accessToken: credentials.accessToken,
                             refreshToken: credentials.refreshToken)
        case let .failure(error):
            throw error
        }
    }
    
    func updateAccessToken(refreshToken: String) async throws -> (AuthToken) {
        switch result {
        case let .success(credentials):
            return AuthToken(accessToken: credentials.accessToken,
                             refreshToken: credentials.refreshToken)
        case let .failure(error):
            throw error
        }
        
        #warning("I previously attempted to prevent multiple calls to refresh the token from here, but I since have changed my mind and do not think this is the proper place for it to go, it should be at a higher point than the implementation of the token provider.")
//        if let refreshTask = refreshTask {
//            return try await refreshTask.value
//        }
//
//        let task = Task { () throws -> AuthToken in
//            defer { refreshTask = nil }
//            switch result {
//            case let .success(credentials):
//                return AuthToken(accessToken: credentials.accessToken,
//                                 refreshToken: credentials.refreshToken)
//            case let .failure(error):
//                throw error
//            }
//        }
//
//        self.refreshTask = task
//
//        return try await task.value
    }
    
    func revokeRefreshToken(refreshToken: String) async throws {
        switch result {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }
}
