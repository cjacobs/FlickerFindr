//
//  FrameView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label).resizable().aspectRatio(contentMode: .fit)
        }
        else {
            Color(.black)
        }
    }
}

#Preview {
    FrameView()
}
