import CoreData

class CoreDataController {
    static let shared = CoreDataController() // Singleton para acesso global

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Paints")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }

    func fetchAllPaints() -> [PaintEntity] {
        let fetchRequest: NSFetchRequest<PaintEntity> = PaintEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch paints: \(error.localizedDescription)")
            return [];
        }
    }

    func savePaint(name: String, date: Date, drawing: Data) {
        let paint = PaintEntity(context: context)
        paint.id = UUID()
        paint.name = name
        paint.date = date
        paint.drawing = drawing
        saveContext()
    }

    func updatePaint(paint: PaintEntity, id: UUID , name: String, date: Date, drawing: Data) {
        paint.id = id
        paint.name = name
        paint.date = date
        paint.drawing = drawing
        saveContext()
    }

    func deletePaint(paint: PaintEntity) {
        context.delete(paint)
        saveContext()
    }
}
