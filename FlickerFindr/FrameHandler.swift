//
//  FrameHandler.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

// Taken from tutorial at: https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameHandler.swift

import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var fps: Float = 0.0

    var prevFrameDifference: Float = 0.0

    private var capturedFrame: CGImage? = nil
    private var prevCaptureTime = Date()
    private var count = 0
    private let maxFrames = 10
    private var droppedFrames = 0
    
    private var permissionGranted = true
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    
    override init() {
        super.init()
        
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.permissionGranted = true
            
        case .notDetermined: // The user has not yet been asked for camera access.
            self.requestPermission()
            
            // Combine the two other cases into the default case
        default:
            self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        // Strong reference not a problem here but might become one in the future.
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else { return }
//        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }

//        configureCameraForHighestFrameRate(device: videoDevice)
        switchFormatWithDesiredFPS(device: videoDevice, desiredFPS: 240.0)
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.beginConfiguration()
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        videoOutput.alwaysDiscardsLateVideoFrames = false
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
        videoOutput.connection(with: .video)?.videoRotationAngle = 90.0
    }
    
    func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?

        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate > bestFrameRateRange?.maxFrameRate ?? 0 {
                    bestFormat = format
                    bestFrameRateRange = range
                    print("Current best framerate range: \(String(describing: bestFrameRateRange))")
                }
            }
        }
        
        if let bestFormat = bestFormat,
           let bestFrameRateRange = bestFrameRateRange {
            do {
                try device.lockForConfiguration()
                let duration = bestFrameRateRange.minFrameDuration
                print("Best frame duration: \(String(describing: duration))")

                device.activeFormat = bestFormat
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration

                device.unlockForConfiguration()
            } catch {
                // Handle error.
            }
        }
    }
    
    func switchFormatWithDesiredFPS(device: AVCaptureDevice, desiredFPS: Float)
    {
        let isRunning = captureSession.isRunning
        if (isRunning) 
        {
            captureSession.stopRunning()
        }
        
        var selectedFormat: AVCaptureDevice.Format? = nil
        var maxWidth = 0
        var frameRateRange: AVFrameRateRange? = nil

        for format in device.formats
        {
            for range in format.videoSupportedFrameRateRanges
            {
                
                let desc = format.formatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
                let width = Int(dimensions.width)

                if (Float(range.minFrameRate) <= desiredFPS && desiredFPS <= Float(range.maxFrameRate) && width >= maxWidth) 
                {
                    selectedFormat = format;
                    frameRateRange = range;
                    maxWidth = width;
                }
            }
        }
        
        if let selectedFormat = selectedFormat
        {
            do
            {
                try device.lockForConfiguration()
                print("desiredFPS: \(String(describing: desiredFPS))")
                print("format: \(String(describing: selectedFormat))")
                print("frameRateRange: \(String(describing: frameRateRange))")
                print("max width: \(String (describing: maxWidth))")

                device.activeFormat = selectedFormat
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
                device.unlockForConfiguration()
            }
            catch {
                // handle error
            }
        }
        
        if (isRunning)
        {
            captureSession.startRunning();
        }
    }

    func imageDifference(_ a: CGImage, _ b: CGImage) -> Float
    {
        return 0.0
    }
    
    func imageDifference3(_ a: CGImage, _ b: CGImage) -> Float
    {
        let compareRect = CGRect(x: 0, y: 0, width: CGFloat(a.width), height: CGFloat(a.height))
        let ciImageA = CIImage(cgImage: a)
        let ciImageB = CIImage(cgImage: b)

        // Maybe try using CIAreaAverage filter -- need to set the rect to use
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else { return 0.0 }
        avgFilter.setDefaults()
        avgFilter.setValue(ciImageA, forKey: kCIInputImageKey)
//        let resultA = avgFilter.outputImage!
        let resultA = avgFilter.value(forKey: kCIOutputImageKey)! as! CIImage
        
        avgFilter.setValue(ciImageB, forKey: kCIInputImageKey)
//        let resultB = avgFilter.outputImage!
        let resultB = avgFilter.value(forKey: kCIOutputImageKey)! as! CIImage

        let extents = CIVector(cgRect: compareRect)
        avgFilter.setValue(extents, forKey: kCIInputExtentKey)

        // The filter has been set up, now set up the CGContext bitmap context the
        // output is drawn to. Set up the context with our supplied buffer.
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var buf: [CUnsignedChar] = Array<CUnsignedChar>(repeating: 255, count: 16)

        guard let context = CGContext(
            data: &buf,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return 0.0 }

        // Now create the core image context CIContext from the bitmap context.
        let ciContextOpts = [
            CIContextOption.workingColorSpace : colorSpace,
            CIContextOption.useSoftwareRenderer : false
            ] as [CIContextOption : Any]

        let ciContext = CIContext(cgContext: context, options: ciContextOpts)

        // Get the output CIImage and draw that to the Core Image context.
        ciContext.draw(resultA, in: CGRect(x: 0, y: 0, width: 1, height: 1),
                     from: resultA.extent)
        let maxValA = Float(max(buf[0], max(buf[1], buf[2])))

        ciContext.draw(resultB, in: CGRect(x: 0, y: 0, width: 1, height: 1),
                     from: resultB.extent)
        let maxValB = Float(max(buf[0], max(buf[1], buf[2])))

        let diff = abs(maxValA - maxValB)

        return diff
    }

    func imageDifference2(_ a: CGImage, _ b: CGImage) -> Float
    {
        let ciImageA = CIImage(cgImage: a)
        let ciImageB = CIImage(cgImage: b)

        guard let diffFilter = CIFilter(name: "CIDifferenceBlendMode") else { return 0.0 }

        diffFilter.setDefaults()
        diffFilter.setValue(ciImageA, forKey: kCIInputImageKey)
        diffFilter.setValue(ciImageB, forKey: kCIInputBackgroundImageKey)

        // Create the area max filter and set its properties.
        guard let areaMaxFilter = CIFilter(name: "CIAreaMaximum") else {
            return 0
        }

        areaMaxFilter.setDefaults()
        areaMaxFilter.setValue(diffFilter.value(forKey: kCIOutputImageKey),
                             forKey: kCIInputImageKey)
        let compareRect = CGRect(x: 0, y: 0, width: CGFloat(a.width), height: CGFloat(a.height))

        let extents = CIVector(cgRect: compareRect)
        areaMaxFilter.setValue(extents, forKey: kCIInputExtentKey)

        // The filters have been setup, now set up the CGContext bitmap context the
        // output is drawn to. Setup the context with our supplied buffer.
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var buf: [CUnsignedChar] = Array<CUnsignedChar>(repeating: 255, count: 16)

        guard let context = CGContext(
            data: &buf,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return 0.0 }

        // Now create the core image context CIContext from the bitmap context.
        let ciContextOpts = [
            CIContextOption.workingColorSpace : colorSpace,
            CIContextOption.useSoftwareRenderer : false
            ] as [CIContextOption : Any]

        let ciContext = CIContext(cgContext: context, options: ciContextOpts)

        // Get the output CIImage and draw that to the Core Image context.
        let valueImage = areaMaxFilter.value(forKey: kCIOutputImageKey)! as! CIImage
        ciContext.draw(valueImage, in: CGRect(x: 0, y: 0, width: 1, height: 1),
                     from: valueImage.extent)

        // This will have modified the contents of the buffer used for the CGContext.
        // Find the maximum value of the different color components. Remember that
        // the CGContext was created with a Premultiplied last meaning that alpha
        // is the fourth component with red, green and blue in the first three.
        let maxVal = max(buf[0], max(buf[1], buf[2]))
        let diff = Float(maxVal)

        return diff
    }

//
//    
//    func compare(leftImage: CGImage, rightImage: CGImage) throws -> Int {
//
//      let left = CIImage(cgImage: leftImage)
//      let right = CIImage(cgImage: rightImage)
//
//      guard let diffFilter = CIFilter(name: "CIDifferenceBlendMode") else {
//        throw ImageDiffError.failedToCreateFilter
//      }
//      diffFilter.setDefaults()
//      diffFilter.setValue(left, forKey: kCIInputImageKey)
//      diffFilter.setValue(right, forKey: kCIInputBackgroundImageKey)
//
//      // Create the area max filter and set its properties.
//      guard let areaMaxFilter = CIFilter(name: "CIAreaMaximum") else {
//        throw ImageDiffError.failedToCreateFilter
//      }
//      areaMaxFilter.setDefaults()
//      areaMaxFilter.setValue(diffFilter.value(forKey: kCIOutputImageKey),
//                             forKey: kCIInputImageKey)
//      let compareRect = CGRect(x: 0, y: 0, width: CGFloat(leftImage.width), height: CGFloat(leftImage.height))
//
//      let extents = CIVector(cgRect: compareRect)
//      areaMaxFilter.setValue(extents, forKey: kCIInputExtentKey)
//
//      // The filters have been setup, now set up the CGContext bitmap context the
//      // output is drawn to. Setup the context with our supplied buffer.
//      let alphaInfo = CGImageAlphaInfo.premultipliedLast
//      let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
//      let colorSpace = CGColorSpaceCreateDeviceRGB()
//
//      var buf: [CUnsignedChar] = Array<CUnsignedChar>(repeating: 255, count: 16)
//
//      guard let context = CGContext(
//        data: &buf,
//        width: 1,
//        height: 1,
//        bitsPerComponent: 8,
//        bytesPerRow: 16,
//        space: colorSpace,
//        bitmapInfo: bitmapInfo.rawValue
//      ) else {
//        throw ImageDiffError.failedToCreateContext
//      }
//
//      // Now create the core image context CIContext from the bitmap context.
//      let ciContextOpts = [
//        CIContextOption.workingColorSpace : colorSpace,
//        CIContextOption.useSoftwareRenderer : false
//      ] as [CIContextOption : Any]
//      let ciContext = CIContext(cgContext: context, options: ciContextOpts)
//
//      // Get the output CIImage and draw that to the Core Image context.
//      let valueImage = areaMaxFilter.value(forKey: kCIOutputImageKey)! as! CIImage
//      ciContext.draw(valueImage, in: CGRect(x: 0, y: 0, width: 1, height: 1),
//                     from: valueImage.extent)
//
//      // This will have modified the contents of the buffer used for the CGContext.
//      // Find the maximum value of the different color components. Remember that
//      // the CGContext was created with a Premultiplied last meaning that alpha
//      // is the fourth component with red, green and blue in the first three.
//      let maxVal = max(buf[0], max(buf[1], buf[2]))
//      let diff = Int(maxVal)
//
//      return diff
//    }
}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let captureTime = Date()
        let period = prevCaptureTime.distance(to: captureTime)
        prevCaptureTime = captureTime
        let currFPS = Float(1 / period)

//        print("running fps: \(String (describing: currFPS))")
        
        // All UI updates should be/ must be performed on the main queue.
        if (count == 0)
        {
//            guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
            DispatchQueue.main.async { [unowned self] in
                fps = Float(1 / period)
//                self.frame = cgImage
//                if (self.frame == nil)
//                {
//                    self.frame = cgImage
//                }
//                else
//                {
//                    self.frame = self.capturedFrame
//                }
                self.prevFrameDifference = 0
            }
        }
        else
        {
//            // diff cgImage and prevFrame, and see if the new one is worse than the last one
//            if (self.frame != nil)
//            {
//                let diff = imageDifference(cgImage, self.frame!)
//                if (diff >= self.prevFrameDifference)
//                {
//                    self.capturedFrame = cgImage
//                    self.prevFrameDifference = diff
//                }
//            }
        }
        
        count = (count+1) % maxFrames;
        
        //                self.frameDuration = sampleBuffer.duration // of type CMTime
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.droppedFrames += 1
        var mode: CMAttachmentMode = 0
        let reason = CMGetAttachment(sampleBuffer,
                                     key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
                                     attachmentModeOut: &mode)
        print("reason \(String(describing: reason)), mode: \(String(describing: mode))") // Optional(OutOfBuffers)
    }

    // NOTE: look at alwaysDiscardsLateVideoFrames property
    
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}
