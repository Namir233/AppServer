//
//  Version.swift
//  AppServer
//
//  Created by 王振旺 on 2017/7/10.
//
//

import Foundation

class Version: Comparable{
    let major: Int
    let minor: Int
    let maintenance: Int
    let build: Int
    
    init(_ versionStr: String) {
        let strs = versionStr.components(separatedBy: ".")
        major = strs.count > 0 ? Int(strs[0]) ?? 0 : 0
        minor = strs.count > 1 ? Int(strs[1]) ?? 0 : 0
        maintenance = strs.count > 2 ? Int(strs[2]) ?? 0 : 0
        build = strs.count > 3 ? Int(strs[3]) ?? 0 : 0
    }
    
    static func compare(lhs: Version, rhs: Version) -> Int {
        if lhs.major < rhs.major {
            return -1
        } else if lhs.major > rhs.major {
            return 1
        }
        if lhs.minor < rhs.minor {
            return -1
        } else if lhs.minor > rhs.minor {
            return 1
        }
        if lhs.maintenance < rhs.maintenance {
            return -1
        } else if lhs.maintenance > rhs.maintenance {
            return 1
        }
        if lhs.build < rhs.build {
            return -1
        } else if lhs.build > rhs.build {
            return 1
        }
        return 0
    }
    
    public static func ==(lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) == 0
    }
    
    public static func <(lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) < 0
    }
    
    public static func >(lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) > 0
    }
    
    public static func <=(lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) <= 0
    }
    
    public static func >=(lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) >= 0
    }
}
