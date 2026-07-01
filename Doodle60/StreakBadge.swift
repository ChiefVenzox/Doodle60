//
//  StreakBadge.swift
//  Doodle60
//

import SwiftUI

struct StreakBadge: View {
    var body: some View {
        let streak = StatsStore.streak
        return HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? .orange : .secondary)
            Text("\(streak)")
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.glass, in: Capsule())
        .accessibilityLabel("\(streak) day streak")
    }
}

#Preview {
    StreakBadge()
        .padding()
}
