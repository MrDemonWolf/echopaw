import AppKit
import Combine
import Observation

@MainActor
@Observable
final class PreviewSession {
    let audio = PreviewAudio()
    private let capture = MascotWindow()
    private let preferences: UserDefaults

    @ObservationIgnored private var blinkTask: Task<Void, Never>?
    @ObservationIgnored private var displayOptionsObserver: AnyCancellable?
    private(set) var isBlinking = false
    private(set) var character: CharacterPack?
    private(set) var characterError: String?
    private(set) var isStopped = false
    private(set) var isMuted = false
    private(set) var isCaptureVisible = false

    var reducesMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        didSet {
            if reducesMotion != oldValue { scheduleBlinking() }
        }
    }

    var blinksAutomatically = true {
        didSet {
            preferences.set(blinksAutomatically, forKey: "blinkAutomatically")
            scheduleBlinking()
        }
    }

    var hasBlinkFrames: Bool {
        character?.blinking != nil || character?.talkingBlinking != nil
    }

    var usesChromaKey = false {
        didSet { updateCapture() }
    }

    var canTestOutput: Bool {
        character != nil && !isStopped && !isMuted && !audio.isPlaying && audio.isSelectedOutputAvailable
    }

    var canControlTestOutput: Bool { audio.isPlaying || canTestOutput }
    var testOutputActionTitle: String { audio.isPlaying ? "Stop test" : "Test output" }
    var captureActionTitle: String { isCaptureVisible ? "Hide mascot window" : "Show mascot window" }

    var image: NSImage? {
        character?.image(isTalking: audio.isPlaying, isBlinking: isBlinking)
    }

    var playbackLabel: String {
        if isStopped { return "Stopped" }
        if !audio.isSelectedOutputAvailable { return "Output unavailable" }
        if isMuted { return "Muted" }
        if audio.isPlaying { return "Playing test sound" }
        return "Idle"
    }

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        blinksAutomatically = preferences.object(forKey: "blinkAutomatically") as? Bool ?? true
        audio.onPlaybackChange = { [weak self] _ in self?.updateCapture() }
        capture.onVisibilityChange = { [weak self] visible in self?.isCaptureVisible = visible }
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
        scheduleBlinking()
    }

    func importCharacter(_ result: Result<URL, Error>) {
        do {
            character = try CharacterPack.importFolder(result.get())
            preferences.set(false, forKey: "useSampleCharacter")
            characterError = nil
            scheduleBlinking()
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
        } catch {
            characterError = error.localizedDescription
        }
    }

    func toggleTestOutput() {
        if audio.isPlaying {
            audio.stop()
        } else if canTestOutput {
            audio.playTest()
        }
    }

    func toggleMute() {
        guard !isStopped else { return }
        isMuted.toggle()
        if isMuted { audio.stop() }
    }

    func emergencyStop() {
        isStopped = true
        isMuted = true
        audio.stop()
        scheduleBlinking()
    }

    func resume() {
        isStopped = false
        scheduleBlinking()
    }

    func toggleCapture() {
        if isCaptureVisible {
            capture.hide()
        } else if let image {
            capture.show(image: image, chromaKey: usesChromaKey)
        }
    }

    private func updateCapture() {
        if let image { capture.update(image: image, chromaKey: usesChromaKey) }
    }

    private func scheduleBlinking() {
        blinkTask?.cancel()
        blinkTask = nil
        setBlinking(false)
        guard blinksAutomatically, !reducesMotion, hasBlinkFrames, !isStopped else { return }

        blinkTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.2...5.6)))
                guard !Task.isCancelled, self != nil else { return }
                self?.setBlinking(true)
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                self?.setBlinking(false)
            }
        }
    }

    private func setBlinking(_ value: Bool) {
        isBlinking = value
        updateCapture()
    }
}
