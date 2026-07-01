//
//  Theme.swift
//  Doodle60
//
//  Design system: colors, gradients, button styles, haptics.
//

import SwiftUI
import UIKit

// MARK: - Color helpers
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                   red: Double((hex >> 16) & 0xFF) / 255,
                   green: Double((hex >> 8) & 0xFF) / 255,
                   blue: Double(hex & 0xFF) / 255,
                   opacity: opacity)
    }
}

// MARK: - Theme
struct Theme {
    static func background(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(hex: 0x1E1B4B), Color(hex: 0x3B1D63), Color(hex: 0x581C55)]
            : [Color(hex: 0x6C5CE7), Color(hex: 0x9B5DE5), Color(hex: 0xFD79A8)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let card = Color(.secondarySystemBackground)
    static let glass: Material = .ultraThinMaterial

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xFF6B6B), Color(hex: 0xFFA36B)],
        startPoint: .leading, endPoint: .trailing
    )

    static func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return Color(hex: 0x2ECC71)
        case .medium: return Color(hex: 0xF39C12)
        case .hard: return Color(hex: 0xE74C3C)
        }
    }

    static func ringColor(progress: Double) -> Color {
        if progress > 0.5 { return Color(hex: 0x2ECC71) }
        if progress > 0.17 { return Color(hex: 0xF39C12) }
        return Color(hex: 0xE74C3C)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let strokeWidth: CGFloat = configuration.isPressed ? 1.5 : 1.0
        return configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.separator, lineWidth: strokeWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.clear))
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(height: 52)
            .padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.red))
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Reusable view modifiers
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(Theme.glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptics
enum Haptics {
    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard !isPreview else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard !isPreview else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
