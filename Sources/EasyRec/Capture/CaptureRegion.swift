import CoreGraphics
import Foundation

/// Screen-local points with a top-left origin, as used by SCStream.sourceRect.
struct CaptureRegion {
    static func rectangle(from start: CGPoint, to end: CGPoint, in bounds: CGRect) -> CGRect {
        CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y)
        ).intersection(bounds)
    }
}
