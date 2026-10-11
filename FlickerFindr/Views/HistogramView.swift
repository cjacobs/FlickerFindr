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
    @Binding var frameDifferenceValues: TimeIntervalList<Float>
    var data: [Float] {
        frameDifferenceValues.data
    }

    var body: some View {
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                print(index)
                return BarMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
            }
        }
        .frame(height: 150)
        .padding()
        //        // print histogram
        //        // TODO: get moving average?
        //        print(h.counts)
        //
        //        print()

    }
}
//
//#Preview {
//    func getDiffValues() -> TimeIntervalList<Float> {
//        var result = TimeIntervalList<Float>(span: 1.0)
//        result.append(0.1, t: Date(timeIntervalSinceNow: 0))
//        result.append(0.5, t: Date(timeIntervalSinceNow: 0.1))
//        result.append(0.2, t: Date(timeIntervalSinceNow: 0.2))
//        result.append(0.9, t: Date(timeIntervalSinceNow: 0.3))
//        return result
//    }
//    let diffValues = getDiffValues()
//
//    return HistogramView(data: diffValues.data)
//}
