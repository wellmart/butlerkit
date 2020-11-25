//
//  ButlerKit
//
//  Copyright (c) 2020 Wellington Marthas
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Adrenaline

#if canImport(UIKit)
import UIKit
#endif

public final class RequestManager {
    public static let `default` = RequestManager()
    
    private let log = Log(category: "Request Manager")
    private var urlSession: URLSession?
    
    private init() {
    }
    
    public func prepare(delegate: URLSessionDelegate? = nil) {
        let configuration = URLSessionConfiguration.ephemeral.apply {
            $0.timeoutIntervalForRequest = 30
            $0.timeoutIntervalForResource = 30
        }
        
        #if canImport(UIKit)
        configuration.httpAdditionalHeaders = ["User-Agent": UIDevice.current.userAgent]
        #endif
        
        self.urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    @discardableResult
    public func perform<T: Codable>(_ repository: Repository, _ completion: @escaping (RequestResult<T>) -> Void) -> RequestTask? {
        let request = repository.createRequest()
        
        guard let url = URL(string: "https://\(repository.domain.rawValue)\(request.path)") else {
            preconditionFailure("Invalid URL")
        }
        
        return perform(url: url, method: request.method) { [self] result in
            switch result {
            case let .success(data):
                do {
                    completion(.success(try data.decodeJson() as T))
                    return
                }
                catch let error {
                    let description = (error as CustomStringConvertible).description
                    
                    log?.debug("🔶 DECODING FAILURE: %@", description)
                    completion(.failure(.firstChance(.decoding(description: description))))
                }
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func perform(url: URL, method: RequestMethod = .get, _ completion: @escaping (RequestResult<Data>) -> Void) -> RequestTask? {
        guard let urlSession = urlSession else {
            preconditionFailure("Request manager not prepared")
        }
        
        log?.debug("Perform: %@ %@", method.rawValue, url.description)
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        #if DEBUG
        log?.debug("-------> %@", request.stringCurl())
        #endif
        
        let task = urlSession.dataTask(with: request) { [self] data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse else {
                if let error = error as NSError? {
                    if error.code != NSURLErrorCancelled {
                        let description = (error as CustomStringConvertible).description
                        
                        log?.debug("🔶 REQUEST FAILURE: %@", description)
                        completion(.failure(.firstChance(.request(description: description))))
                    }
                }
                else {
                    log?.debug("No response")
                    completion(.failure(.noResponse))
                }
                
                return
            }
            
            if response.statusCode < 200 && response.statusCode > 299 {
                log?.debug("🔶 SERVER ERROR: %@", response.statusCode)
                completion(.failure(.firstChance(.serverError(code: response.statusCode))))
                
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
        return RequestTask(task)
    }
}
