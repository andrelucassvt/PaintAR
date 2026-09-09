import CoreData
import Testing
@testable import PaintAR

struct PaintMappingTests {
    @Test("Mapeia uma entidade completa para o domínio")
    func mapsCompleteEntity() {
        let persistence = PersistenceController(inMemory: true)
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_740_744_000)
        let drawingData = Data([0x01, 0x02, 0x03])
        let entity = PaintEntity(context: persistence.viewContext)
        entity.id = id
        entity.name = "Casa"
        entity.date = date
        entity.drawing = drawingData

        #expect(
            Paint(entity: entity) == Paint(
                id: id,
                name: "Casa",
                date: date,
                drawingData: drawingData
            )
        )
    }

    @Test("Descarta entidade sem dados do desenho")
    func ignoresEntityWithoutDrawing() {
        let persistence = PersistenceController(inMemory: true)
        let entity = PaintEntity(context: persistence.viewContext)
        entity.id = UUID()
        entity.name = "Incompleto"
        entity.date = Date()

        #expect(Paint(entity: entity) == nil)
    }

    @Test("Descarta entidade sem nome")
    func ignoresEntityWithoutName() {
        let persistence = PersistenceController(inMemory: true)
        let entity = PaintEntity(context: persistence.viewContext)
        entity.id = UUID()
        entity.date = Date()
        entity.drawing = Data([0x01])

        #expect(Paint(entity: entity) == nil)
    }
}
