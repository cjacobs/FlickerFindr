//
//  RingBuffer.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/6/26.
//

import Foundation

class RingBuffer<T> {
    private var capacity: Int = 0
    private var buffer: [T?] = []
    private var defaultValue: T? = nil
    private var currentIndex: Int = 0

    init() {
        
    }
    
    init(capacity: Int, defaultValue: T?) {
        self.capacity = capacity
        self.buffer.reserveCapacity(capacity)
        self.buffer = Array<T?>.init(repeating: defaultValue, count: capacity)
        self.defaultValue = defaultValue
    }
    
    func add(_ element: T) {
        buffer.insert(element, at: currentIndex)
        currentIndex = (currentIndex + 1) % capacity
    }
    
    var data: any Collection<T> {
        // concatenate buffer[currentIndex..<capacity]
        // and buffer[0..<currentIndex]
        let firstPart = buffer[self.currentIndex ..< self.capacity].filter { $0 != nil }.map {$0!}
        let secondPart = buffer[0 ..< self.currentIndex]

        let result = (firstPart + secondPart).filter { $0 != nil }.map {$0!}
        return result
    }
}
