import AudioToolbox
import UIKit

/// Plays system sounds + haptics. No audio assets required.
struct SoundManager {

    // MARK: - Combat Events

    static func cardPlay() {
        AudioServicesPlaySystemSound(1114)   // "Swish"
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func enemyHit() {
        AudioServicesPlaySystemSound(1117)   // "Tock"
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heroHit() {
        AudioServicesPlaySystemSound(1521)   // System haptic thud
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func levelUp() {
        AudioServicesPlaySystemSound(1155)   // Ascending chime
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func victory() {
        AudioServicesPlaySystemSound(1256)   // Payment success ding
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func defeat() {
        AudioServicesPlaySystemSound(1257)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func cardDraw() {
        AudioServicesPlaySystemSound(1104)   // Soft click
    }

    static func buttonTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
