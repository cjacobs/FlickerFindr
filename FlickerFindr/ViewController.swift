//
//  ViewController.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/25/24.
//

// taken from "Live camera feed in SwiftUI with AVCaptureVideoPreviewLayer" video: https://www.youtube.com/watch?v=R2STbo53_vc

import AVFoundation
import SwiftUI
import UIKit

class ViewController: UIViewController {
    //    @Published var frame: CGImage?
    @Published var fps: Float = 0.0

    var prevFrameDifference: Float = 0.0

    private var capturedFrame: CGImage? = nil
    private var prevCaptureTime = Date()
    private var count = 0
    private let maxFrames = 10
    private var droppedFrames = 0

    private var permissionGranted = false  // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()

    var screenRect: CGRect! = nil  // For view dimensions

    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()

    override func viewDidLoad() {
        checkPermission()

        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            //            self.setupLayers()
            //            self.setupDetector()
            self.captureSession.startRunning()
        }
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: screenRect.size.width,
            height: screenRect.size.height
        )

        switch UIDevice.current.orientation {
        // Home button on top
        case UIDeviceOrientation.portraitUpsideDown:
            self.previewLayer.connection?.videoRotationAngle = 180

        // Home button on rightf
        case UIDeviceOrientation.landscapeLeft:
            self.previewLayer.connection?.videoRotationAngle = 90

        // Home button on left
        case UIDeviceOrientation.landscapeRight:
            self.previewLayer.connection?.videoRotationAngle = 270

        // Home button at bottom
        case UIDeviceOrientation.portrait:
            self.previewLayer.connection?.videoRotationAngle = 0

        default:
            break
        }

        // Detector
        //        updateLayers()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // Permission has been granted before
        case .authorized:
            permissionGranted = true

        // Permission has not been requested yet
        case .notDetermined:
            requestPermission()

        default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }

    func setupCaptureSession() {
        captureSession.sessionPreset = .inputPriority

        // Camera input
        guard let videoDevice = getDeviceWithHighestFrameRate() else { return }

        // TODO: add code to request high-frame-rate input
        //        configureCameraForHighestFrameRate(device: videoDevice)

        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(
                device: videoDevice
            )
        else { return }

        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)

        // Preview layer
        screenRect = UIScreen.main.bounds

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: screenRect.size.width,
            height: screenRect.size.height
        )
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill  // Fill screen
        previewLayer.connection?.videoRotationAngle = 0

        // Detector
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "sampleBufferQueue")
        )
        captureSession.addOutput(videoOutput)
        //        videoOutput.alwaysDiscardsLateVideoFrames = false

        videoOutput.connection(with: .video)?.videoRotationAngle = 0

        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }

    func getDeviceWithHighestFrameRate() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInUltraWideCamera,
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInTrueDepthCamera,
            ],
            mediaType: .video,
            position: .back
        )

        let devices = discoverySession.devices
        print("num devices: \(devices.count)")
        guard !devices.isEmpty else { fatalError("Missing capture devices.") }
        
        for device in devices {
            print(device)
            for format in device.formats {
//                print("Format \(format.formatDescription) supports:")
                for rate in format.videoSupportedFrameRateRanges {
                    if rate.maxFrameRate == 240 {
                        do
                            {
                            
                            try device.lockForConfiguration()
                            defer { device.unlockForConfiguration() }
                            device.activeFormat = format
                            device.activeVideoMinFrameDuration = rate.minFrameDuration
                            device.activeVideoMaxFrameDuration = rate.maxFrameDuration
                            return device
                            }
                        catch {
                            print("ERROR getting device")
                            return nil
                        }
                    }
                }
            }
            print()
        }

        return nil
    }
}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let captureTime = Date()
        let period = prevCaptureTime.distance(to: captureTime)
        prevCaptureTime = captureTime
        let currFPS = Float(1 / period)

        print("running fps: \(String (describing: currFPS))")

        // All UI updates must be performed on the main queue.
        if count == 0 {
            //            guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
            DispatchQueue.main.async { [unowned self] in
                self.fps = Float(1 / period)
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
        } else {
            // TODO: implement an image diff in Metal

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
        //        self.droppedFrames += 1
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
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
    }
}
