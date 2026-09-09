# Modernização do TraceAR — Parte 3: Editor de desenho

> **Objetivo da parte:** editor com folha de papel sobre fundo grafite, toolbar inferior própria, undo/redo que refletem o estado real do canvas, nomear em sheet no lugar do alert quebrado e guarda de alterações não salvas.
> **Plano:** `00-indice.md` (Design de Origem, ordem e dependências)
> **Depende de:** partes 1 e 2 concluídas

## Contexto

O `PaintView` atual tem três defeitos de fluxo. Os botões de undo/redo ficam sempre habilitados porque ninguém observa o `undoManager` — o toque simplesmente não faz nada quando não há o que desfazer. O alert de nomear coloca `TextField` e botões dentro de um `VStack`, container que o builder de alert do SwiftUI não suporta, então o layout é imprevisível. E o botão com ícone de borracha chama `canvasView.drawing.strokes.removeAll()`, apagando o desenho inteiro sem confirmação — a borracha de verdade já existe dentro do `PKToolPicker`. Somado a isso, sair da tela com traços não salvos descarta o trabalho em silêncio.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `PaintAR/src/views/paint/viewModel/PaintViewModel.swift` | criar | Modo novo/edição, salvar, validar nome, rastrear alterações |
| `PaintAR/src/views/paint/components/DrawingCanvasView.swift` | criar | `UIViewRepresentable` + `Coordinator: PKCanvasViewDelegate` publicando `canUndo`/`canRedo`/`isEmpty` |
| `PaintAR/src/views/paint/components/PaintToolbar.swift` | criar | Toolbar inferior com as ações do editor |
| `PaintAR/src/views/paint/components/NamePaintSheet.swift` | criar | Sheet de nomear com foco automático e validação |
| `PaintAR/src/views/paint/PaintView.swift` | reescrever | Composição da tela, guarda de saída, navegação para a RA |
| `PaintARTests/PaintViewModelTests.swift` | criar | Salvar novo, atualizar existente, validação e alterações não salvas |
| `PaintAR/src/core/Localizable.xcstrings` | editar | Chaves novas do editor em pt-BR e en |

## Fases

### Fase 1 — Testes do PaintViewModel (contrato antes da implementação)

> Os testes vão falhar inicialmente — isso é intencional.

- [ ] Criar `PaintARTests/PaintViewModelTests.swift` reusando `InMemoryPaintRepository` de `PaintARTests/Support/`
- [ ] Testar o modo novo: `save(drawingData:)` com nome válido chama `create` uma vez e devolve o `Paint`; nome vazio ou só com espaços é rejeitado sem chamar o repositório; nome é aparado antes de gravar
- [ ] Testar o modo edição: `save(drawingData:)` chama `updateDrawing(id:drawingData:)` e nunca `create`; nome existente é preservado, sem pedir nome de novo
- [ ] Testar alterações não salvas: `hasUnsavedChanges` é falso na abertura, verdadeiro depois de `markDirty()`, e volta a falso após salvar com sucesso; erro do repositório mantém `hasUnsavedChanges` verdadeiro e publica mensagem de erro
- [ ] Verificação: `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PaintARTests test` compila e falha nas asserções novas

### Fase 2 — PaintViewModel

- [ ] Criar `PaintAR/src/views/paint/viewModel/PaintViewModel.swift` como `@MainActor @Observable final class PaintViewModel` com `enum Mode { case new, editing(Paint) }`, `private(set) var isSaving`, `private(set) var hasUnsavedChanges`, `var errorMessage: String?` e `init(mode: Mode, repository: PaintRepository)`
- [ ] Implementar `save(drawingData:name:) async -> Paint?` com a bifurcação `create`/`updateDrawing`, `markDirty()` e `func trimmedNameIsValid(_:) -> Bool`
- [ ] Verificação: a suíte `-only-testing:PaintARTests` passa inteira

### Fase 3 — Canvas com estado observável

- [ ] Criar `PaintAR/src/views/paint/components/DrawingCanvasView.swift`: `UIViewRepresentable` sobre `PKCanvasView` com `drawingPolicy = .anyInput`, fundo `Theme.paper`, `minimumZoomScale`/`maximumZoomScale` preservados, e `PKToolPicker` controlado por binding
- [ ] No `Coordinator: PKCanvasViewDelegate`, implementar `canvasViewDrawingDidChange` alimentando um `@Observable final class CanvasState` com `canUndo`, `canRedo` e `isEmpty` (lendo `canvasView.undoManager`), e chamando o `onChange` que marca o ViewModel como sujo
- [ ] Carregar o desenho existente em `makeUIView` via `PKDrawing(data: paint.drawingData)`, sem `onAppear` — some o `canvasInit()` chamado em cada aparição da tela
- [ ] Verificação: build limpo e `grep -n "canvasViewDrawingDidChange" PaintAR/src/views/paint/components/DrawingCanvasView.swift` retorna a implementação do delegate

### Fase 4 — Tela do editor

- [ ] Criar `PaintAR/src/views/paint/components/PaintToolbar.swift`: barra inferior em `.safeAreaInset(edge: .bottom)` com undo, redo (ambos `.disabled` pelo `CanvasState`), alternar `PKToolPicker`, **Limpar**, **Ver em RA** e **Salvar**, usando `Theme` e ícones SF Symbols com `.symbolEffect` no toque
- [ ] Criar `PaintAR/src/views/paint/components/NamePaintSheet.swift`: `TextField` com `@FocusState` focado na abertura, `.presentationDetents([.height(220)])`, botão de salvar desabilitado enquanto o nome aparado estiver vazio e `submitLabel(.done)`
- [ ] Reescrever `PaintAR/src/views/paint/PaintView.swift`: fundo `Theme.backgroundGradient`, canvas como folha de papel com sombra e `Theme.Radius.card`, `.toolbarBackground`/`.toolbarColorScheme` coerentes com o fundo escuro, e `PaintViewModel` como `@State`
- [ ] Trocar o botão de borracha por **Limpar** com `.confirmationDialog` antes de esvaziar os traços, deixando a borracha real para o `PKToolPicker`
- [ ] Adicionar a guarda de saída: `.interactiveDismissDisabled(viewModel.hasUnsavedChanges)` e botão de voltar próprio que abre `.confirmationDialog` com Descartar / Continuar editando quando houver alterações pendentes
- [ ] Acrescentar em `PaintAR/src/core/Localizable.xcstrings` as chaves do editor (limpar, confirmar limpeza, descartar alterações, continuar editando, nome inválido, erro ao salvar) em pt-BR e en
- [ ] Verificação: build limpo; `grep -n "undoManager" PaintAR/src/views/paint/PaintView.swift` não retorna nada — o acesso ao undo fica encapsulado no componente; `grep -rn "strokes.removeAll" PaintAR/src/views/paint/` só aparece dentro do fluxo de confirmação; `python3 -c "import json;d=json.load(open('PaintAR/src/core/Localizable.xcstrings'));[print(k) for k,v in d['strings'].items() if set(v.get('localizations',{})) != {'pt-BR','en'}]"` não lista nenhuma chave do editor
- [ ] Checkpoint: commit das mudanças da parte + resumo curto do que ficou pronto, seguindo direto para a parte 4

## Critérios de Sucesso

- [ ] Undo e redo ficam desabilitados quando não há o que desfazer ou refazer
- [ ] Nomear um desenho novo acontece em sheet, não em alert com container
- [ ] Limpar o canvas exige confirmação
- [ ] Sair com traços não salvos pede confirmação
- [ ] Build sem erros
- [ ] Todos os testes unitários passando
- [ ] _(manual — feito pelo usuário)_ Validação funcional no app: desenhar com dedo e com Apple Pencil, salvar, reabrir e continuar editando

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `PKToolPicker` disputar espaço com a toolbar inferior própria | Alta | A toolbar recua para fora da tela enquanto o tool picker está visível; alternar o picker é uma das ações da própria toolbar |
| `undoManager` do `PKCanvasView` ser nulo antes do canvas virar first responder | Média | `CanvasState` parte de `canUndo`/`canRedo` falsos e é atualizado no primeiro `canvasViewDrawingDidChange`, sem forçar unwrap |
| Guarda de saída bloquear o gesto de voltar do sistema e irritar em vez de proteger | Média | A confirmação só aparece quando `hasUnsavedChanges` é verdadeiro, e "Descartar" é a primeira opção do diálogo |

## Rollback

`git revert` do commit do checkpoint. Partes 1 e 2 permanecem.
