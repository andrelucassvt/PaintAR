import Foundation
import Testing
@testable import PaintAR

@MainActor
struct HomeViewModelTests {
    @Test("Carrega os desenhos e publica estado loaded")
    func loadPublishesPaints() async {
        let paint = makePaint(name: "Casa")
        let repository = InMemoryPaintRepository(paints: [paint])
        let viewModel = HomeViewModel(repository: repository)

        #expect(isLoading(viewModel.state))
        await viewModel.load()

        #expect(loadedPaints(in: viewModel.state) == [paint])
    }

    @Test("Carrega estado vazio")
    func loadPublishesEmptyState() async {
        let viewModel = HomeViewModel(repository: InMemoryPaintRepository())

        await viewModel.load()

        #expect(loadedPaints(in: viewModel.state) == [])
    }

    @Test("Publica erro e permite tentar novamente")
    func retryAfterErrorLoadsPaints() async {
        let paint = makePaint(name: "Árvore")
        let repository = InMemoryPaintRepository(paints: [paint])
        await repository.setFailNextCall(TestRepositoryError.expected)
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()
        #expect(isError(viewModel.state))

        await viewModel.load()
        #expect(loadedPaints(in: viewModel.state) == [paint])
    }

    @Test("Busca ignora maiúsculas, minúsculas e acentos")
    func searchFiltersIgnoringCaseAndAccents() async {
        let casa = makePaint(name: "Casa")
        let arvore = makePaint(name: "Árvore")
        let viewModel = HomeViewModel(
            repository: InMemoryPaintRepository(paints: [casa, arvore])
        )

        await viewModel.load()
        viewModel.searchText = "arvore"

        #expect(viewModel.visiblePaints == [arvore])

        viewModel.searchText = "sem resultado"
        #expect(viewModel.visiblePaints.isEmpty)
        #expect(loadedPaints(in: viewModel.state) != nil)
    }

    @Test("Excluir atualiza estado e chama o repositório")
    func deleteUpdatesStateAndRepository() async {
        let paint = makePaint(name: "Excluir")
        let repository = InMemoryPaintRepository(paints: [paint])
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.delete(paint)

        #expect(loadedPaints(in: viewModel.state) == [])
        let deleteCallCount = await repository.deleteCallCount
        #expect(deleteCallCount == 1)
    }

    @Test("Renomear atualiza o estado e rejeita somente espaços")
    func renameUpdatesStateAndRejectsBlankName() async {
        let paint = makePaint(name: "Antes")
        let repository = InMemoryPaintRepository(paints: [paint])
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.rename(paint, to: "Depois")
        #expect(loadedPaints(in: viewModel.state)?.first?.name == "Depois")

        await viewModel.rename(paint, to: "   ")
        let renameCallCount = await repository.renameCallCount
        #expect(renameCallCount == 1)
        #expect(loadedPaints(in: viewModel.state)?.first?.name == "Depois")
    }

    @Test("Importar arquivo válido atualiza a lista e publica sucesso")
    func importValidFilePublishesSuccess() async throws {
        let repository = InMemoryPaintRepository()
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()
        let paint = makePaint(name: "Importado")
        let url = try makeExchangeFile(for: paint)
        defer { try? FileManager.default.removeItem(at: url) }

        await viewModel.importFile(at: url)

        #expect(loadedPaints(in: viewModel.state) == [paint])
        #expect(isSuccess(viewModel.activeAlert))
    }

    @Test("Importar JSON inválido mantém a lista e publica erro")
    func importInvalidFilePublishesError() async throws {
        let paint = makePaint(name: "Mantido")
        let viewModel = HomeViewModel(
            repository: InMemoryPaintRepository(paints: [paint])
        )
        await viewModel.load()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid-\(UUID().uuidString).json")
        try Data("{ inválido".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        await viewModel.importFile(at: url)

        #expect(loadedPaints(in: viewModel.state) == [paint])
        #expect(isError(viewModel.activeAlert))
    }

    private func makePaint(name: String) -> Paint {
        Paint(
            id: UUID(),
            name: name,
            date: Date(timeIntervalSince1970: 1_740_744_000),
            drawingData: Data([0x01, 0x02])
        )
    }

    private func makeExchangeFile(for paint: Paint) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("paint-\(UUID().uuidString).json")
        try JSONEncoder().encode(PaintExchangeModel(paint: paint)).write(to: url)
        return url
    }

    private func isLoading(_ state: HomeState) -> Bool {
        if case .loading = state {
            return true
        }

        return false
    }

    private func isError(_ state: HomeState) -> Bool {
        if case .error = state {
            return true
        }

        return false
    }

    private func isError(_ alert: ActiveAlert?) -> Bool {
        if case .error = alert {
            return true
        }

        return false
    }

    private func isSuccess(_ alert: ActiveAlert?) -> Bool {
        if case .success = alert {
            return true
        }

        return false
    }

    private func loadedPaints(in state: HomeState) -> [Paint]? {
        guard case .loaded(let paints) = state else {
            return nil
        }

        return paints
    }

    private enum TestRepositoryError: Error {
        case expected
    }
}
