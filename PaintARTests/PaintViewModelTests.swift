import Foundation
import Testing
@testable import PaintAR

@MainActor
struct PaintViewModelTests {
    @Test("Salva desenho novo com nome aparado")
    func savesNewPaintWithTrimmedName() async throws {
        let repository = InMemoryPaintRepository()
        let viewModel = PaintViewModel(mode: .new, repository: repository)
        viewModel.markDirty()

        let savedPaint = await viewModel.save(
            drawingData: Data([0x01]),
            name: "  Casa  "
        )

        let paint = try #require(savedPaint)
        #expect(paint.name == "Casa")
        #expect(paint.drawingData == Data([0x01]))
        #expect(await repository.createCallCount == 1)
        #expect(await repository.updateDrawingCallCount == 0)
        #expect(!viewModel.hasUnsavedChanges)
    }

    @Test("Rejeita nome vazio sem criar desenho")
    func rejectsBlankNameWithoutCreatingPaint() async {
        let repository = InMemoryPaintRepository()
        let viewModel = PaintViewModel(mode: .new, repository: repository)

        let savedPaint = await viewModel.save(
            drawingData: Data([0x01]),
            name: "   "
        )

        #expect(savedPaint == nil)
        #expect(await repository.createCallCount == 0)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Atualiza desenho existente sem criar outro")
    func updatesExistingPaintWithoutCreatingAnother() async throws {
        let existingPaint = makePaint(name: "Original", drawingData: Data([0x01]))
        let repository = InMemoryPaintRepository(paints: [existingPaint])
        let viewModel = PaintViewModel(mode: .editing(existingPaint), repository: repository)

        let savedPaint = await viewModel.save(
            drawingData: Data([0x02]),
            name: "Ignorado"
        )

        let paint = try #require(savedPaint)
        #expect(paint.id == existingPaint.id)
        #expect(paint.name == existingPaint.name)
        #expect(paint.drawingData == Data([0x02]))
        #expect(await repository.updateDrawingCallCount == 1)
        #expect(await repository.createCallCount == 0)
    }

    @Test("Controla alterações não salvas e preserva estado diante de erro")
    func tracksUnsavedChangesAndKeepsThemAfterSaveFailure() async {
        let repository = InMemoryPaintRepository()
        let viewModel = PaintViewModel(mode: .new, repository: repository)

        #expect(!viewModel.hasUnsavedChanges)
        viewModel.markDirty()
        #expect(viewModel.hasUnsavedChanges)

        await repository.setFailNextCall(TestRepositoryError.expected)
        let savedPaint = await viewModel.save(
            drawingData: Data([0x01]),
            name: "Falha"
        )

        #expect(savedPaint == nil)
        #expect(viewModel.hasUnsavedChanges)
        #expect(viewModel.errorMessage != nil)
    }

    private func makePaint(name: String, drawingData: Data) -> Paint {
        Paint(
            id: UUID(),
            name: name,
            date: Date(timeIntervalSince1970: 1_740_744_000),
            drawingData: drawingData
        )
    }

    private enum TestRepositoryError: Error {
        case expected
    }
}
