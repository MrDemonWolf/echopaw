import CoreText
import SwiftUI

enum BrandType {
    static func registerFonts() {
        for family in ["montserrat", "roboto"] {
            if let url = Bundle.main.url(forResource: family, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static let heading = Font.custom(EP.headingFamily, size: EP.headingSize, relativeTo: .title2).weight(.semibold)
    static let body = Font.custom(EP.bodyFamily, size: EP.bodySize, relativeTo: .body)
}

struct PreviewSurface: View {
    let session: PreviewSession
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            landscape
                .accessibilityHidden(true)
            if let image = session.image {
                Image(nsImage: image)
                    .resizable().scaledToFit()
                    .padding(.vertical, EP.space3)
                    .accessibilityLabel(session.isTalking ? "Talking mascot" : "Idle mascot")
            } else {
                ContentUnavailableView("Choose a character", systemImage: "pawprint")
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: EP.radiusPanel))
        .overlay {
            RoundedRectangle(cornerRadius: EP.radiusPanel)
                .strokeBorder(.primary.opacity(contrast == .increased ? 0.7 : 0.13))
                .allowsHitTesting(false)
        }
    }

    private var landscape: some View {
        let dark = scheme == .dark
        return ZStack {
            LinearGradient(colors: dark ? [EP.navy900, EP.navy700] : [EP.paper, EP.stageLight],
                           startPoint: .top, endPoint: .bottomTrailing)
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let peaks: [[CGFloat]] = [
                    [0.73, 0.51, 0.66, 0.48, 0.78, 0.67, 0.53, 0.72, 0.48],
                    [0.83, 0.73, 0.88, 0.74, 0.81, 0.67, 0.82, 0.70, 0.76]
                ]
                for (index, ridge) in peaks.enumerated() {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: h))
                    for (step, height) in ridge.enumerated() {
                        path.addLine(to: CGPoint(x: w * CGFloat(step) / CGFloat(ridge.count - 1), y: height * h))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                    let ink = dark ? EP.navy900 : EP.navy700
                    context.fill(path, with: .color(ink.opacity(dark ? 0.24 + Double(index) * 0.16 : 0.06 + Double(index) * 0.04)))
                }
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let symbol: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: EP.space2) {
            Image(systemName: symbol)
                .frame(width: 18).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(title)
            Spacer(minLength: EP.space2)
            Text(value).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

struct TalkingButton: View {
    let session: PreviewSession

    var body: some View {
        Button(session.audio.isPlaying ? "Stop test" : "Preview talking",
               systemImage: session.audio.isPlaying ? "stop.fill" : "play.fill",
               action: session.toggleTestOutput)
            .buttonStyle(.borderedProminent)
            .disabled(!session.canControlTestOutput)
            .help("Play the local test sound on the selected output (⇧⌘T)")
    }
}
