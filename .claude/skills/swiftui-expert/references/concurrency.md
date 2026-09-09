# Swift Concurrency e isolamento

Use structured concurrency para manter ownership, cancelamento e erros legíveis. `async/await`, tasks e actors são recursos da linguagem/runtime com requisitos próprios; não os classifique como iOS 17-only. Confirme o mínimo de Swift/Xcode e a disponibilidade de cada API no target real.

## Regras de isolamento

- ViewModels ligados a UI são `@MainActor`; atualizações de `@Published` acontecem nesse ator.
- Um `actor` protege estado mutável compartilhado. Use-o para cache, token refresh, fila ou storage que realmente tenha concorrência.
- `Sendable` significa que o valor é seguro entre domínios concorrentes. Structs imutáveis com propriedades Sendable são o default; referências mutáveis precisam de actor/lock ou isolamento equivalente.
- Não marque classes como `Sendable`/`@unchecked Sendable` para calar warnings. Documente e revise qualquer escape hatch.
- Closures que atravessam atores devem ser `@Sendable` e capturar apenas valores seguros. Evite capturar View, `self` de ViewModel ou UIKit/AppKit em trabalho de fundo.

```swift
import Foundation

actor TokenStore {
    private var token: String?

    func set(_ token: String?) { self.token = token }
    func current() -> String? { token }
}
```

## Structured tasks e cancelamento

- Prefira `.task`, `.task(id:)`, `async let` e task groups com escopo. Uma task criada por uma View cancela ao desaparecer; uma task persistente precisa de owner e cancelamento explícitos.
- Verifique `Task.isCancelled`/`Task.checkCancellation()` depois de awaits e antes de publicar resultado.
- Capture um identificador de geração, query ou request ID para impedir que resultados obsoletos sobrescrevam a tela.
- Capture `CancellationError` separadamente e restaure o último estado; cancelamento é controle de fluxo, não falha de rede.
- Não use `DispatchQueue` para saltos de thread novos. Não use `Task.detached` sem uma razão documentada e sem valores Sendable; ele abandona herança de ator, prioridade e contexto.

## Trabalho fora do Main Actor

Mova parsing, downsampling, hashing e cálculos grandes para uma camada não-UI segura. Passe cópias de valores Sendable e devolva somente o resultado necessário. Não acesse `UIScreen`, View ou estado de UI dentro de `Task.detached`/closures que o SwiftUI pode executar fora do Main Actor.

## Networking e retries

Faça retry apenas para erros transitórios, com limite, backoff e cancelamento. Não repita automaticamente operações não idempotentes sem idempotency key/contrato da API. Propague erros tipados até a fronteira do ViewModel e mapeie a UX ali.

## Checklist

- [ ] Cada estado mutável compartilhado tem owner/ator/lock identificável.
- [ ] `Sendable` e `@Sendable` foram usados por segurança real, sem `@unchecked` ornamental.
- [ ] Tarefas são estruturadas, canceláveis e não deixam resultados antigos vencerem os novos.
- [ ] `CancellationError` não aparece como mensagem de erro ao usuário.
- [ ] Trabalho pesado não bloqueia Main Actor e só atravessa a fronteira com valores seguros.
- [ ] Retries respeitam idempotência, backoff, limite e cancelamento.
- [ ] O código não usa GCD como substituto de isolamento nem `Task.detached` por padrão.
