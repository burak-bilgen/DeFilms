import XCTest
import CoreGraphics
import ImageIO

extension XCTestCase {
    func assertSnapshot(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let observed = SnapshotFingerprint.make(from: screenshot.pngRepresentation)
        if SnapshotMode.isRecording {
            XCTFail(
                SnapshotRecorder.recordingMessage(for: name, fingerprint: observed),
                file: file,
                line: line
            )
            return
        }

        guard let baseline = SnapshotBaselines.values[name] else {
            XCTFail(
                SnapshotRecorder.missingBaselineMessage(for: name, fingerprint: observed),
                file: file,
                line: line
            )
            return
        }

        XCTAssertEqual(observed.width, baseline.width, "Snapshot width changed for \(name)", file: file, line: line)
        XCTAssertEqual(observed.height, baseline.height, "Snapshot height changed for \(name)", file: file, line: line)
        XCTAssertEqual(observed.hash, baseline.hash, "Snapshot hash changed for \(name)", file: file, line: line)
    }
}

struct SnapshotFingerprint: Equatable {
    let width: Int
    let height: Int
    let hash: String

    static func make(from pngData: Data) -> SnapshotFingerprint {
        guard
            let source = CGImageSourceCreateWithData(pngData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return SnapshotFingerprint(width: 0, height: 0, hash: "invalid")
        }

        let width = image.width
        let height = image.height
        let thumbDimension = 8
        let bytesPerPixel = 4
        let bytesPerRow = thumbDimension * bytesPerPixel
        var raw = [UInt8](repeating: 0, count: thumbDimension * thumbDimension * bytesPerPixel)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &raw,
                width: thumbDimension,
                height: thumbDimension,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return SnapshotFingerprint(width: width, height: height, hash: "context-failed")
        }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: thumbDimension, height: thumbDimension))

        var lumaValues: [UInt8] = []
        lumaValues.reserveCapacity(thumbDimension * thumbDimension)

        for index in stride(from: 0, to: raw.count, by: bytesPerPixel) {
            let red = Double(raw[index])
            let green = Double(raw[index + 1])
            let blue = Double(raw[index + 2])
            let luma = UInt8((0.299 * red) + (0.587 * green) + (0.114 * blue))
            lumaValues.append(luma)
        }

        let average = UInt8(lumaValues.reduce(0) { $0 + Int($1) } / max(lumaValues.count, 1))
        let bits = lumaValues.map { $0 >= average ? "1" : "0" }.joined()
        let hash = stride(from: 0, to: bits.count, by: 4).map { offset in
            let start = bits.index(bits.startIndex, offsetBy: offset)
            let end = bits.index(start, offsetBy: 4, limitedBy: bits.endIndex) ?? bits.endIndex
            let chunk = bits[start..<end]
            let value = Int(chunk, radix: 2) ?? 0
            return String(value, radix: 16)
        }.joined()

        return SnapshotFingerprint(width: width, height: height, hash: hash)
    }
}

enum SnapshotMode {
    static var isRecording: Bool {
        ProcessInfo.processInfo.environment["UITest.RecordSnapshots"] == "1"
    }
}

enum SnapshotRecorder {
    static func missingBaselineMessage(for name: String, fingerprint: SnapshotFingerprint) -> String {
        """
        Missing snapshot baseline for \(name).

        No image file needs to be stored in the repo for this flow.
        Review the attached screenshot in the Xcode test report, then add this entry to SnapshotBaselines.values:

        "\(name)": .init(width: \(fingerprint.width), height: \(fingerprint.height), hash: "\(fingerprint.hash)")
        """
    }

    static func recordingMessage(for name: String, fingerprint: SnapshotFingerprint) -> String {
        """
        Snapshot record mode is enabled for \(name).

        Review the attached screenshot in the Xcode test report.
        If the image is approved, paste this into SnapshotBaselines.values:

        "\(name)": .init(width: \(fingerprint.width), height: \(fingerprint.height), hash: "\(fingerprint.hash)")

        Then disable UITest.RecordSnapshots and run the snapshot test again.
        """
    }
}
