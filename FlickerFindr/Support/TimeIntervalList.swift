//
//  TimeIntervalList.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/7/26.
//

import Foundation
import AVFoundation

struct TimeEntry<T> {
    let time: CMTime
    let value: T
    typealias ElementType = T
}

class TimeIntervalList<T> {
    var buffer: [TimeEntry<T>] = []
    private var span: TimeInterval
    typealias ElementType = T
    
    private var _currentTime:CMTime = .zero
    var currentTime:CMTime {
        get {
            _currentTime
        }
        set {
            _currentTime = newValue
            compact()
        }
    }
    
    var count: Int {
        return buffer.count
    }
    
    var isEmpty : Bool {
        count == 0
    }
    
    var data: [T] {
        return buffer.map { $0.value }
    }
    
    init(span: TimeInterval) {
        self.span = span
    }
    
    func append(_ newElement: T, t: CMTime) {
        currentTime = t
        compact()
        buffer.append(TimeEntry(time: t, value: newElement))
    }
    
    func removeAll() {
        buffer.removeAll()
    }
    
    private func compact(asOf t:CMTime) {
        buffer.removeAll { entry in
            (t-entry.time).seconds > span
        }}
    
    private func compact() {
        buffer.removeAll { entry in
            (currentTime-entry.time).seconds > span
        }}
    
}

