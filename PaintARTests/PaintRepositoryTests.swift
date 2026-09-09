import CoreData
import Foundation
import Testing
@testable import PaintAR

struct PaintRepositoryTests {
    @Test("Cria e busca um desenho")
    func createsAndFetchesPaint() async throws {
        let (repository, _) = makeRepository()
        let created = try await repository.create(name: "Primeiro", drawingData: Data([0x01]))

        let paints = try await repository.fetchAll()

        #expect(paints == [created])
    }

    @Test("Busca os desenhos em ordem decrescente de data")
    func fetchesPaintsInDescendingDateOrder() async throws {
        let (repository, _) = makeRepository()
        let older = PaintExchangeModel(
            id: UUID(),
            name: "Antigo",
            date: "2025-02-27 12:00:00 +0000",
            drawing: "AQ=="
        )
        let newer = PaintExchangeModel(
            id: UUID(),
            name: "Novo",
            date: "2025-02-28 12:00:00 +0000",
            drawing: "Ag=="
        )

        _ = try await repository.importPaint(older)
        _ = try await repository.importPaint(newer)

        let paints = try await repository.fetchAll()

        #expect(paints.map(\.id) == [newer.id, older.id])
    }

    @Test("Renomear persiste para um contexto novo")
    func renamePersistsToNewContext() async throws {
        let (repository, persistence) = makeRepository()
        let paint = try await repository.create(name: "Antes", drawingData: Data([0x01]))

        try await repository.rename(id: paint.id, to: "Depois")

        let context = persistence.newBackgroundContext()
        let savedName = try await context.perform {
            let request: NSFetchRequest<PaintEntity> = PaintEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", paint.id as CVarArg)
            return try context.fetch(request).first?.name
        }

        #expect(savedName == "Depois")
    }

    @Test("Atualizar o desenho troca os bytes e atualiza a data")
    func updateDrawingReplacesDataAndDate() async throws {
        let (repository, _) = makeRepository()
        let original = try await repository.importPaint(
            PaintExchangeModel(
                id: UUID(),
                name: "Original",
                date: "2025-02-28 12:00:00 +0000",
                drawing: "AQ=="
            )
        )
        let updatedData = Data([0x02, 0x03])

        try await repository.updateDrawing(id: original.id, drawingData: updatedData)

        let paints = try await repository.fetchAll()
        let updated = try #require(paints.first)
        #expect(updated.drawingData == updatedData)
        #expect(updated.date > original.date)
    }

    @Test("Excluir remove o desenho")
    func deleteRemovesPaint() async throws {
        let (repository, _) = makeRepository()
        let paint = try await repository.create(name: "Excluir", drawingData: Data([0x01]))

        try await repository.delete(id: paint.id)

        let paints = try await repository.fetchAll()
        #expect(paints.isEmpty)
    }

    @Test("Excluir identificador desconhecido retorna notFound")
    func deleteUnknownIDThrowsNotFound() async {
        let (repository, _) = makeRepository()

        do {
            try await repository.delete(id: UUID())
            Issue.record("Era esperado PaintError.notFound")
        } catch let error as PaintError {
            #expect(error == .notFound)
        } catch {
            Issue.record("Erro inesperado: \(error)")
        }
    }

    @Test("Importar grava e devolve o desenho")
    func importPaintStoresAndReturnsPaint() async throws {
        let (repository, _) = makeRepository()
        let model = PaintExchangeModel(
            id: UUID(),
            name: "Importado",
            date: "2025-02-28 12:00:00 +0000",
            drawing: "AQID"
        )

        let imported = try await repository.importPaint(model)
        let expected = try model.toPaint()

        #expect(imported == expected)
        let paints = try await repository.fetchAll()
        #expect(paints == [imported])
    }

    private func makeRepository() -> (CoreDataPaintRepository, PersistenceController) {
        let persistence = PersistenceController(inMemory: true)
        return (CoreDataPaintRepository(persistence: persistence), persistence)
    }
}
