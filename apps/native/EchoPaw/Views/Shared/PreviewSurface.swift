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

    var body: some View {
        Group {
            if let image = session.image {
                Image(nsImage: image)
                    .resizable().scaledToFit()
                    .padding(.vertical, EP.space3)
                    .accessibilityLabel(session.isTalking ? "Talking mascot" : "Idle mascot")
            } else {
                ContentUnavailableView("Choose a character", systemImage: "pawprint")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Canvas { context, size in
                let tile = EP.space4
                var checks = Path()
                for row in 0..<Int(ceil(size.height / tile)) {
                    for column in stride(from: row % 2, to: Int(ceil(size.width / tile)), by: 2) {
                        checks.addRect(CGRect(x: CGFloat(column) * tile, y: CGFloat(row) * tile,
                                              width: tile, height: tile))
                    }
                }
                context.fill(checks, with: .color(.primary.opacity(0.07)))
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
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
