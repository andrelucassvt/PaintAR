# Modernização do TraceAR — Parte 4: Realidade aumentada, localização e documentação

> **Objetivo da parte:** projetar o traçado em RA com gestos que não saltam, HUD de opacidade/travar/recentrar, ancoragem por toque na superfície e acesso direto pelo card da galeria — fechando com o catálogo de strings limpo e os flows atualizados.
> **Plano:** `00-indice.md` (Design de Origem, ordem e dependências)
> **Depende de:** partes 1, 2 e 3 concluídas

## Contexto

A RA é a premissa do app e hoje é a parte mais frágil. `handlePinch` faz `node.scale = SCNVector3(scale, scale, scale)` com a escala **absoluta** do gesto e depois zera `gesture.scale` em `.ended`, então cada novo pinça recomeça de 1.0 e o desenho salta de volta ao tamanho original; `handleRotation` tem o mesmo defeito com `eulerAngles.z`. O plano nasce fixo em `SCNVector3(0, 0.1, -0.8)` sem forma de recentrar, `planeDetection` está desligado, não há aviso em aparelho sem suporte a `ARWorldTrackingConfiguration`, e a tela só é alcançável de dentro do editor porque recebe o `PKCanvasView` vivo. O tipo `PaintAR` ainda colide com o nome do módulo.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `PaintAR/src/views/paintAR/ARTraceTransform.swift` | criar | Funções puras de escala e rotação acumulativas, com limites |
| `PaintAR/src/views/paintAR/ARTraceSceneController.swift` | criar | `UIViewControllerRepresentable` + controller do `ARSCNView`, gestos e raycast |
| `PaintAR/src/views/paintAR/ARTraceOverlay.swift` | criar | HUD SwiftUI de opacidade, travar, recentrar e fechar |
| `PaintAR/src/views/paintAR/ARTraceView.swift` | criar | Tela que compõe cena + HUD e trata aparelho sem suporte |
| `PaintAR/src/views/paintAR/PaintAR.swift` | remover | Substituído pelos arquivos acima; o tipo colidia com o nome do módulo |
| `PaintAR/src/views/home/components/PaintCard.swift` | editar | "Ver em RA" do menu de contexto deixa de ser stub |
| `PaintAR/src/views/paint/PaintView.swift` | editar | Abre a RA passando `PKDrawing`, não o `PKCanvasView` |
| `PaintARTests/ARTraceTransformTests.swift` | criar | Acúmulo e limites de escala e rotação |
| `PaintAR/src/core/Localizable.xcstrings` | editar | Chaves da RA em pt-BR e en; remoção das entradas vazias |
| `AGENTS.md` | editar | Stack, estrutura, convenções e gotchas pós-modernização |
| `docs/flow/project-structure.md` | editar | Documento de estrutura reconciliado com o código novo |
| `docs/flow/flow-suggestions.md` | editar | Resumos que citam arquivos e APIs renomeados |

## Fases

### Fase 1 — Testes das transformações (contrato antes da implementação)

> Os testes vão falhar inicialmente — isso é intencional.

- [x] Criar `PaintARTests/ARTraceTransformTests.swift`
- [x] Testar escala acumulativa: dois gestos de pinça de fator 2 partindo de 1.0 resultam em 4.0 — o segundo gesto não recomeça do valor base (é o teste que fixa o bug atual)
- [x] Testar limites: escala é presa entre 0.05 e 5.0 em ambos os extremos
- [x] Testar rotação acumulativa: rotações sucessivas somam ao ângulo base e o resultado é normalizado para o intervalo de -π a π
- [x] Verificação: antes da implementação, os testes não compilavam pela ausência intencional de `ARTraceTransform`; após a Fase 2, `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PaintARTests test` passou integralmente.

### Fase 2 — Cena de RA

- [x] Criar `PaintAR/src/views/paintAR/ARTraceTransform.swift` com `enum ARTraceTransform` e as funções puras `scale(base:gesture:)` e `rotation(base:gesture:)` que os testes exercitam
- [x] Criar `PaintAR/src/views/paintAR/ARTraceSceneController.swift`: controller recebendo `PKDrawing` (não `PKCanvasView`), montando o `SCNPlane` com a textura gerada do `drawing.bounds`, `planeDetection = [.horizontal, .vertical]` e `ARCoachingOverlayView` com `goal = .anyPlane`
- [x] Reescrever os gestos capturando `baseScale`/`baseRotation` em `.began` e aplicando `ARTraceTransform` em `.changed`; travar pan, pinça e rotação quando `isLocked` estiver ativo
- [x] Adicionar toque simples com `raycastQuery(from:allowing:.estimatedPlane, alignment:.any)` para reposicionar o plano na superfície apontada, com fallback para a posição fixa a 0,8 m quando não houver resultado
- [x] Expor `setOpacity(_:)`, `setLocked(_:)` e `recenter()` para o HUD, e pausar a sessão em `viewWillDisappear` como já acontece hoje
- [x] Verificação: a suíte `-only-testing:PaintARTests` passa inteira e `grep -n "gesture.scale = 1.0" PaintAR/src/views/paintAR/` não retorna nada

### Fase 3 — HUD e entradas

- [x] Criar `PaintAR/src/views/paintAR/ARTraceOverlay.swift`: controles sobre a câmera em `.ultraThinMaterial` com slider de opacidade (0,1–1,0), botão de travar/destravar, recentrar e fechar, aparecendo com `Motion.sheet` e recolhíveis para não tapar o traçado
- [x] Criar `PaintAR/src/views/paintAR/ARTraceView.swift` compondo cena + HUD, com `ContentUnavailableView` quando `ARWorldTrackingConfiguration.isSupported` for falso, e remover `PaintAR/src/views/paintAR/PaintAR.swift`
- [x] Em `PaintAR/src/views/paint/PaintView.swift`, abrir `ARTraceView(drawing:)` a partir do desenho corrente do canvas, em vez de passar o `PKCanvasView`
- [x] Em `PaintAR/src/views/home/components/PaintCard.swift`, ligar "Ver em RA" a `ARTraceView(drawing:)` construído de `paint.drawingData`, dando o atalho da galeria direto para a premissa do app
- [x] Verificação: build limpo e `grep -rn "PKCanvasView" PaintAR/src/views/paintAR/` não retorna nada

### Fase 4 — Localização

- [x] Acrescentar em `PaintAR/src/core/Localizable.xcstrings` as chaves da RA (opacidade, travar, destravar, recentrar, toque para posicionar, procurando superfície, RA indisponível neste aparelho) em pt-BR e en
- [x] Remover as entradas sem uso e sem tradução do catálogo: `""`, `Key`, `nameApp`, `Paint`, `Try Again`, `Error`, `Error: %@`, `OK`, `yourSure`, e corrigir a chave `sucess`
- [x] Verificação: `python3 -c "import json;d=json.load(open('PaintAR/src/core/Localizable.xcstrings'));bad=[k for k,v in d['strings'].items() if set(v.get('localizations',{})) != {'pt-BR','en'}];print(bad);assert not bad"` passa, e cada chave restante aparece em pelo menos um `.swift` sob `PaintAR/src/`

### Fase 5 — Atualizar flows e instruções

- [x] Atualizar `docs/flow/project-structure.md`: Stack e Tecnologias (iOS 18, `@Observable`), Arquitetura (repositório protocolar, ViewModels de Home e Paint; controller UIKit dedicado à RA), Features, Camadas / Módulos Compartilhados, Configuração e a tabela de dependências
- [x] Reescrever a seção "Observações" do mesmo arquivo: os itens de force unwrap, instâncias paralelas de Core Data, `HomeViewModel` sem `@MainActor` e testes vazios deixam de existir; registrar o que ficou (AdMob configurado sem SDK, `keychain-swift` resolvido e não importado, nome do produto `PaintAR` vs. título `TraceAR`)
- [x] Atualizar em `docs/flow/flow-suggestions.md` os resumos de Home, Paint, PaintAR, Card do desenho, Import/Export e Persistência, que citam `CoreDataController`, `ShareFileController`, `PaintModelJson` e `HomeCardPaint`
- [x] Atualizar `AGENTS.md`: iOS mínimo 18, seção Estrutura com `domain/repository/` e `core/design/`, convenções de `@Observable` e injeção por protocolo, e substituir os gotchas resolvidos pelos que continuam válidos
- [x] Verificação: `grep -rn "CoreDataController\|ShareFileController\|PaintModelJson\|HomeCardPaint\|iOS 16" AGENTS.md docs/flow/` não retorna nada
- [x] Checkpoint: commit das mudanças da parte + resumo curto do que ficou pronto e do que resta para validação manual

## Critérios de Sucesso

- [x] Escala e rotação acumulam entre gestos, comprovado por teste
- [x] A RA abre direto do card da galeria, sem passar pelo editor
- [x] Aparelho sem suporte a `ARWorldTrackingConfiguration` mostra aviso em vez de tela preta
- [x] Nenhuma chave de `Localizable.xcstrings` fica sem pt-BR e en
- [x] `AGENTS.md` e `docs/flow/` descrevem o código que existe
- [x] Build sem erros
- [x] Todos os testes unitários passando
- [ ] _(manual — feito pelo usuário)_ Validação funcional no app: apontar a câmera para uma superfície, posicionar o traçado, escalar, girar, travar e usar como guia de decalque

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Nada de RA é verificável sem dispositivo físico | Alta | A lógica testável é extraída para `ARTraceTransform` como funções puras; o resto entra explicitamente na lista de validação manual entregue ao usuário |
| `planeDetection` ligado aumentar o consumo em cena sem plano detectável | Média | A ancoragem por raycast tem fallback para posição fixa, então o app segue utilizável mesmo sem plano; `isLightEstimationEnabled` permanece desligado |
| Remover chaves do catálogo apagar alguma ainda referenciada | Média | A verificação da Fase 4 confere cada chave restante contra os `.swift` antes do commit |

## Rollback

`git revert` do commit do checkpoint. As partes 1–3 permanecem e o app continua utilizável sem a RA reformada.

## Registro de execução

- O contrato de teste foi escrito antes da implementação, mas a ausência proposital do símbolo provocou erro de compilação, e não falha de asserção; a suíte completa passou depois da Fase 2.
- O flow registra a arquitetura efetiva: Home e Paint usam ViewModels `@Observable`; RA é uma composição SwiftUI com controller UIKit, sem camada de ViewModel artificial.
- Restam somente os cenários de RA que exigem câmera e superfície física, listados no critério manual abaixo.

## Após a Implementação

> Perguntar ao usuário: "Deseja criar um flow dessa funcionalidade em `./docs/flow/`? Ele documenta o caminho completo do fluxo e serve de referência para futuros planos e revisões." — os candidatos já listados em `docs/flow/flow-suggestions.md` são `home.md`, `paint.md`, `paint-ar.md`, `import-export.md` e `core-data.md`.
