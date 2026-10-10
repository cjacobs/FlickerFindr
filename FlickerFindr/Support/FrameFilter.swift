//
//  FrameFilter.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/9/26.
//

import CoreImage
import Foundation

class FrameFilter {
    private var prevFrame: CIImage? = nil
    var coeff1: CGFloat
    var coeff2: CGFloat
    private let addFilter = CIBlendKernel.componentAdd
    private let multFilter = CIBlendKernel.componentMultiply

    init(coeff1: CGFloat, coeff2: CGFloat) {
        self.coeff1 = coeff1
        self.coeff2 = coeff2
    }

    func processFrame(frame: CIImage) -> CIImage {
        // out = coeff1*frame + coeff2*prevFrame

        guard let prevFrame else {
            prevFrame = frame
            return frame
        }

        let coeff1Image = CIImage(
            color: CIColor(red: coeff1, green: coeff1, blue: coeff1)
        ).cropped(to: frame.extent)
        let coeff2Image = CIImage(
            color: CIColor(red: coeff2, green: coeff2, blue: coeff2)
        )

        let term1 = multFilter.apply(
            foreground: frame,
            background: coeff1Image
        )!

        let term2 = multFilter.apply(
            foreground: prevFrame,
            background: coeff2Image
        )!

        let output = addFilter.apply(foreground: term1, background: term2)!.cropped(to: frame.extent)
        self.prevFrame = output
        return output
    }
}
