//
//  CVPixelBufferExtension.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/9/26.
//

import Foundation
import CoreImage

extension CVPixelBuffer {
    
    // Source - https://stackoverflow.com/a/61864272
    // Posted by Pit WARLORD
    // Retrieved 2026-10-09, License - CC BY-SA 4.0
    
    func copy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        
        var _copy : CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            nil,
            &_copy)
        
        guard let copy = _copy else { fatalError() }
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        
        let copyBaseAddress = CVPixelBufferGetBaseAddress(copy)
        let currBaseAddress = CVPixelBufferGetBaseAddress(self)
        
//        print("copy data size: \(CVPixelBufferGetDataSize(copy))")
//        print("self data size: \(CVPixelBufferGetDataSize(self))")
        
        memcpy(copyBaseAddress, currBaseAddress, CVPixelBufferGetDataSize(copy))
        //memcpy(copyBaseAddress, currBaseAddress, CVPixelBufferGetDataSize(self) * 2)
        
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        
        return copy
    }
}
