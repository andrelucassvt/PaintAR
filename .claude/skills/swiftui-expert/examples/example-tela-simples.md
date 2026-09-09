# Exemplo: Tela Simples

Pedido exemplo: "Crie uma tela de perfil local com nome, email e botão de atualizar".

## Referências

Leia:

- `references/architecture.md`
- `references/model.md`
- `references/view.md`
- `references/view-model.md`
- `references/testing-previews.md`

## Arquivos

```text
Models/Profile.swift
ViewModels/ProfileViewModel.swift
Views/Profile/ProfileView.swift
Views/Profile/Components/ProfileHeaderView.swift
Utilities/ViewState.swift
```

## Modelo e ViewModel

```swift
import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
}
```

```swift
import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var state: ViewState<Profile> = .idle

    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        guard !Task.isCancelled else { return }
        state = .loading
        state = .success(Profile(id: "1", name: "Ana Silva", email: "ana@example.com"))
        hasLoaded = true
    }
}
```

## View

```swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: @autoclosure @escaping () -> ProfileViewModel = ProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
                    .accessibilityHidden(true)
            case .loading:
                ProgressView()
                    .accessibilityLabel(Text("Carregando perfil", comment: "Profile loading accessibility label"))
            case .success(let profile):
                ProfileHeaderView(profile: profile)
            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.load() }
                }
            }
        }
        .navigationTitle(Text("Perfil", comment: "Profile screen title"))
        .task { await viewModel.loadIfNeeded() }
    }
}
```

A tela é apresentada dentro da `NavigationView` de seu fluxo raiz; não crie uma
segunda `NavigationView` dentro de uma tela filha. Use uma preview com o
ViewModel determinístico e exercite, no mínimo, loading, sucesso e erro.

## Checklist

- Não usar `NavigationStack` no baseline iOS 15.
- Não usar booleans soltos para loading/error.
- Criar preview funcional sem rede ou estado global compartilhado.
- Extrair header, card ou empty state se tiver identidade própria.
- Fornecer rótulos localizáveis e suporte a Dynamic Type/VoiceOver.
