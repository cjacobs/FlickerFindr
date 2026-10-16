//
//  HistoryView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/15/26.
//

import Charts
import SwiftUI

struct HistoryView: View {
    let threshold: Float = 0.02
    @Binding var datapoints: TimeIntervalFrameList
    let domain = 0.0...1.0
    var data: [TimeEntry<FrameInfo>] {
        datapoints.buffer.filter {
            $0.value.difference > threshold
        }

    }

    var body: some View {
        let displayInterval = (domain.upperBound-domain.lowerBound)
        let firstTimeSeconds = datapoints.currentTime.seconds - displayInterval // (== LHS of graph
        return Chart(data.enumerated(), id: \.offset) { element in
            let t = (element.element.time.seconds - firstTimeSeconds)

            return BarMark(
                x: .value(
                    "time",
                    t
                ),
                y: .value("diff", element.element.value.difference)
            )
        }
                .chartXScale(domain: 0.0...1.0)
                .chartYScale(domain: 0.0 ... 1.0)
    }

}

//#Preview {
//    HistoryView()
//}
