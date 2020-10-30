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

public struct RequestManager {
    public static let `default` = RequestManager()
    private let log = Log(category: "Request Manager")
    
    private init() {
    }
    
    @discardableResult
    public func perform<T: Codable>(_ repository: Repository, _ completion: @escaping (RequestResult<T>) -> Void) -> RequestTask? {
        let request = repository.createRequest()
        
        guard let url = URL(string: "\(repository.domain.domain())\(request.path)") else {
            preconditionFailure("Invalid URL")
        }
        
        return perform(url: url, method: request.method) { result in
            switch result {
            case let .success(data):
                do {
                    completion(.success(try data.decodeJson() as T))
                    return
                }
                catch let error {
                    let description = (error as CustomStringConvertible).description
                    
                    log.debug("Decoding Failure: %@", description)
                    completion(.failure(.trace(.decoding(description: description))))
                }
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func perform(url: URL, method: RequestMethod = .get, _ completion: @escaping (RequestResult<Data>) -> Void) -> RequestTask? {
        log.debug("Perform: <%@> %@", method.rawValue, url.description)
        
        let session = URLSession(configuration: URLSessionConfiguration.default.apply {
            $0.timeoutIntervalForRequest = 30
            $0.timeoutIntervalForResource = 30
        })
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, let data = data else {
                if let error = error as NSError? {
                    if error.code != NSURLErrorCancelled {
                        let description = (error as CustomStringConvertible).description
                        
                        log.debug("Request Failure: %@", description)
                        completion(.failure(.trace(.request(description: description))))
                    }
                }
                else {
                    log.debug("No Response")
                    completion(.failure(.noResponse))
                }
                
                return
            }
            
            if response.statusCode < 200 && response.statusCode > 299 {
                log.debug("Server Error: %@", response.statusCode)
                completion(.failure(.trace(.serverError(code: response.statusCode))))
                
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
        return RequestTask(task)
    }
}
