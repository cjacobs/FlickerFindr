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
    let domain = 0.0 ... 1.0
    var data: [TimeEntry<FrameInfo>] {
        datapoints.buffer.filter {
            $0.value.difference > threshold
        }
        
    }

    var body: some View {
        let firstTime = Date.now - (domain.upperBound-domain.lowerBound)
        TimelineView(.periodic(from: Date.distantPast, by: 0.1)) { _ in
            return Chart(data.enumerated(), id: \.offset) { element in
                return BarMark(
                    x: .value(
                        "time",
                        firstTime.distance(to: element.element.time)
                    ),
                    y: .value("diff", element.element.value.difference),
                    width: .fixed(0.5)
                )
            }
            .chartXScale(domain: 0.0...1.0)
        }
    }
}

//#Preview {
//    HistoryView()
//}
