//
//  HelperFunctions.swift
//  Auth0AsyncTestTests
//
//  Created by Luis Garcia on 5/27/22.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 10, userInfo: nil)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyRequest() -> URLRequest {
    return URLRequest(url: anyURL())
}

func signRequest(_ request: URLRequest) -> URLRequest {
    var unsigned = request
    unsigned.addValue("Bearer 123", forHTTPHeaderField: "Authorization")
    let signed = unsigned
    return signed
}

func anyData() -> Data {
    return Data("any data".utf8)
}

func httpResponse(statusCode: Int = 200) -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}
