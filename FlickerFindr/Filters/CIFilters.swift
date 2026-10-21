//
//  Filters.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/17/26.
//

import CoreImage
import Foundation

func getKernel(function: String) -> CIColorKernel {
    let url = Bundle.main.url(
        forResource: "default",
        withExtension: "metallib"
    )!
    let data = try! Data(contentsOf: url)
    return try! CIColorKernel(
        functionName: function,
        fromMetalLibraryData: data
    )
}

// here, applyFilter and apply are methods on a controller object
//func applyFilter() {
//    guard let filter,
//          let originalImage else { return }
//    uiImage = apply(filter: filter, to: originalImage)
//}
//
//private func apply(filter: CIFilter, to image: UIImage) -> UIImage {
//    // 1
//    let originalImage = CIImage(image: image)
//
//    // 2
//    filter.setValue(originalImage, forKey: kCIInputImageKey)
//
//    guard let outputImage = filter.outputImage,
//          // 3
//          let cgImage = context.createCGImage(
//        outputImage, from: outputImage.extent
//    ) else { return image }
//    return UIImage(cgImage: cgImage)
//}

class CIMultFilter: CIFilter {
    var inputImage: CIImage?
    var frac: Float = 1.0

    // Create the kernel statically so it is compiled/loaded only once
    static var colorKernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "mult2",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }

        return CIMultFilter.colorKernel.apply(
            extent: input.extent,
            arguments: [input, frac]
        )
    }
}

class CIAvgFilter: CIFilter {
    var inputImage1: CIImage?
    var inputImage2: CIImage?
    var a1: Float = 0
    var a2: Float = 0

    static var kernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "filt",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input1 = inputImage1 else { return nil }
        guard let input2 = inputImage2 else { return nil }

        return Self.kernel.apply(
            extent: input1.extent,
            arguments: [input1, input2, a1, a2]
        )
    }
}

class CIBinaryFilter: CIFilter {
    var inputImage1: CIImage? = nil
    var inputImage2: CIImage? = nil

    required override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CIMinFilter: CIBinaryFilter {
    static var kernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "min",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input1 = inputImage1 else { return nil }
        guard let input2 = inputImage2 else { return nil }

        return Self.kernel.apply(
            extent: input1.extent,
            arguments: [input1, input2]
        )
    }
}

class CIMaxFilter: CIBinaryFilter {
    static var kernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "max",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input1 = inputImage1 else { return nil }
        guard let input2 = inputImage2 else { return nil }

        return Self.kernel.apply(
            extent: input1.extent,
            arguments: [input1, input2]
        )
    }
}

class CISumFilter: CIBinaryFilter {
    static var kernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "sum",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input1 = inputImage1 else { return nil }
        guard let input2 = inputImage2 else { return nil }

        return Self.kernel.apply(
            extent: input1.extent,
            arguments: [input1, input2]
        )
    }
}

class CIMinMaxSumFilter: CIBinaryFilter {

    static var kernel: CIColorKernel = {
        let url = Bundle.main.url(
            forResource: "default",
            withExtension: "metallib"
        )!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(
            functionName: "min_max_sum",
            fromMetalLibraryData: data
        )
    }()

    override var outputImage: CIImage? {
        guard let input1 = inputImage1 else { return nil }
        guard let input2 = inputImage2 else { return nil }

        // Pass the image extent and arguments into apply(_:arguments:options:)
        return Self.kernel.apply(
            extent: input1.extent,
            arguments: [input1, input2]
        )
    }
}
