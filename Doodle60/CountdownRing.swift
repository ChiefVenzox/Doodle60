//
//  CountdownRing.swift
//  Doodle60
//

import SwiftUI

struct CountdownRing: View {
    let progress: Double // 1 = full time remaining, 0 = expired
    let timeLeft: Int
    let isRunning: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(progress, 0.001))
                .stroke(Theme.ringColor(progress: progress), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
            Text("\(timeLeft)")
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .fontWeight(.bold)
                .contentTransition(.numericText(countsDown: true))
        }
        .frame(width: 58, height: 58)
        .scaleEffect(isRunning && timeLeft <= 10 ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRunning && timeLeft <= 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeLeft) seconds left")
    }
}

#Preview {
    CountdownRing(progress: 0.2, timeLeft: 12, isRunning: true)
        .padding()
}
