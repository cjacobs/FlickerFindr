//
//  RingBuffer.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/6/26.
//

import Foundation

class RingBuffer<T> {
    private var capacity: Int
    private var buffer: [T] = []
    private var defaultValue: T

    init(capacity: Int, defaultValue: T) {
        self.capacity = capacity
        self.buffer = Array<T>.init(repeating: defaultValue, count: capacity)
        self.defaultValue = defaultValue
    }
}
