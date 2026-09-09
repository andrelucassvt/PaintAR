---
name: swiftui-expert
description: Guia e revisa código SwiftUI MVVM para projetos iOS 15+ com foco em correção, disponibilidade de APIs, estado, concorrência, acessibilidade, localização, previews, networking, navegação e performance medida. Use esta skill sempre que o usuário criar, revisar, refatorar ou diagnosticar Views, ViewModels, Models, Repositories, Services, listas, imagens, estado async ou UI Liquid Glass, mesmo sem mencionar “SwiftUI Expert”.
license: MIT
metadata:
  version: "3.0.0"
---

# SwiftUI Expert

Use esta skill para produzir mudanças pequenas, compiláveis e coerentes com o projeto. Ela preserva o contrato deste repositório (deployment target mínimo iOS 15, MVVM, `ViewState<T>`, `ObservableObject`, `@StateObject`/`@ObservedObject`, Repository com protocolo + implementação) e acrescenta práticas modernas somente quando o SDK, o toolchain e a disponibilidade do alvo permitirem.

## Regras de operação

- Leia `references/availability.md` no início de toda tarefa para separar deployment target, SDK e Swift/Xcode.
- Faça um preflight do projeto: target mínimo, versão da linguagem, dependências, convenções de pastas, instruções locais e estado atual do fluxo. Preserve padrões existentes antes de introduzir abstrações.
- Carregue apenas as referências aplicáveis no roteador abaixo. Em tarefa desconhecida ou que cruza camadas, leia também `references/architecture.md`.
- Prefira APIs nativas e Foundation/Swift Concurrency; não adicione frameworks de terceiros sem pedido explícito.
- Não altere o deployment target silenciosamente. Se uma API posterior for adotada, use `#available` e um fallback que preserve a função principal.
- Não invente sucesso: rode as verificações disponíveis e diferencie “verificado”, “hipótese” e “validação manual”.
- Nunca coloque tokens, chaves, PII ou dados de gravação em código, logs, previews ou exemplos.

## Preflight mínimo

1. Localize o target e leia `AGENTS.md`/`CLAUDE.md`, `Package.swift`, `*.xcodeproj/project.pbxproj` ou equivalente.
2. Registre deployment target, Swift language mode, Xcode/SDK quando visíveis e frameworks realmente usados.
3. Mapeie ownership e fluxo atual: View → ViewModel → protocolo → implementação → Service/Storage; não mova responsabilidades sem necessidade.
4. Selecione referências pelo tópico e confirme disponibilidade antes de copiar qualquer snippet.
5. Faça uma mudança mínima, compile/analyze quando houver projeto executável e rode os testes relevantes.

## Roteador de tópicos

| Tarefa | Leia |
|---|---|
| Qualquer tarefa nova, projeto desconhecido ou API possivelmente deprecated | `references/availability.md`, e `references/architecture.md` quando houver mais de uma camada |
| Model, DTO, Codable, identidade ou mocks de dados | `references/model.md` |
| View, componente, formulário, estado visual ou preview | `references/view.md`, `references/accessibility.md`, `references/localization.md`, `references/testing-previews.md` |
| ViewModel, busca, debounce, refresh, save, delete ou paginação | `references/view-model.md`, `references/concurrency.md`, `references/testing-previews.md` |
| Repository, APIClient, Endpoint, auth, Keychain ou UserDefaults | `references/repository.md`, `references/service.md` e a referência específica `networking.md` ou `storage-security.md` |
| NavigationView, rotas, sheets, alerts ou deep link compatível com iOS 15 | `references/navigation.md` |
| Lag, hitches, memória, imagens, listas ou re-renders | `references/performance.md`; use `references/concurrency.md` se houver trabalho fora do Main Actor |
| Liquid Glass ou visual iOS 26 | `references/liquid-glass.md` (somente por pedido explícito) |
| Animação avançada, macOS exclusivo ou StoreKit | Use também a skill irmã `animation`, `macos` ou `payment` quando disponível |

## Contrato arquitetural do repositório

- **iOS 15:** use `NavigationView`, `NavigationLink(destination:)`, `ObservableObject`, `@Published`, `@StateObject` e `@ObservedObject` como baseline. Não substitua o baseline por `NavigationStack`, `NavigationPath`, `@Observable` ou `@Bindable` sem atualizar explicitamente o target.
- **Views:** importam `SwiftUI`, renderizam estado e emitem intenções. Use `Button` para ações; `onTapGesture` fica reservado a localização/contagem de toques.
- **ViewModels:** `@MainActor final class ...: ObservableObject`, `import Combine` quando usar `ObservableObject`/`@Published`, estado exposto como `@Published private(set)` e dependências injetadas por `init`.
- **Estado async:** represente o fluxo com `ViewState<T>`; mantenha estados independentes para operações independentes. Não transforme cancelamento em erro visível e não deixe uma requisição antiga sobrescrever a atual.
- **Models:** structs de domínio sem `SwiftUI`; adote `Codable`, `Identifiable`, `Equatable` ou `Hashable` somente quando o contrato exigir. Separe DTO de domínio quando isso proteger o modelo.
- **Repositories:** mantenha protocolo + implementação concreta; o ViewModel depende do protocolo. Inclua somente operações usadas e doubles determinísticos para testes/previews.
- **Services:** use isolamento explícito para estado compartilhado, `async/await` estruturado e erros tipados. `Sendable` é uma garantia de segurança, não um marcador decorativo.
- **Performance:** mantenha `body` barato, identidade estável e estado estreito. Trate otimizações como hipóteses até medi-las; não use `AnyView`, `UUID()` ou índices para mascarar problemas de identidade.
- **UX:** suporte Dynamic Type, VoiceOver, Reduce Motion/Transparency, RTL, contraste e textos localizáveis. Datas, números e moedas usam `FormatStyle`.

## Fluxos de trabalho

### Criar ou alterar uma feature

1. Defina o contrato e a fonte única de verdade.
2. Construa na ordem Model/DTO → Service/Endpoint → Repository → ViewModel → View/Components → Navigation.
3. Mantenha a composição de dependências no entry point/container; não crie serviços live no `body` ou em previews.
4. Cubra sucesso, vazio, loading, erro, cancelamento e ações destrutivas conforme aplicável.
5. Verifique compilação/análise, testes de lógica, referências de localização e previews isolados.

### Revisar código existente

Organize cada achado por arquivo e linha, com severidade (`bloqueador`, `importante`, `melhoria`), evidência, impacto e correção mínima. Separe problemas confirmados de hipóteses que exigem Instruments ou reprodução. Não faça refatoração estética sem benefício observável.

### Diagnosticar performance

Comece pelo sintoma e código; depois peça uma medição reproduzível. Para problemas persistentes, use SwiftUI Instruments/Time Profiler em Release e aparelho real quando possível, compare a mesma interação antes/depois e só então proponha a correção. Consulte `references/performance.md`.

## Saída esperada

- **Implementação:** resumo curto, arquivos alterados, decisões de disponibilidade, verificações executadas e pendências manuais.
- **Revisão:** achados ordenados por impacto, com linhas, regra, evidência e correção sugerida; omita arquivos sem problema.
- **Diagnóstico:** sintoma, hipóteses code-backed, evidência de trace/métrica, plano priorizado e critério de sucesso.

## Checklist final

- [ ] Deployment target e APIs usadas foram confirmados; nenhum `#available` ou fallback está silenciosamente ausente.
- [ ] Imports correspondem aos tipos usados; snippets não dependem de globals ou singletons não declarados.
- [ ] ViewModels estão no Main Actor, são testáveis por DI e não deixam tarefas/resultados obsoletos atualizarem estado.
- [ ] Nenhuma camada não-View importa `SwiftUI`; erros e textos de usuário têm fronteira/localização apropriada.
- [ ] Views usam controles semânticos, Dynamic Type, identidade estável e previews sem rede/segredos.
- [ ] Performance foi medida quando o pedido era diagnóstico; listas e imagens têm estratégia proporcional ao uso.
- [ ] Rodei a verificação adequada e reportei o que ainda exige Xcode, dispositivo ou revisão humana.

## Exemplos

Consulte somente o cenário mais próximo:

- `examples/example-tela-simples.md` — tela local e estados básicos.
- `examples/example-feature-api.md` — feature completa com API, DI, busca e paginação.
- `examples/example-navegacao.md` — navegação iOS 15 e sheets.
- `examples/example-service-storage.md` — storage seguro e preferências.
- `examples/example-performance-audit.md` — diagnóstico orientado a medição.
- `examples/example-liquid-glass.md` — glass iOS 26 com fallback.
