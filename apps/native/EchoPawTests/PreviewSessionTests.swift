import Foundation
import Testing
@testable import EchoPaw

@MainActor
struct PreviewSessionTests {
    @Test("The sample blinks and Reduce Motion clears the blink")
    func sampleBlinksAndHonorsReduceMotion() async throws {
        let suiteName = UUID().uuidString
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        preferences.set(true, forKey: "useSampleCharacter")
        let session = PreviewSession(preferences: preferences)

        session.reducesMotion = true
        #expect(!session.isBlinking)
        session.reducesMotion = false

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(7))
        while !session.isBlinking && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(session.isBlinking)
        #expect(session.image === session.character?.blinking)

        session.reducesMotion = true
        #expect(!session.isBlinking)
        #expect(session.image === session.character?.idle)
    }

    @Test("An unavailable explicit output never falls back")
    func unavailableOutputStaysSelected() {
        let audio = PreviewAudio()
        let missingDevice = UUID().uuidString
        audio.selectOutput(missingDevice)
        audio.playTest()
        #expect(audio.selectedDeviceUID == missingDevice)
        #expect(!audio.isPlaying)
        #expect(audio.lastError != nil)

        audio.selectOutput(nil)
        #expect(audio.isSelectedOutputAvailable)
        #expect(audio.lastError == nil)
    }

    @Test("Emergency stop requires resume and explicit unmute")
    func emergencyStopLatches() throws {
        let suiteName = UUID().uuidString
        let preferences = try #require(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        preferences.set(true, forKey: "useSampleCharacter")
        let session = PreviewSession(preferences: preferences)
        #expect(session.canTestOutput)

        session.emergencyStop()
        session.toggleMute()
        session.toggleTestOutput()
        #expect(session.isStopped)
        #expect(session.isMuted)
        #expect(!session.audio.isPlaying)
        #expect(!session.canTestOutput)

        session.resume()
        #expect(!session.isStopped)
        #expect(session.isMuted)
        #expect(!session.canTestOutput)

        session.toggleMute()
        #expect(session.canTestOutput)
    }
}
