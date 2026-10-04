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

    //    private var capturedFrame: CGImage? = nil
    private var prevCaptureTime = Date()
    private var prevDisplayTime = Date()
    private var count = 0
    private let maxFrames = 10
    private var droppedFrames = 0

    private var permissionGranted = false
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
        print("checking permission")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:  // The user has previously granted access to the camera.
            print("authorized")
            self.permissionGranted = true

        case .notDetermined:  // The user has not yet been asked for camera access.
            print("requesting")
            self.requestPermission()
        // Combine the two other cases into the default case
        default:
            print("no")
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
        captureSession.sessionPreset = .inputPriority

        let videoOutput = AVCaptureVideoDataOutput()

        guard permissionGranted else { return }
        //        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        else { return }

                configureCameraForHighestFrameRate(device: videoDevice)
        switchFormatWithDesiredFPS(device: videoDevice, desiredFPS: 240.0)

        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(
                device: videoDevice
            )
        else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }

        //        captureSession.beginConfiguration()
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "sampleBufferQueue")
        )
        //        videoOutput.alwaysDiscardsLateVideoFrames = false
        captureSession.addOutput(videoOutput)
        //        captureSession.commitConfiguration()
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
                    print(
                        "Current best framerate range: \(String(describing: bestFrameRateRange))"
                    )
                }
            }
        }

        if let bestFormat = bestFormat,
            let bestFrameRateRange = bestFrameRateRange
        {
            do {
                try device.lockForConfiguration()
                let duration = bestFrameRateRange.minFrameDuration
                print("Best frame duration: \(String(describing: duration))")

                device.activeFormat = bestFormat
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration

                device.unlockForConfiguration()
            } catch {
                print("ERROR in configureCameraForHighestFrameRate")
                // Handle error.
            }
        }
    }

    func switchFormatWithDesiredFPS(device: AVCaptureDevice, desiredFPS: Float)
    {
        //        let isRunning = captureSession.isRunning
        //        if (isRunning)
        //        {
        //            captureSession.stopRunning()
        //        }

        var selectedFormat: AVCaptureDevice.Format? = nil
        let maxWidth = 0
        var frameRateRange: AVFrameRateRange? = nil

        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {

                let desc = format.formatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
                let width = Int(dimensions.width)

                if Float(range.minFrameRate) <= desiredFPS
                    && desiredFPS <= Float(range.maxFrameRate)
                    && width >= maxWidth
                {
                    selectedFormat = format
                    frameRateRange = range
                    //                    maxWidth = width;
                }
            }
        }

        if let selectedFormat {
            do {
                try device.lockForConfiguration()
                defer {device.unlockForConfiguration()}
                print("desiredFPS: \(String(describing: desiredFPS))")
                print("format: \(String(describing: selectedFormat))")
                print("frameRateRange: \(String(describing: frameRateRange))")
                print("max width: \(String (describing: maxWidth))")

                device.activeFormat = selectedFormat
                device.activeVideoMinFrameDuration =
                    frameRateRange!.minFrameDuration
                device.activeVideoMaxFrameDuration =
                    frameRateRange!.maxFrameDuration
                
            } catch {
                print("ERROR in switchFormatWithDesiredFPS")
                // handle error
            }
        }

        //        if (isRunning)
        //        {
        //            captureSession.startRunning();
        //        }
    }
}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let captureTime = Date()
        let period = prevCaptureTime.distance(to: captureTime)
        prevCaptureTime = captureTime
        let currFPS = Float(1 / period)
        self.fps = currFPS
//        print("capture fps: \(String (describing: currFPS))")

        // All UI updates should be/ must be performed on the main queue.
        if count == 0 {
            let period = prevDisplayTime.distance(to: captureTime)
            prevDisplayTime = captureTime
            let currFPS = Float(1 / period)
//            print("display fps: \(String (describing: currFPS))")

            guard
                let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            else { return }
            DispatchQueue.main.async { [unowned self] in
                self.frame = cgImage
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
        } else {
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

        count = (count + 1) % maxFrames

        //                self.frameDuration = sampleBuffer.duration // of type CMTime
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        self.droppedFrames += 1
        var mode: CMAttachmentMode = 0
        let reason = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
            attachmentModeOut: &mode
        )
        print(
            "reason \(String(describing: reason)), mode: \(String(describing: mode))"
        )  // Optional(OutOfBuffers)
    }

    // NOTE: look at alwaysDiscardsLateVideoFrames property

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage?
    {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        else { return nil }

        return cgImage
    }
}
