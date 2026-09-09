import SwiftUI

enum Theme {
    static let graphite = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let graphiteElevated = Color(red: 0.12, green: 0.14, blue: 0.15)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let accentInk = Color(red: 0.28, green: 0.56, blue: 0.75)
    static let textPrimary = paper
    static let textSecondary = Color.white.opacity(0.62)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [graphiteElevated, graphite],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Radius {
        static let card: CGFloat = 22
        static let sheet: CGFloat = 28
        static let control: CGFloat = 14
    }

    struct CardShadow {
        let radius: CGFloat
        let opacity: Double
        let offset: CGSize

        static let paper = CardShadow(
            radius: 16,
            opacity: 0.18,
            offset: CGSize(width: 0, height: 8)
        )
    }
}
