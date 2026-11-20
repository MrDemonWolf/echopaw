import AVFoundation
import CoreAudio
import Observation

@MainActor
@Observable
final class PreviewAudio {
    struct OutputDevice: Identifiable {
        let uid: String
        let name: String
        var id: String { uid }
    }

    private(set) var devices: [OutputDevice] = []
    private(set) var selectedDeviceUID: String?
    private(set) var isPlaying = false
    private(set) var lastError: String?
    var isSelectedOutputAvailable: Bool {
        guard let selectedDeviceUID else { return true }
        return observer != nil && devices.contains { $0.uid == selectedDeviceUID }
    }

    var onPlaybackChange: ((Bool) -> Void)?
    var volume: Float = 0.35 {
        didSet { player?.volume = volume }
    }

    @ObservationIgnored private var observer: DeviceObserver?
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var completion: PlaybackCompletion?

    init() {
        observer = DeviceObserver { [weak self] in
            Task { @MainActor [weak self] in self?.refreshDevices() }
        }
        refreshDevices()
    }

    func selectOutput(_ uid: String?) {
        guard uid != selectedDeviceUID else { return }
        stop()
        selectedDeviceUID = uid
        lastError = nil
        refreshDevices()
    }

    func playTest() {
        guard !isPlaying else { return }
        refreshDevices()
        guard isSelectedOutputAvailable else { return }
        lastError = nil

        guard let url = Bundle.main.url(forResource: "PreviewTone", withExtension: "wav") else {
            lastError = "The test sound is missing from this build."
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            if let selectedDeviceUID {
                player.currentDevice = selectedDeviceUID
                guard player.currentDevice == selectedDeviceUID else {
                    lastError = "The selected device did not accept the route. Choose another output."
                    return
                }
            }
            let completion = PlaybackCompletion { [weak self] id, succeeded in
                Task { @MainActor [weak self] in
                    guard let self, self.completion?.id == id else { return }
                    self.stop()
                    if !succeeded { self.lastError = "Playback was interrupted. Check your audio output." }
                }
            }
            player.delegate = completion
            player.volume = volume
            guard player.play() else {
                lastError = "The test sound could not play. Check your audio output."
                return
            }
            self.completion = completion
            self.player = player
            setPlaying(true)
        } catch {
            lastError = "The test sound could not be opened."
        }
    }

    func stop() {
        player?.delegate = nil
        player?.stop()
        player = nil
        completion = nil
        setPlaying(false)
    }

    private func refreshDevices() {
        devices = Self.outputDevices()
        guard let selectedDeviceUID else { return }

        if observer == nil {
            stop()
            lastError = "Device changes cannot be monitored. Choose System Default."
        } else if !devices.contains(where: { $0.uid == selectedDeviceUID }) {
            stop()
            lastError = "The selected output is unavailable. Choose another device or reconnect it."
        } else {
            lastError = nil
        }
    }

    private func setPlaying(_ value: Bool) {
        guard isPlaying != value else { return }
        isPlaying = value
        onPlaybackChange?(value)
    }

    private static func outputDevices() -> [OutputDevice] {
        var property = DeviceObserver.address
        var byteCount: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &property, 0, nil, &byteCount) == noErr,
              byteCount >= MemoryLayout<AudioDeviceID>.stride
        else { return [] }

        var identifiers = [AudioDeviceID](repeating: 0, count: Int(byteCount) / MemoryLayout<AudioDeviceID>.stride)
        let status = identifiers.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(system, &property, 0, nil, &byteCount, buffer.baseAddress!)
        }
        guard status == noErr else { return [] }

        return identifiers.prefix(Int(byteCount) / MemoryLayout<AudioDeviceID>.stride).compactMap { device in
            var streams = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamBytes: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(device, &streams, 0, nil, &streamBytes) == noErr,
                  streamBytes > 0,
                  let uid = stringProperty(kAudioDevicePropertyDeviceUID, of: device),
                  let name = stringProperty(kAudioObjectPropertyName, of: device)
            else { return nil }
            return OutputDevice(uid: uid, name: name)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func stringProperty(_ selector: AudioObjectPropertySelector, of device: AudioDeviceID) -> String? {
        var property = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var string: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout.size(ofValue: string))
        guard AudioObjectGetPropertyData(device, &property, 0, nil, &size, &string) == noErr else { return nil }
        return string?.takeRetainedValue() as String?
    }
}

private final class DeviceObserver {
    private let listener: AudioObjectPropertyListenerBlock

    static var address: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    init?(onChange: @escaping @Sendable () -> Void) {
        let listener: AudioObjectPropertyListenerBlock = { _, _ in onChange() }
        var address = Self.address
        guard AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, .main, listener
        ) == noErr else { return nil }
        self.listener = listener
    }

    deinit {
        var address = Self.address
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, .main, listener
        )
    }
}

private final class PlaybackCompletion: NSObject, AVAudioPlayerDelegate {
    let id = UUID()
    let notify: @Sendable (UUID, Bool) -> Void

    init(notify: @escaping @Sendable (UUID, Bool) -> Void) {
        self.notify = notify
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        notify(id, flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        notify(id, false)
    }
}
