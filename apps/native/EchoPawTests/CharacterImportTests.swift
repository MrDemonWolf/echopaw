import AppKit
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import EchoPaw

@MainActor
struct CharacterImportTests {
    @Test func loadsBundledSample() throws {
        let pack = try CharacterPack.sample()
        #expect(pack.name == "EchoPaw sample")
        #expect(pack.idle.size == NSSize(width: 512, height: 512))
        #expect(pack.talking.size == pack.idle.size)
        let blinking = try #require(pack.blinking)
        let talkingBlinking = try #require(pack.talkingBlinking)
        #expect(blinking.size == pack.idle.size)
        #expect(talkingBlinking.size == pack.idle.size)
        #expect(pack.image(isTalking: true, isBlinking: true) === talkingBlinking)
    }

    @Test func savedCopySurvivesRemovingTheSource() throws {
        let files = try Folders()
        defer { files.remove() }
        try makePNG(width: 16, at: files.idle)
        try makePNG(width: 16, at: files.talking)

        _ = try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        try FileManager.default.removeItem(at: files.source)

        let saved = try #require(try CharacterPack.saved(storageRoot: files.storage))
        #expect(saved.name == "Character")
        #expect(saved.idle.size == NSSize(width: 16, height: 16))
        #expect(saved.image(isTalking: false, isBlinking: true) === saved.idle)
        #expect(saved.image(isTalking: true, isBlinking: true) === saved.talking)
    }

    @Test func optionalBlinkPersistsAndMissingTalkingBlinkKeepsTalkingPose() throws {
        let files = try Folders()
        defer { files.remove() }
        try makePNG(width: 16, at: files.idle)
        try makePNG(width: 16, at: files.talking)
        let blink = files.source.appending(path: "blinking.png")
        try makePNG(width: 16, at: blink)
        _ = try CharacterPack.importFolder(files.source, storageRoot: files.storage)

        try makePNG(width: 24, at: blink)
        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
        let saved = try #require(try CharacterPack.saved(storageRoot: files.storage))
        let blinking = try #require(saved.blinking)
        #expect(saved.image(isTalking: false, isBlinking: true) === blinking)
        #expect(saved.image(isTalking: true, isBlinking: true) === saved.talking)
    }

    @Test func invalidReplacementKeepsSavedCharacter() throws {
        let files = try Folders()
        defer { files.remove() }
        try makePNG(width: 16, at: files.idle)
        try makePNG(width: 16, at: files.talking)
        _ = try CharacterPack.importFolder(files.source, storageRoot: files.storage)

        try makePNG(width: 24, at: files.talking)
        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
        try Data("Malformed content".utf8).write(to: files.talking)
        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
        let validBytes = try Data(contentsOf: files.idle)
        try validBytes.prefix(validBytes.count / 2).write(to: files.talking)
        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }

        let saved = try #require(try CharacterPack.saved(storageRoot: files.storage))
        #expect(saved.talking.size == NSSize(width: 16, height: 16))
    }

    @Test func rejectsSymlinkedAndOversizedPoses() throws {
        let files = try Folders()
        defer { files.remove() }
        try makePNG(width: 16, at: files.idle)
        let outside = files.source.deletingLastPathComponent().appending(path: "outside.png")
        try makePNG(width: 16, at: outside)
        try FileManager.default.createSymbolicLink(at: files.talking, withDestinationURL: outside)

        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
        try FileManager.default.removeItem(at: files.talking)
        try makePNG(width: 2_049, at: files.talking)
        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
        #expect(try CharacterPack.saved(storageRoot: files.storage) == nil)
    }

    @Test func rejectsAnimatedPNG() throws {
        let files = try Folders()
        defer { files.remove() }
        try makePNG(width: 16, at: files.idle)
        try makePNG(width: 16, at: files.talking, frameCount: 2)
        let animated = try #require(CGImageSourceCreateWithURL(files.talking as CFURL, nil))
        try #require(CGImageSourceGetCount(animated) == 2)

        #expect(throws: (any Error).self) {
            try CharacterPack.importFolder(files.source, storageRoot: files.storage)
        }
    }

    private func makePNG(width: Int, at url: URL, frameCount: Int = 1) throws {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: 16,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let image = try #require(context.makeImage())
        let output = try #require(CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, frameCount, nil
        ))
        for _ in 0..<frameCount {
            CGImageDestinationAddImage(output, image, nil)
        }
        try #require(CGImageDestinationFinalize(output))
    }

    private struct Folders {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        var source: URL { root.appending(path: "Character") }
        var storage: URL { root.appending(path: "Storage") }
        var idle: URL { source.appending(path: "idle.png") }
        var talking: URL { source.appending(path: "talking.png") }

        init() throws {
            try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        }

        func remove() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
