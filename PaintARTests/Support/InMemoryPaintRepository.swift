import Foundation
@testable import PaintAR

actor InMemoryPaintRepository: PaintRepository {
    private var paints: [Paint]
    var failNextCall: Error?
    private(set) var deleteCallCount = 0
    private(set) var renameCallCount = 0

    init(paints: [Paint] = []) {
        self.paints = paints
    }

    func setFailNextCall(_ error: Error?) {
        failNextCall = error
    }

    func fetchAll() throws -> [Paint] {
        try consumeFailure()
        return paints.sorted { $0.date > $1.date }
    }

    func create(name: String, drawingData: Data) throws -> Paint {
        try consumeFailure()
        let paint = Paint(id: UUID(), name: name, date: Date(), drawingData: drawingData)
        paints.append(paint)
        return paint
    }

    func updateDrawing(id: UUID, drawingData: Data) throws {
        try consumeFailure()
        guard let index = paints.firstIndex(where: { $0.id == id }) else {
            throw PaintError.notFound
        }

        let paint = paints[index]
        paints[index] = Paint(
            id: paint.id,
            name: paint.name,
            date: Date(),
            drawingData: drawingData
        )
    }

    func rename(id: UUID, to name: String) throws {
        try consumeFailure()
        guard let index = paints.firstIndex(where: { $0.id == id }) else {
            throw PaintError.notFound
        }

        renameCallCount += 1
        let paint = paints[index]
        paints[index] = Paint(
            id: paint.id,
            name: name,
            date: Date(),
            drawingData: paint.drawingData
        )
    }

    func delete(id: UUID) throws {
        try consumeFailure()
        guard let index = paints.firstIndex(where: { $0.id == id }) else {
            throw PaintError.notFound
        }

        deleteCallCount += 1
        paints.remove(at: index)
    }

    func importPaint(_ model: PaintExchangeModel) throws -> Paint {
        try consumeFailure()
        let paint = try model.toPaint()
        paints.append(paint)
        return paint
    }

    private func consumeFailure() throws {
        if let failNextCall {
            self.failNextCall = nil
            throw failNextCall
        }
    }
}
