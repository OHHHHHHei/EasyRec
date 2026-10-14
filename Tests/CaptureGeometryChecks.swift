import Foundation

/// A standalone test runner works with Apple's Command Line Tools, including
/// installations without the XCTest framework shipped in full Xcode.
@main
struct CaptureGeometryChecks {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError(message) }
    }

    static func main() throws {
        let retina = try CaptureGeometry.fit(width: 1280, height: 800, scale: 2)
        expect(
            retina == CaptureGeometry(width: 2560, height: 1600), "Retina pixel conversion failed")
        print("PASS: Retina pixels preserved")

        let sixK = try CaptureGeometry.fit(width: 3008, height: 1692, scale: 2)
        expect(sixK == CaptureGeometry(width: 3840, height: 2160), "6K aspect fit failed")
        print("PASS: 6K display fits 3840 × 2160")

        let portrait = try CaptureGeometry.fit(width: 1001, height: 2001, scale: 2)
        expect(portrait.height == 3840, "Portrait longest edge exceeded")
        expect(portrait.width % 2 == 0 && portrait.height % 2 == 0, "Odd encoder dimensions")
        expect(
            abs(Double(portrait.width) / Double(portrait.height) - 1001.0 / 2001) < 0.001,
            "Aspect ratio changed")
        print("PASS: Portrait odd dimensions stay even and proportional")

        for (w, h, s) in [
            (0.0, 800.0, 2.0), (100.0, Double.nan, 1.0),
            (100.0, 100.0, -1.0), (Double.greatestFiniteMagnitude, 1.0, 2.0),
        ] {
            do {
                _ = try CaptureGeometry.fit(width: w, height: h, scale: s)
                fatalError("Invalid geometry was accepted")
            } catch CaptureError.invalidSize { /* Expected. */  }
        }
        print("PASS: Invalid and overflowing sizes rejected")
    }
}
