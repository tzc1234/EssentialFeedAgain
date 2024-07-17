//
//  Date+TestHelpers.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 16/07/2024.
//

import Foundation

extension Date {
    func minusMaxCacheAgeInDays() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func adding(days: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        calendar.date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
