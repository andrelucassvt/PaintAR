# PaintAR (TraceAR)

App iOS nativo em SwiftUI onde o usuário desenha com PencilKit, salva os desenhos em Core Data e projeta o traçado em Realidade Aumentada (ARKit + SceneKit) para usar como guia de decalque. Desenhos podem ser exportados e importados como JSON.

## Stack

- Swift 5.0 / SwiftUI, **mínimo iOS 16** (target `PaintAR`); iPhone e iPad
- PencilKit (`PKCanvasView`, `PKToolPicker`), ARKit + SceneKit (`ARSCNView`, `SCNPlane`), Core Data
- Workspace CocoaPods (`PaintAR.xcworkspace`) — abra sempre o **workspace**, nunca o `.xcodeproj`
- Testes unitários com **Swift Testing** (`import Testing`, `@Test`, `#expect`); `PaintARUITests` usa XCTest
- Idiomas suportados: `pt-BR` (origem) e `en`, em `PaintAR/src/core/Localizable.xcstrings`

## Estrutura

- `PaintAR/AppDelegate.swift` — `@main struct PaintARApp`, injeta `managedObjectContext` e abre `HomeView`
- `PaintAR/src/views/<feature>/` — uma pasta por feature (`home`, `paint`, `paintAR`)
- `PaintAR/src/views/home/viewModel/` — ViewModels; `PaintAR/src/views/home/components/` — subviews da feature
- `PaintAR/src/data/` — `CoreDataController` (CRUD) e `ShareFileController` (export JSON / share sheet)
- `PaintAR/src/domain/model/` — `extension PaintEntity` e `PaintModelJson` (Codable de import/export)
- `PaintAR/src/core/` — `Paints.xcdatamodeld` e `Localizable.xcstrings`
- `PaintARTests/`, `PaintARUITests/` — alvos de teste
- `.claude/skills/`, `.github/skills/`, `.agents/skills/` — skills espelhadas, sincronizadas por `sync-instructions.sh`

## Comandos

- `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'generic/platform=iOS' build` — compila o app
- `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` — roda os testes (ajuste o `name` para um simulador de `xcrun simctl list devices available`)
- `pod install` — regenera o workspace após alterar o `Podfile`
- `./sync-instructions.sh` — atualiza as instruções e skills espelhadas

## Convenções

- Idioma: Português Brasileiro em documentação e comentários; **inglês** em nomes de código
- Nomenclatura: Views `*View`, ViewModels `*ViewModel`, componentes com nome próprio (`HomeCardPaint`), extensions `Type+Context`
- Estado assíncrono em ViewModel é enum de estado (padrão de `HomeState`: `.loading` / `.loaded([T])` / `.error(String)`), nunca booleans avulsos
- ViewModels importam apenas `Foundation`/`CoreData` — `import SwiftUI` só em Views
- Dependências injetadas pelo `init` com valor padrão (`init(coreDataController: CoreDataController = .shared)`)
- Toda string de UI passa por `LocalizedStringKey` e existe no `Localizable.xcstrings` nos dois idiomas
- Componentes com identidade própria vivem em `views/<feature>/components/` e recebem dados via `let` e callbacks (`onDelete`, `onRefresh`), nunca o ViewModel do pai
- Arquivo de feature acima de ~300 linhas deve ser quebrado em componentes
- Navegação: `NavigationStack` + `NavigationLink`/`navigationDestination` (iOS 16); a lista se atualiza pelo `viewModel.fetchPaints()` no `onDisappear` do destino

## Gotchas

- **Instâncias paralelas de Core Data:** `PaintARApp`, `PaintView` e `HomeCardPaint` criam `CoreDataController()` próprio enquanto `HomeViewModel` usa `CoreDataController.shared` — cada instância abre seu próprio `NSPersistentContainer`. Ao mexer em persistência, prefira `CoreDataController.shared`.
- **Atributos de `PaintEntity` são todos opcionais** no `Paints.xcdatamodeld` (`id`, `name`, `date`, `drawing`), e o código atual usa force unwrap (`paintEntity.drawing!`). Em código novo, faça unwrap seguro.
- **Deployment target divergente:** o nível de projeto está em 18.2 e o target do app em 16.0. O mínimo efetivo do app é **iOS 16** — valide disponibilidade de API por esse número.
- **`HomeViewModel` não é `@MainActor`** e usa `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` como atraso artificial em `fetchPaints`, `deletePaint` e `handleError`.
- **Import de JSON** espera `date` no formato `"yyyy-MM-dd HH:mm:ss Z"` (locale `en_US_POSIX`, GMT) e `drawing` em Base64 — o mesmo formato gerado por `ShareFileController.exportPaintEntityAsJson`.
- **AdMob configurado mas não integrado:** `GADApplicationIdentifier` e `SKAdNetworkItems` estão no `Info.plist`, sem SDK correspondente no `Podfile` nem no `Package.resolved`.
- O `Podfile` não declara nenhum pod; `keychain-swift` está resolvido via SwiftPM mas não é importado por nenhum arquivo.

## Não fazer

- Não abra nem construa pelo `PaintAR.xcodeproj` — use `PaintAR.xcworkspace`
- Não edite arquivos em `Pods/` nem os `Target Support Files`
- Não escreva testes novos em XCTest no alvo `PaintARTests` — use Swift Testing
- Não adicione strings de UI direto no código sem entrada correspondente no `Localizable.xcstrings`
- Não faça upgrade de dependências nem `pod update` sem pedido explícito

## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique a pasta `./docs/flow/`: leia os títulos dos arquivos `.md` disponíveis e, se algum for relevante para a tarefa atual, leia-o antes de implementar ou debugar. Invoque a skill `flow` para criar ou atualizar flows individuais.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validar o resultado (rodar o app, emulador/simulador, dispositivo físico, servidor local, screenshots ou interação simulada). Teste funcional/visual é responsabilidade do usuário.

- Limite a verificação a análise estática, build/compile e testes automatizados
- Ao concluir, liste objetivamente o que o usuário deve testar manualmente
- Não pergunte se deve executar o projeto — só faça isso se o usuário pedir explicitamente
