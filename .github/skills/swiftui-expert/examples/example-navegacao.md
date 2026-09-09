# Exemplo: Navegação iOS 15

Pedido: “Adicione uma rota de detalhe de produto”. Leia `references/availability.md`, `references/navigation.md`, `references/view.md` e `references/accessibility.md`.

## Link direto

```swift
import SwiftUI

struct ProductListView: View {
    let products: [Product]

    var body: some View {
        List(products) { product in
            NavigationLink(destination: ProductDetailView(id: product.id)) {
                Label(product.name, systemImage: "shippingbox")
            }
        }
        .navigationTitle(Text("Produtos", comment: "Título da lista"))
    }
}
```

O `NavigationView` deve existir uma vez no root da feature/app:

```swift
NavigationView { ProductListView(products: Product.mockList) }
    .navigationViewStyle(.stack)
```

## Router programático

```swift
import Combine
import Foundation

enum Route: Hashable {
    case productDetail(id: String)
    case settings
}

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var activeRoute: Route? = nil

    func navigate(to route: Route) { activeRoute = route }
    func pop() { activeRoute = nil }
}
```

Use `@EnvironmentObject` somente para esse estado de apresentação compartilhado. Para criação/edição, prefira `.sheet(item:)` com enum `Identifiable`; confirme ações destrutivas com `confirmationDialog`.

## Checklist

- [ ] Target iOS 15 usa `NavigationView` e `NavigationLink(destination:)`.
- [ ] Router é `@MainActor`, importa Combine e é criado uma vez no composition root.
- [ ] Rotas passam IDs pequenos e estáveis, não snapshots gigantes de Models.
- [ ] ViewModel não recebe `View`, `NavigationPath` ou contexto de UI.
- [ ] Sheets, alerts, deep links e dismiss respeitam disponibilidade e ownership.
