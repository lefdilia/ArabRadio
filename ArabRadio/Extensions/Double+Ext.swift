//
//  Double+Ext.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 24/6/2021.
//

import Foundation

extension Double {
  func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second, .nanosecond]
    formatter.unitsStyle = style
    guard let formattedString = formatter.string(from: self) else { return "" }
    return formattedString
  }
}

extension Int {
    
    func secondsToHoursMinutesSeconds () -> (Int, Int, Int) {
      return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
}
