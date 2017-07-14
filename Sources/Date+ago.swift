//
//  Date+ago.swift
//  AppServer
//
//  Created by 王振旺 on 2017/7/14.
//
//

import Foundation

extension Date {
    
    public func toShortString() -> String {
        let Minute = 60.0
        let Hour = 60 * Minute
        let Day = 24 * Hour
        
        // 这里通过 舍去 Day 的余数得到当天0点的时间，但是由于该时间是 GMT 的时间，所以要补上当前时区的时间
        let timeZone = TimeZone.current
        let timeZoneOffset = TimeInterval(timeZone.secondsFromGMT())
        let time = timeIntervalSince1970 + timeZoneOffset
        let timeNow = Date().timeIntervalSince1970 + timeZoneOffset
        
        let timeDifference = timeNow - time
        let dayDifference = floor(timeNow / Day) - floor(time / Day)
        
        if timeDifference < -2 * Minute {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M-d H:mm"
            return dateFormatter.string(from: self)
        } else if timeDifference < 2 * Minute {
            return "刚刚"
        } else if timeDifference < Hour {
            return String(format: "%.lf分钟前", arguments: [timeDifference / Minute])
        } else if timeDifference < 6 * Hour || dayDifference == 0 {
            return String(format: "%.lf小时前", arguments: [timeDifference / Hour])
        } else if dayDifference == 1 {
            return "昨天"
        } else if dayDifference < 7 * Day {
            return String(format: "%.lf天前", arguments: [dayDifference])
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M-d H:mm"
            return dateFormatter.string(from: self)
        }
    }
}
