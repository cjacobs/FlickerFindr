//
//  Histogram.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/6/26.
//

import Foundation

class Histogram<T> where T == Float {
    // input:
    // - bounds on data
    // - num bins
    // - data

    typealias Entry = (range: ClosedRange<Double>, count: Int)
    var data: [T] = []
    var domain: ClosedRange<Double>
    var numBins: Int
    var counts: [Int] = []
    var ranges: [ClosedRange<Double>] = []

    init(data: [T], domain: ClosedRange<Double>, numBins: Int) {
        self.data = data
        self.domain = domain
        self.numBins = numBins
        
        computeBins()
        computeHistogram()
    }
    
    var binWidth : Double {
        (domain.upperBound - domain.lowerBound) / Double(numBins)
    }
    
    func computeBins() {
        for i in 0..<numBins {
            let start = domain.lowerBound + Double(i)*binWidth
            ranges.append(start...start+binWidth)
            counts.append(0)
        }
    }

    func computeHistogram() {
        for value in data {
            let dataValue = Double(value)
            let bin = Int((dataValue - domain.lowerBound) / binWidth)
            if bin >= 0 && bin < numBins{
                counts[bin] += 1
            }
        }
    }

    var binCounts: [Int] {
        return []
    }
}
