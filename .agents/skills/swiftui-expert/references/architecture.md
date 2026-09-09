# Arquitetura SwiftUI MVVM

Use esta referência antes de uma feature completa, revisão entre camadas ou projeto desconhecido. O objetivo é manter responsabilidades claras sem impor pastas novas quando o projeto já tem uma organização funcional.

## Contrato de compatibilidade

- O baseline deste repositório é deployment target iOS 15.
- `NavigationView`, `ObservableObject`, `@Published`, `@StateObject` e `@ObservedObject` continuam sendo os defaults de compatibilidade. APIs modernas podem ser usadas somente se o target real permitir e a decisão estiver documentada.
- Deployment target, SDK/Xcode e Swift language mode são dimensões diferentes. Uma API disponível no SDK não significa que ela possa ser executada no menor sistema suportado.
- Nenhum arquivo não-View importa `SwiftUI`. ViewModels usam `Foundation` e `Combine` quando adotam `ObservableObject`/`@Published`.

## Camadas e dependências

| Camada | Responsabilidade | Pode depender de |
|---|---|---|
| View | Renderizar estado, capturar interação e emitir intenções | SwiftUI, ViewModel, Models, rotas |
| ViewModel | Orquestrar estado de apresentação, validação e ações | Foundation, Combine quando necessário, protocolos |
| Repository | Traduzir operações do domínio para uma fonte de dados | Protocolos de Service/APIClient, Models/DTOs |
| Service | Infraestrutura reutilizável: HTTP, auth, Keychain, storage | Foundation e frameworks específicos |
| Model/DTO | Dados de domínio e transporte, sem efeitos colaterais | Foundation quando necessário |

O entry point ou container é o composition root: constrói implementações reais e injeta protocolos. Previews e testes constroem doubles determinísticos no mesmo seam; não usam rede, autenticação ou banco de produção.

## Ownership e fonte de verdade

1. Use `@State` para valor que a View cria e possui, sempre `private`.
2. Use `@StateObject` para um `ObservableObject` que a View cria; use `@ObservedObject` para um objeto recebido de fora.
3. Passe valores, bindings e callbacks estreitos para componentes. Não injete o ViewModel pai em toda row.
4. Armazene uma informação em um único lugar. Valores derivados devem ser computed ou recalculados junto com a fonte, não sincronizados por booleans paralelos.
5. Estado compartilhado e mutável precisa de isolamento explícito; `ObservableObject` não torna acesso concorrente seguro.

## ViewState

Use uma enumeração para que transições ilegais sejam difíceis de representar:

```swift
import Foundation

enum ViewState<Value> {
    case idle
    case loading
    case success(Value)
    case error(String)
}
```

O ViewModel pode expor estados independentes (`contentState`, `saveState`) quando as operações coexistem. A camada de apresentação converte erros técnicos em mensagens localizáveis; não mostre `localizedDescription` de um erro de transporte como contrato de UX sem revisão.

## Estrutura sugerida

```text
App/
Models/                 # domínio e DTOs, se separados
ViewModels/
Views/<Feature>/        # tela e Components/
Repositories/
Services/Networking/    # cliente e endpoints
Services/Storage/       # Keychain e preferências
Utilities/              # ViewState e tipos compartilhados
```

Adapte nomes ao projeto. Não mova arquivos em massa para “corrigir” uma convenção que já funciona.

## Checklist arquitetural

- [ ] O fluxo e a fonte única de verdade estão descritos antes da mudança.
- [ ] Dependências externas entram pelo inicializador e ViewModels dependem de protocolos.
- [ ] Estado async está em `ViewState<Value>`; operações independentes não sobrescrevem umas às outras.
- [ ] Views não possuem regra de negócio nem trabalho bloqueante no `body`.
- [ ] Models não dependem de SwiftUI e DTOs não vazam detalhes de transporte sem necessidade.
- [ ] O target mínimo, SDK e toolchain foram confirmados separadamente.
- [ ] Testes e previews conseguem trocar Services/Repositories por doubles sem rede real.
