//
//  ControlsView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/10/26.
//

import AVFoundation
import SwiftUI

struct ControlsView: View {
    @Bindable var model: FrameHandler
    @State private var cameraSelection: AVCaptureDevice? = nil

    var body: some View {
        Text("Controls")

        Form {
            Section(header: Text("Filtering controls")) {

                HStack {
                    Text("blur:")
                    Slider(
                        value: $model.blurRadius,
                        in: 0.0...50.0,
                    ) {
                        Text("blur")
                    }
                }

                HStack {
                    Text("divisor:")
                    Slider(value: $model.divisorConstant, in: 0.001...0.9) {
                        Text("divisor")
                    }
                }

                Toggle("temp filt", isOn: $model.useTemporalFilter)
            }

            Section(header: Text("Camera controls"))  // model picker
            {
                if !model.availableDeviceMap.isEmpty {
                    Picker(selection: $cameraSelection) {
                        ForEach(
                            Array(model.availableDeviceMap),
                            id: \.key.uniqueID
                        ) {
                            entry in
                            Text(
                                "\(entry.key.localizedName) : \(model.availableDeviceMap[entry.key]!.count)"
                            )
                            .tag(Optional(entry.key.uniqueID))
                        }

                        Text("Device")
                            .tag(Optional<AVCaptureDevice>.none)
                    } label: {
                        Text("Device")
                    }
                    .pickerStyle(.automatic)
                }
            }
        }
        .navigationTitle("Controls")
    }
}

extension View {
    fileprivate func compactToggleStyle() -> some View {
        toggleStyle(.switch)
            .controlSize(.mini)
    }
}

//#Preview {
//    ControlsView()
//}
