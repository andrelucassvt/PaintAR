import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    private let persistentContainer: NSPersistentContainer
    private(set) var loadError: Error?

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "Paints")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Paints-\(UUID().uuidString)")
            container.persistentStoreDescriptions = [description]
        }

        persistentContainer = container

        container.loadPersistentStores { [weak self] _, error in
            guard let error else {
                return
            }

            self?.loadError = error
            print("Falha ao carregar a store persistente: \(error.localizedDescription)")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
