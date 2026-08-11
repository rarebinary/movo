import Foundation

public struct ManagedLibraryManifest: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var items: [WallpaperItem]

    public init(version: Int = currentVersion, items: [WallpaperItem] = []) {
        self.version = version
        self.items = items
    }
}

public struct ManagedLibraryLocation: Equatable, Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL.standardizedFileURL
    }

    public var mediaDirectoryURL: URL {
        rootURL.appending(path: "Media", directoryHint: .isDirectory)
    }

    public var manifestURL: URL {
        rootURL.appending(path: "manifest.json", directoryHint: .notDirectory)
    }

    public func mediaURL(for item: WallpaperItem) -> URL {
        mediaDirectoryURL.appending(path: item.managedFilename, directoryHint: .notDirectory)
    }

    public func managedFilename(
        title: String,
        id: UUID,
        fileExtension: String
    ) -> String {
        let slug = Self.slug(for: title)
        let identifier = id.uuidString.prefix(8).lowercased()
        let normalizedExtension = fileExtension.lowercased()
        return "\(slug)-\(identifier).\(normalizedExtension)"
    }

    public func destinationURL(
        title: String,
        id: UUID,
        fileExtension: String
    ) -> URL {
        mediaDirectoryURL.appending(
            path: managedFilename(title: title, id: id, fileExtension: fileExtension),
            directoryHint: .notDirectory
        )
    }

    private static func slug(for title: String) -> String {
        let folded = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let components = folded.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        let slug = components.filter { !$0.isEmpty }.joined(separator: "-")
        return slug.isEmpty ? "wallpaper" : String(slug.prefix(64))
    }
}

public actor ManagedLibraryStore {
    public enum StoreError: Error, Equatable, Sendable {
        case unsupportedManifestVersion(Int)
    }

    public let location: ManagedLibraryLocation

    public init(libraryURL: URL) {
        location = ManagedLibraryLocation(rootURL: libraryURL)
    }

    public func load() throws -> ManagedLibraryManifest {
        guard FileManager.default.fileExists(atPath: location.manifestURL.path) else {
            return ManagedLibraryManifest()
        }

        let data = try Data(contentsOf: location.manifestURL)
        let manifest = try Self.decoder.decode(ManagedLibraryManifest.self, from: data)
        guard manifest.version == ManagedLibraryManifest.currentVersion else {
            throw StoreError.unsupportedManifestVersion(manifest.version)
        }
        return manifest
    }

    public func save(_ manifest: ManagedLibraryManifest) throws {
        guard manifest.version == ManagedLibraryManifest.currentVersion else {
            throw StoreError.unsupportedManifestVersion(manifest.version)
        }
        try FileManager.default.createDirectory(
            at: location.mediaDirectoryURL,
            withIntermediateDirectories: true
        )
        let data = try Self.encoder.encode(manifest)
        try data.write(to: location.manifestURL, options: [.atomic])
    }

    public func upsert(_ item: WallpaperItem) throws -> ManagedLibraryManifest {
        var manifest = try load()
        if let index = manifest.items.firstIndex(where: { $0.id == item.id }) {
            manifest.items[index] = item
        } else {
            manifest.items.append(item)
        }
        try save(manifest)
        return manifest
    }

    @discardableResult
    public func remove(id: UUID) throws -> WallpaperItem? {
        var manifest = try load()
        guard let index = manifest.items.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        let item = manifest.items.remove(at: index)
        try save(manifest)
        return item
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
