//
//  Theme.swift
//  RapidDent
//
//  Shared colors, gradients, and reusable style modifiers
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Primary brand blue used throughout the app.
    static let rdBrand = Color(red: 0.0, green: 0.4, blue: 0.8)

    /// Accent green for success states.
    static let rdSuccess = Color(red: 0.0, green: 0.7, blue: 0.3)

    /// Accent red for error/false states.
    static let rdError = Color(red: 0.95, green: 0.3, blue: 0.3)

    /// Accent orange for warnings/review states.
    static let rdWarning = Color(red: 1.0, green: 0.6, blue: 0.0)

    /// Purple accent for exam mode.
    static let rdExam = Color(red: 0.5, green: 0.2, blue: 0.8)
}

// MARK: - Background Gradient Modifier

/// The standard app background gradient used across all screens.
struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 0.99),
                        Color(red: 0.90, green: 0.94, blue: 0.98)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    /// Applies the standard RapidDent background gradient.
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

// MARK: - Haptic Feedback

enum HapticManager {
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
