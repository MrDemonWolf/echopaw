import AppKit
import SwiftUI

@main
struct EchoPawApp: App {
    @State private var session = PreviewSession()

    var body: some Scene {
        Window("EchoPaw", id: "dashboard") {
            DashboardView(session: session)
        }
        .defaultSize(width: 950, height: 600)
        .commands {
            InspectorCommands()
            CommandMenu("Preview") {
                Button(session.testOutputActionTitle, action: session.toggleTestOutput)
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                    .disabled(!session.canControlTestOutput)
                Button(session.isMuted ? "Unmute speech" : "Mute speech", action: session.toggleMute)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                    .disabled(session.isStopped)
                Button(session.captureActionTitle, action: session.toggleCapture)
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                    .disabled(session.character == nil)
                Divider()
                Button("Emergency stop", action: session.emergencyStop)
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(session.isStopped)
                Button("Resume preview", action: session.resume)
                    .disabled(!session.isStopped)
            }
        }

        MenuBarExtra("EchoPaw", systemImage: session.isStopped ? "stop.circle" : "waveform") {
            PreviewMenu(session: session)
        }
    }
}

private struct PreviewMenu: View {
    @Environment(\.openWindow) private var openWindow
    let session: PreviewSession

    var body: some View {
        Button("Open EchoPaw") {
            openWindow(id: "dashboard")
            NSApp.activate()
        }
        Button(session.captureActionTitle, action: session.toggleCapture)
            .disabled(session.character == nil)
        Divider()
        Button(session.testOutputActionTitle, action: session.toggleTestOutput)
            .disabled(!session.canControlTestOutput)
        Button(session.isMuted ? "Unmute speech" : "Mute speech", action: session.toggleMute)
            .disabled(session.isStopped)
        if session.isStopped {
            Button("Resume preview", action: session.resume)
        } else {
            Button("Emergency stop", action: session.emergencyStop)
        }
        Divider()
        Button("Quit EchoPaw") { NSApp.terminate(nil) }
    }
}
