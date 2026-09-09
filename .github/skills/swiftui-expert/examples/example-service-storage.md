# Exemplo: Service de Storage

Pedido exemplo: "Crie um UserDefaultsService para salvar se o onboarding foi visto".

## Referências

Leia:

- `references/architecture.md`
- `references/service.md`
- `references/storage-security.md`
- `references/view-model.md`

## Decisão

`UserDefaults` é adequado para uma preferência não sensível e pequena. Tokens,
credenciais e identificadores que permitam acesso devem usar o Keychain. O
service é um valor de dependência injetado no ViewModel; a View não acessa
storage diretamente.

## Service

```swift
import Foundation

protocol OnboardingStorageServiceProtocol {
    func hasSeenOnboarding() -> Bool
    func setHasSeenOnboarding(_ value: Bool)
}

final class OnboardingStorageService: OnboardingStorageServiceProtocol {
    private enum Key {
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasSeenOnboarding() -> Bool {
        defaults.bool(forKey: Key.hasSeenOnboarding)
    }

    func setHasSeenOnboarding(_ value: Bool) {
        defaults.set(value, forKey: Key.hasSeenOnboarding)
    }
}
```

O protocolo só deve ser `Sendable` se a implementação e a fronteira de
isolamento forem realmente seguras para concorrência. Para um service síncrono
usado exclusivamente no ViewModel `@MainActor`, não adicione a conformidade
decorativamente.

## Uso no ViewModel

```swift
import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var state: ViewState<Bool> = .idle

    private let storage: OnboardingStorageServiceProtocol

    init(storage: OnboardingStorageServiceProtocol) {
        self.storage = storage
    }

    func load() {
        state = .success(storage.hasSeenOnboarding())
    }

    func complete() {
        storage.setHasSeenOnboarding(true)
        state = .success(true)
    }
}
```

Na composition root, injete `OnboardingStorageService()`; em testes, use uma
instância com `UserDefaults(suiteName:)` temporária e remova o suite ao terminar.

## Checklist

- Use Keychain para dados sensíveis e `UserDefaults` apenas para preferências.
- Injete o service por protocolo quando ele for usado por um ViewModel.
- Importe `Combine` em arquivos que declaram `ObservableObject`/`@Published`.
- Não acesse storage diretamente pela View.
- Não registre tokens, senhas ou dados pessoais em logs.
