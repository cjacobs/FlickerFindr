//
//  CaptureInfoView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/13/26.
//

import SwiftUI

struct InfoView: View {
    @Bindable var model: FrameHandler

    let fpsRange = Float(0)...240
    var body: some View {
        VStack {
//            HStack {
//                Gauge(value: model.fps.clamped(to: fpsRange), in: fpsRange) {
//                    Text("\(model.fps)")
//                }
//            }

            HistogramView(model: model)
                .frame(height: 80)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(range.upperBound, max(self, range.lowerBound))
    }
}

//#Preview {
//    CaptureInfoView()
//}
