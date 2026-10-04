//
//  ContentView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 1/22/24.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack {
            HStack {
            }

            HStack
            {
                HostedViewController().ignoresSafeArea()
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

