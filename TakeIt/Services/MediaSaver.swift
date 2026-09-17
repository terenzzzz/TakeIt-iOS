import Foundation

enum MediaSaver {
    static func save(
        _ data: Data,
        item: MediaItem,
        filename requestedName: String? = nil,
        contentType: String? = nil
    ) throws -> URL {
        guard !data.isEmpty else { throw MediaSaveError.emptyFile }

        let name = requestedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = (name?.isEmpty == false ? name! : item.displayName)
        let format = MediaFormat.detect(
            data: data,
            filename: baseName,
            contentType: contentType,
            fallback: item.type
        )
        let filename = sanitizedFilename(baseName, fileExtension: format.fileExtension)
        let fileURL = uniqueURL(in: try cacheDirectory(), filename: filename)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func cacheDirectory() throws -> URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TakeItDownloads", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func uniqueURL(in directory: URL, filename: String) -> URL {
        var url = directory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: url.path) {
            let stem = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            url = directory.appendingPathComponent("\(stem)-\(UUID().uuidString.prefix(8)).\(ext)")
        }
        return url
    }

    private static func sanitizedFilename(_ name: String, fileExtension: String) -> String {
        var cleaned = name.replacingOccurrences(of: "/", with: "-")
        cleaned = cleaned.replacingOccurrences(of: ":", with: "-")
        if cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cleaned = "download"
        }
        let url = URL(fileURLWithPath: cleaned)
        let ext = fileExtension.lowercased()
        if url.pathExtension.lowercased() == ext {
            return url.lastPathComponent
        }
        return url.deletingPathExtension().lastPathComponent + "." + ext
    }
}

struct MediaFormat: Equatable {
    let type: MediaType
    let fileExtension: String

    static func detect(data: Data, filename: String, contentType: String?, fallback: MediaType) -> MediaFormat {
        if let sniffed = sniff(data) {
            return sniffed
        }
        if let fromType = from(contentType: contentType) {
            return fromType
        }
        if let fromName = from(filename: filename) {
            return fromName
        }
        return MediaFormat(
            type: fallback,
            fileExtension: fallback == .video ? "mp4" : fallback == .audio ? "m4a" : "jpg"
        )
    }

    static func sniff(_ data: Data) -> MediaFormat? {
        guard data.count >= 12 else { return nil }
        let bytes = [UInt8](data.prefix(12))

        if bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
            return MediaFormat(type: .image, fileExtension: "jpg")
        }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return MediaFormat(type: .image, fileExtension: "png")
        }
        if bytes.starts(with: [0x47, 0x49, 0x46]) {
            return MediaFormat(type: .image, fileExtension: "gif")
        }
        if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]), data.count >= 12 {
            let tag = data.subdata(in: 8..<12)
            if tag == Data("WEBP".utf8) {
                return MediaFormat(type: .image, fileExtension: "webp")
            }
        }
        if data.count >= 12, data.subdata(in: 4..<8) == Data("ftyp".utf8) {
            let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii)?.lowercased() ?? ""
            let heicBrands: Set<String> = ["heic", "heix", "hevc", "hevx", "mif1", "msf1"]
            if heicBrands.contains(brand) {
                return MediaFormat(type: .image, fileExtension: "heic")
            }
            return MediaFormat(type: .video, fileExtension: "mp4")
        }
        if bytes.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) {
            return MediaFormat(type: .video, fileExtension: "webm")
        }
        return nil
    }

    static func from(contentType: String?) -> MediaFormat? {
        guard let raw = contentType?.split(separator: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty
        else { return nil }

        switch raw {
        case "image/jpeg", "image/jpg":
            return MediaFormat(type: .image, fileExtension: "jpg")
        case "image/png":
            return MediaFormat(type: .image, fileExtension: "png")
        case "image/gif":
            return MediaFormat(type: .image, fileExtension: "gif")
        case "image/heic", "image/heif":
            return MediaFormat(type: .image, fileExtension: "heic")
        case "image/webp":
            return MediaFormat(type: .image, fileExtension: "webp")
        case "video/mp4", "video/x-m4v":
            return MediaFormat(type: .video, fileExtension: "mp4")
        case "video/quicktime":
            return MediaFormat(type: .video, fileExtension: "mov")
        case "video/webm":
            return MediaFormat(type: .video, fileExtension: "webm")
        case "audio/mpeg":
            return MediaFormat(type: .audio, fileExtension: "mp3")
        case "audio/mp4", "audio/aac":
            return MediaFormat(type: .audio, fileExtension: "m4a")
        default:
            return nil
        }
    }

    static func from(filename: String) -> MediaFormat? {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return MediaFormat(type: .image, fileExtension: "jpg")
        case "png", "gif", "heic", "webp":
            return MediaFormat(type: .image, fileExtension: ext)
        case "mp4", "mov", "m4v", "webm":
            return MediaFormat(type: .video, fileExtension: ext)
        case "mp3", "m4a", "aac", "wav":
            return MediaFormat(type: .audio, fileExtension: ext)
        default:
            return nil
        }
    }
}
