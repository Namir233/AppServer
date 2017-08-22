//
//  HMAC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 13/01/15.
//  Copyright (c) 2015 Marcin Krzyzanowski. All rights reserved.
//

public final class HMAC {
    
    public enum Error: Swift.Error {
        case authenticateError
        case invalidInput
    }
    
    public enum Variant {
        
        var digestLength: Int {
            return SHA1.digestLength
        }
        
        func calculateHash(_ bytes: Array<UInt8>) -> Array<UInt8>? {
            return SHA1().calculate(for: bytes)
        }
        
        func blockSize() -> Int {
            return 64
        }
    }
    
    var key: Array<UInt8>
    
    public init(key: Array<UInt8>) {
        self.key = key
        
        if key.count > 64 {
            let hash = SHA1().calculate(for: key)
            self.key = hash
        }
        
        if key.count < 64 {
            self.key = add(to: key, blockSize: 64)
        }
    }
    
    convenience init(key: String) {
        let data = key.data(using: .utf8)!
        self.init(key: Array(data))
    }
    
    fileprivate func hexString(bytes: Array<UInt8>) -> String {
        return bytes.lazy.reduce("") {
            var s = String($1, radix: 16)
            if s.characters.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
    
    fileprivate func add(to bytes: Array<UInt8>, blockSize: Int) -> Array<UInt8> {
        let paddingCount = blockSize - (bytes.count % blockSize)
        if paddingCount > 0 {
            return bytes + Array<UInt8>(repeating: 0, count: paddingCount)
        }
        return bytes
    }
    // MARK: Authenticator
    
    public func authenticate(_ string: String) throws -> String {
        let data = string.data(using: .utf8)!
        let bytes = try authenticate(Array(data))
        return hexString(bytes: bytes)
    }
    
    public func authenticate(_ bytes: Array<UInt8>) throws -> Array<UInt8> {
        var opad = Array<UInt8>(repeating: 0x5c, count: 64)
        for idx in key.indices {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = Array<UInt8>(repeating: 0x36, count: 64)
        for idx in key.indices {
            ipad[idx] = key[idx] ^ ipad[idx]
        }
        
        let ipadAndMessageHash = SHA1().calculate(for: ipad + bytes)
        let result = SHA1().calculate(for: opad + ipadAndMessageHash)
        // return Array(result[0..<10]) // 80 bits
        return result
    }
}
