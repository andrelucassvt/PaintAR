---
name: view-model
description: Cria ou revisa ViewModels SwiftUI iOS 15+ com ObservableObject, ViewState, DI, cancelamento, busca, refresh, save/delete e paginação. Use quando a tela tiver estado async ou lógica de apresentação testável.
argument-hint: <NomeDoViewModel> (ex: ProductList, Profile)
---

# ViewModel

O ViewModel é um adaptador de estado de apresentação, não um segundo Service. Ele é `@MainActor final`, depende de protocolos e expõe intenções do usuário. A View não conhece erros de transporte, tokens ou detalhes de persistência.

## Base correta

`ObservableObject` e `@Published` são fornecidos por Combine, mesmo que o arquivo não importe SwiftUI:

```swift
import Combine
import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Product]> = .idle

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
        generation += 1
        let requestGeneration = generation
        state = .loading

        do {
            let products = try await repository.fetchAll(page: 1, limit: 20)
            try Task.checkCancellation()
            guard requestGeneration == generation else { return }
            state = .success(products)
        } catch is CancellationError {
            // A View disappearing or a newer request is normal; keep the last UI state.
        } catch {
            guard requestGeneration == generation else { return }
            state = .error(mapToUserMessage(error))
        }
    }

    func refresh() async {
        // Preserve existing content while a refresh indicator is shown by the View.
        await load()
    }

    private func mapToUserMessage(_ error: Error) -> String {
        // Use a localized presentation error in a real project; do not expose secrets or raw server text.
        error.localizedDescription
    }
}
```

`loadIfNeeded()` makes `.task` idempotente on reappearance. The generation guard protects against a previous request completing after a newer one. If a project needs retries or refresh without clearing content, expose a second `ViewState<Void>` (`refreshState`) or a feature-specific state type instead of an `isLoading`/`hasError` combination.

## Concurrent actions

Use one state per independent operation:

```swift
@Published private(set) var contentState: ViewState<[Product]> = .idle
@Published private(set) var saveState: ViewState<Void> = .idle
@Published private(set) var deleteState: ViewState<Void> = .idle
```

Do not set `contentState = .loading` for a save/delete that can leave the existing list visible. Keep mutations on the Main Actor and call the Repository with the smallest identifier or DTO needed.

## Search and debounce

Prefer structured `.task(id:)` in the View, which cancels the previous query automatically:

```swift
@Published var searchText = ""
@Published private(set) var searchState: ViewState<[Product]> = .idle

func search(query: String) async {
    do {
        try await Task.sleep(nanoseconds: 300_000_000) // iOS 15-compatible spelling
        try Task.checkCancellation()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchState = .idle
            return
        }
        searchState = .loading
        let results = try await repository.search(query: query)
        try Task.checkCancellation()
        searchState = .success(results)
    } catch is CancellationError {
        // Ignore cancellation; it means the query changed or the View disappeared.
    } catch {
        searchState = .error(mapToUserMessage(error))
    }
}
```

```swift
.searchable(text: $viewModel.searchText)
.task(id: viewModel.searchText) {
    await viewModel.search(query: viewModel.searchText)
}
```

Use a Combine pipeline only when the project already has a publisher-based contract or needs multiple publisher operators. Store and cancel its `AnyCancellable`s; do not launch an unmanaged `Task` from every `sink` event.

## Paginação

Keep the loaded page visible and represent the next-page request separately:

```swift
@Published private(set) var state: ViewState<[Product]> = .idle
@Published private(set) var nextPageState: ViewState<Void> = .idle

private var nextPage = 1
private let pageSize = 20

func loadFirstPage() async {
    nextPage = 1
    state = .loading
    do {
        let items = try await repository.fetchAll(page: nextPage, limit: pageSize)
        state = .success(items)
        nextPage += 1
    } catch is CancellationError {
        // Keep the prior state.
    } catch {
        state = .error(mapToUserMessage(error))
    }
}

func loadNextPage() async {
    guard case .success(let current) = state else { return }
    guard case .idle = nextPageState else { return }
    nextPageState = .loading

    do {
        let additions = try await repository.fetchAll(page: nextPage, limit: pageSize)
        try Task.checkCancellation()
        state = .success(current + additions)
        nextPage += 1
        nextPageState = .success(())
    } catch is CancellationError {
        nextPageState = .idle
    } catch {
        nextPageState = .error(mapToUserMessage(error))
    }
}
```

Use an API-provided `hasNext`/cursor when available; item count is only a safe heuristic when the API contract guarantees page size semantics. Reset pagination when the query/filter changes.

## Test seams

- Inject a protocol, never a concrete Repository or singleton hidden in the initializer.
- Test initial idle state, success, typed failure, cancellation, stale-result protection, pagination merge and independent action states.
- Mark Swift Testing suites that access this ViewModel `@MainActor`; do not share mutable mock state between parallel tests.

## Checklist

- [ ] `import Combine` exists whenever `ObservableObject`/`@Published` appears.
- [ ] `@MainActor final class` owns presentation state and dependencies come through `init`.
- [ ] `ViewState<Value>` is exhaustive; unrelated actions use separate states.
- [ ] `.task`/`.task(id:)` cancellation is expected and not rendered as an error.
- [ ] Newer requests cannot be overwritten by stale results.
- [ ] Refresh and pagination preserve existing content when that is the intended UX.
- [ ] Debounce is structured/cancelable and does not leak tasks or subscriptions.
- [ ] Errors are mapped at a presentation boundary and are localizable.
- [ ] Tests use deterministic protocol doubles for success, error and cancellation.
