import CoreData
import Foundation

final class CoreDataPaintRepository: PaintRepository, @unchecked Sendable {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll() async throws -> [Paint] {
        let context = persistence.newBackgroundContext()

        return try await context.perform {
            let request: NSFetchRequest<PaintEntity> = PaintEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PaintEntity.date, ascending: false)]

            return try context.fetch(request).compactMap(Paint.init(entity:))
        }
    }

    func create(name: String, drawingData: Data) async throws -> Paint {
        let context = persistence.newBackgroundContext()

        return try await context.perform {
            let entity = PaintEntity(
                context: context,
                name: name,
                date: Date(),
                drawing: drawingData
            )
            try self.save(context)

            guard let paint = Paint(entity: entity) else {
                throw PaintError.persistenceFailed("Não foi possível criar o desenho.")
            }

            return paint
        }
    }

    func updateDrawing(id: UUID, drawingData: Data) async throws {
        let context = persistence.newBackgroundContext()

        try await context.perform {
            let entity = try self.fetchEntity(id: id, in: context)
            entity.drawing = drawingData
            entity.date = Date()
            try self.save(context)
        }
    }

    func rename(id: UUID, to name: String) async throws {
        let context = persistence.newBackgroundContext()

        try await context.perform {
            let entity = try self.fetchEntity(id: id, in: context)
            entity.name = name
            entity.date = Date()
            try self.save(context)
        }
    }

    func delete(id: UUID) async throws {
        let context = persistence.newBackgroundContext()

        try await context.perform {
            let entity = try self.fetchEntity(id: id, in: context)
            context.delete(entity)
            try self.save(context)
        }
    }

    func importPaint(_ model: PaintExchangeModel) async throws -> Paint {
        let paint = try model.toPaint()
        let context = persistence.newBackgroundContext()

        return try await context.perform {
            let entity = PaintEntity(context: context)
            entity.id = paint.id
            entity.name = paint.name
            entity.date = paint.date
            entity.drawing = paint.drawingData
            try self.save(context)

            guard let importedPaint = Paint(entity: entity) else {
                throw PaintError.persistenceFailed("Não foi possível importar o desenho.")
            }

            return importedPaint
        }
    }

    private func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> PaintEntity {
        let request: NSFetchRequest<PaintEntity> = PaintEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let entity = try context.fetch(request).first else {
            throw PaintError.notFound
        }

        return entity
    }

    private func save(_ context: NSManagedObjectContext) throws {
        do {
            try context.save()
        } catch {
            throw PaintError.persistenceFailed(error.localizedDescription)
        }
    }
}
