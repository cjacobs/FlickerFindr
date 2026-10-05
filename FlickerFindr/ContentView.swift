//
//  ContentView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

import SwiftUI

struct ContentView: View {
    @State private var model = FrameHandler()

    var body: some View {
        ZStack {
            HStack {
                FrameView(image: model.frame).ignoresSafeArea()
            }.onAppear { model.start() }

            VStack {
                HStack {
                    Text(String(describing: model.fps))
                    Spacer()
                    Text(String(describing: model.droppedCount))
                    Spacer()
                    Text(String(describing: model.processFps))
                }

                Spacer()

                HStack {

                    Text("# devices: \(model.availableDevices.count)")
                    List(Array(model.availableDeviceNames), id: \.self) { name in
                        Text(name)
                    }

                }
            }
        }
    }
}

#Preview {
    ContentView()
}
