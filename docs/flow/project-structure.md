---
generated_at: 2026-09-09
source_commit: 7993058
source_state: clean
verified_at: 2026-09-09
status: current
related_plans: []
---

# Estrutura do Projeto: PaintAR (TraceAR)

> **Resumo:** App iOS em SwiftUI onde o usuário desenha com PencilKit, salva os desenhos em Core Data e projeta o traçado em Realidade Aumentada (ARKit + SceneKit) para servir de guia de decalque; desenhos também podem ser exportados e importados como JSON.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Swift 5.0 (`SWIFT_VERSION = 5.0`) |
| Framework | SwiftUI (`App` + `@UIApplicationDelegateAdaptor`), com UIKit via `UIViewRepresentable`/`UIViewControllerRepresentable` |
| Plataforma | iOS 16.0 (target `PaintAR`); iPhone e iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Gerenciadores de pacotes | CocoaPods (`Podfile`, `platform :ios, '16.0'`, sem pods declarados) e SwiftPM (`PaintAR.xcworkspace/xcshareddata/swiftpm/Package.resolved`) |
| Frameworks Apple usados | SwiftUI, PencilKit, CoreData, ARKit, SceneKit, UIKit, Foundation |
| Workspace | `PaintAR.xcworkspace` (gerado pelo CocoaPods; abre `PaintAR.xcodeproj` + `Pods`) |
| Bundle ID | `com.andre.PaintAR` — versão `1.0.5` (build `6`) |
| Testes | Swift Testing (`import Testing`, `@Test`) em `PaintARTests`; XCTest UI em `PaintARUITests` |

## Arquitetura

O app é organizado por feature dentro de `PaintAR/src/`, com separação parcial em MVVM. Apenas a feature **home** possui ViewModel (`HomeViewModel`, `ObservableObject` com enum de estado `HomeState`); **paint** e **paintAR** são Views que falam diretamente com a camada de dados ou encapsulam um `UIViewController`. O acesso a dados é feito por *controllers* concretos (`CoreDataController`, `ShareFileController`) — não há protocolo de repositório nem injeção por protocolo; a injeção existente é por valor padrão no `init` (`HomeViewModel(coreDataController: .shared)`).

A navegação é um `NavigationStack` declarado em `HomeView`, com `NavigationLink` para `PaintView` e, de dentro dele, para `PaintAR`. A sincronização de lista após edição é feita por callback: cada destino chama `viewModel.fetchPaints()` no `onDisappear`.

```
views/home (HomeView + HomeViewModel + HomeCardPaint)
        │  NavigationLink
        ▼
views/paint (PaintView → DrawingView/PKCanvasView)
        │  NavigationLink (passa o PKCanvasView)
        ▼
views/paintAR (PaintAR → ARViewContainer → ViewController/ARSCNView)

todas as camadas de tela → data (CoreDataController, ShareFileController) → core (Paints.xcdatamodeld)
```

### Regras de dependência

- `data/` importa apenas `CoreData`/`UIKit`, nunca SwiftUI.
- `domain/model/PaintModel.swift` importa apenas `Foundation` + `CoreData`.
- `HomeViewModel` importa apenas `Foundation` + `CoreData` (sem SwiftUI).
- As Views são as únicas que importam SwiftUI, PencilKit e ARKit.

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| Home (lista de desenhos) | `PaintAR/src/views/home/` | Lista os desenhos salvos ordenados por data, com estados loading/loaded/error, pull-to-refresh, empty state e entrada para criar um novo desenho. |
| Card do desenho (ações do item) | `PaintAR/src/views/home/components/HomeCardPaint.swift` | Miniatura do traçado em `PKCanvasView` somente leitura, com menu de exportar (`ShareLink`), editar, renomear e excluir. |
| Import de desenho (JSON) | `HomeView.importSheetView` + `HomeViewModel.addImportFile` | Sheet com `fileImporter` (`.json`) que decodifica `PaintModelJson`, valida data e Base64 e grava um novo `PaintEntity`. |
| Export/compartilhamento | `PaintAR/src/data/ShareFileController.swift` | Serializa o `PaintEntity` em JSON (com `drawing` em Base64) num arquivo temporário e devolve a URL para `ShareLink`/`UIActivityViewController`. |
| Paint (canvas de desenho) | `PaintAR/src/views/paint/PaintView.swift` | Canvas PencilKit com `PKToolPicker`, undo/redo, borracha, salvar (novo) ou atualizar (existente) e acesso ao modo AR. |
| PaintAR (projeção em RA) | `PaintAR/src/views/paintAR/PaintAR.swift` | Renderiza o desenho como textura de um `SCNPlane` sobre `ARSCNView`, com gestos de pinça (escala), arrasto (posição) e rotação. |
| Persistência Core Data | `PaintAR/src/data/CoreDataController.swift` + `PaintAR/src/core/Paints.xcdatamodeld` | CRUD de `PaintEntity` (id, name, date, drawing) sobre `NSPersistentContainer` chamado `Paints`. |

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Camada de dados | `PaintAR/src/data/` | `CoreDataController` (CRUD + `saveContext`) e `ShareFileController` (export JSON e share sheet). |
| Modelo de domínio | `PaintAR/src/domain/model/PaintModel.swift` | `extension PaintEntity` com `convenience init` e struct `PaintModelJson: Codable` para import/export. |
| Core / recursos | `PaintAR/src/core/` | Modelo Core Data `Paints.xcdatamodeld` e catálogo de strings `Localizable.xcstrings`. |
| Componentes de UI | `PaintAR/src/views/home/components/` | Subviews da home (`HomeCardPaint`, `DrawingViewContainer`). |
| Assets | `PaintAR/Assets.xcassets` | `AppIcon` e `AccentColor`. |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Entry point / Scene | `PaintAR/AppDelegate.swift` | `@main struct PaintARApp: App` — cria `CoreDataController()`, injeta `\.managedObjectContext` e abre `HomeView()` num `WindowGroup`; `AppDelegate` via `@UIApplicationDelegateAdaptor` (sem lógica). |
| Persistência | `PaintAR/src/data/CoreDataController.swift` | `NSPersistentContainer(name: "Paints")` com `fatalError` caso a store não carregue; singleton `CoreDataController.shared`. |
| Modelo de dados | `PaintAR/src/core/Paints.xcdatamodeld/Paints.xcdatamodel/contents` | Entidade `PaintEntity` (codegen `class`): `id: UUID?`, `name: String?`, `date: Date?`, `drawing: Binary?` — todos opcionais. |
| Localização | `PaintAR/src/core/Localizable.xcstrings` | 29 chaves em `pt-BR` (origem) e `en`, consumidas via `LocalizedStringKey`. |
| Permissões | `PaintAR.xcodeproj/project.pbxproj` (`INFOPLIST_KEY_NSCameraUsageDescription`) | Texto de uso da câmera para a experiência de RA. |
| Info.plist adicional | `PaintAR/Info.plist` | `GADApplicationIdentifier` (AdMob) e lista de `SKAdNetworkItems`. |
| Dependências CocoaPods | `Podfile` / `Podfile.lock` | Estrutura de targets pronta, sem nenhum pod declarado (CocoaPods 1.16.2). |
| Instruções de agentes | `AGENTS.md`, `CLAUDE.md`, `.claude/skills/`, `.github/skills/`, `.agents/skills/` | Skills e instruções sincronizadas por `sync-instructions.sh`. |

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| `evgenyneu/keychain-swift` | 24.0.0 (SwiftPM, resolvido no workspace) | Resolvido em `Package.resolved`, mas sem nenhum `import KeychainSwift` no código atual. |
| CocoaPods | 1.16.2 (`Podfile.lock`) | Workspace configurado, sem pods declarados. |

## Observações

- **`AGENTS.md`/`CLAUDE.md` estavam desatualizados:** descreviam este repositório como "repositório de templates de instruções, não um app executável" e citavam arquivos inexistentes (`mvvm-architecture-instructions.md`, `skills-lock.json`, skills `model`/`view`/`repository`/`service`/`navigation`/`performance`/`liquid-glass`). O repositório é o app PaintAR com as skills sincronizadas dentro dele. O `AGENTS.md` foi reescrito a partir do código real nesta inicialização.
- **Deployment target divergente:** o nível de projeto usa `IPHONEOS_DEPLOYMENT_TARGET = 18.2` (e os targets de teste também), enquanto o target do app `PaintAR` usa `16.0` e o `Podfile` declara `platform :ios, '16.0'`. O mínimo efetivo do app é iOS 16.
- **APIs iOS 16+ em uso:** `NavigationStack`, `navigationDestination`, `ShareLink`/`SharePreview` — incompatíveis com a regra "iOS 15 / `NavigationView`" que constava nas instruções antigas.
- **Force unwraps em atributos opcionais:** `paintEntity.drawing!`, `paintEntity.name!`, `paintEntity.date!`, `paintEntity.id!` (em `HomeCardPaint`, `PaintView` e `ShareFileController`) sobre atributos declarados opcionais no modelo Core Data — risco de crash para entidades incompletas ou importadas.
- **Instâncias paralelas de `CoreDataController`:** `PaintARApp`, `HomeCardPaint` e `PaintView` criam `CoreDataController()` próprio, enquanto `HomeViewModel` usa `CoreDataController.shared` — cada instância cria um `NSPersistentContainer` separado, então as escritas de `PaintView`/`HomeCardPaint` só aparecem na lista após o `fetchPaints()` do `onDisappear`.
- **`HomeViewModel` não é `@MainActor`:** usa `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` como atraso artificial em `fetchPaints`, `deletePaint` e `handleError`.
- **AdMob configurado mas não integrado:** `GADApplicationIdentifier` e `SKAdNetworkItems` no `Info.plist` sem SDK do Google Mobile Ads no `Podfile` nem no `Package.resolved`.
- **Testes vazios:** `PaintARTests.swift` contém apenas um `@Test func example()` sem asserções; `PaintARUITests` é o scaffold padrão do Xcode.
- **Nome do produto vs. UI:** o projeto se chama `PaintAR`, mas o título exibido na home é `"TraceAR"`.
