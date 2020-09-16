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

public struct Request {
    let method: RequestMethod
    let path: String
    
    public static func get(_ path: RequestPath) -> Request {
        return Request(method: .get, path: path.path)
    }
    
    public static func post(_ path: RequestPath) -> Request {
        return Request(method: .post, path: path.path)
    }
    
    public static func put(_ path: RequestPath) -> Request {
        return Request(method: .put, path: path.path)
    }
    
    public static func delete(_ path: RequestPath) -> Request {
        return Request(method: .delete, path: path.path)
    }
    
    @usableFromInline
    init(method: RequestMethod, path: String) {
        self.method = method
        self.path = path
    }
}
