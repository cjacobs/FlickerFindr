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
    @Binding var isRunning: Bool
    @State private var cameraSelection: AVCaptureDevice? = nil

    var body: some View {
        Text("Controls")

        HStack {
            Button("pause", systemImage: "pause.circle") {
                model.pause()
            }
            .disabled(!isRunning)
            Spacer()
            Button("play", systemImage: "play.circle") {
                model.run()
            }
            .disabled(isRunning)
        }
        .controlSize(.regular)
        Form {
            Section(header: Text("Filtering controls")) {
                HStack {
                    Text("update period")
                    Slider(value: .convert($model.framesPerUpdate), in: 1...8, step: 1)

                }
                Toggle("min filt", isOn: $model.useMinFilter)
                Toggle("max filt", isOn: $model.useMaxFilter)
                Picker("MinMax Display", selection: $model.minMaxDisplayType) {
                    ForEach(MinMaxDisplay.allCases) { displayType in
                        Text(displayType.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!model.useMinFilter && !model.useMaxFilter)

                HStack {
                    Text("blur:")
                    Slider(
                        value: $model.blurRadius,
                        in: 0.0...50.0,
                    )
                }

                HStack {
                    Text("divisor:")
                    Slider(value: $model.divisorConstant, in: 0.001...0.9) {
                        Text("divisor")
                    }
                }

                Picker("Mask Display", selection: $model.maskDisplayType) {
                    ForEach(MaskDisplay.allCases) { displayType in
                        Text(displayType.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("IIR filt", isOn: $model.useIIRFilter)
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
