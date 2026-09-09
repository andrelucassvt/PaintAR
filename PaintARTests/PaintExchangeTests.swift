import Foundation
import Testing
@testable import PaintAR

struct PaintExchangeTests {
    @Test("Round-trip preserva todos os dados do desenho")
    func preservesPaintInRoundTrip() throws {
        let original = Paint(
            id: UUID(),
            name: "Paisagem",
            date: Date(timeIntervalSince1970: 1_740_744_000),
            drawingData: Data([0x00, 0x01, 0xFE, 0xFF])
        )

        let restored = try PaintExchangeModel(paint: original).toPaint()

        #expect(restored == original)
    }

    @Test("Decodifica o formato JSON exportado pela versão anterior")
    func decodesLegacyExchangeJSON() throws {
        let data = Data(
            #"""
            {
              "id": "A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D",
              "name": "Desenho importado",
              "date": "2025-02-28 12:00:00 +0000",
              "drawing": "AQID"
            }
            """#.utf8
        )

        let model = try JSONDecoder().decode(PaintExchangeModel.self, from: data)
        let paint = try model.toPaint()

        #expect(paint.id.uuidString == "A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D")
        #expect(paint.name == "Desenho importado")
        #expect(
            PaintExchangeModel.dateFormatter.string(from: paint.date)
                == "2025-02-28 12:00:00 +0000"
        )
        #expect(paint.drawingData == Data([0x01, 0x02, 0x03]))
    }

    @Test("Rejeita data inválida")
    func rejectsInvalidDate() {
        let model = PaintExchangeModel(
            id: UUID(),
            name: "Data inválida",
            date: "28/02/2025",
            drawing: "AQID"
        )

        do {
            _ = try model.toPaint()
            Issue.record("Era esperado PaintError.invalidDate")
        } catch let error as PaintError {
            #expect(error == .invalidDate)
        } catch {
            Issue.record("Erro inesperado: \(error)")
        }
    }

    @Test("Rejeita Base64 inválido")
    func rejectsInvalidDrawingData() {
        let model = PaintExchangeModel(
            id: UUID(),
            name: "Dados inválidos",
            date: "2025-02-28 12:00:00 +0000",
            drawing: "%%%"
        )

        do {
            _ = try model.toPaint()
            Issue.record("Era esperado PaintError.invalidDrawingData")
        } catch let error as PaintError {
            #expect(error == .invalidDrawingData)
        } catch {
            Issue.record("Erro inesperado: \(error)")
        }
    }
}
