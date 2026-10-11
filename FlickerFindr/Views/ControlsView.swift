//
//  ControlsView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/10/26.
//

import SwiftUI
import AVFoundation

struct ControlsView: View {
    @State var model: FrameHandler
    @State private var cameraSelection: AVCaptureDevice? = nil

    var body: some View {
        // controls
        Text("\(model.frameDifferenceValues.data.count)")
        HStack {
            Spacer()
            Slider(value: $model.blurRadius, in: 0.0...50.0) {
                Text("blur")
            }
            .frame(width: 100)
            Spacer()
            // toggle for temp filter
            Toggle("temp filt", isOn: $model.useTemporalFilter)
                .compactToggleStyle()
            Spacer()
            // model picker
            if !model.availableDeviceMap.isEmpty {
                Picker(selection: $cameraSelection) {
                    ForEach(
                        Array(model.availableDeviceMap),
                        id: \.key.uniqueID
                    ) {
                        entry in
                        Text("\(entry.key.localizedName) : \(model.availableDeviceMap[entry.key]!.count)")
                            .tag(Optional(entry.key.uniqueID))
                    }

                    Text("Device")
                        .tag(Optional<AVCaptureDevice>.none)
                } label: {
                    Text("Device")
                }
                .pickerStyle(.automatic)
                .background(Color.white)
            }

        }
    }
}


extension View {
    fileprivate func compactToggleStyle() -> some View {
        toggleStyle(.switch)
            .controlSize(.small)
    }
}

//#Preview {
//    ControlsView()
//}
