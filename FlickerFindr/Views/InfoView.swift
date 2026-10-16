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
            HistogramView(data: $model.frameDifferenceValues)
                .frame(height: 80)
            
            HistoryView(datapoints: $model.frameDifferenceValues)
                .frame(height:80)
        }
    }
}

//#Preview {
//    CaptureInfoView()
//}
