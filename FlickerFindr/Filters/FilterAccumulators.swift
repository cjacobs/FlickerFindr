//
//  MinMaxFilter.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/18/26.
//

import CoreImage
import Foundation
import SwiftUI

// TODO: make a generic version of a CIFilter with 2 inputs, and make min and max be instantiations of that

class FilterAccumulator<FilterType: CIBinaryFilter> {
    private var accumulator: CIImageAccumulator? = nil
    private var shouldClear = true
    let filter: FilterType = FilterType()
    var context: CIContext

    init(context: CIContext) {
        self.context = context
    }

    func reset() {
        print("reset")
        accumulator?.clear()
        shouldClear = true
    }

    var outputImage: CIImage? {
        print("retimg")
        return accumulator?.image()
    }

    // adds a new frame
    func processFrame(frame: CIImage) {
        if accumulator == nil {
            accumulator = CIImageAccumulator(
                extent: frame.extent,
                format: context.workingFormat
            )
            print("init accum")
            shouldClear = true
        }

        guard let accumulator else {
            fatalError("no accumulator!")
        }

        if shouldClear {
            print("clearframe")
            accumulator.setImage(frame)
            shouldClear = false
            return
        }

        filter.inputImage1 = frame
        filter.inputImage2 = accumulator.image()
        guard let output = filter.outputImage else {
            print("failed")
            return
        }
        self.accumulator?.setImage(output)
        print("setinput")
    }
}

typealias MinFilter = FilterAccumulator<CIMinFilter>
typealias MaxFilter = FilterAccumulator<CIMaxFilter>
typealias SumFilter = FilterAccumulator<CISumFilter>
typealias MinMaxSumFilter = FilterAccumulator<CIMinMaxSumFilter>
