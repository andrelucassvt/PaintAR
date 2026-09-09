# Modernização do TraceAR — Parte 2: Design system e home redesenhada

> **Objetivo da parte:** a home vira galeria em grid com identidade "studio escuro", miniaturas cacheadas em vez de um `PKCanvasView` por card, busca por nome, menu de contexto e transição zoom para o editor.
> **Plano:** `00-indice.md` (Design de Origem, ordem e dependências)
> **Depende de:** parte 1 concluída

## Contexto

A home atual empilha cards de 300 pt de altura numa `LazyVStack`, cada um instanciando um `PKCanvasView` inteiro só para exibir traço estático. O `NavigationLink` externo disputa o toque com um `onTapGesture` interno e com um `navigationDestination(isPresented:)` declarado dentro de célula lazy; o `frame(width: .infinity, height: 50)` do botão de adicionar usa `.infinity` como largura fixa, o que não é um valor de layout válido. Não há identidade visual, nem estados vazio/erro nativos, nem animação de transição.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `PaintAR/src/core/design/Theme.swift` | criar | Paleta grafite/papel/acento, raios, sombras, gradiente de fundo |
| `PaintAR/src/core/design/Motion.swift` | criar | Curvas de mola padrão, com colapso sob Reduce Motion |
| `PaintAR/Assets.xcassets/AccentColor.colorset/Contents.json` | editar | Acento alinhado ao `Theme` |
| `PaintAR/src/core/DrawingThumbnailStore.swift` | criar | Render de `PKDrawing` em `UIImage` com cache por id |
| `PaintAR/src/views/home/viewModel/HomeViewModel.swift` | reescrever | `@MainActor @Observable`, `HomeState`, busca, delete, rename, import |
| `PaintAR/src/views/home/HomeView.swift` | reescrever | Grid, header, estados nativos, busca, botão fixo, transição zoom |
| `PaintAR/src/views/home/components/PaintCard.swift` | criar | Card de papel com miniatura, nome, data e menu de contexto |
| `PaintAR/src/views/home/components/ImportSheet.swift` | criar | Sheet de import com `fileImporter` |
| `PaintAR/src/views/home/components/HomeCardPaint.swift` | remover | Substituído por `PaintCard` |
| `PaintARTests/HomeViewModelTests.swift` | criar | Estados, busca, delete, rename e import contra repositório falso |
| `PaintARTests/Support/InMemoryPaintRepository.swift` | criar | Duplo de teste determinístico do `PaintRepository` |

## Fases

### Fase 1 — Tokens de design

- [x] Criar `PaintAR/src/core/design/Theme.swift`: `enum Theme` com `graphite`, `graphiteElevated`, `paper`, `accentInk`, `textPrimary`, `textSecondary`; `static var backgroundGradient: LinearGradient`; `enum Radius` (card, sheet, control) e `struct CardShadow` (raio, opacidade, offset)
- [x] Criar `PaintAR/src/core/design/Motion.swift`: `enum Motion` com `cardAppear`, `listChange`, `sheet` como `Animation`, mais `static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation?` devolvendo `nil` quando Reduce Motion está ligado
- [x] Atualizar `PaintAR/Assets.xcassets/AccentColor.colorset/Contents.json` com o valor de `Theme.accentInk` nas variantes any/dark
- [x] Verificação: build passou em 2026-09-09; `Theme.swift` tem 12 ocorrências dos seis tokens e `Motion.swift` contém `respecting(`

### Fase 2 — Testes do HomeViewModel (contrato antes da implementação)

> Os testes vão falhar inicialmente — isso é intencional.
>
> **Drift registrado (2026-09-09):** adaptadores temporários para `load()`, `delete(_:)`, `rename(_:to:)` e `importFile(at:)` foram introduzidos no ViewModel antes dos testes, pois as assinaturas da parte 3 ainda não existiam após a parte 1. A fase 3 os substitui pela implementação final.
>
> **Estabilização de testes (2026-09-09):** `PaintMappingTests` e `PaintRepositoryTests` foram agrupados sob `PersistenceTests` com `.serialized`, pois stores Core Data em memória abertas simultaneamente provocavam erro intermitente de configuração do modelo. A suíte passou duas vezes em sequência após o agrupamento.

- [x] Criar `PaintARTests/Support/InMemoryPaintRepository.swift`: implementação do `PaintRepository` sobre array, com `var failNextCall: Error?` para forçar o caminho de erro
- [x] Criar `PaintARTests/HomeViewModelTests.swift` e testar: `load()` parte de `.loading` e termina em `.loaded` com os itens do repositório; repositório vazio termina em `.loaded([])`; erro do repositório termina em `.error`; `load()` após erro volta a `.loaded` (retry funciona)
- [x] Testar busca: `searchText` filtrando por nome sem diferenciar maiúsculas/minúsculas nem acentos; texto sem correspondência devolve lista vazia sem sair de `.loaded`
- [x] Testar mutações: `delete(paint)` remove do estado e chama o repositório uma vez; `rename(paint, to:)` atualiza o nome no estado; nome só com espaços é rejeitado sem chamar o repositório; `importFile(at:)` com JSON válido acrescenta o item e publica alerta de sucesso; JSON inválido publica alerta de erro e mantém a lista
- [x] Verificação: a suíte compila e falha somente nas três asserções do comportamento ainda não implementado (busca normalizada, rejeição de nome vazio e preservação da lista em import inválido); 19 testes passam em 2026-09-09

### Fase 3 — HomeViewModel

- [x] Reescrever `PaintAR/src/views/home/viewModel/HomeViewModel.swift` como `@MainActor @Observable final class HomeViewModel` com `private(set) var state: HomeState` (`.loading`/`.loaded([Paint])`/`.error(String)`), `var searchText`, `var visiblePaints: [Paint]` derivado do filtro, `var activeAlert: ActiveAlert?` e `init(repository: PaintRepository, fileService: PaintFileService)`
- [x] Implementar `load()`, `delete(_:)`, `rename(_:to:)` e `importFile(at:)` como `async`, sem `DispatchQueue`, atualizando o estado otimisticamente em delete/rename e revertendo quando o repositório lançar
- [x] Remover o `fetchPaints()` do `init` — a carga passa a ser disparada por `.task` na View
- [x] Verificação: a suíte `-only-testing:PaintARTests` passa inteira em 2026-09-09 (22 testes)

### Fase 4 — Miniaturas

- [x] Criar `PaintAR/src/core/DrawingThumbnailStore.swift`: `@MainActor @Observable final class DrawingThumbnailStore` com `NSCache<NSUUID, UIImage>`, `func thumbnail(for paint: Paint, size: CGSize) async -> UIImage?` que retorna o cache ou renderiza via `PKDrawing(data:)` + `image(from:scale:)` num `Task.detached(priority: .utility)`, e `func invalidate(id:)` chamado após editar/renomear
- [x] Recortar a renderização pelo `drawing.bounds` real (não pelo bounds do canvas) e aplicar `.aspectRatio(contentMode: .fit)` no consumo, para traço pequeno não sumir na miniatura
- [x] Verificação: `rg -n "PKCanvasView" PaintAR/src/views/home/` não retornou nada em 2026-09-09 — nenhum canvas vivo sobra na home

### Fase 5 — Grid, card e sheet de import

- [x] Criar `PaintAR/src/views/home/components/PaintCard.swift`: retângulo de papel (`Theme.paper`, `Theme.Radius.card`, `CardShadow`) com a miniatura, nome e data via `Text(paint.date, format: .relative(presentation: .named))`, e `.contextMenu` com Ver em RA (stub até a parte 4), Editar, Renomear, Exportar (`ShareLink` sobre a URL de `PaintFileService`) e Excluir (`role: .destructive`)
- [x] Criar `PaintAR/src/views/home/components/ImportSheet.swift` com o `fileImporter` de `.json` e `.presentationDetents([.height(280)])`, movendo para cá o conteúdo do `importSheetView` atual
- [x] Reescrever `PaintAR/src/views/home/HomeView.swift`: `NavigationStack` sobre `Theme.backgroundGradient`, header com título e contagem, `LazyVGrid` de duas colunas com `PaintCard`, `.searchable(text: $viewModel.searchText)`, botão **Desenhar** em `.safeAreaInset(edge: .bottom)`, `.task { await viewModel.load() }` e `.refreshable`
- [x] Cobrir os estados com `ContentUnavailableView`: sem desenhos (com botão de criar o primeiro), busca sem resultado (`.search`) e erro (com botão de tentar de novo)
- [x] Em `PaintAR/src/views/home/HomeView.swift` e `components/PaintCard.swift`, aplicar as animações: `.scrollTransition` de opacidade/escala nos cards, `matchedTransitionSource(id:in:)` no card com `.navigationTransition(.zoom(sourceID:in:))` no destino `PaintView`, `Motion.listChange` na remoção e `.symbolEffect(.bounce)` no botão de importar
- [x] Remover `PaintAR/src/views/home/components/HomeCardPaint.swift` e, com ele, o `onTapGesture` concorrente e o `navigationDestination(isPresented:)` dentro de célula lazy
- [x] Verificação: build limpo em 2026-09-09 e `rg -n "onTapGesture|width: \\.infinity" PaintAR/src/views/home/` não retornou nada
- [x] Checkpoint: commit das mudanças da parte + resumo curto do que ficou pronto; execução pausada após a parte 2 conforme solicitado pelo usuário

## Critérios de Sucesso

- [x] A home usa uma única rota de navegação por card — nenhum gesto concorrendo com `NavigationLink`
- [x] Nenhum `PKCanvasView` é instanciado na home
- [x] Vazio, busca sem resultado e erro usam `ContentUnavailableView`
- [x] Build sem erros
- [x] Todos os testes unitários passando
- [ ] _(manual — feito pelo usuário)_ Validação funcional no app: rolagem da galeria fluida com muitos desenhos, transição zoom do card para o editor, e comportamento em Reduce Motion

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `PKDrawing.image(from:scale:)` não ser seguro fora do main actor | Média | Se o build ou o runtime acusarem restrição de isolamento, renderizar no main actor mantendo o cache — o ganho principal já vem de não instanciar `PKCanvasView` por card |
| Cache de miniatura mostrar imagem velha após editar | Média | `invalidate(id:)` chamado no retorno do editor e após renomear, coberto pela chave `id` do `NSCache` |
| Traço branco sobre papel branco ficar invisível na miniatura | Baixa | O card desenha sobre `Theme.paper`, igual ao fundo do canvas do editor — a miniatura reproduz exatamente o que o usuário vê ao desenhar |

## Rollback

`git revert` do commit do checkpoint. A parte 1 permanece, então a persistência corrigida não é perdida.
