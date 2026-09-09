import Foundation
import Observation

@MainActor
@Observable
final class PaintViewModel {
    enum Mode {
        case new
        case editing(Paint)
    }

    private let mode: Mode
    private let repository: any PaintRepository

    private(set) var isSaving = false
    private(set) var hasUnsavedChanges = false
    var errorMessage: String?

    init(mode: Mode, repository: any PaintRepository) {
        self.mode = mode
        self.repository = repository
    }

    func save(drawingData: Data, name: String) async -> Paint? {
        guard !isSaving else {
            return nil
        }

        errorMessage = nil

        switch mode {
        case .new:
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

            guard trimmedNameIsValid(trimmedName) else {
                errorMessage = "invalidName"
                return nil
            }

            isSaving = true
            defer { isSaving = false }

            do {
                let paint = try await repository.create(
                    name: trimmedName,
                    drawingData: drawingData
                )
                try Task.checkCancellation()
                hasUnsavedChanges = false
                return paint
            } catch is CancellationError {
                return nil
            } catch {
                errorMessage = "errorSaving"
                return nil
            }

        case .editing(let paint):
            isSaving = true
            defer { isSaving = false }

            do {
                try await repository.updateDrawing(id: paint.id, drawingData: drawingData)
                try Task.checkCancellation()
                hasUnsavedChanges = false

                return Paint(
                    id: paint.id,
                    name: paint.name,
                    date: Date(),
                    drawingData: drawingData
                )
            } catch is CancellationError {
                return nil
            } catch {
                errorMessage = "errorSaving"
                return nil
            }
        }
    }

    func markDirty() {
        hasUnsavedChanges = true
    }

    func trimmedNameIsValid(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
