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
    private var profiler: ProfilerProtocol?
    
    private init() {
    }
    
    public mutating func enableProfiler() {
        profiler = createProfilerIfSupported(category: "Request Manager")
    }
    
    @discardableResult
    public func perform<T: Codable>(_ repository: Repository, _ completion: @escaping (RequestResult<T>) -> Void) -> RequestTask? {
        let tracing = profiler?.begin(name: "Perform")
        
        defer {
            tracing?.end()
        }
        
        let request = repository.createRequest()
        
        guard let url = URL(string: "\(repository.domain.domain())\(request.path)") else {
            profiler?.debug("Invalid URL")
            completion(.failure(.request(description: "Invalid URL")))
            
            return nil
        }
        
        return perform(url: url, method: request.method) { result in
            switch result {
            case let .success(data):
                do {
                    completion(.success(try data.decodeJson() as T))
                    return
                }
                catch let error {
                    profiler?.debug("Decoding Failure: \(error.localizedDescription)")
                    completion(.failure(.decoding(description: error.localizedDescription)))
                }
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func perform(url: URL, method: RequestMethod = .get, _ completion: @escaping (RequestResult<Data>) -> Void) -> RequestTask? {
        let session = URLSession(configuration: URLSessionConfiguration.default.apply {
            $0.timeoutIntervalForRequest = 15
            $0.timeoutIntervalForResource = 15
        })
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, let data = data else {
                if let error = error as NSError? {
                    if error.code != NSURLErrorCancelled {
                        profiler?.debug("Request Failure: \(error.localizedDescription)")
                        completion(.failure(.request(description: error.localizedDescription)))
                    }
                }
                else {
                    profiler?.debug("No Response")
                    completion(.failure(.noResponse))
                }
                
                return
            }
            
            if response.statusCode < 200 && response.statusCode > 299 {
                profiler?.debug("Server Error: \(response.statusCode)")
                completion(.failure(.serverError(code: response.statusCode)))
                
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
        return RequestTask(task)
    }
}
