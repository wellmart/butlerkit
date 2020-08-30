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

public struct RequestPath {
    @usableFromInline
    let path: String
}

extension RequestPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.path = value
    }
}

extension RequestPath: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        @usableFromInline
        var path: String
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            self.path = String(reserveCapacity: literalCapacity)
        }
        
        @inlinable
        public mutating func appendLiteral(_ literal: String) {
            path.append(literal)
        }
        
        @inlinable
        public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
            guard let value = value?.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return
            }
            
            path.append(value)
        }
    }
    
    public init(stringInterpolation interpolation: StringInterpolation) {
        self.path = interpolation.path
    }
}
