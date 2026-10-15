//
//  HistogramView.swift
//  FlickerFindr
//
//  Created by Charles Jacobs on 10/6/26.
//

import Charts
import Foundation
import SwiftUI

struct HistogramView: View {
    @Binding var frameDifferenceValues: FrameHandler.TimeIntervalFrameList

    var data: [Float] {
        return frameDifferenceValues.data.map { element in
            element.difference
        }
    }

    // https://nilcoalescing.com/blog/PlottingDataDistributionsWithSwiftCharts/
    var body: some View {
        VStack {
            // TODO: find better defaults for range and numBins
            // TODO: use a moving average of max value for range upper bound
            let domain = 0.0...1.0
            let numBins = 20
            let range = 0.0...0.2
            let histogram = Histogram<Float>(
                data: data,
                domain: domain,
                numBins: numBins,
                range: range
            )
            histogram.setup()
            let barWidth =
                (range.upperBound - range.lowerBound) / Double(numBins)

            // TODO: use NumberBins for histogram (if we're only using it for display)

            return Chart(histogram.counts.enumerated(), id: \.offset) { value in
                return BarMark(
                    x: .value(
                        "Image Diff",
                        range.lowerBound + Double(value.offset) * barWidth
                    ),
                    y: .value("Frequency", value.element)
                )
            }
        }
    }
}

//
//#Preview {
//    @Previewable @State var diffs: TimeIntervalList<Float> = TimeIntervalList<
//        Float
//    >(span: 1.0)
//
//    for t in stride(from: 0.0, to: 1.0, by: 0.05) {
//        diffs.append(
//            Float.random(in: 0.0..<0.5),
//            t: Date(timeIntervalSinceNow: t)
//        )
//    }
//    //
//    return HistogramView(frameDifferenceValues: $diffs)
//}
