//
//  FrameFilter.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/9/26.
//

import CoreImage
import Foundation
import SwiftUI

class TemporalFilter {
    private var prevFrame: CIImage? = nil
    var coeff1: CGFloat
    var coeff2: CGFloat

    init(coeff1: CGFloat, coeff2: CGFloat) {
        self.coeff1 = coeff1
        self.coeff2 = coeff2
    }

    func processFrame(frame cgFrame: CGImage) -> CIImage {
        let frame:CIImage = CIImage(cgImage: cgFrame)

        guard let prevFrame else {
            prevFrame = frame
            print("first frame")
            return frame
        }

        // maybe we need to use a CIImageAccumulator?
        
        let filter = CIAvgFilter()
        // note: if I pass in 'frame' for both images, the app runs at normal (high) framerate
        // if I pass in 'prevFrame' for both, it bogs down and crashes
        filter.inputImage1 = frame
        filter.inputImage2 = prevFrame
        filter.a1 = Float(coeff1)
        filter.a2 = Float(coeff2)
        let output = filter.outputImage!
        self.prevFrame = output
        return output
    }
}
