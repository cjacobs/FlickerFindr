//
//  ContentView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

import SwiftUI

struct ContentView: View {
//    @StateObject private var model = FrameHandler()

    var body: some View {
        VStack {
            HStack {
//                Text(String(describing: model.fps))
            }

            HStack
            {
                HostedViewController().ignoresSafeArea()
//                FrameView(image: model.frame).ignoresSafeArea()
                    
            }

            HStack {
                Text("Controls")
            }
        }
    }
}

#Preview {
    ContentView()
}

