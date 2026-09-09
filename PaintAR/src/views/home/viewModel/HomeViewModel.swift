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
        case .error:
            "error"
        case .success:
            "success"
        }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    private let repository: any PaintRepository
    private let fileService: PaintFileService

    private(set) var paints: [Paint] = []
    private(set) var state: HomeState = .loading
    var showImportView = false
    var importActivated = false
    var activeAlert: ActiveAlert?

    init(
        repository: any PaintRepository,
        fileService: PaintFileService = .init()
    ) {
        self.repository = repository
        self.fileService = fileService
    }

    func fetchPaints(isLoading: Bool = true) async {
        if isLoading {
            state = .loading
        }

        do {
            let fetchedPaints = try await repository.fetchAll()
            try Task.checkCancellation()
            paints = fetchedPaints
            state = .loaded(fetchedPaints)
        } catch is CancellationError {
            return
        } catch {
            handleError(error)
        }
    }

    func deletePaint(_ paint: Paint) async {
        do {
            try await repository.delete(id: paint.id)
            try Task.checkCancellation()
            await fetchPaints(isLoading: false)
        } catch is CancellationError {
            return
        } catch {
            handleError(error)
        }
    }

    func renamePaint(_ paint: Paint, to name: String) async {
        do {
            try await repository.rename(id: paint.id, to: name)
            try Task.checkCancellation()
            await fetchPaints(isLoading: false)
        } catch is CancellationError {
            return
        } catch {
            handleError(error)
        }
    }

    func importPaint(from url: URL) async {
        showImportView = false

        do {
            let model = try fileService.decode(fileAt: url)
            _ = try await repository.importPaint(model)
            try Task.checkCancellation()
            await fetchPaints(isLoading: false)
            activeAlert = .success
        } catch is CancellationError {
            return
        } catch {
            handleError(error)
        }
    }

    func handleError(_ error: Error) {
        state = .error(error.localizedDescription)
        activeAlert = .error(error.localizedDescription)
    }
}
