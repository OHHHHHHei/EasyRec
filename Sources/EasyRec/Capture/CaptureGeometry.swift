import Foundation

struct CaptureGeometry: Equatable {
    let width: Int
    let height: Int

    /// Preserve the selected content's aspect ratio and Retina density, with an
    /// even pixel size for H.264. Cap the longest edge to bound encoder workload.
    static func fit(
        width: Double, height: Double, scale: Double
    ) throws -> Self {
        let maxEdge: Double = 3840
        guard width.isFinite, height.isFinite, scale.isFinite,
            width >= 1, height >= 1, scale > 0,
            (width * scale).isFinite, (height * scale).isFinite
        else {
            throw CaptureError.invalidSize
        }
        let pixelWidth = width * scale
        let pixelHeight = height * scale
        let factor = min(1, maxEdge / max(pixelWidth, pixelHeight))
        return Self(
            width: max(2, Int((pixelWidth * factor / 2).rounded(.down)) * 2),
            height: max(2, Int((pixelHeight * factor / 2).rounded(.down)) * 2))
    }
}
