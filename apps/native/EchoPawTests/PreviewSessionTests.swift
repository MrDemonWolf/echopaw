import SwiftUI
import Testing
@testable import EchoPaw

@MainActor
struct PreviewSessionTests {
    @Test("The editor draws alternating transparency tiles behind the mascot")
    func previewShowsTransparencyGrid() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let renderer = ImageRenderer(content: PreviewSurface(session: fixture.session).frame(width: 360, height: 240))
        let bitmap = try NSBitmapImageRep(cgImage: #require(renderer.cgImage))
        let first = try #require(bitmap.colorAt(x: 8, y: 120))
        let adjacent = try #require(bitmap.colorAt(x: 24, y: 120))
        #expect(first != adjacent)
        #expect(first == bitmap.colorAt(x: 40, y: 120))
        let center = try #require(bitmap.colorAt(x: 180, y: 120))
        #expect(center != first && center != adjacent)
        #expect(center.alphaComponent > 0.9)
    }

    @Test("Eye and mouth states compose, even while speech is muted")
    func independentEyesAndMouth() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        let clock = fixture.clock
        let pack = try #require(session.character)
        session.setPreviewVisible(true)
        let blink = try #require(clock.next)
        #expect(blink.delay == .seconds(4))
        session.toggleMute()
        session.setMicrophoneActivity(true)
        #expect(session.image === pack.talking)
        blink.fire()
        #expect(session.image === pack.talkingBlinking)
        let reopen = try #require(clock.next)
        #expect(reopen.delay == .milliseconds(150))
        session.setMicrophoneActivity(false)
        #expect(session.image === pack.blinking)
        reopen.fire()
        #expect(session.image === pack.idle)
    }

    @Test("Reduce Motion cancels automatic blinks and keeps the manual pose preview available")
    func reduceMotionAndManualPreview() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        session.setPreviewVisible(true)
        let stale = try #require(fixture.clock.next)
        session.reducesMotion = true
        #expect(stale.task.isCancelled)
        stale.fire()
        #expect(!session.isBlinking)
        session.previewBlink()
        #expect(session.isBlinking)
        let reopen = try #require(fixture.clock.next)
        #expect(reopen.delay == .milliseconds(300))
        reopen.fire()
        #expect(!session.isBlinking)
        #expect(reopen.task.isCancelled)
        #expect(fixture.clock.scheduled == 2)
    }

    @Test("Changing packs supersedes old callbacks and reopening the same view does not start extra timers")
    func lifecycleCancelsStaleWork() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        session.setPreviewVisible(true)
        session.setPreviewVisible(true)
        #expect(fixture.clock.scheduled == 1)
        let oldPack = try #require(fixture.clock.next)
        session.useSample()
        let currentPack = try #require(fixture.clock.next)
        #expect(oldPack.task.isCancelled)
        oldPack.fire()
        #expect(!session.isBlinking)
        currentPack.fire()
        #expect(session.isBlinking)
        let stale = try #require(fixture.clock.next)
        session.setPreviewVisible(false)
        #expect(stale.task.isCancelled)
        stale.fire()
        #expect(!session.isBlinking)
        #expect(!session.canPreviewBlink)
        #expect(fixture.clock.scheduled == 3)
    }

    @Test("Closing the main preview keeps an open output panel blinking")
    func captureContinuesWhenPreviewCloses() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        session.setPreviewVisible(true)
        let blink = try #require(fixture.clock.next)
        session.toggleCapture()
        try #require(session.isCaptureVisible)
        session.setPreviewVisible(false)
        #expect(!blink.task.isCancelled)
        blink.fire()
        #expect(session.isBlinking)
        let reopen = try #require(fixture.clock.next)
        session.toggleCapture()
        #expect(!session.isCaptureVisible)
        #expect(reopen.task.isCancelled)
        #expect(!session.isBlinking)
    }

    @Test("A missing selected route survives relaunch, with its volume and capture preference")
    func unavailableOutputStaysSelected() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        let missingDevice = UUID().uuidString
        session.audio.selectOutput(missingDevice)
        session.audio.volume = 0.7
        session.usesChromaKey = true

        let restored = PreviewSession(preferences: fixture.preferences)
        let audio = restored.audio
        #expect(restored.usesChromaKey)
        #expect(audio.volume == 0.7)
        audio.playTest()
        #expect(audio.selectedDeviceUID == missingDevice)
        #expect(!audio.isSelectedOutputAvailable)
        #expect(!audio.isPlaying)
        #expect(audio.lastError != nil)
        audio.selectOutput(nil)
        #expect(audio.isSelectedOutputAvailable)
        #expect(audio.lastError == nil)
        #expect(fixture.preferences.string(forKey: "outputDeviceUID") == nil)
    }

    @Test("Emergency stop rejects late activity, and resuming leaves speech muted")
    func emergencyStopLatches() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let session = fixture.session
        #expect(session.recentActivity.isEmpty)
        session.setPreviewVisible(true)
        #expect(!session.isMuted)
        #expect(session.canTestOutput)
        session.setMicrophoneActivity(true)
        var shutDown = false
        session.onEmergencyStop = { shutDown = true }
        let staleBlink = try #require(fixture.clock.next)

        session.toggleCapture()
        #expect(session.isCaptureVisible)
        session.emergencyStop()
        session.toggleCapture()
        #expect(!session.isCaptureVisible)
        session.toggleMute()
        session.toggleTestOutput()
        session.setMicrophoneActivity(true)
        staleBlink.fire()
        #expect(shutDown)
        #expect(session.isStopped)
        #expect(session.isMuted)
        #expect(!session.audio.isPlaying)
        #expect(!session.isTalking)
        #expect(!session.isBlinking)
        #expect(!session.canTestOutput)
        #expect(session.recentActivity.first == "Emergency stop")

        session.resume()
        #expect(!session.isStopped)
        #expect(session.isMuted)
        #expect(!session.canTestOutput)
        session.toggleMute()
        #expect(session.canTestOutput)
    }

    @MainActor
    private struct Fixture {
        let suite = UUID().uuidString
        let preferences: UserDefaults
        let clock = BlinkClock()
        let session: PreviewSession

        init() throws {
            preferences = try #require(UserDefaults(suiteName: suite))
            preferences.set(true, forKey: "useSampleCharacter")
            session = PreviewSession(preferences: preferences, schedule: clock.schedule, blinkInterval: { .seconds(4) })
            session.reducesMotion = false
        }

        func cleanUp() {
            session.setPreviewVisible(false)
            if session.isCaptureVisible { session.toggleCapture() }
            preferences.removePersistentDomain(forName: suite)
        }
    }

    @MainActor
    private final class BlinkClock {
        struct Alarm {
            let delay: Duration
            let fire: @MainActor () -> Void
            let task: Task<Void, Never>
        }

        var next: Alarm?
        var scheduled = 0

        func schedule(_ delay: Duration, fire: @escaping @MainActor () -> Void) -> Task<Void, Never> {
            let task = Task {}
            next = Alarm(delay: delay, fire: fire, task: task)
            scheduled += 1
            return task
        }
    }
}
