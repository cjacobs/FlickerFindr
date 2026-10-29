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
    @State private var isShowingControls = true
    @State private var isShowingSlideshow = false

    var body: some View {

        NavigationStack {
            VStack {
                FrameView(image: model.frame)
                    .onAppear { model.start() }
            }
            .overlay(alignment: .top) {
                InfoView(model: model)
                    .background(
                        .white.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(.white)
            }
            .sheet(isPresented: $isShowingControls) {
                ControlsView(model: model, isRunning: $model.isRunning, isShowingSlideshow: $isShowingSlideshow)
                    .background(
                        .white.opacity(0.5)
                    )
                    .padding()
                    .presentationDetents([.height(80), .medium, .large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                    .presentationBackground(alignment: .bottomTrailing) {Color.blue}
            }
            .overlay(alignment:.top) {
                if isShowingSlideshow {
                    SlideshowView(frames: Array<CGImage>(model.frameBuffer.data), isShowingSlideshow: $isShowingSlideshow)
                }
            }

        }
    }
}

#Preview {
    ContentView()
}
