import Foundation
import OSLog
import MetricKit

/// Product events for the launch funnel: install → first note → first session → repeat use → (later) purchase.
/// Events carry no personal content: never note text, names or reflections, only ids, counts and flags.
enum AnalyticsEvent {
    case appOpened
    case introFinished(openedSetup: Bool), introSkipped(page: Int)
    case preferencesSaved(focus: String, mode: String, minutes: Int)
    case noteSaved(isNew: Bool, usedVoice: Bool, category: String), noteActivated
    case sessionStarted(planID: String, resumed: Bool), sessionCompleted(planID: String, minutes: Int, loggedResult: Bool)
    case sessionLeft(planID: String, keptDraft: Bool)
    case motionViewed(motionID: String), motionCameraChanged(camera: String), motionSlowToggled(on: Bool)

    var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .introFinished: "intro_finished"
        case .introSkipped: "intro_skipped"
        case .preferencesSaved: "preferences_saved"
        case .noteSaved: "note_saved"
        case .noteActivated: "note_activated"
        case .sessionStarted: "session_started"
        case .sessionCompleted: "session_completed"
        case .sessionLeft: "session_left"
        case .motionViewed: "motion_viewed"
        case .motionCameraChanged: "motion_camera_changed"
        case .motionSlowToggled: "motion_slow_toggled"
        }
    }
    var parameters: [String: String] {
        switch self {
        case .appOpened, .noteActivated: [:]
        case let .introFinished(openedSetup): ["opened_setup": "\(openedSetup)"]
        case let .introSkipped(page): ["page": "\(page)"]
        case let .preferencesSaved(focus, mode, minutes): ["focus": focus, "mode": mode, "minutes": "\(minutes)"]
        case let .noteSaved(isNew, usedVoice, category): ["new": "\(isNew)", "voice": "\(usedVoice)", "category": category]
        case let .sessionStarted(planID, resumed): ["plan": planID, "resumed": "\(resumed)"]
        case let .sessionCompleted(planID, minutes, loggedResult): ["plan": planID, "minutes": "\(minutes)", "result": "\(loggedResult)"]
        case let .sessionLeft(planID, keptDraft): ["plan": planID, "kept_draft": "\(keptDraft)"]
        case let .motionViewed(motionID): ["motion": motionID]
        case let .motionCameraChanged(camera): ["camera": camera]
        case let .motionSlowToggled(on): ["on": "\(on)"]
        }
    }
}

/// Where events go. Today: the device log only (nothing leaves the phone).
/// To ship analytics, add a provider here (e.g. a privacy-first service) and update PrivacyInfo.xcprivacy.
protocol AnalyticsProvider { func send(_ name: String, _ parameters: [String: String]) }

struct DeviceLogProvider: AnalyticsProvider {
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Ralli", category: "analytics")
    func send(_ name: String, _ parameters: [String: String]) {
        log.info("\(name, privacy: .public) \(parameters.description, privacy: .public)")
    }
}

enum Analytics {
    nonisolated(unsafe) static var providers: [AnalyticsProvider] = [DeviceLogProvider()]
    static func track(_ event: AnalyticsEvent) {
        for provider in providers { provider.send(event.name, event.parameters) }
    }
}

/// Receives Apple's daily performance metrics and crash / hang diagnostics from MetricKit.
/// They are logged on device now; when a backend exists, forward `jsonRepresentation()` there.
final class DiagnosticsReceiver: NSObject, MXMetricManagerSubscriber {
    static let shared = DiagnosticsReceiver()
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Ralli", category: "diagnostics")
    func start() { MXMetricManager.shared.add(self) }
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads { log.info("metrics \(payload.jsonRepresentation().count) bytes") }
    }
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            log.error("diagnostics crashes=\(payload.crashDiagnostics?.count ?? 0) hangs=\(payload.hangDiagnostics?.count ?? 0)")
        }
    }
}
