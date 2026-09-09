import SwiftUI

enum Motion {
    static let cardAppear = Animation.spring(response: 0.36, dampingFraction: 0.82)
    static let listChange = Animation.spring(response: 0.32, dampingFraction: 0.86)
    static let sheet = Animation.spring(response: 0.42, dampingFraction: 0.88)

    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}
