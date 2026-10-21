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
    private var clear = true
    let filter: FilterType = FilterType()
    var context: CIContext

    init(context: CIContext) {
        self.context = context
    }

    func reset() {
        accumulator?.clear()
        clear = true
    }

    var outputImage: CIImage? {
        accumulator?.image()
    }

    @discardableResult func processFrame(frame: CIImage) -> CIImage {
        if accumulator == nil {
            accumulator = CIImageAccumulator(
                extent: frame.extent,
                format: context.workingFormat
            )
            clear = true
        }

        guard let accumulator else {
            print("no accumulator!")
            return frame
        }

        if clear {
            accumulator.setImage(frame)
            print("first frame")
            clear = false
            return frame
        }

        filter.inputImage1 = frame
        filter.inputImage2 = accumulator.image()
        guard let output = filter.outputImage else {
            print("failed")
            return frame
        }
        self.accumulator?.setImage(output)
        return output
    }
}

typealias MinFilter = FilterAccumulator<CIMinFilter>
typealias MaxFilter = FilterAccumulator<CIMaxFilter>
typealias SumFilter = FilterAccumulator<CISumFilter>
typealias MinMaxSumFilter = FilterAccumulator<CIMinMaxSumFilter>
