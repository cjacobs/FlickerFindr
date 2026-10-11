//
//  ContentView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var model = FrameHandler()

    var body: some View {

        // information
        HStack {
            Gauge(value: model.fps, in: 0...240) {
                Text("\(model.fps)")
            }

            Spacer()
            Text(String(describing: model.droppedFrames.count))
            Spacer()
            Text(
                String(
                    describing: model.frameDifferenceValues.data.reduce(0) {
                        (prev, value) in
                        prev + value
                    } / Float(model.frameDifferenceValues.data.count)
                )
            )
        }.hidden()

        VStack {
            HistogramView(frameDifferenceValues: $model.frameDifferenceValues)
//            HistogramView(data: $model.frameDifferenceValues)

            Text("# devices: \(model.availableDeviceMap.count)")
        }

        // frame
        VStack {
            FrameView(image: model.frame)
                .padding(50)
                .onAppear { model.start() }
        }

        ControlsView(model: model)
    }
}

//#Preview {
//    ContentView()
//}
