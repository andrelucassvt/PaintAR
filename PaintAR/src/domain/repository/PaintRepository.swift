import Foundation

protocol PaintRepository: Sendable {
    func fetchAll() async throws -> [Paint]
    func create(name: String, drawingData: Data) async throws -> Paint
    func updateDrawing(id: UUID, drawingData: Data) async throws
    func rename(id: UUID, to name: String) async throws
    func delete(id: UUID) async throws
    func importPaint(_ model: PaintExchangeModel) async throws -> Paint
}
