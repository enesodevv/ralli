import AVFoundation
import Speech
import SwiftUI

@MainActor final class SpeechNoteRecorder: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var recording = false
    @Published private(set) var requesting = false
    @Published var message: String?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer = SFSpeechRecognizer(locale: L10n.speechLocale)
    private var tapInstalled = false
    private var timeout: Task<Void, Never>?
    private var generation = UUID()

    func start() async {
        guard !recording && !requesting else { return }
        requesting = true
        message = nil
        defer { requesting = false }
        let token = UUID()
        generation = token
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard generation == token else { return }
        guard speech == .authorized else {
            message = L10n.text("Sesli not için Ayarlar’dan konuşma tanıma izni verebilirsin. Yazıyla devam edebilirsin.")
            return
        }
        let microphone = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard generation == token else { return }
        guard microphone else {
            message = L10n.text("Mikrofon izni kapalı. Ayarlar’dan izin verebilir veya notunu yazabilirsin.")
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            message = L10n.text("Türkçe konuşma tanıma şu anda kullanılamıyor. Yazıyla devam edebilirsin.")
            return
        }
        do {
            transcript = ""
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            // Keep speech on the device whenever the phone supports it; audio then never leaves the iPhone.
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
            self.request = request
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0 && format.channelCount > 0 else {
                stop(); message = L10n.text("Mikrofona erişilemedi. Gerçek cihazda tekrar deneyebilirsin."); return
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let final = result?.isFinal ?? false
                let failed = error != nil
                Task { @MainActor in
                    guard let self, self.generation == token else { return }
                    if let text { self.transcript = text }
                    if final || failed {
                        self.stop()
                        if failed { self.message = L10n.text("Dinleme sona erdi. Gelen metni kontrol edebilir veya yeniden deneyebilirsin.") }
                    }
                }
            }
            engine.prepare()
            try engine.start()
            recording = true
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(55))
                guard !Task.isCancelled else { return }
                self?.stop()
                self?.message = L10n.text("Dinleme tamamlandı. Metni kontrol edip kaydedebilirsin.")
            }
        } catch {
            stop()
            message = L10n.text("Sesli not başlatılamadı. Notunu yazarak kaydedebilirsin.")
        }
    }
    func stop() {
        generation = UUID()
        timeout?.cancel(); timeout = nil
        engine.stop()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); task?.cancel()
        request = nil; task = nil; recording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
