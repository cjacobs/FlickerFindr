//
//  TimeIntervalList.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/7/26.
//

import Foundation

struct TimeEntry<T> {
    let time: Date
    let value: T
}

class TimeIntervalList<T> {
    private var buffer: [TimeEntry<T>] = []
    private var span: TimeInterval

    var count: Int {
        compact()
        return buffer.count
    }
    
    var data: [T] {
        compact()
        return buffer.map { $0.value }
    }

    init(span: TimeInterval) {
        self.span = span
    }

    func append(_ newElement: T, t: Date = Date.now) {
        compact(asOf: t)
        buffer.append(TimeEntry(time: t, value: newElement))
    }

    func removeAll() {
        buffer.removeAll()
    }
    
    private func compact(asOf t:Date = Date.now) {
        buffer.removeAll { entry in
            t.timeIntervalSince(entry.time) > span
        }
    }
}
