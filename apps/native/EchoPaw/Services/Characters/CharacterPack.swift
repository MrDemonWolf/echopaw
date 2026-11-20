import AppKit
import Darwin
import ImageIO
import UniformTypeIdentifiers

@MainActor
struct CharacterPack {
    let idle: NSImage
    let talking: NSImage
    let blinking: NSImage?
    let talkingBlinking: NSImage?
    let name: String

    private static let maximumPNGBytes = 16 * 1024 * 1024
    private static let maximumStoredBytes = 4 * maximumPNGBytes + 16 * 1024
    private static let maximumDimension = 2_048
    private static let fileFlags = O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC

    static func sample() throws -> Self {
        func sampleData(_ name: String) throws -> Data? {
            let bundle = Bundle.main
            let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "SampleCharacter")
                ?? bundle.url(forResource: name, withExtension: "png")
            guard let url else { return nil }
            return try Data(contentsOf: url)
        }

        guard let idle = try sampleData("idle"), let talking = try sampleData("talking") else {
            throw PackError.sampleUnavailable
        }
        return try Self(StoredPack(
            name: "Blue wolf",
            idle: idle,
            talking: talking,
            blinking: sampleData("blinking"),
            talkingBlinking: sampleData("talking-blinking")
        ))
    }

    static func saved(storageRoot: URL? = nil) throws -> Self? {
        let url = try storageFile(in: storageRoot)
        let file = open(url.path, fileFlags)
        if file < 0, errno == ENOENT { return nil }
        guard file >= 0 else { throw PackError.savedUnavailable }
        defer { close(file) }

        do {
            let data = try read(file, maximumBytes: maximumStoredBytes, name: url.lastPathComponent)
            let stored = try PropertyListDecoder().decode(StoredPack.self, from: data)
            return try Self(stored)
        } catch {
            throw PackError.savedUnavailable
        }
    }

    static func importFolder(_ folder: URL, storageRoot: URL? = nil) throws -> Self {
        let hasScope = folder.startAccessingSecurityScopedResource()
        defer {
            if hasScope { folder.stopAccessingSecurityScopedResource() }
        }

        // Open required paths relative to one verified folder so source symlinks cannot escape it.
        let directory = open(folder.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard directory >= 0 else { throw PackError.folderUnavailable }
        defer { close(directory) }

        func source(_ name: String) throws -> Data? {
            let file = openat(directory, name, fileFlags)
            if file < 0, errno == ENOENT { return nil }
            guard file >= 0 else { throw PackError.sourceUnavailable(name) }
            defer { close(file) }
            return try read(file, maximumBytes: maximumPNGBytes, name: name)
        }

        guard let idle = try source("idle.png") else { throw PackError.sourceUnavailable("idle.png") }
        guard let talking = try source("talking.png") else { throw PackError.sourceUnavailable("talking.png") }
        let stored = try StoredPack(
            name: folder.lastPathComponent,
            idle: idle,
            talking: talking,
            blinking: source("blinking.png"),
            talkingBlinking: source("talking-blinking.png")
        )
        let pack = try Self(stored)
        let url = try storageFile(in: storageRoot)

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Both original PNGs are committed together, so a partial import cannot replace a pack.
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            try encoder.encode(stored).write(to: url, options: .atomic)
        } catch {
            throw PackError.saveFailed
        }

        return pack
    }

    func image(isTalking: Bool, isBlinking: Bool) -> NSImage {
        if isTalking { return isBlinking ? talkingBlinking ?? talking : talking }
        return isBlinking ? blinking ?? idle : idle
    }

    private init(_ stored: StoredPack) throws {
        let idle = try Self.decodePNG(stored.idle, name: "idle.png")
        let talking = try Self.decodePNG(stored.talking, name: "talking.png")
        guard idle.width == talking.width, idle.height == talking.height else {
            throw PackError.canvasMismatch("talking.png")
        }

        let size = NSSize(width: idle.width, height: idle.height)
        func blinkImage(_ data: Data?, named name: String) throws -> NSImage? {
            guard let data else { return nil }
            let image = try Self.decodePNG(data, name: name)
            guard image.width == idle.width, image.height == idle.height else {
                throw PackError.canvasMismatch(name)
            }
            return NSImage(cgImage: image, size: size)
        }
        self.idle = NSImage(cgImage: idle, size: size)
        self.talking = NSImage(cgImage: talking, size: size)
        self.blinking = try blinkImage(stored.blinking, named: "blinking.png")
        self.talkingBlinking = try blinkImage(stored.talkingBlinking, named: "talking-blinking.png")
        let cleaned = stored.name
            .components(separatedBy: .controlCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = cleaned.isEmpty ? "Imported character" : String(cleaned.prefix(80))
    }

    private static func decodePNG(_ data: Data, name: String) throws -> CGImage {
        guard data.count <= maximumPNGBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetType(source) as String? == UTType.png.identifier,
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0
        else { throw PackError.invalidPNG(name) }

        guard width <= maximumDimension, height <= maximumDimension else {
            throw PackError.canvasTooLarge(name)
        }

        let container = CGImageSourceCopyProperties(source, nil) as? [CFString: Any]
        let png = container?[kCGImagePropertyPNGDictionary] as? [CFString: Any]
        let frame = properties[kCGImagePropertyPNGDictionary] as? [CFString: Any]
        guard png?[kCGImagePropertyAPNGLoopCount] == nil,
              png?[kCGImagePropertyAPNGFrameInfoArray] == nil,
              frame?[kCGImagePropertyAPNGDelayTime] == nil,
              let image = CGImageSourceCreateImageAtIndex(
                source,
                0,
                [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
              ),
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete,
              image.width == width, image.height == height
        else { throw PackError.invalidPNG(name) }

        return image
    }

    private static func read(_ file: Int32, maximumBytes: Int, name: String) throws -> Data {
        var info = stat()
        guard fstat(file, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_size > 0 else {
            throw PackError.sourceUnavailable(name)
        }
        guard info.st_size <= maximumBytes else { throw PackError.fileTooLarge(name) }
        let handle = FileHandle(fileDescriptor: file, closeOnDealloc: false)
        guard let data = try? handle.read(upToCount: Int(info.st_size) + 1),
              data.count == info.st_size
        else { throw PackError.sourceUnavailable(name) }
        return data
    }

    private static func storageFile(in root: URL?) throws -> URL {
        if let root { return root.appending(path: "character.plist") }
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { throw PackError.savedUnavailable }

        let identifier = Bundle.main.bundleIdentifier ?? "com.mrdemonwolf.echopaw.dev"
        return support
            .appending(path: identifier, directoryHint: .isDirectory)
            .appending(path: "Characters", directoryHint: .isDirectory)
            .appending(path: "character.plist")
    }

    private struct StoredPack: Codable {
        let name: String
        let idle: Data
        let talking: Data
        let blinking: Data?
        let talkingBlinking: Data?
    }
}

private enum PackError: LocalizedError {
    case sampleUnavailable
    case savedUnavailable
    case folderUnavailable
    case sourceUnavailable(String)
    case fileTooLarge(String)
    case invalidPNG(String)
    case canvasTooLarge(String)
    case canvasMismatch(String)
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .sampleUnavailable:
            "The sample character is missing from this build."
        case .savedUnavailable:
            "The saved character could not be opened. Choose a folder to replace it."
        case .folderUnavailable:
            "Choose a regular folder containing idle.png and talking.png."
        case let .sourceUnavailable(name):
            "Add a readable \(name) file to the folder. Aliases and symbolic links cannot be imported."
        case let .fileTooLarge(name):
            "\(name) must be 16 MiB or smaller."
        case let .invalidPNG(name):
            "\(name) could not be opened as a static PNG."
        case let .canvasTooLarge(name):
            "\(name) must be 2048 × 2048 pixels or smaller."
        case let .canvasMismatch(name):
            "Export \(name) with the same canvas size as idle.png."
        case .saveFailed:
            "The character could not be saved. Free some space or check folder permissions and try again."
        }
    }
}
