import Foundation
import Testing
@testable import EchoPaw

@MainActor
struct MicrophoneTests {
    @Test func matchesCompleteLocalPhrase() {
        #expect(WakePhrase.lastMatch(in: ["Say", "Hey", "EchoPaw!"], phrase: "hey echopaw") == 3)
        #expect(WakePhrase.lastMatch(in: ["they", "echopaw"], phrase: "hey echopaw") == nil)
        #expect(WakePhrase.lastMatch(in: ["Hey", "EchoPaw", "later"], phrase: "hey echopaw") == nil)
        #expect(WakePhrase.lastMatch(in: [], phrase: "") == nil)
    }

    @Test func stopRejectsLateMicrophonePermission() async {
        var permission: CheckedContinuation<Bool, Never>?
        var active = false
        let mic = LocalMicrophone(authorize: { await withCheckedContinuation { permission = $0 } }) { active = $0 }
        mic.start(deviceID: "", followsVoice: true, phrase: nil)
        mic.stop()
        await Task.yield()
        #expect(permission == nil)

        mic.start(deviceID: "", followsVoice: true, phrase: nil)
        while permission == nil { await Task.yield() }
        #expect(mic.state == .starting)
        mic.stop()
        permission?.resume(returning: false)
        await Task.yield()
        #expect(mic.state == .off)
        #expect(mic.message == nil)
        #expect(!active)
    }
}
