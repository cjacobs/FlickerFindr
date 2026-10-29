//
//  SlideshowView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/28/26.
//

import SwiftUI

struct SlideshowView: View {
    @State var frames: [CGImage]
    @Binding var isShowingSlideshow: Bool
    @State var currentIndex = 0

    var image: CGImage? {
        let numFrames = frames.count
        if currentIndex < numFrames {
            return frames[currentIndex]
        }
        return nil
    }

    private let label = Text("frame")

    var body: some View {
        TimelineView(.periodic(from: .distantPast, by: 2)) { context in
            VStack {
                if let image = image {
                    Image(image, scale: 1.0, orientation: .up, label: label)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.black)
                }

                HStack {
                    Button("Back") {
                        prevFrame()
                    }
                    Spacer()
                    Button("Exit") {
                        isShowingSlideshow = false
                    }
                    Button("Next") {
                        nextFrame()
                    }
                }
                Spacer()
            }
            .onChange(of: context.date) {
                nextFrame()
            }
        }
    }
    
    func prevFrame() {
        guard !frames.isEmpty else {
            return
        }
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = frames.count - 1
        }
    }

    func nextFrame() {
        guard !frames.isEmpty else {
            return
        }
        currentIndex += 1
        if currentIndex >= frames.count {
            currentIndex = 0
        }
    }
}

//#Preview {
//    SlideshowView()
//}
