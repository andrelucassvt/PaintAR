# Modernização do TraceAR — Parte 1: Fundação de dados

> **Objetivo da parte:** app rodando em iOS 18 sobre um único container Core Data, com domínio, repositório protocolar e serviço de arquivo testados — e a edição/renomeação de desenhos voltando a gravar de verdade, sem ainda mexer no layout das telas.
> **Plano:** `00-indice.md` (Design de Origem, ordem e dependências)
> **Depende de:** nenhuma

## Contexto

`CoreDataController` é instanciado quatro vezes no app (`PaintARApp`, `HomeViewModel` via `.shared`, `PaintView`, `HomeCardPaint`), e cada instância abre seu próprio `NSPersistentContainer`. `PaintView.updatePaint` e o rename de `HomeCardPaint` mutam um `PaintEntity` que pertence ao contexto do `.shared` e depois chamam `saveContext()` no container privado — que não tem alterações e retorna sem gravar. Esta parte elimina a classe de bug na raiz e estabelece o contrato que as partes 2–4 consomem.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `PaintAR.xcodeproj/project.pbxproj` | editar | `IPHONEOS_DEPLOYMENT_TARGET` unificado em 18.0; `MARKETING_VERSION` 2.0.0 |
| `Podfile` | editar | `platform :ios, '18.0'` |
| `PaintAR/src/data/PersistenceController.swift` | criar | Único `NSPersistentContainer("Paints")`, contexto de background, variante in-memory para testes/previews |
| `PaintAR/src/domain/model/Paint.swift` | criar | `struct Paint` + `init?(entity:)` com unwrap seguro dos atributos opcionais |
| `PaintAR/src/domain/model/PaintExchangeModel.swift` | criar | `Codable` do JSON de import/export, com o formato de data congelado |
| `PaintAR/src/domain/model/PaintError.swift` | criar | Erros tipados de domínio |
| `PaintAR/src/domain/repository/PaintRepository.swift` | criar | Protocolo `async` consumido pelos ViewModels |
| `PaintAR/src/data/CoreDataPaintRepository.swift` | criar | Implementação Core Data em contexto de background |
| `PaintAR/src/data/PaintFileService.swift` | criar | Export para URL temporária e decode de arquivo importado |
| `PaintAR/src/data/CoreDataController.swift` | remover | Substituído por `PersistenceController` + repositório |
| `PaintAR/src/data/ShareFileController.swift` | remover | Substituído por `PaintFileService` |
| `PaintAR/src/domain/model/PaintModel.swift` | remover | `PaintModelJson` vira `PaintExchangeModel`; o `convenience init` migra para `Paint.swift` |
| `PaintARTests/PaintMappingTests.swift` | criar | Mapeamento entidade → domínio |
| `PaintARTests/PaintExchangeTests.swift` | criar | Round-trip do JSON de troca |
| `PaintARTests/PaintRepositoryTests.swift` | criar | CRUD e import sobre store in-memory |
| `PaintARTests/PaintARTests.swift` | remover | Scaffold vazio (`@Test func example()` sem asserção) |
| `PaintAR/AppDelegate.swift` | editar | Vira `PaintARApp.swift`; injeta o repositório e descarta o `AppDelegate` sem lógica |
| `PaintAR/src/views/home/viewModel/HomeViewModel.swift` | editar | Passa a falar com `PaintRepository`; sai o `DispatchQueue.main.asyncAfter(… + 0.5)` |
| `PaintAR/src/views/paint/PaintView.swift` | editar | Salvar/atualizar via repositório (adaptação mínima, sem redesenho) |
| `PaintAR/src/views/home/components/HomeCardPaint.swift` | editar | Rename e export via repositório/serviço (adaptação mínima, sem redesenho) |

## Fases

### Fase 1 — Target iOS 18 e container único

- [ ] Em `PaintAR.xcodeproj/project.pbxproj`, trocar todo `IPHONEOS_DEPLOYMENT_TARGET = 16.0` e `= 18.2` por `= 18.0` (target do app, targets de teste e nível de projeto) e `MARKETING_VERSION` do target `PaintAR` de `1.0.5` para `2.0.0`
- [ ] Em `Podfile`, trocar `platform :ios, '16.0'` por `platform :ios, '18.0'` e rodar `pod install`
- [ ] Criar `PaintAR/src/data/PersistenceController.swift`: `final class PersistenceController`, `static let shared`, `init(inMemory: Bool = false)` (com `NSPersistentStoreDescription(url: /dev/null)` quando in-memory), `viewContext.automaticallyMergesChangesFromParent = true`, `viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy`, `func newBackgroundContext()` e, no lugar do `fatalError`, um erro logado guardado em `loadError`
- [ ] Verificação: `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'generic/platform=iOS' build` compila e `grep -rn "IPHONEOS_DEPLOYMENT_TARGET" PaintAR.xcodeproj/project.pbxproj` só retorna `18.0`

### Fase 2 — Contratos (assinaturas antes dos testes)

> Em Swift, um teste que referencia tipo inexistente não compila — então os tipos e o protocolo nascem aqui com corpo mínimo, e os testes da Fase 3 falham por asserção, não por erro de compilação.

- [ ] Criar `PaintAR/src/domain/model/Paint.swift`: `struct Paint: Identifiable, Hashable, Sendable` com `id: UUID`, `name: String`, `date: Date`, `drawingData: Data`; `init?(entity: PaintEntity)` retornando `nil` se `id`, `name`, `date` ou `drawing` forem nulos; e o `convenience init` de `PaintEntity` migrado de `PaintModel.swift`
- [ ] Criar `PaintAR/src/domain/model/PaintExchangeModel.swift`: `struct PaintExchangeModel: Codable` com as chaves atuais `id`/`name`/`date`/`drawing`, `static let dateFormatter` em `"yyyy-MM-dd HH:mm:ss Z"` / `en_US_POSIX` / GMT, `init(paint:)` e `func toPaint() throws -> Paint`
- [ ] Criar `PaintAR/src/domain/model/PaintError.swift`: `enum PaintError: LocalizedError` com `invalidDate`, `invalidDrawingData`, `notFound`, `persistenceFailed(String)`
- [ ] Criar `PaintAR/src/domain/repository/PaintRepository.swift`: `protocol PaintRepository: Sendable` com `fetchAll() async throws -> [Paint]`, `create(name:drawingData:) async throws -> Paint`, `updateDrawing(id:drawingData:) async throws`, `rename(id:to:) async throws`, `delete(id:) async throws` e `importPaint(_ model: PaintExchangeModel) async throws -> Paint`
- [ ] Criar `PaintAR/src/data/CoreDataPaintRepository.swift` e `PaintAR/src/data/PaintFileService.swift` com as assinaturas públicas e corpos `throw PaintError.notFound` / `fatalError("não implementado")`
- [ ] Verificação: `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'generic/platform=iOS' build` compila com os arquivos novos, e `grep -c "func " PaintAR/src/domain/repository/PaintRepository.swift` retorna 6 — o protocolo tem as seis operações que os testes da Fase 3 vão exercitar

### Fase 3 — Testes (contrato antes da implementação)

> Os testes vão falhar inicialmente — isso é intencional.

- [ ] Remover `PaintARTests/PaintARTests.swift` (scaffold sem asserção)
- [ ] Criar `PaintARTests/PaintMappingTests.swift`: entidade completa vira `Paint` com os mesmos valores; entidade com `drawing` nulo retorna `nil`; entidade com `name` nulo retorna `nil`
- [ ] Criar `PaintARTests/PaintExchangeTests.swift`: round-trip `Paint → PaintExchangeModel → Paint` preserva id/nome/data/bytes; decodificar um JSON fixo no formato exportado hoje (`"2025-02-28 12:00:00 +0000"`, drawing em Base64) produz o `Paint` esperado; data em formato inválido lança `PaintError.invalidDate`; Base64 inválido lança `PaintError.invalidDrawingData`
- [ ] Criar `PaintARTests/PaintRepositoryTests.swift` sobre `PersistenceController(inMemory: true)`: `create` seguido de `fetchAll` devolve o item; `fetchAll` vem ordenado por data decrescente; `rename` **persiste em um contexto novo** (o teste que pega o bug atual); `updateDrawing` troca os bytes e atualiza a data; `delete` remove; `delete` de id inexistente lança `notFound`; `importPaint` grava e devolve o `Paint`
- [ ] Verificação: `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PaintARTests test` compila e falha nas asserções (não em erro de sintaxe ou símbolo ausente)

### Fase 4 — Implementação do repositório

- [ ] Implementar `CoreDataPaintRepository` em `PaintAR/src/data/CoreDataPaintRepository.swift`: cada operação em `context.perform` sobre `newBackgroundContext()`, `fetchAll` com `NSSortDescriptor(keyPath: \PaintEntity.date, ascending: false)` mapeando por `Paint(entity:)` e descartando os `nil`, escrita sempre seguida de `context.save()`
- [ ] Implementar `PaintFileService` em `PaintAR/src/data/PaintFileService.swift`: `export(_ paint: Paint) throws -> URL` gravando `JSONEncoder` com `.prettyPrinted` em `FileManager.default.temporaryDirectory` com nome derivado do `paint.name` saneado (fallback `desenho.json` para nome vazio), e `decode(fileAt url: URL) throws -> PaintExchangeModel` com `startAccessingSecurityScopedResource`/`stopAccessing` em `defer`
- [ ] Remover `PaintAR/src/data/CoreDataController.swift`, `PaintAR/src/data/ShareFileController.swift` e `PaintAR/src/domain/model/PaintModel.swift`
- [ ] Verificação: `xcodebuild -workspace PaintAR.xcworkspace -scheme PaintAR -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PaintARTests test` passa inteiro

### Fase 5 — Rewire das telas atuais (sem redesenho)

- [ ] Renomear `PaintAR/AppDelegate.swift` para `PaintAR/PaintARApp.swift`: remover a classe `AppDelegate` vazia e o `@UIApplicationDelegateAdaptor`, e construir `CoreDataPaintRepository(persistence: .shared)` uma única vez, passando-o a `HomeView`
- [ ] Em `PaintAR/src/views/home/viewModel/HomeViewModel.swift`: injetar `PaintRepository` pelo `init`, `HomeState` passa a carregar `[Paint]`, `fetchPaints`/`deletePaint` viram `async` sobre o repositório e todos os `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` saem
- [ ] Em `PaintAR/src/views/paint/PaintView.swift` e `PaintAR/src/views/home/components/HomeCardPaint.swift`: trocar `CoreDataController()` por chamadas ao repositório injetado, dentro de `Task`; trocar os force unwraps (`paintEntity.drawing!`, `.name!`, `.date!`, `.id!`) pelos campos não-opcionais de `Paint`
- [ ] Verificação: `grep -rn "CoreDataController\|ShareFileController\|PaintModelJson\|asyncAfter" PaintAR/` não retorna nada, e o build + a suíte `-only-testing:PaintARTests` passam
- [ ] Checkpoint: commit das mudanças da parte + resumo curto do que ficou pronto, seguindo direto para a parte 2

## Critérios de Sucesso

- [ ] `grep -rn "IPHONEOS_DEPLOYMENT_TARGET" PaintAR.xcodeproj/project.pbxproj` retorna apenas `18.0`
- [ ] Nenhum `NSPersistentContainer` é criado fora de `PersistenceController`
- [ ] O teste que renomeia e relê num contexto novo passa — a gravação silenciosamente perdida deixa de acontecer
- [ ] Um JSON no formato exportado pela versão atual do app ainda importa
- [ ] Build sem erros
- [ ] Todos os testes unitários passando
- [ ] _(manual — feito pelo usuário)_ Validação funcional no app: editar um desenho, fechar e reabrir o app, confirmar que a alteração ficou

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `pod install` regenerar o workspace e derrubar configuração | Baixa | O `Podfile` não declara pods; a única mudança é a linha de `platform`. Conferir que `PaintAR.xcworkspace` ainda lista os schemes `PaintAR` e `Pods-PaintAR` |
| As telas antigas ficarem meio-adaptadas e o app não compilar no meio da parte | Média | A Fase 5 é a última e trata as três telas juntas; a verificação dela é o build completo, não o arquivo isolado |
| Nomes de arquivo saneados colidirem no diretório temporário ao exportar | Baixa | Sufixar com os 8 primeiros caracteres do `id` quando o arquivo já existir |

## Rollback

`git revert` do commit do checkpoint. O `Paints.xcdatamodeld` não é tocado, então a store do usuário continua legível pela versão anterior.
