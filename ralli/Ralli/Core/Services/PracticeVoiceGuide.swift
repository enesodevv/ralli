import AVFoundation
import SwiftUI
import UIKit

@MainActor final class PracticeVoiceGuide: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String) {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        synthesizer.stopSpeaking(at: .immediate)
        // Match app language. This is local speech synthesis, not microphone recording.
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: L10n.speechLocale.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}
