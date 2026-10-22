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

typealias FrameInfo = (difference: Float, frame: CGImage?, dropped: Bool)
typealias TimeIntervalFrameList = TimeIntervalList<FrameInfo>

enum MinMaxDisplay: String, CaseIterable, Identifiable {
    case alternating, diff
    var id: Self { self }
}

enum MaskDisplay: String, CaseIterable, Identifiable {
    case raw, colormap, none
    var id: Self { self }
}

@Observable class FrameHandler: NSObject {
    var frame: CGImage? = nil
    var desiredFps: Double = 240
    let visibleTimeSpan: TimeInterval = 1
    var droppedFrames: TimeIntervalList<Int>
    var frameDifferenceValues: TimeIntervalFrameList

    // control parameters
    var isRunning: Bool = false
    var blurRadius: Double = 20
    var divisorConstant: CGFloat = 0.2
    var useMinFilter = false
    var useMaxFilter = false
    var useIIRFilter = false

    private var chunkFrameIndex = 0
    var framesPerUpdate = 8

    private var prevCapturedFrame: CIImage? = nil
    private var prevProcessedFrame: CIImage? = nil
    private var prevDisplayFrame: CIImage? = nil
    private var prevAverageBrightness: Float = 0.0

    private let diffFilter = CIFilter.colorAbsoluteDifference()
    private let minFilter: MinFilter
    private let maxFilter: MaxFilter
    private let colorMaskFilter = CIColorMaskFilter()
    private let iirFilter: IIRFilter
    private var isMinPhase: Bool = true
    var minMaxDisplayType: MinMaxDisplay = .alternating
    var maskDisplayType: MaskDisplay = .none

    var currentDevice: AVCaptureDevice? = nil

    typealias DeviceMap = [AVCaptureDevice: [(
        format: AVCaptureDevice.Format, frameRate: AVFrameRateRange
    )]]

    var availableDeviceMap: DeviceMap = [:]
    var availableDeviceNames: [String] {
        availableDeviceMap.keys.map { $0.localizedName }
    }

    private var prevCaptureTimestamp: CMTime = .negativeInfinity
    private var prevProcessTimestamp: CMTime = .negativeInfinity

    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    // CIFilters
    // gaussian blur
    // componentMultiply
    // colorAbsoluteDifference
    // componentAdd
    // componentMax
    // divide
    // falseColor (for grayscale conversion)
    // gammaAdjust
    // CIAreaAverage

    override init() {
        self.droppedFrames = TimeIntervalList<Int>(span: 1.0)
        self.frameDifferenceValues = TimeIntervalFrameList(span: 1.0)
        self.iirFilter = IIRFilter(
            context: context,
            coeff1: CGFloat(0.4),
            coeff2: CGFloat(0.6)
        )
        self.minFilter = MinFilter(context: context)
        self.maxFilter = MaxFilter(context: context)

        super.init()
    }

    func start() {
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setUpCaptureSession()
            self.run()
        }
    }

    func pause() {
        sessionQueue.async { [unowned self] in
            self.captureSession.stopRunning()
            isRunning = self.captureSession.isRunning
            self.withMutation(keyPath: \.isRunning) {}
        }

    }

    func run() {
        sessionQueue.async { [unowned self] in
            self.captureSession.startRunning()
            isRunning = self.captureSession.isRunning
            self.withMutation(keyPath: \.isRunning) {}
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

        // TODO: make `alwaysDiscardsLateVideoFrames` be selectable
        videoOutput.alwaysDiscardsLateVideoFrames = false
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)

        let connection = videoOutput.connection(with: .video)
        guard let connection else { return }
        connection.videoRotationAngle = 90.0

        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .lowLatency
        }

        self.currentDevice = device
    }

    func discoverDevices() -> DeviceMap {
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

        var deviceMap: DeviceMap = [:]

        // TODO: factor this out into getAvailableDevices or something
        for device in devices {
            for format in device.formats {
                if let goodRange = format.videoSupportedFrameRateRanges.first(
                    where: {
                        $0.minFrameRate <= desiredFps
                            && desiredFps <= $0.maxFrameRate
                    })
                {
                    deviceMap[device, default: []].append(
                        (format: format, frameRate: goodRange)
                    )
                }
            }
        }

        guard !deviceMap.isEmpty else {
            fatalError("Missing adequate capture devices.")
        }

        // print(deviceMap.keys)
        // returns:
        //        [[Back Camera][com.apple.avfoundation.avcapturedevice.built-in_video:0],
        //         [Back Telephoto Camera][com.apple.avfoundation.avcapturedevice.built-in_video:2],
        //         [Back Ultra Wide Camera][com.apple.avfoundation.avcapturedevice.built-in_video:5]]

        return deviceMap
    }

    func maskDisplayFrame(frame: CIImage, mask: CIImage) -> CIImage {
        let multFilter = CIBlendKernel.componentMultiply

        let filter = colorMaskFilter
        filter.inputImage1 = frame
        filter.inputImage2 = mask

        return switch maskDisplayType {
        case .raw:
            multFilter.apply(foreground: frame, background: mask)!
        case .colormap:
            filter.outputImage!
        case .none:
            frame
        }

    }

    func computeDiff(image1: CIImage, image2: CIImage) -> CIImage {
        diffFilter.inputImage = image1
        diffFilter.inputImage2 = image2
        let diffImage = diffFilter.outputImage!
        return diffImage
    }

    // difference value between 2 processed images
    // TODO: implement this in Metal
    func makeMaskImage(currentFrame: CIImage, prevFrame: CIImage) -> CIImage? {
        let diffImage = computeDiff(image1: currentFrame, image2: prevFrame)

        let maxFilter = CIBlendKernel.componentMax
        let maxImage = maxFilter.apply(
            foreground: currentFrame,
            background: prevFrame
        )!

        let constImage = CIImage(
            color: CIColor(
                red: divisorConstant,
                green: divisorConstant,
                blue: divisorConstant
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

    func blurImage(_ image: CIImage, blurRadius: Double) -> CIImage {
        let result = image.applyingFilter(
            "CIGaussianBlur",
            parameters: [
                kCIInputRadiusKey: NSNumber(value: blurRadius)
            ]
        ).cropped(
            to: image.extent.insetBy(
                dx: CGFloat(blurRadius),
                dy: CGFloat(blurRadius)
            )
        )
        return result
    }

    // preprocessing images before they're differenced
    func preprocessFrame(
        _ image: CIImage,
        blurRadius: Double = 2,
        gamma: Float = 4
    ) -> CIImage {
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

        let gammaFilter = CIFilter.gammaAdjust()
        gammaFilter.inputImage = gray
        gammaFilter.power = gamma

        let output = gammaFilter.outputImage!
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

    func getDisplayFrame(frame: CIImage, mask: CIImage) -> CIImage {
        let filteredFrame =
            if useMinFilter && useMaxFilter {
                switch minMaxDisplayType {
                case .alternating:
                    isMinPhase ? minFilter.outputImage : maxFilter.outputImage
                case .diff:
                    computeDiff(
                        image1: minFilter.outputImage!,
                        image2: maxFilter.outputImage!
                    )
                }

            } else if useMinFilter {
                minFilter.outputImage
            } else if useMaxFilter {
                maxFilter.outputImage
            } else if maskDisplayType != .none {
                maskDisplayFrame(frame: frame, mask: mask)

            } else {
                frame
            }

        if minMaxDisplayType == .alternating {
            isMinPhase.toggle()
        }

        let displayFrame =
            if useIIRFilter {
                iirFilter.processFrame(frame: filteredFrame!)
            } else {
                filteredFrame
            }

        return displayFrame ?? frame
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
        print(chunkFrameIndex)
        let captureTimestamp = sampleBuffer.presentationTimeStamp
        prevCaptureTimestamp = captureTimestamp

        defer { chunkFrameIndex = (chunkFrameIndex + 1) % framesPerUpdate }

        prevProcessTimestamp = captureTimestamp

        guard let imageBuffer = sampleBuffer.imageBuffer?.copy() ?? nil
        else { return }

        let inputFrame = CIImage(cvPixelBuffer: imageBuffer)

        defer { self.prevCapturedFrame = inputFrame }

        let processedFrame = preprocessFrame(
            inputFrame,
            blurRadius: self.blurRadius
        )
        defer { self.prevProcessedFrame = processedFrame }

        if useMinFilter {
            minFilter.processFrame(frame: inputFrame)
        }

        if useMaxFilter {
            maxFilter.processFrame(frame: inputFrame)
        }

        if chunkFrameIndex > 0 { return }
        // the following only happens once per `framesPerUpdate` frames

        guard let prevProcessedFrame else { return }

        guard
            let maskImage = makeMaskImage(
                currentFrame: processedFrame,
                prevFrame: prevProcessedFrame
            )
        else { return }

        // this is expensive! and maybe worthless!
        let avgFrameDifference = averageBrightness(maskImage) ?? 0
        defer { prevAverageBrightness = avgFrameDifference }
        let diff = abs(avgFrameDifference - prevAverageBrightness)
        self.frameDifferenceValues.append(
            (difference: diff, frame: nil, dropped: false),
            t: captureTimestamp
        )
        self.withMutation(keyPath: \.frameDifferenceValues) {}

        let displayFrame = getDisplayFrame(frame: inputFrame, mask: maskImage)

        minFilter.reset()
        maxFilter.reset()

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
        let timestamp = sampleBuffer.presentationTimeStamp
        self.frameDifferenceValues.currentTime = timestamp
        self.frameDifferenceValues.append(
            (difference: 1.0, frame: nil, dropped: true),
            t: timestamp
        )

        DispatchQueue.main.async { [unowned self] in
            self.droppedFrames.append(1, t: timestamp)
            self.withMutation(keyPath: \.droppedFrames) {
            }
        }

        let reason = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
            attachmentModeOut: nil
        )
        print(
            "reason \(String(describing: reason))"
        )
    }
}
