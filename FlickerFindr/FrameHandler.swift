//
//  FrameHandler.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

// Taken from tutorial at: https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameHandler.swift

import AVFoundation
import CoreImage

@Observable class FrameHandler: NSObject {
    var frame: CGImage? = nil
    var fps: Float = 0.0
    var processFps: Float = 0.0
    var droppedCount = 0

    var prevFrame: CIImage? = nil
    var droppedFrames = 0

    var prevFrameDifference: Float = 0.0
    var prevLightLevel: Float = 0.0
    var availableDevices:
        [(
            device: AVCaptureDevice, format: AVCaptureDevice.Format,
            frameRate: AVFrameRateRange
        )] = []
    var availableDeviceNames: Set<String>{
        Set(availableDevices.map {
            $0.device.localizedName
        })
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
        super.init()
    }

    func start() {
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
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

    func setupCaptureSession() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        captureSession.sessionPreset = .inputPriority

        let videoOutput = AVCaptureVideoDataOutput()

        guard permissionGranted else { return }
        //        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        //        else { return }

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

        availableDevices = []

        // TODO: factor this out into getAvailableDevices or something
        let desiredFPS: Double = 120
        for device in devices {
            for format in device.formats {
                if let goodRange = format.videoSupportedFrameRateRanges.first(
                    where: {
                        $0.minFrameRate <= desiredFPS
                            && desiredFPS <= $0.maxFrameRate
                    })
                {
                    availableDevices.append(
                        (device: device, format: format, frameRate: goodRange)
                    )

                }

                //                for range in format.videoSupportedFrameRateRanges {
                //                    if range.minFrameRate <= desiredFPS
                //                        && desiredFPS <= range.maxFrameRate
                //                    {
                //                        availableDevices.append(
                //                            (device: device, format: format, frameRate: range)
                //                        )
                //                    }
            }
        }

        guard !availableDevices.isEmpty else {
            fatalError("Missing adequate capture devices.")
        }

        let device = availableDevices.first!.device
        let format = availableDevices.first!.format
        let range = availableDevices.first!.frameRate
        print(range)
        print(format)
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            device.activeFormat = format
            device.activeVideoMinFrameDuration =
                range.minFrameDuration
            device.activeVideoMaxFrameDuration =
                range.minFrameDuration

        } catch {
            print("ERROR in switchFormatWithDesiredFPS")
            // handle error
        }

        print(device.activeVideoMaxFrameDuration)
        print(device.activeVideoMinFrameDuration)

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
        videoOutput.connection(with: .video)?.videoRotationAngle = 90.0
    }
}

//
// AVCaptureVideoDataOutputSampleBufferDelegate protocol
//
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let captureTime = Date()
        let period = prevCaptureTime.distance(to: captureTime)
        prevCaptureTime = captureTime

        let captureFPS = Float(1 / period)

        // All UI updates should be/ must be performed on the main queue.
        DispatchQueue.main.async { [unowned self] in
            self.fps = captureFPS
        }

        if count == 0 {
            let period = prevProcessTime.distance(to: captureTime)
            prevProcessTime = captureTime
            let processFPS = Float(1 / period)
            DispatchQueue.main.async { [unowned self] in
                self.processFps = processFPS
            }

            guard
                let ciImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            else { return }
            defer { self.prevFrame = ciImage }

            //            let processedImage = ciImage
            //                .convertingWorkingSpaceToLab()

            guard let prevImage = prevFrame else { return }
            guard
                let processedImage = subtractImages(
                    foreground: ciImage,
                    background: prevImage
                )
            else { return }

            let currentLightLevel = averageBrightness(processedImage) ?? 0
            defer { prevLightLevel = currentLightLevel }
            let diff = abs(currentLightLevel - prevLightLevel)
            //            print(diff)

            if diff > 0.05 {
                let displayImage = processedImage

                guard
                    let cgImage = context.createCGImage(
                        displayImage,
                        from: displayImage.extent
                    )
                else { return }

                DispatchQueue.main.async { [unowned self] in
                    self.frame = cgImage
                }
            }
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
        DispatchQueue.main.async { [unowned self] in
            self.droppedCount = droppedFrames
        }

        //        let reason = CMGetAttachment(
        //            sampleBuffer,
        //            key: kCMSampleBufferAttachmentKey_DroppedFrameReason,
        //            attachmentModeOut: nil
        //        )

        // reasons seen:
        // Optional(FrameWasLate)
        // Optional(OutOfBuffers)
    }

    // NOTE: look at alwaysDiscardsLateVideoFrames property

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage?
    {
        guard let imageBuffer = sampleBuffer.imageBuffer
        else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return ciImage
    }

    func subtractImages(foreground: CIImage, background: CIImage) -> CIImage? {
        let filter = CIBlendKernel.difference
        let output = filter.apply(
            foreground: foreground,
            background: background
        )
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
