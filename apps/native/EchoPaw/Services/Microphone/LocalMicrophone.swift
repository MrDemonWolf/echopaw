import AVFoundation
import Observation
import Speech

@MainActor @Observable
final class LocalMicrophone {
    enum State: String { case off = "Off", starting = "Starting…", listening = "Listening locally" }
    private(set) var state = State.off
    private(set) var message: String?
    private(set) var inputs: [AVCaptureDevice] = []
    private var generation = UUID()
    private let worker = InputWorker()
    private let authorize: () async -> Bool
    private let activity: (Bool) -> Void

    init(authorize: @escaping () async -> Bool = { await AVCaptureDevice.requestAccess(for: .audio) },
         activity: @escaping (Bool) -> Void) {
        self.authorize = authorize
        self.activity = activity
    }

    func refreshInputs() {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else { return }
        inputs = AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external],
                                                  mediaType: .audio, position: .unspecified).devices
    }

    func start(deviceID: String, followsVoice: Bool, phrase: String?) {
        guard state == .off, followsVoice || phrase != nil else { return }
        state = .starting
        message = nil
        let turn = UUID()
        generation = turn
        Task { [self] in
            guard generation == turn else { return }
            guard await authorize() else {
                finish(turn, "Allow microphone access in System Settings > Privacy & Security.")
                return
            }
            guard generation == turn else { return }
            refreshInputs()
            if phrase != nil {
                let permission = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
                }
                guard generation == turn else { return }
                guard permission == .authorized else {
                    finish(turn, "Allow Speech Recognition or turn off wake phrase detection.")
                    return
                }
            }
            worker.start(id: deviceID, phrase: phrase) { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self, generation == turn else { return }
                    switch event {
                    case .ready: state = .listening
                    case .activity(let active): if followsVoice { activity(active) }
                    case .keyword: message = "Wake phrase heard locally."
                    case .failed(let reason): finish(turn, reason)
                    }
                }
            }
        }
    }

    func stop() {
        generation = UUID()
        state = .off
        message = nil
        activity(false)
        worker.stop()
    }

    func setPlaying(_ playing: Bool) { worker.setPlaying(playing) }

    private func finish(_ turn: UUID, _ reason: String) {
        guard generation == turn else { return }
        stop()
        message = reason
    }
}

// Capture objects and recognition callbacks are confined to this serial queue.
private final class InputWorker: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Event: Sendable { case ready, activity(Bool), keyword, failed(String) }
    private let queue = DispatchQueue(label: "dev.echopaw.local-input")
    private var capture: AVCaptureSession?
    private var observers: [NSObjectProtocol] = []
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognition: SFSpeechRecognitionTask?
    private var notify: (@Sendable (Event) -> Void)?
    private var lastActive = false
    private var suppressUntil = ContinuousClock.now
    private var playing = false
    private var token = UUID()
    private var lastMatchEnd = -1
    private var lastHeard = ContinuousClock.now

    func start(id: String, phrase: String?, notify: @escaping @Sendable (Event) -> Void) {
        queue.async { [self] in
            tearDown()
            self.notify = notify
            guard let device = id.isEmpty ? AVCaptureDevice.default(for: .audio) : AVCaptureDevice(uniqueID: id),
                  device.isConnected, let input = try? AVCaptureDeviceInput(device: device) else {
                fail("The selected microphone is unavailable. Choose another input.")
                return
            }
            let session = AVCaptureSession()
            let output = AVCaptureAudioDataOutput()
            guard session.canAddInput(input) else { fail("The microphone input could not be opened."); return }
            session.addInput(input)
            guard session.canAddOutput(output) else { fail("The microphone output could not be opened."); return }
            session.addOutput(output)
            output.setSampleBufferDelegate(self, queue: queue)
            capture = session
            if let phrase, !startRecognition(phrase) { return }
            let run = token
            for (name, object) in [(AVCaptureSession.runtimeErrorNotification, session as AnyObject),
                                   (AVCaptureDevice.wasDisconnectedNotification, device as AnyObject)] {
                let observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: nil) { [weak self] _ in
                    self?.queue.async { [weak self] in
                        guard let self, token == run else { return }
                        fail("Microphone capture was interrupted. Check the input and try again.")
                    }
                }
                observers.append(observer)
            }
            session.startRunning()
            if session.isRunning { notify(.ready) } else { fail("Microphone capture could not start.") }
        }
    }

    private func startRecognition(_ phrase: String) -> Bool {
        guard let recognizer = SFSpeechRecognizer(), recognizer.supportsOnDeviceRecognition, recognizer.isAvailable else {
            fail("On-device speech recognition is unavailable for this language. Turn off wake phrase detection to use voice activity.")
            return false
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        self.request = request
        let run = token
        recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let words = result?.bestTranscription.segments.map(\.substring) ?? []
            let finished = result?.isFinal == true || error != nil
            self?.queue.async { [weak self] in
                guard let self, token == run else { return }
                if !playing, ContinuousClock.now >= suppressUntil,
                   let end = WakePhrase.lastMatch(in: words, phrase: phrase),
                   end > lastMatchEnd {
                    lastMatchEnd = end
                    if ContinuousClock.now >= lastHeard {
                        lastHeard = .now.advanced(by: .seconds(3))
                        notify?(.keyword)
                    }
                }
                if finished { fail("Local keyword listening ended. Start listening again when ready.") }
            }
        }
        return true
    }

    func setPlaying(_ value: Bool) {
        queue.async { [self] in
            playing = value
            suppressUntil = .now.advanced(by: .milliseconds(400))
            if lastActive { lastActive = false; notify?(.activity(false)) }
        }
    }

    func stop() { queue.async { [self] in tearDown() } }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard notify != nil, !playing, ContinuousClock.now >= suppressUntil else { return }
        let peak = connection.audioChannels.map(\.averagePowerLevel).max() ?? -160
        let active = peak > (lastActive ? -43 : -36)
        if lastActive != active { lastActive = active; notify?(.activity(active)) }
        request?.appendAudioSampleBuffer(sampleBuffer)
    }

    private func fail(_ reason: String) {
        notify?(.failed(reason))
        tearDown()
    }

    private func tearDown() {
        token = UUID()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        recognition?.cancel()
        recognition = nil
        request?.endAudio()
        request = nil
        capture?.stopRunning()
        capture = nil
        notify = nil
        lastMatchEnd = -1
        lastHeard = .now
        lastActive = false
    }
}

enum WakePhrase {
    static func lastMatch(in segments: [String], phrase: String) -> Int? {
        func words(_ string: String) -> [Substring] {
            string.lowercased().split { !$0.isLetter && !$0.isNumber }
        }
        let tokens = words(segments.suffix(16).joined(separator: " "))
        let target = words(phrase)
        guard !target.isEmpty, tokens.suffix(target.count).elementsEqual(target) else { return nil }
        return segments.count
    }
}
