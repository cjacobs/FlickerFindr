#  <#Notes#>
TODO (this branch):
- [x] switch to using sample time instead of `Date` time
- [x] have `FrameHandler` keep the current timestamp
- [x] have `HistoryView` depend on `FrameHandler.currentTimestamp` instead of using a `TimelineView`
- [x] add a pause button that pauses the frame grabbing (and therefore the updating of timestamp-dependent views
- [ ] add whole-frame (instead of per-pixel) versions of min and max filters


TODO:
- [x] make a RingBuffer class
- [x] keep a ring buffer of previous frame-diff values 
(actually, a timestamped buffer of a constant amount of time)    
- [x] add a view showing where in the timeline the high-diff frames are
- [ ] guess frequency based on buffer of frame diff (maybe just count, rather than fft?)
- [ ] add a picker to pick which camera
- [ ] add a slider to zoom
- [ ] HDR? maybe make a mask - everything over 1.0 == bright enough to process?
- [ ] figure out why temporal filter is so slow
- [ ] write metal shaders for temporal filter, et al
- [ ] refactor things so that previews work
- [ ] subsample input image if blur is big enough

## Notes on CIFilters and Metal
There is an annoyingly large number of ways to invoke a metal kernel from swift. In SwiftUI, you can apply a shader to a view easily. Consider this metal filter:
```
[[ stitchable ]] half4 mult(float2 position, half4 currentColor, float frac) {
    auto result = currentColor;
    result.rgb *= frac;
    return result;
}
```

we can apply it to a view like this:
```
MyView().colorEffect(ShaderLibrary.mult(.float(1.30)))
```

but I don't know how to use it that easily on a plain `CIImage`. We can make a filter class for it:
```class CIMultFilter: CIFilter {
    var inputImage: CIImage?
    var inputIntensity: Float = 1.0
    
    // Create the kernel statically so it is compiled/loaded only once
    static var colorKernel: CIColorKernel = {
        let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(functionName: "mult", fromMetalLibraryData: data)
    }()
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        
        // Pass the image extent and arguments into apply(_:arguments:options:)
        return CIMultFilter.colorKernel.apply(
            extent: input.extent,
            arguments: [input, inputIntensity]
        )
    }
}
```

and then call it like this:
```
        let filter = CIMultFilter()
        filter.inputImage = frame
        filter.frac = 0.01
        let output = filter.outputImage!.cropped(to: frame.extent)
        self.prevFrame = output
        return output
```
...but for some reason, running that kernel only sends in an input color, not a position. So we have to change the kernel to this:
```
[[ stitchable ]] half4 mult2(half4 currentColor, float frac) {
    auto result = currentColor;
    result.rgb *= frac;
    return result;
}

```

for my temporal filter, I need to blend between 2 (or N) images. for 2 images, I can subclass `CIBlendKernel` , in which case my Metal kernel returns a `float4` (not half4?) and takes 2 parameters of type `sample_t` instead of `half4` .

## Resources on the web
Info on dealing with high-frame-rate video:
https://stackoverflow.com/questions/42116314/ios-synchronizing-frames-from-camera-and-motion-data

Info on implementing sheet views:
https://21zerixpm.medium.com/bottom-sheets-in-swiftui-modal-presentations-done-right-bc4ab6825d02
https://www.createwithswift.com/exploring-interactive-bottom-sheets-in-swiftui/

Info on writing metal image filters:
https://gostrobrod.medium.com/mtl-s01e13-metal-stitching-functions-e878f8c33c5a
https://blog.jacobstechtavern.com/p/metal-in-swiftui-how-to-write-shaders
https://blog.jacobstechtavern.com/p/advanced-core-image
https://www.createwithswift.com/custom-parameters-and-animation-with-metal-shaders/
https://developer.apple.com/documentation/coreimage/writing-custom-kernels
https://medium.com/@shu223/core-image-filters-with-metal-71afd6377f4



TODO (for previews): get rid of view dependencies on whole model, just use the parts they need(?)



