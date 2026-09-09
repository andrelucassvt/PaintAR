# Modernização do TraceAR — Índice

> **Objetivo:** Entregar o TraceAR em iOS 18 com identidade visual "studio escuro", animações nativas e fluxo fluido, sobre uma camada de dados única que faz a edição de desenhos voltar a persistir — mantendo a premissa de desenhar no PencilKit e projetar o traçado em RA.
> **Design de origem:** brainstorming desta conversa
> **Flows relacionados:** `docs/flow/project-structure.md`, `docs/flow/flow-suggestions.md`

## Contexto

O app funciona, mas três problemas se somam. **Persistência quebrada:** `PaintView` e `HomeCardPaint` criam um `CoreDataController()` próprio e mutam um `PaintEntity` que pertence ao contexto do `.shared`; o `saveContext()` roda no container privado, que não tem alterações, e não grava nada — editar ou renomear um desenho parece funcionar em memória e some ao reabrir o app. **Fluxo com atrito:** atrasos artificiais de 0,5 s nos estados da home, `onTapGesture` competindo com `NavigationLink`, `navigationDestination` declarado dentro de célula lazy e um `PKCanvasView` completo instanciado por card só para exibir traço estático. **Visual datado:** layout padrão sem identidade, sem animação de transição e com estados vazio/erro improvisados.

A RA, que é a premissa do app, hoje só existe dentro do editor e tem gestos que saltam de volta ao valor inicial a cada novo toque.

## Design de Origem

- **Decisão aprovada:** reescrever as três telas (home, paint, paintAR) sobre uma camada de dados única — `PersistenceController` + `PaintRepository` protocolar + ViewModels `@MainActor @Observable` expondo a struct de domínio `Paint` — com deployment target iOS 18 e identidade visual "studio escuro" (fundo grafite, cards de papel branco, acento único), corrigindo junto os bugs de persistência, de gestos de RA e de navegação.
- **Alternativas descartadas:** `@FetchRequest` direto nas Views — elimina os ViewModels e o padrão de enum de estado exigido pelo `AGENTS.md`, acopla a View a `NSManagedObject` (traz de volta os force unwraps) e deixa import/export sem camada onde morar.
- **Tipo de mudança:** Logic

## Partes

| # | Arquivo | Entrega | Delegável | Depende de | Status |
|---|---------|---------|-----------|-----------|--------|
| 1 | `01-fundacao-dados.md` | App em iOS 18 sobre um único container Core Data; editar e renomear voltam a persistir de verdade, com as telas atuais intactas | não — abre o contrato `PaintRepository` que as partes 2–4 consomem | — | concluída |
| 2 | `02-home-redesenhada.md` | Galeria em grid com identidade "studio escuro", miniaturas cacheadas, busca, menu de contexto e transição zoom para o editor | não — a evidência de conclusão do redesenho é validação visual do usuário, não automatizável | 1 | pendente |
| 3 | `03-editor-paint.md` | Editor com folha de papel, toolbar própria, undo/redo reativo, sheet de nomear e guarda de alterações não salvas | não — parte da verificação é visual e ela edita `Localizable.xcstrings`, também tocado pela parte 4 | 1, 2 | pendente |
| 4 | `04-realidade-aumentada.md` | RA acessível direto do card, gestos acumulativos corretos, HUD de opacidade/travar/recentrar, ancoragem por toque; localização e flows atualizados | não — exige câmera e validação manual em dispositivo | 1, 2, 3 | pendente |

## Riscos e Mitigações (globais)

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Subir o deployment target de 16 para 18 corta usuários em aparelhos antigos | Alta (é uma decisão, não um acidente) | Decisão explícita do usuário no brainstorming; `MARKETING_VERSION` sobe para 2.0.0 para sinalizar a quebra |
| Desenhos gravados antes da mudança param de abrir | Baixa | O `Paints.xcdatamodeld` não muda — nenhuma migração de schema; o `init?(entity:)` apenas descarta entidade sem `drawing`, em vez de quebrar com force unwrap |
| Arquivos JSON já compartilhados por usuários param de importar | Média | O formato de troca (chaves `id`/`name`/`date`/`drawing`, data em `"yyyy-MM-dd HH:mm:ss Z"`, drawing em Base64) é congelado e coberto por teste de round-trip na parte 1 |
| Novos arquivos `.swift` não entrarem no target do Xcode | Baixa | O `project.pbxproj` usa `PBXFileSystemSynchronizedRootGroup` (`objectVersion = 77`): tudo sob `PaintAR/` e `PaintARTests/` entra no target automaticamente, sem editar o pbxproj |

## Rollback (global)

Cada parte termina em um commit próprio. Reverter uma parte é `git revert` do commit correspondente, na ordem inversa da numeração. A parte 1 é a única com efeito sobre dados do usuário e mesmo assim não altera o schema Core Data, então reverter não corrompe a store existente.
