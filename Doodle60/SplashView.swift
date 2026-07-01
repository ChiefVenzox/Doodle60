//
//  SplashView.swift
//  Doodle60
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    @State private var pulse = false
    @State private var appear = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Theme.background(for: colorScheme).ignoresSafeArea()

            // Floating decorative doodle shapes
            GeometryReader { proxy in
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: floatingIcons[i % floatingIcons.count])
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.18))
                        .position(
                            x: proxy.size.width * floatingPositions[i].0,
                            y: proxy.size.height * floatingPositions[i].1
                        )
                        .offset(y: pulse ? -10 : 10)
                        .animation(
                            .easeInOut(duration: Double(2 + i)).repeatForever(autoreverses: true),
                            value: pulse
                        )
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 20) {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .scaleEffect(pulse ? 1.0 : 0.85)
                    .opacity(pulse ? 1 : 0.6)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Doodle 60")
                        .font(.system(.largeTitle, design: .rounded)).bold()
                        .foregroundStyle(.white)
                    Text("Draw, save, and smile in 60 seconds.")
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Theme.glass, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                )
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)

                Button {
                    Haptics.impact(.medium)
                    onFinish()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) { appear = true }
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                NotificationManager.prepareDailyReminder()
            }
        }
    }

    private let floatingIcons = ["scribble.variable", "star.fill", "heart.fill", "cloud.fill", "bolt.fill"]
    private let floatingPositions: [(CGFloat, CGFloat)] = [
        (0.15, 0.12), (0.85, 0.18), (0.12, 0.8), (0.88, 0.75), (0.5, 0.06)
    ]
}

#Preview {
    SplashView(onFinish: {})
}
