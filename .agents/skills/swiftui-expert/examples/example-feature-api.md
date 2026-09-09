# Exemplo: Feature REST com estados e paginação

Pedido: “Crie uma listagem de produtos consumindo uma API REST”. Antes de editar, leia `references/availability.md`, `architecture.md`, `model.md`, `networking.md`, `repository.md`, `view-model.md`, `view.md`, `testing-previews.md` e `navigation.md` se houver rota nova.

## Arquivos

```text
Models/Product.swift
Services/Networking/Endpoint.swift
Repositories/ProductRepository.swift
ViewModels/ProductListViewModel.swift
Views/ProductList/ProductListView.swift
Views/ProductList/Components/ProductRowView.swift
Tests/ProductListViewModelTests.swift
```

## Model e Repository

```swift
import Foundation

struct Product: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let price: Decimal
}

protocol ProductRepositoryProtocol {
    func fetchAll(page: Int, limit: Int) async throws -> [Product]
}

final class ProductRepository: ProductRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchAll(page: Int, limit: Int) async throws -> [Product] {
        try await apiClient.request(
            endpoint: .productList(page: page, limit: limit),
            responseType: [Product].self
        )
    }
}
```

## ViewModel e View

O ViewModel usa `ViewState<[Product]>`, generation/cancellation guard e um estado independente para próxima página. A View usa `NavigationView` apenas se for o container raiz e injeta um mock na preview.

```swift
import Combine
import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Product]> = .idle
    @Published private(set) var nextPageState: ViewState<Void> = .idle

    private let repository: ProductRepositoryProtocol
    private var generation = 0

    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        guard !Task.isCancelled else { return }
        generation += 1
        let requestGeneration = generation
        state = .loading
        do {
            let products = try await repository.fetchAll(page: 1, limit: 20)
            try Task.checkCancellation()
            guard requestGeneration == generation else { return }
            state = .success(products)
        } catch is CancellationError {
            // Normal quando o .task é cancelado.
        } catch {
            guard requestGeneration == generation else { return }
            state = .error(error.localizedDescription)
        }
    }
}
```

```swift
import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel: ProductListViewModel

    init(viewModel: ProductListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .idle: Text("Nenhum produto", comment: "Estado inicial da lista")
            case .loading: ProgressView("Carregando…")
            case .success(let products):
                ForEach(products) { ProductRowView(product: $0) }
            case .error(let message):
                ErrorStateView(message: message) { Task { await viewModel.load() } }
            }
        }
        .navigationTitle(Text("Produtos", comment: "Título da lista de produtos"))
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
    }
}
```

Não copie o `load()` sem o guard de idempotência/generation quando a View puder reaparecer ou receber queries. Em produção, mapeie erro técnico para uma mensagem localizável e preserve o conteúdo durante refresh/paginação.

## Checklist

- [ ] APIClient e Repository entram por DI; ViewModel não conhece URLSession.
- [ ] Endpoint é tipado e paginação/cursor segue o contrato real da API.
- [ ] Loading inicial é separado de refresh/next page quando o conteúdo deve permanecer visível.
- [ ] Cancelamento e resultado obsoleto não sobrescrevem o estado atual.
- [ ] IDs são estáveis, rows são componentes focados e não leem estado global amplo.
- [ ] Preview e Swift Testing usam doubles locais, sem rede ou credenciais.
