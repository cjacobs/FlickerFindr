//
//  Comparable+clamped.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/15/26.
//

import Foundation

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(range.upperBound, max(self, range.lowerBound))
    }
}
