//
//  StringExtension.swift
//  ruckus
//
//  Created by Gareth on 20/03/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation

extension String {
    func stringTimeToDouble() -> Double {
        let parts = self.components(separatedBy: ":")
        let minsInSeconds = Int(parts[0])! * 60
        let seconds = Int(parts[1])!
        return Double(minsInSeconds + seconds)
    }
    var camelcaseString: String {
        let source = self
        let lower = source.lowercased()
        let end = lower.index(after: source.startIndex)
        let first = lower[...end]
        if source.contains(" ") {
            let cammel = source.capitalized.replacingOccurrences(of: " ", with: "")
            let rest = String(cammel.dropFirst())
            return "\(first)\(rest)"
        } else {
            let rest = String(source.dropFirst())
            return "\(first)\(rest)"
        }
    }
}
