import Foundation
import Observation
import PencilKit
import UIKit

@MainActor
@Observable
final class DrawingThumbnailStore {
    private let cache = NSCache<NSUUID, UIImage>()

    func thumbnail(for paint: Paint, size: CGSize) async -> UIImage? {
        let cacheKey = paint.id as NSUUID

        if let image = cache.object(forKey: cacheKey) {
            return image
        }

        let drawingData = paint.drawingData
        let image = await Task.detached(priority: .utility) { () -> UIImage? in
            guard let drawing = try? PKDrawing(data: drawingData) else {
                return nil
            }

            let drawingBounds = drawing.bounds
            guard !drawingBounds.isNull, !drawingBounds.isEmpty else {
                return nil
            }

            let scale = max(
                1,
                min(size.width / drawingBounds.width, size.height / drawingBounds.height)
            )

            return drawing.image(from: drawingBounds, scale: scale)
        }.value

        guard let image else {
            return nil
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }

    func invalidate(id: UUID) {
        cache.removeObject(forKey: id as NSUUID)
    }
}
