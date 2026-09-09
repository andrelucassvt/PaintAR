---
generated_at: 2026-09-09
source_commit: 377fd14
source_state: dirty
verified_at: 2026-09-09
status: current
related_plans:
  - docs/plan/modernizacao-tracear/00-indice.md
---

# Estrutura do Projeto: PaintAR (TraceAR)

> **Resumo:** App iOS de desenho que cria e persiste traços PencilKit, organiza-os numa galeria e os projeta em Realidade Aumentada como guia de decalque, com importação e exportação em JSON.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Swift 5.0 (`SWIFT_VERSION = 5.0`) |
| Framework | SwiftUI (`App`) com UIKit por `UIViewRepresentable` e `UIViewControllerRepresentable` |
| Plataforma | iOS 18.0; iPhone e iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Estado de apresentação | Observation (`@Observable`, `@State`, `@Bindable`) em Home e Paint; `@State` e controller UIKit na cena de RA |
| Frameworks Apple | SwiftUI, PencilKit, Core Data, ARKit, SceneKit, UIKit, Foundation |
| Gerenciadores | CocoaPods (`platform :ios, '18.0'`, sem pods) e SwiftPM (`Package.resolved`) |
| Workspace | `PaintAR.xcworkspace` — contém o projeto e Pods; é a entrada de build |
| Testes | Swift Testing em `PaintARTests`; XCTest somente em `PaintARUITests` |
| Produto | Bundle `com.andre.PaintAR`, versão 2.0.0 (build 6) |

## Arquitetura

O composition root em `PaintAR/PaintARApp.swift` cria `CoreDataPaintRepository` sobre o único `PersistenceController.shared` e o injeta em `HomeView`. A Home usa `HomeViewModel` para buscar, filtrar, excluir, renomear e importar `Paint` por meio do protocolo `PaintRepository`; as Views recebem structs de domínio, não `PaintEntity`.

O editor cria `PaintViewModel` com o mesmo repositório e recebe o `PKCanvasView` encapsulado em `DrawingCanvasView`. O `CanvasState` é a ponte de UI para o estado de undo, redo e desenho atual. A projeção de RA recebe apenas um `PKDrawing`: `ARTraceView` controla o HUD e atualiza o `ARTraceSceneController`, que hospeda o `ARSCNView` e aplica os gestos.

```
PaintARApp
  └─ HomeView → HomeViewModel → PaintRepository
        │                         └─ CoreDataPaintRepository → PersistenceController → Paints.xcdatamodeld
        ├─ PaintCard → ARTraceView → ARTraceSceneController → ARKit / SceneKit
        └─ PaintView → PaintViewModel → PaintRepository
              └─ DrawingCanvasView / CanvasState → PencilKit
```

### Regras de dependência

- Views importam SwiftUI e os frameworks visuais específicos; ViewModels importam Foundation e Observation, sem SwiftUI.
- `domain/model/` e `domain/repository/` expressam o contrato de dados; a implementação Core Data fica em `data/`.
- `PersistenceController` é a única origem de `NSPersistentContainer`; apenas `CoreDataPaintRepository` cria contextos de background.
- A RA não acessa persistência nem ViewModels: recebe um snapshot `PKDrawing` do editor ou do card.

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| Home | `src/views/home/` | Galeria em grid com busca, importação, ações de card e navegação para criar ou editar. |
| Card do desenho | `src/views/home/components/PaintCard.swift` | Mostra miniatura cacheada e oferece RA direta, editar, renomear, exportar e excluir. |
| Paint | `src/views/paint/` | Editor PencilKit com folha de papel, toolbar própria, nome em sheet, confirmação de limpeza e guarda de alterações não salvas. |
| PaintAR | `src/views/paintAR/` | Projeta um `PKDrawing` como plano SceneKit, detecta planos, permite raycast, opacidade, lock e recenter. |
| Importação e exportação | `ImportSheet`, `PaintFileService` | Decodifica e exporta o formato JSON estável com data e desenho em Base64. |
| Persistência | `CoreDataPaintRepository`, `PersistenceController` | Executa CRUD e importação em contextos Core Data de background. |

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Dados | `PaintAR/src/data/` | `PersistenceController`, `CoreDataPaintRepository` e `PaintFileService`. |
| Domínio | `PaintAR/src/domain/model/`, `PaintAR/src/domain/repository/` | `Paint`, DTO de troca, erros tipados e o protocolo de persistência. |
| Design e recursos | `PaintAR/src/core/design/`, `PaintAR/src/core/` | Tema, animações, cache de miniaturas, catálogo de strings e modelo Core Data. |
| Componentes de UI | `views/*/components/` | Componentes de Home e Paint com valores, bindings e callbacks estreitos. |
| Testes | `PaintARTests/` | Repositório in-memory, mapeamento, formato de troca, Home, Paint e transformações da RA. |

## Configuração

| Componente | Arquivo | Responsabilidade |
|------------|---------|-----------------|
| Entry point | `PaintAR/PaintARApp.swift` | Monta o repositório de produção e abre `HomeView`. |
| Persistência | `PaintAR/src/data/PersistenceController.swift` | Carrega `Paints`, expõe o contexto de View e contextos de background; registra falha de carregamento em `loadError`. |
| Dados | `PaintAR/src/core/Paints.xcdatamodeld/` | Define `PaintEntity` com `id`, `name`, `date` e `drawing`, todos opcionais no schema. |
| Localização | `PaintAR/src/core/Localizable.xcstrings` | Catálogo pt-BR/en para toda a interface. |
| Permissões | `PaintAR.xcodeproj/project.pbxproj` | Declara o texto de uso da câmera para RA. |
| Dependências | `Podfile`, `Package.resolved` | Mantêm a configuração CocoaPods e o pacote SwiftPM resolvido. |

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| `evgenyneu/keychain-swift` | 24.0.0 | Resolvido por SwiftPM, mas não importado pelo app. |
| CocoaPods | 1.16.2 | Workspace configurado sem pods declarados. |

## Observações

- `PaintEntity` permanece com atributos opcionais por compatibilidade do schema; `Paint.init?(entity:)` descarta registros incompletos em vez de usar force unwrap.
- A configuração de AdMob e SKAdNetwork continua no `Info.plist`, mas não há SDK do Google Mobile Ads configurado.
- `keychain-swift` continua resolvido sem uso no código.
- O bundle e o nome técnico são `PaintAR`, enquanto a interface apresenta o produto como `TraceAR`.
- A validação da câmera, do raycast e dos gestos em RA exige aparelho físico compatível; os limites e o acúmulo de transformações têm cobertura unitária em `ARTraceTransformTests`.
