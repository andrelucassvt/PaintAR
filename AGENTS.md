# PaintAR (TraceAR)

App iOS nativo em SwiftUI onde o usuário desenha com PencilKit, salva os desenhos em Core Data e projeta o traçado em Realidade Aumentada (ARKit + SceneKit) como guia de decalque. Desenhos podem ser exportados e importados em JSON.

## Stack

- Swift 5.0 / SwiftUI, **mínimo iOS 18.0** (target `PaintAR`); iPhone e iPad
- PencilKit (`PKCanvasView`, `PKToolPicker`), ARKit + SceneKit (`ARSCNView`, `SCNPlane`), Core Data
- Workspace CocoaPods (`PaintAR.xcworkspace`) — abra e construa sempre pelo **workspace**, nunca pelo `.xcodeproj`
- Estado por Observation: `@Observable`, `@State` e `@Bindable`; ViewModels `@MainActor`
- Testes unitários com **Swift Testing** (`import Testing`, `@Test`, `#expect`); `PaintARUITests` usa XCTest
- Idiomas: `pt-BR` (origem) e `en`, em `PaintAR/src/core/Localizable.xcstrings`

## Estrutura

- `PaintAR/PaintARApp.swift` — `@main`, monta `CoreDataPaintRepository` sobre `PersistenceController.shared` e abre `HomeView`
- `PaintAR/src/views/<feature>/` — features `home`, `paint` e `paintAR`; componentes ficam em `components/`, ViewModels em `viewModel/`
- `PaintAR/src/data/` — `PersistenceController`, `CoreDataPaintRepository` e `PaintFileService`
- `PaintAR/src/domain/model/` — `Paint`, `PaintExchangeModel` e `PaintError`
- `PaintAR/src/domain/repository/` — protocolo `PaintRepository`
- `PaintAR/src/core/design/` — `Theme` e `Motion`; `core/` também contém cache, modelo Core Data e strings
- `PaintARTests/`, `PaintARUITests/` — alvos de teste

## Comandos

- `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'generic/platform=iOS' build` — compila o app
- `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` — roda os testes (ajuste o simulador conforme `xcrun simctl list devices available`)
- `pod install` — regenera o workspace após alterar o `Podfile`

## Convenções

- Documentação e comentários em Português Brasileiro; nomes de código em inglês
- Views terminam em `View`, ViewModels em `ViewModel`; componentes recebem dados por `let`, bindings ou callbacks estreitos, nunca o ViewModel pai
- ViewModels são `@MainActor @Observable final class`, importam Foundation e Observation, dependem de protocolos e recebem dependências pelo `init`
- Estado assíncrono principal usa enum de estado (como `HomeState`); flags podem representar operações independentes e contextuais, como `isSaving` e `hasUnsavedChanges`
- O domínio usa `Paint`; Views e ViewModels não recebem `PaintEntity`
- Toda string de UI passa por `LocalizedStringKey` e deve existir em `Localizable.xcstrings` nos dois idiomas
- Navegação usa `NavigationStack` + `NavigationLink`/`navigationDestination`; entradas de RA em tela cheia usam `fullScreenCover`
- A RA recebe apenas um `PKDrawing`; `ARTraceSceneController` mantém ARKit/SceneKit fora das Views SwiftUI
- Arquivos de feature acima de aproximadamente 300 linhas devem ser quebrados em componentes

## Gotchas

- **Container único de Core Data:** apenas `PersistenceController.shared` cria o container; acesse dados pelo `PaintRepository`, nunca crie um container ou contexto diretamente numa View.
- **Atributos opcionais no schema:** `PaintEntity` ainda declara `id`, `name`, `date` e `drawing` como opcionais. Use `Paint.init?(entity:)` e unwrap seguro para dados legados incompletos.
- **Import/export congelado:** o JSON usa `id`/`name`/`date`/`drawing`, data `yyyy-MM-dd HH:mm:ss Z` com locale `en_US_POSIX`/GMT e desenho Base64.
- **RA exige aparelho físico compatível:** build e testes cobrem a matemática de transformação, mas câmera, raycast, coaching e gestos requerem validação manual no hardware.
- **AdMob sem SDK:** `GADApplicationIdentifier` e `SKAdNetworkItems` existem no `Info.plist`, porém Google Mobile Ads não é dependência do projeto.
- **Dependência SwiftPM sem uso:** `keychain-swift` está resolvido, mas não há `import KeychainSwift`.
- **Nome do produto:** o bundle permanece `PaintAR`, enquanto a interface apresenta `TraceAR`.

## Não fazer

- Não abra nem construa pelo `PaintAR.xcodeproj`; use `PaintAR.xcworkspace`
- Não edite arquivos em `Pods/` nem em `Target Support Files`
- Não escreva testes novos em XCTest no alvo `PaintARTests`; use Swift Testing
- Não adicione texto de UI sem a entrada correspondente no catálogo de strings
- Não faça upgrade de dependências nem `pod update` sem pedido explícito

## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique os títulos em `./docs/flow/`; leia o documento relevante antes de implementar ou depurar. Use a skill `flow` para criar ou atualizar flows individuais e mantenha o campo `related_plans` dos documentos alterados.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validação funcional/visual (app, simulador, dispositivo, screenshots ou interação simulada). Limite a verificação a análise estática, build/compile e testes automatizados.

Ao concluir, liste objetivamente o que o usuário deve testar manualmente. Não pergunte se deve executar o projeto; só faça isso se houver pedido explícito.
