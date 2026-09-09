---
generated_at: 2026-09-09
source_commit: 377fd14
source_state: dirty
verified_at: 2026-09-09
status: current
related_plans:
  - docs/plan/modernizacao-tracear/00-indice.md
---

# Sugestões de Flows a Documentar

> Gerado em 2026-09-09 e reconciliado com a modernização do TraceAR. Invoque a skill `flow` para criar qualquer um destes flows.

## Flows Sugeridos

### Home — galeria de desenhos

**Arquivo a criar:** `docs/flow/home.md`
**Resumo:** Do `PaintARApp` injetando `CoreDataPaintRepository` em `HomeView` até `HomeViewModel.load()` buscar os `Paint`, aplicar busca sem distinção de caixa ou acento, e atualizar a galeria, a exclusão, o rename e a importação.

---

### Paint — criar e editar desenho

**Arquivo a criar:** `docs/flow/paint.md`
**Resumo:** Da entrada em `PaintView` até `PaintViewModel.save`: `DrawingCanvasView` encapsula o PencilKit, `CanvasState` publica undo/redo e traços, e o ViewModel persiste criação ou atualização com confirmação para limpar e sair.

---

### PaintAR — projeção do traçado em RA

**Arquivo a criar:** `docs/flow/paint-ar.md`
**Resumo:** Da `ARTraceView(drawing:)` aberta pelo editor ou card até `ARTraceSceneController` configurar o `ARSCNView`, detectar superfícies, posicionar por raycast e aplicar escala/rotação acumulativas, opacidade, lock e recenter.

---

### Card do desenho — ações da galeria

**Arquivo a criar:** `docs/flow/home-card-actions.md`
**Resumo:** Do menu de contexto de `PaintCard` a cada efeito: abrir RA direto a partir de `paint.drawingData`, navegar para o editor, renomear e excluir pelo `HomeViewModel`, ou compartilhar o arquivo gerado por `PaintFileService`.

---

### Import/Export — desenhos em JSON

**Arquivo a criar:** `docs/flow/import-export.md`
**Resumo:** Exportação por `PaintFileService.export` e importação pelo `fileImporter` de `ImportSheet`: o arquivo troca `PaintExchangeModel`, valida data/Base64 e é persistido por `PaintRepository.importPaint`.

---

### Persistência Core Data

**Arquivo a criar:** `docs/flow/core-data.md`
**Resumo:** Do schema opcional `PaintEntity` à conversão segura para `Paint`, passando pelo único `PersistenceController` e por `CoreDataPaintRepository`, que executa CRUD em contextos de background.

## Já documentados

- `docs/flow/project-structure.md` — Estrutura e dependências atuais do app.
