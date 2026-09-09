import Foundation

enum ARTraceTransform {
    static let minimumScale: Float = 0.05
    static let maximumScale: Float = 5

    static func scale(base: Float, gesture: Float) -> Float {
        min(max(base * gesture, minimumScale), maximumScale)
    }

    static func rotation(base: Float, gesture: Float) -> Float {
        normalizedAngle(base + gesture)
    }

    private static func normalizedAngle(_ angle: Float) -> Float {
        let fullTurn = 2 * Float.pi
        var normalized = (angle + Float.pi).truncatingRemainder(dividingBy: fullTurn)

        if normalized < 0 {
            normalized += fullTurn
        }

        return normalized - Float.pi
    }
}
