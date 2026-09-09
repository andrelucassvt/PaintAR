import Foundation
import Observation

enum HomeState {
    case loading
    case loaded([Paint])
    case error(String)
}

enum ActiveAlert: Identifiable {
    case error(String)
    case success

    var id: String {
        switch self {
        case .error(let message):
            return "error-\(message)"
        case .success:
            return "success"
        }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    private let repository: any PaintRepository
    private let fileService: PaintFileService
    private var paints: [Paint] = []

    private(set) var state: HomeState = .loading
    var searchText = ""
    var activeAlert: ActiveAlert?

    var visiblePaints: [Paint] {
        let query = normalized(searchText)

        guard !query.isEmpty else {
            return paints
        }

        return paints.filter { normalized($0.name).contains(query) }
    }

    var hasPaints: Bool {
        !paints.isEmpty
    }

    init(
        repository: any PaintRepository,
        fileService: PaintFileService = .init()
    ) {
        self.repository = repository
        self.fileService = fileService
    }

    func load() async {
        state = .loading

        do {
            let fetchedPaints = try await repository.fetchAll()
            try Task.checkCancellation()

            paints = fetchedPaints
            state = .loaded(fetchedPaints)
        } catch is CancellationError {
            return
        } catch {
            let message = error.localizedDescription
            state = .error(message)
            activeAlert = .error(message)
        }
    }

    func delete(_ paint: Paint) async {
        let previousPaints = paints

        paints.removeAll { $0.id == paint.id }
        state = .loaded(paints)

        do {
            try await repository.delete(id: paint.id)
            try Task.checkCancellation()
        } catch is CancellationError {
            paints = previousPaints
            state = .loaded(previousPaints)
        } catch {
            paints = previousPaints
            state = .loaded(previousPaints)
            activeAlert = .error(error.localizedDescription)
        }
    }

    func rename(_ paint: Paint, to name: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty,
              let index = paints.firstIndex(where: { $0.id == paint.id }) else {
            return
        }

        let previousPaints = paints
        let updatedPaint = Paint(
            id: paint.id,
            name: trimmedName,
            date: Date(),
            drawingData: paint.drawingData
        )

        paints[index] = updatedPaint
        state = .loaded(paints)

        do {
            try await repository.rename(id: paint.id, to: trimmedName)
            try Task.checkCancellation()
        } catch is CancellationError {
            paints = previousPaints
            state = .loaded(previousPaints)
        } catch {
            paints = previousPaints
            state = .loaded(previousPaints)
            activeAlert = .error(error.localizedDescription)
        }
    }

    func importFile(at url: URL) async {
        do {
            let exchangeModel = try fileService.decode(fileAt: url)
            let importedPaint = try await repository.importPaint(exchangeModel)
            try Task.checkCancellation()

            paints.append(importedPaint)
            paints.sort { $0.date > $1.date }
            state = .loaded(paints)
            activeAlert = .success
        } catch is CancellationError {
            return
        } catch {
            activeAlert = .error(error.localizedDescription)
        }
    }

    func handleError(_ error: Error) {
        let message = error.localizedDescription
        activeAlert = .error(message)

        if paints.isEmpty {
            state = .error(message)
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
