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

        VStack {

            FrameView(image: model.frame)
                .onAppear { model.start() }
                .overlay(alignment: .bottom) {
                    ControlsView(model: model)
                        .background(
                            .white.opacity(0.5),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .overlay(alignment: .top) {
                    InfoView(model: model)
                        .background(
                            .white.opacity(0.5),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(.white)
                }

        }
    }

}

//#Preview {
//    ContentView()
//}
