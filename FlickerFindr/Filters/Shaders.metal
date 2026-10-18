//
//  Shaders.metal
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/17/26.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;


// Hm. This doesn't seem to work as a Core Image filter, though it can be applied directly to a SwiftUI view:
//  MyView().colorEffect(ShaderLibrary.chessboard(.float(30), .color(.yellow)))
[[ stitchable ]] half4 chessboard(float2 position, half4 currentColor, float tileSize, half4 fillColor) {
    uint2 gridCoords = uint2(position.x / tileSize, position.y / tileSize);

    bool shouldFill = (gridCoords.x ^ gridCoords.y) & 1;
    
    return shouldFill ? fillColor * currentColor.a : half4(0.0, 0.0, 0.0, 0.0);
}

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

