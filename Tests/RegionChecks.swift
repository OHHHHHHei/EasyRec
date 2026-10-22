import Foundation
import CoreGraphics

@main
struct RegionChecks {
    static func main() {
        let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let forward = CaptureRegion.rectangle(from: CGPoint(x: 40, y: 80),
            to: CGPoint(x: 400, y: 300), in: bounds)
        let reverse = CaptureRegion.rectangle(from: CGPoint(x: 400, y: 300),
            to: CGPoint(x: 40, y: 80), in: bounds)
        precondition(forward == reverse && forward == CGRect(x: 40, y: 80, width: 360, height: 220))
        let clipped = CaptureRegion.rectangle(from: CGPoint(x: -10, y: 850),
            to: CGPoint(x: 1600, y: 1000), in: bounds)
        precondition(clipped == CGRect(x: 0, y: 850, width: 1440, height: 50))
        print("PASS: Region drag direction and screen-local boundary clipping")
    }
}
