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
    @State private var cameraSelection: AVCaptureDevice? = nil

    var body: some View {

        HistogramView()
        HStack {
            Text(String(describing: model.fps))
            Spacer()
            Text(String(describing: model.droppedFrames.count))
            Spacer()
            Text(
                String(
                    describing: model.frameDiffValues.data.reduce(0) {
                        (prev, value) in
                        prev + value
                    } / Float(model.frameDiffValues.data.count)
                )
            )
        }

        VStack {
            Text("# devices: \(model.availableDeviceMap.count)")
        }
        VStack {
            FrameView(image: model.frame)
                .padding(50)
                .onAppear { model.start() }
        }

        HStack {
            // controls
            //
            // checkbox for
            // slider for blur radius

            if !model.availableDeviceMap.isEmpty {
                Picker(selection: $cameraSelection) {
                    ForEach(
                        Array(model.availableDeviceMap),
                        id: \.key.uniqueID
                    ) {
                        entry in
                        Text(entry.key.localizedName).tag(
                            Optional(entry.key.uniqueID)
                        )
                    }

                    Text("Device")
                        .tag(Optional<AVCaptureDevice>.none)
                } label: {
                    Text("Device")
                }
                .pickerStyle(.automatic)
                .background(Color.white)

                .onAppear {
                }
            }

        }
    }
}

//#Preview {
//    ContentView()
//}
