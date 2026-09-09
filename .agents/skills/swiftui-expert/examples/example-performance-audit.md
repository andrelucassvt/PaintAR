# Exemplo: Diagnóstico de lista lenta

Pedido: “A tela de produtos tem lag no scroll”. Leia `references/performance.md`, `references/concurrency.md`, `references/view.md` e `references/view-model.md` quando o estado participar do custo.

## Triage inicial

1. Registre aparelho/OS, build (Release ou Debug), quantidade de itens, ação reproduzida e baseline.
2. Procure sorting/filtering/formatting/decoding/I/O em `body`, identidade instável, estado global lido pela row, imagens grandes e geometry/animation em alta frequência.
3. Use SwiftUI Instruments + Time Profiler + Hangs/Hitches antes de escolher a correção. Sem trace, reporte hipóteses, não certezas.

## Exemplo de correção proporcional

```swift
import SwiftUI

struct ProductListView: View {
    let products: [Product]

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(products) { product in
                    ProductRowView(product: product)
                }
            }
        }
    }
}
```

Ordene/filtre antes da renderização (Repository/ViewModel ou valor derivado com owner claro), não dentro do `body`. Use `LazyVStack` quando a construção eager for material, não por um número mágico de itens. Rows recebem apenas os campos/ações que leem.

## Estado e imagens

```swift
import Combine
import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Product]> = .idle
    private let repository: ProductRepositoryProtocol

    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            let products = try await repository.fetchAll(page: 1, limit: 50)
            try Task.checkCancellation()
            state = .success(products.sorted { $0.name < $1.name })
        } catch is CancellationError {
            // Cancelamento não é erro de UX.
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

Para galerias, downsample `UIImage(data:)` ao tamanho de renderização fora do Main Actor e limite o cache. Confirme o ganho com pico de memória e tempo de atualização; não adicione `Task.detached` sem isolamento/Sendable corretos.

## Output esperado

Liste problemas por arquivo/linha quando possível, separe evidência de hipótese, proponha a menor correção e inclua como repetir a medição. Não refatore arquitetura fora do sintoma observado.
