import UIKit
import SwiftUI

/// Stores images as files inside Application Support/Images.
///
/// SwiftData models only hold the filename (section 32). Images are
/// compressed for normal UI display.
final class ImageStore {
    static let shared = ImageStore()

    private let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
            try? FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        } else {
            let dir = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Images", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.baseDirectory = dir
        }
    }

    private func url(for name: String) -> URL {
        baseDirectory.appendingPathComponent(name)
    }

    /// Saves a JPEG and returns the stored filename.
    @discardableResult
    func save(_ image: UIImage, quality: CGFloat = 0.85) -> String {
        let name = UUID().uuidString + ".jpg"
        guard let data = image.jpegData(compressionQuality: quality) else {
            return ""
        }
        try? data.write(to: url(for: name))
        return name
    }

    func load(_ name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        return UIImage(contentsOfFile: url(for: name).path)
    }

    func delete(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(for: name))
    }

    /// Replaces the old image with a new one.
    func replace(oldName: String?, with image: UIImage) -> String {
        let newName = save(image)
        delete(oldName)
        return newName
    }

    /// Copies a stored image to a new file.
    ///
    /// Used when a material is deleted so that historical projects keep
    /// their own copy of the reference (section 38).
    func copy(_ name: String?) -> String? {
        guard let name, !name.isEmpty,
              FileManager.default.fileExists(atPath: url(for: name).path) else {
            return nil
        }
        let newName = UUID().uuidString + ".jpg"
        do {
            try FileManager.default.copyItem(at: url(for: name), to: url(for: newName))
            return newName
        } catch {
            return nil
        }
    }

    /// Average color of a stored image, used for flat-color previews when
    /// a material has no photo yet.
    func averageColor(_ name: String?) -> UIColor? {
        guard let name,
              let image = UIImage(contentsOfFile: url(for: name).path),
              let cgImage = image.cgImage else {
            return nil
        }

        let size = 16
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let data = context.data else { return nil }

        let pixels = data.assumingMemoryBound(to: UInt8.self)
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        let count = size * size
        for i in 0..<count {
            r += Double(pixels[i * 4])
            g += Double(pixels[i * 4 + 1])
            b += Double(pixels[i * 4 + 2])
        }

        return UIColor(
            red: r / Double(count) / 255,
            green: g / Double(count) / 255,
            blue: b / Double(count) / 255,
            alpha: 1
        )
    }
}
