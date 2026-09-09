import CoreData
import Foundation

struct Paint: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let date: Date
    let drawingData: Data

    init(id: UUID, name: String, date: Date, drawingData: Data) {
        self.id = id
        self.name = name
        self.date = date
        self.drawingData = drawingData
    }

    init?(entity: PaintEntity) {
        guard
            let id = entity.id,
            let name = entity.name,
            let date = entity.date,
            let drawing = entity.drawing
        else {
            return nil
        }

        self.init(id: id, name: name, date: date, drawingData: drawing)
    }
}

extension PaintEntity {
    convenience init(context: NSManagedObjectContext, name: String, date: Date, drawing: Data) {
        self.init(context: context)
        id = UUID()
        self.name = name
        self.date = date
        self.drawing = drawing
    }
}
