//
//  Shaders.metal
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/17/26.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

[[ stitchable ]] half4 mult(float2 position, half4 currentColor, float frac) {
    auto result = currentColor;
    result.rgb *= frac;
    return result;
}

[[ stitchable ]] half4 mult2(half4 currentColor, float frac) {
    auto result = currentColor;
    result.rgb *= frac;
    return result;
}

// this is also a CIColorKernel (I couldn't get it to work as a CIBlendKernel)
[[ stitchable ]] float4 filt(coreimage::sample_t foreground, coreimage::sample_t background, float a1, float a2, coreimage::destination dest) {
    
    auto blendColor = foreground.rgb * a1 + background.rgb * a2;
    return float4(blendColor, 1.0);
}

// this is also a CIColorKernel (I couldn't get it to work as a CIBlendKernel)
[[ stitchable ]] float4 min(coreimage::sample_t foreground, coreimage::sample_t background, coreimage::destination dest) {

    // using green channel as intensity for now
    auto blendColor = (foreground.g < background.g) ? foreground.rgb : background.rgb;
    return float4(blendColor, 1.0);
}

// this is also a CIColorKernel (I couldn't get it to work as a CIBlendKernel)
[[ stitchable ]] float4 max(coreimage::sample_t foreground, coreimage::sample_t background, coreimage::destination dest) {

    // using green channel as intensity for now
    auto blendColor = (foreground.g > background.g) ? foreground.rgb : background.rgb;
    return float4(blendColor, 1.0);
}

// this is also a CIColorKernel (I couldn't get it to work as a CIBlendKernel)
[[ stitchable ]] float4 sum(coreimage::sample_t foreground, coreimage::sample_t background, coreimage::destination dest) {

    // using green channel as intensity for now
    return foreground + background;
}

[[ stitchable ]] float4 min_max_sum(coreimage::sample_t foreground, coreimage::sample_t background, coreimage::destination dest) {
    // using green channel as intensity for now
    const auto val1 = foreground.g;
    const auto val2 = background.g;
    const auto minVal = min(val1, val2);
    const auto maxVal = max(val1, val2);
    const auto sumVal = val1+val2;
    return float4(minVal, maxVal, sumVal, 1.0);
}

