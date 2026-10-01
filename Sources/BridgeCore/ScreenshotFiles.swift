import Foundation
import Darwin

public enum ScreenshotFiles {
    /// Screenshot writes this attribute itself; this works with localized filenames
    /// and does not depend on Spotlight finishing indexing the file.
    public static func isScreenshot(_ url: URL) -> Bool {
        let attribute = "com.apple.metadata:kMDItemIsScreenCapture"
        let count = getxattr(url.path, attribute, nil, 0, 0, 0)
        guard count > 0, count < 4096 else { return false }
        var data = Data(count: count)
        let actual = data.withUnsafeMutableBytes { bytes in
            getxattr(url.path, attribute, bytes.baseAddress, count, 0, 0)
        }
        guard actual == count,
              let value = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else { return false }
        if let boolean = value as? NSNumber { return boolean.boolValue }
        if let text = value as? String { return ["1", "true", "yes"].contains(text.lowercased()) }
        return false
    }
}
