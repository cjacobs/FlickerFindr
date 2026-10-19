//
//  FrameFilter.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/9/26.
//

import CoreImage
import Foundation
import SwiftUI

class IIRFilter {
    private var accumulator: CIImageAccumulator? = nil
    var coeff1: CGFloat
    var coeff2: CGFloat
    var context: CIContext
    private let filter = CIAvgFilter()

    init(context: CIContext, coeff1: CGFloat, coeff2: CGFloat) {
        self.coeff1 = coeff1
        self.coeff2 = coeff2
        self.context = context
    }

    func processFrame(frame: CIImage) -> CIImage {
        guard let accumulator else {
            accumulator = CIImageAccumulator(extent: frame.extent, format: context.workingFormat)
            accumulator?.setImage(frame)
            print("first frame")
            return frame
        }

        filter.inputImage1 = frame
        filter.inputImage2 = accumulator.image()
        filter.a1 = Float(coeff1)
        filter.a2 = Float(coeff2)
        guard let output = filter.outputImage else { print("failed")
            return frame }
        self.accumulator?.setImage(output)
        return output
    }
}
