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
        ZStack {
            FrameView(image: model.frame)
                .padding(50)
                .onAppear { model.start() }

            VStack {

                HStack {
                    Text(String(describing: model.fps))
                    Spacer()
                    Text(String(describing: model.droppedCount))
                    Spacer()
                    Text(String(describing: model.processFps))
                }
                Spacer()
                Picker("Choose a camera", selection: $cameraSelection) {
                    ForEach(Array(model.availableDeviceMap), id: \.key.uniqueID) {
                        entry in
                        print(entry.key.localizedName)
                        return Text(entry.key.localizedName)
                    }
                }.background(Color.white)
                    .onAppear() {
                        
                    }

                Spacer()

                VStack {
                    Text("# devices: \(model.availableDeviceMap.count)")
                }
                .background(Color.white)

            }
        }
    }
}

//#Preview {
//    ContentView()
//}
