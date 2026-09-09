---
generated_at: 2026-09-09
source_commit: 7993058
source_state: clean
verified_at: 2026-09-09
status: current
related_plans: []
---

# Sugestões de Flows a Documentar

> Gerado em 2026-09-09. Invoque a skill `flow` para criar qualquer um destes flows.

## Flows Sugeridos

### Home — listagem de desenhos
**Arquivo a criar:** `docs/flow/home.md`
**Resumo:** Do `PaintARApp` abrindo `HomeView` até `HomeViewModel.fetchPaints()` buscar os `PaintEntity` via `CoreDataController.fetchAllPaints()`, ordenar por data e alimentar os estados `.loading`/`.loaded`/`.error`, incluindo empty state, pull-to-refresh e o refetch disparado no `onDisappear` dos destinos de navegação.

---

### Paint — criar e editar desenho
**Arquivo a criar:** `docs/flow/paint.md`
**Resumo:** Da entrada em `PaintView` (com ou sem `PaintEntity`) até a gravação: configuração do `PKCanvasView`/`PKToolPicker` em `DrawingView`, undo/redo e borracha, alerta de nome, e a bifurcação entre `CoreDataController.savePaint` (novo) e `updatePaint` (existente) usando `canvasView.drawing.dataRepresentation()`.

---

### PaintAR — projeção do traçado em RA
**Arquivo a criar:** `docs/flow/paint-ar.md`
**Resumo:** Do `NavigationLink` em `PaintView` passando o `PKCanvasView` para `PaintAR` → `ARViewContainer` → `ViewController`, até o `ARSCNView` renderizar o desenho como textura de um `SCNPlane` (aspect ratio, `textureCache`, sessão `ARWorldTrackingConfiguration`) e os gestos de pinça, arrasto e rotação manipularem o `planeNode`.

---

### Card do desenho — ações do item na home
**Arquivo a criar:** `docs/flow/home-card-actions.md`
**Resumo:** Do menu do `HomeCardPaint` até cada efeito: preview somente leitura em `DrawingViewContainer`, `ShareLink` com a URL de `ShareFileController.exportPaintEntityAsJson`, renomear via `CoreDataController.updatePaint`, excluir via callback `onDelete` → `HomeViewModel.deletePaint`, e editar via `navigationDestination` para `PaintView`.

---

### Import/Export — desenhos em JSON
**Arquivo a criar:** `docs/flow/import-export.md`
**Resumo:** Nos dois sentidos: export serializando `PaintEntity` (com `drawing` em Base64) num arquivo temporário em `ShareFileController`; import pelo `fileImporter` da sheet da home até `HomeViewModel.addImportFile`, com acesso security-scoped, decode de `PaintModelJson`, validação de data e Base64, criação do `PaintEntity` e alertas de sucesso/erro.

---

### Persistência Core Data
**Arquivo a criar:** `docs/flow/core-data.md`
**Resumo:** Da definição de `PaintEntity` em `Paints.xcdatamodeld` e do `convenience init` em `PaintModel.swift` até o ciclo de vida do `NSPersistentContainer` em `CoreDataController`, cobrindo `saveContext`, o singleton `shared` e as instâncias paralelas criadas por `PaintARApp`, `PaintView` e `HomeCardPaint`.

## Já documentados

- `docs/flow/project-structure.md` — Estrutura geral do projeto
