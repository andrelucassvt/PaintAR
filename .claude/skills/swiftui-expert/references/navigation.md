---
name: navigation
description: Configura ou revisa navegação SwiftUI iOS 15+ com NavigationView, rotas tipadas, sheets, alerts e deep links sem misturar responsabilidades no ViewModel.
argument-hint: setup | route <Nome> | audit
---

# Navegação iOS 15+

Escolha a menor solução que representa o fluxo real. Para o baseline deste projeto, use `NavigationView` e links por destination/tag. `NavigationStack` é uma migração de target, não uma substituição silenciosa.

## Rota tipada e router

Prefira passar identificadores pequenos na rota e recarregar o detalhe pelo Repository; isso evita rotas gigantes, requisitos desnecessários de `Hashable` e dados desatualizados.

```swift
import Foundation

enum Route: Hashable, Identifiable {
    case productDetail(id: String)
    case settings

    var id: String {
        switch self {
        case .productDetail(let id): "product-detail-\(id)"
        case .settings: "settings"
        }
    }
}
```

```swift
import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var activeRoute: Route?

    func navigate(to route: Route) { activeRoute = route }
    func pop() { activeRoute = nil }
}
```

Não use `@EnvironmentObject` para esconder dependências de domínio; o router é uma dependência de apresentação compartilhada. Views que não navegam não precisam recebê-lo.

## Composition root e NavigationView

```swift
import SwiftUI

struct AppRootView: View {
    @StateObject private var router: AppRouter

    init(router: AppRouter = AppRouter()) {
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        NavigationView {
            HomeView()
        }
        .navigationViewStyle(.stack)
        .environmentObject(router)
    }
}
```

Se `AppRouter` for construído no entry point, injete a instância já configurada. Evite criar um router novo em cada tela e não aninhe `NavigationView` em destinos.

## Links e navegação programática

Para um link direto, use `NavigationLink(destination:)`. Para uma ação de botão, mantenha a seleção em um router observado e instale um link oculto com `tag`/`selection`, padrão disponível no iOS 15. O destino deve ser resolvido por uma função `@ViewBuilder` que trate todos os casos.

```swift
struct HomeView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        List {
            NavigationLink(destination: ProductDetailView(id: "product-1")) {
                Label("Produto", systemImage: "shippingbox")
            }
            Button("Configurações") {
                router.navigate(to: .settings)
            }
        }
        .background(
            NavigationLink(
                destination: destination(for: router.activeRoute),
                isActive: isRouteActive
            ) { EmptyView() }
        )
    }

    private var isRouteActive: Binding<Bool> {
        Binding(
            get: { router.activeRoute != nil },
            set: { if !$0 { router.pop() } }
        )
    }

    @ViewBuilder
    private func destination(for route: Route?) -> some View {
        switch route {
        case .productDetail(let id): ProductDetailView(id: id)
        case .settings: SettingsView()
        case nil: EmptyView()
        }
    }
}
```

O exemplo ilustra o padrão; em uma app real, um link `tag` deve ter uma seleção estável e o layout deve ser validado no target de iOS 15. Se o fluxo exigir uma pilha arbitrária, documente a limitação do `NavigationView` e planeje uma migração explícita para um target iOS 16+.

## Sheets, alerts e dismiss

Use um enum `Identifiable` para uma sheet cujo conteúdo depende de dados:

```swift
enum SheetRoute: Identifiable {
    case createProduct
    case editProduct(id: String)

    var id: String {
        switch self {
        case .createProduct: "create"
        case .editProduct(let id): "edit-\(id)"
        }
    }
}
```

`.sheet(item:)` evita booleanos que podem perder o item associado. A sheet possui as próprias ações e usa `@Environment(\.presentationMode)` no baseline iOS 15; use `dismiss` apenas quando a disponibilidade do target permitir. Confirmações destrutivas usam `.confirmationDialog` quando disponível no target e uma ação cancelável explícita.

## Deep links e estado

Converta URL/NSUserActivity em uma rota validada na borda do app. Não passe `URL`, `NavigationPath` ou `View` para um Repository. O estado de navegação deve ser restaurável somente quando o produto exigir; IDs e filtros são preferíveis a snapshots completos de Models.

## Checklist

- [ ] `AppRouter` é `@MainActor final`, importa Combine e é criado/injetado uma vez no composition root.
- [ ] `Route` é pequeno, tipado, `Hashable` e não carrega dados que podem ficar obsoletos sem necessidade.
- [ ] Baseline iOS 15 usa `NavigationView`/`NavigationLink(destination:)`; migração para Stack está documentada.
- [ ] Destinos e sheets têm cobertura exaustiva e não criam dependências live.
- [ ] Views filhas recebem router por `@EnvironmentObject` somente quando realmente navegam.
- [ ] Sheets modeladas usam `.sheet(item:)`; ações destrutivas têm confirmação.
- [ ] Deep links são validados e convertidos em rotas na borda, sem vazar UI para camadas de dados.
