import AppKit
import Combine
import Observation

@MainActor
@Observable
final class PreviewSession {
    typealias BlinkScheduler = @MainActor (Duration, @escaping @MainActor () -> Void) -> Task<Void, Never>

    let audio: PreviewAudio
    private let capture = MascotWindow()
    private let preferences: UserDefaults
    private let schedule: BlinkScheduler
    private let blinkInterval: () -> Duration

    @ObservationIgnored private var blinkTask: Task<Void, Never>?
    @ObservationIgnored private var blinkRevision: UInt64 = 0
    @ObservationIgnored private var displayOptionsObserver: AnyCancellable?
    @ObservationIgnored private var microphoneMayResumeAt: ContinuousClock.Instant?
    @ObservationIgnored var onEmergencyStop: (() -> Void)?
    @ObservationIgnored var onPlaybackChange: ((Bool) -> Void)?

    private(set) var isBlinking = false
    private(set) var character: CharacterPack?
    private(set) var characterError: String?
    private(set) var isStopped = false
    private(set) var isMuted = false
    private(set) var isMicrophoneActive = false
    private(set) var isCaptureVisible = false
    private(set) var recentActivity: [String] = []
    private var previewVisible = false

    var reducesMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        didSet {
            if reducesMotion != oldValue { scheduleBlinking() }
        }
    }

    var blinksAutomatically = true {
        didSet {
            guard oldValue != blinksAutomatically else { return }
            preferences.set(blinksAutomatically, forKey: "blinkAutomatically")
            scheduleBlinking()
        }
    }

    var hasBlinkFrames: Bool {
        character?.blinking != nil || character?.talkingBlinking != nil
    }

    var canPreviewBlink: Bool {
        guard !isStopped, previewVisible || isCaptureVisible else { return false }
        return isTalking ? character?.talkingBlinking != nil : character?.blinking != nil
    }

    var usesChromaKey: Bool {
        didSet {
            preferences.set(usesChromaKey, forKey: "usesChromaKey")
            updateCapture()
        }
    }

    var isTalking: Bool { audio.isSpeaking || isMicrophoneActive }

    var canTestOutput: Bool {
        character != nil && !isStopped && !isMuted && !audio.isPlaying && audio.isSelectedOutputAvailable
    }

    var canControlTestOutput: Bool { audio.isPlaying || canTestOutput }
    var testOutputActionTitle: String { audio.isPlaying ? "Stop test" : "Preview talking" }
    var captureActionTitle: String { isCaptureVisible ? "Hide mascot window" : "Show mascot window" }

    var image: NSImage? {
        character?.image(isTalking: isTalking, isBlinking: isBlinking)
    }

    var playbackLabel: String {
        if isStopped { return "Stopped" }
        if !audio.isSelectedOutputAvailable { return "Output unavailable" }
        if isMuted { return "Muted" }
        if audio.isPlaying { return "Playing test sound" }
        if isMicrophoneActive { return "Microphone activity" }
        return "Idle"
    }

    init(
        preferences: UserDefaults = .standard,
        schedule: @escaping BlinkScheduler = { delay, fire in
            Task {
                do { try await Task.sleep(for: delay) } catch { return }
                guard !Task.isCancelled else { return }
                fire()
            }
        },
        blinkInterval: @escaping () -> Duration = { .seconds(Double.random(in: 3.2...5.6)) }
    ) {
        self.preferences = preferences
        self.schedule = schedule
        self.blinkInterval = blinkInterval
        audio = PreviewAudio(preferences: preferences)
        usesChromaKey = preferences.bool(forKey: "usesChromaKey")
        blinksAutomatically = preferences.object(forKey: "blinkAutomatically") as? Bool ?? true
        audio.onSpeakingChange = { [weak self] in self?.updateCapture() }
        audio.onPlaybackChange = { [weak self] playing in
            guard let self else { return }
            isMicrophoneActive = false
            if playing {
                record("Played local test sound")
            } else {
                microphoneMayResumeAt = .now.advanced(by: .milliseconds(400))
            }
            onPlaybackChange?(playing)
            updateCapture()
        }
        capture.onVisibilityChange = { [weak self] visible in
            guard let self else { return }
            let wasRendering = previewVisible || isCaptureVisible
            isCaptureVisible = visible
            if wasRendering != (previewVisible || visible) { scheduleBlinking() }
            record(visible ? "Opened mascot window" : "Closed mascot window")
        }
        displayOptionsObserver = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.reducesMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                }
            }

        do {
            if !preferences.bool(forKey: "useSampleCharacter"), let saved = try CharacterPack.saved() {
                character = saved
            } else {
                character = try CharacterPack.sample()
            }
        } catch {
            character = try? CharacterPack.sample()
            characterError = error.localizedDescription
        }
    }

    deinit { blinkTask?.cancel() }

    func setPreviewVisible(_ visible: Bool) {
        guard previewVisible != visible else { return }
        previewVisible = visible
        if !isCaptureVisible { scheduleBlinking() }
    }

    func setMicrophoneActivity(_ active: Bool) {
        let permitted = !isStopped && !audio.isPlaying && (microphoneMayResumeAt.map { .now >= $0 } ?? true)
        let speaking = active && permitted
        guard speaking != isMicrophoneActive else { return }
        isMicrophoneActive = speaking
        updateCapture()
    }

    func previewBlink() {
        guard canPreviewBlink else { return }
        scheduleBlinking(closedFor: .milliseconds(300))
    }

    func importCharacter(_ result: Result<URL, Error>) {
        importCharacter { try CharacterPack.importFolder(result.get()) }
    }

    func importCharacterImages(idle: URL, speaking: URL) {
        importCharacter { try CharacterPack.importImages(idle: idle, speaking: speaking) }
    }

    private func importCharacter(_ load: () throws -> CharacterPack) {
        do {
            character = try load()
            preferences.set(false, forKey: "useSampleCharacter")
            characterError = nil
            scheduleBlinking()
            record("Imported character")
        } catch {
            characterError = error.localizedDescription
        }
    }

    func useSample() {
        do {
            character = try CharacterPack.sample()
            preferences.set(true, forKey: "useSampleCharacter")
            characterError = nil
            scheduleBlinking()
            record("Selected starter wolf")
        } catch {
            characterError = error.localizedDescription
        }
    }

    func toggleTestOutput() {
        if audio.isPlaying {
            audio.stop()
            record("Stopped local test sound")
        } else if canTestOutput {
            audio.playTest()
        }
    }

    func toggleMute() {
        guard !isStopped else { return }
        isMuted.toggle()
        if isMuted { audio.stop() }
        record(isMuted ? "Muted speech" : "Unmuted speech")
    }

    func emergencyStop() {
        guard !isStopped else { return }
        isStopped = true
        isMuted = true
        isMicrophoneActive = false
        audio.stop()
        onEmergencyStop?()
        if isCaptureVisible { capture.hide() }
        scheduleBlinking()
        record("Emergency stop")
    }

    func resume() {
        guard isStopped else { return }
        isStopped = false
        scheduleBlinking()
        record("Resumed preview")
    }

    func toggleCapture() {
        guard !isStopped else { return }
        if isCaptureVisible {
            capture.hide()
        } else if let image {
            capture.show(image: image, chromaKey: usesChromaKey)
        }
    }

    private func updateCapture() {
        if isCaptureVisible, let image { capture.update(image: image, chromaKey: usesChromaKey) }
    }

    private func scheduleBlinking(closedFor: Duration? = nil) {
        blinkTask?.cancel()
        blinkTask = nil
        blinkRevision += 1
        isBlinking = closedFor != nil
        updateCapture()
        guard previewVisible || isCaptureVisible, hasBlinkFrames, !isStopped else { return }
        guard closedFor != nil || (blinksAutomatically && !reducesMotion) else { return }

        let revision = blinkRevision
        blinkTask = schedule(closedFor ?? blinkInterval()) { [weak self] in
            guard let self, blinkRevision == revision else { return }
            scheduleBlinking(closedFor: closedFor == nil ? .milliseconds(150) : nil)
        }
    }

    private func record(_ event: String) {
        recentActivity.insert(event, at: 0)
        if recentActivity.count > 5 { recentActivity.removeLast() }
    }
}
