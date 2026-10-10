//
//  FrameHandler.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

// Taken from tutorial at: https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameHandler.swift

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

@Observable class FrameHandler: NSObject {
    var frame: CGImage? = nil
    var fps: Float = 0.0
    var processFps: Float = 0.0
    var desiredFps: Double = 240
    let visibleTimeSpan: TimeInterval = 1
    var droppedFrames: TimeIntervalList<Int>
    var frameDiffValues: TimeIntervalList<Float>

    var blurRadius: Float = 20
    private var prevProcessedFrame: CIImage? = nil
    private var prevDisplayFrame: CIImage? = nil
    private var prevLightLevel: Float = 0.0
    private let temporalFilter = FrameFilter(
        coeff1: CGFloat(0.4),
        coeff2: CGFloat(0.6)
    )

    typealias DeviceMap = [AVCaptureDevice: [(
        format: AVCaptureDevice.Format, frameRate: AVFrameRateRange
    )]]

    var availableDeviceMap: DeviceMap = [:]

    var availableDeviceNames: [String] {
        availableDeviceMap.keys.map { $0.localizedName }
    }

    private var prevCaptureTime = Date()
    private var prevProcessTime = Date()
    private var count = 0
    private let maxFrames = 1

    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    override init() {
        self.droppedFrames = TimeIntervalList<Int>(span: 1.0)
        self.frameDiffValues = TimeIntervalList<Float>(span: 1.0)
        super.init()
    }

    func start() {
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setUpCaptureSession()
            self.captureSession.startRunning()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:  // The user has previously granted access to the camera.
            self.permissionGranted = true

        case .notDetermined:  // The user has not yet been asked for camera access.
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

    
    // AVCaptureVideoStabilizationMode.lowLatency
    func setUpCaptureSession() {
        guard permissionGranted else { return }

        availableDeviceMap = discoverDevices()
        if availableDeviceMap.isEmpty { return }

        let videoOutput = AVCaptureVideoDataOutput()

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        captureSession.sessionPreset = .inputPriority

        let entry = availableDeviceMap.first!
        let device = entry.key
        let format = entry.value.first!.format
        let range = entry.value.first!.frameRate

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            device.activeFormat = format

            //            let desiredFrameDuration = 1 / desiredFps
            //            device.activeVideoMinFrameDuration = CMTime(
            //                seconds: desiredFrameDuration,
            //                preferredTimescale: range.minFrameDuration.timescale
            //            )
            //            device.activeVideoMaxFrameDuration = CMTime(
            //                seconds: desiredFrameDuration,
            //                preferredTimescale: range.maxFrameDuration.timescale
            //            )

            device.activeVideoMinFrameDuration =
                range.minFrameDuration
            device.activeVideoMaxFrameDuration =
                range.maxFrameDuration

        } catch {
            print("ERROR in switchFormatWithDesiredFPS")
            // handle error
        }

        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(
                device: device
            )
        else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "sampleBufferQueue")
        )
        //        videoOutput.alwaysDiscardsLateVideoFrames = false
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        let connection = videoOutput.connection(with: .video)
        guard let connection else {return}
        connection.videoRotationAngle = 90.0
        if connection.isVideoStabilizationSupported {
            print("Stabilization, baby!")
            connection.preferredVideoStabilizationMode = .lowLatency
        }
    }

    func discoverDevices() -> DeviceMap{
        let cameraTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
            .builtInTelephotoCamera,
            .builtInDualCamera,  // Wide + Telephoto combo
            .builtInDualWideCamera,  // Wide + UltraWide combo
            .builtInTripleCamera,  // UltraWide + Wide + Telephoto combo
        ]

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: cameraTypes,
            mediaType: .video,
            position: .back
        )

        let devices = discoverySession.devices
        guard !devices.isEmpty else { fatalError("Missing capture devices.") }

        availableDeviceMap = [:]

        // TODO: factor this out into getAvailableDevices or something
        for device in devices {
            for format in device.formats {
                if let goodRange = format.videoSupportedFrameRateRanges.first(
                    where: {
                        $0.minFrameRate <= desiredFps
                            && desiredFps <= $0.maxFrameRate
                    })
                {
                    availableDeviceMap[device, default: []].append(
                        (format: format, frameRate: goodRange)
                    )
                }
            }
        }

        guard !availableDeviceMap.isEmpty else {
            fatalError("Missing adequate capture devices.")
        }
        return availableDeviceMap
    }
    
    func filterDisplayFrame(frame: CIImage, mask: CIImage) -> CIImage {
        let multFilter = CIBlendKernel.componentMultiply
        let output = multFilter.apply(foreground: frame, background: mask)!
        return temporalFilter.processFrame(frame: output)
    }

    // difference value between 2 processed images
    func imageDifference(image: CIImage, image2: CIImage) -> CIImage? {
        let diffFilter = CIFilter.colorAbsoluteDifference()
        diffFilter.inputImage = image
        diffFilter.inputImage2 = image2
        let diffImage = diffFilter.outputImage!

        let maxFilter = CIBlendKernel.componentMax
        let maxImage = maxFilter.apply(foreground: image, background: image2)!

        let divisorConst: CGFloat = 0.2
        let constImage = CIImage(
            color: CIColor(
                red: divisorConst,
                green: divisorConst,
                blue: divisorConst
            )
        ).cropped(to: maxImage.extent)
        let addFilter = CIBlendKernel.componentAdd
        let divisorImage = addFilter.apply(
            foreground: maxImage,
            background: constImage
        )!

        let divideFilter = CIBlendKernel.divide  // bg / fg
        let divideImage = divideFilter.apply(
            foreground: divisorImage,
            background: diffImage
        )

        return divideImage
    }

    // preprocessing images before they're differenced
    func preprocessFrame(_ image: CIImage, blurRadius: Float = 2) -> CIImage {
        let falseColorFilter = CIFilter.falseColor()
        falseColorFilter.color0 = .black
        falseColorFilter.color1 = .white
        falseColorFilter.inputImage = image

        let grayscale = falseColorFilter.outputImage!
        let gray = grayscale.applyingFilter(
            "CIGaussianBlur",
            parameters: [
                kCIInputRadiusKey: NSNumber(value: blurRadius)
            ]
        ).cropped(
            to: grayscale.extent.insetBy(
                dx: CGFloat(blurRadius),
                dy: CGFloat(blurRadius)
            )
        )

        let gamma = CIFilter.gammaAdjust()
        gamma.inputImage = gray
        gamma.power = 4

        let output = gamma.outputImage!
        return output
    }

    func averageBrightness(_ image: CIImage) -> Float? {
        let cropVector = CIVector(cgRect: image.extent)

        let outputImage = image.applyingFilter(
            "CIAreaAverage",
            parameters: [
                kCIInputImageKey: image, kCIInputExtentKey: cropVector,
            ]
        )

        guard
            let cgImage = context.createCGImage(
                outputImage,
                from: CGRect(x: 0, y: 0, width: 1, height: 1)
            ),
            let dataProvider = cgImage.dataProvider,
            let data = CFDataGetBytePtr(dataProvider.data)
        else { return nil }

        // TODO: convert RGB to Luminance
        return Float(data[1]) / 255
    }

}

//
// AVCaptureVideoDataOutputSampleBufferDelegate protocol
//
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    //
    // Captured a frame handler
    //
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let captureTime = Date.now
        let capturePeriod = prevCaptureTime.distance(to: captureTime)
        prevCaptureTime = captureTime
        let captureFPS = Float(1 / capturePeriod)

        // set per-frame state
        DispatchQueue.main.async { [unowned self] in
            self.fps = captureFPS
        }

        defer { count = (count + 1) % maxFrames }

        if count > 0 { return }
        let processPeriod = prevProcessTime.distance(to: captureTime)
        prevProcessTime = captureTime
        let processFPS = Float(1 / processPeriod)
        DispatchQueue.main.async { [unowned self] in
            self.processFps = processFPS
        }

        guard let imageBuffer = sampleBuffer.imageBuffer?.copy() ?? nil
        else { return }

        //        let frameDuration = sampleBuffer.duration

        let inputImage = CIImage(cvPixelBuffer: imageBuffer)

        let processedFrame = preprocessFrame(
            inputImage,
            blurRadius: self.blurRadius
        )
        defer { self.prevProcessedFrame = processedFrame }

        guard let prevProcessedFrame else { return }

        let maskImage = imageDifference(
            image: processedFrame,
            image2: prevProcessedFrame
        )

        guard let maskImage else { return }

        let currentLightLevel = averageBrightness(maskImage) ?? 0
        defer { prevLightLevel = currentLightLevel }
        let diff = abs(currentLightLevel - prevLightLevel)
        self.frameDiffValues.append(diff, t: captureTime)

        let displayFrame = filterDisplayFrame(
            frame: inputImage,
            mask: maskImage
        )

        guard
            let cgImage = context.createCGImage(
                displayFrame,
                from: displayFrame.extent
            )
        else { return }

        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }

    }

    //
    // Dropped frame handler
    //
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        DispatchQueue.main.async { [unowned self] in
            self.droppedFrames.append(1)
        }

        /*
        let reason = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
            attachmentModeOut: nil
        )
        print(
            "reason \(String(describing: reason))"
        )
         */
    }
}
