# Testes e previews

Testes devem provar contratos de estado e efeitos; previews devem revelar estados visuais sem rede ou infraestrutura de produção. O framework de teste deste repositório é Swift Testing (`@Suite`, `@Test`, `#expect`) quando o toolchain disponível o suporta.

## Swift Testing

```swift
import Testing

@MainActor
@Suite("ProductListViewModel")
struct ProductListViewModelTests {
    @Test("carrega produtos")
    func loadSuccess() async {
        let repository = StubProductRepository(result: .success(.mockList))
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.load()

        if case .success(let products) = viewModel.state {
            #expect(products == Product.mockList)
        } else {
            #expect(Bool(false), "expected success state")
        }
    }
}
```

Adapte helpers ao projeto; não invente propriedades como `matchesSuccess` sem implementá-las. Teste sucesso, vazio, erro tipado, cancelamento, retry, stale-result, paginação e ações independentes. Suites que acessam ViewModels `@MainActor` devem respeitar esse isolamento. Não compartilhe mocks mutáveis entre testes paralelos; use fixture nova por caso ou desabilite paralelismo quando o contrato exigir.

Para callbacks/eventos assíncronos, use confirmações do Swift Testing em vez de sleeps arbitrários. Controle tempo e debounce por uma dependência injetável quando testes precisarem ser rápidos e determinísticos.

## Previews isolados

- Construa o ViewModel com Repository/Service fake; nunca chame API, Keychain, UserDefaults global ou banco real.
- Cubra estados loading, sucesso, vazio, erro e uma variação de conteúdo longa. Inclua dependências de environment necessárias.
- Use `#Preview` no Xcode compatível; em toolchains anteriores use `PreviewProvider` sem elevar o deployment target.
- Sobrescreva locale, Dynamic Type, color scheme e acessibilidade nas previews relevantes.
- Mantenha fixtures estáticas ou factories determinísticas; não use `Date()`, `UUID()` aleatório, credenciais ou assets remotos.

## Verificação

- [ ] Testes de lógica executam sem rede e cobrem a transição de estado, não apenas uma propriedade final.
- [ ] Cancelamento não gera falha falsa nem deixa tarefa vazando.
- [ ] Mocks permitem sucesso, erro, atraso/cancelamento e registro de chamadas quando necessário.
- [ ] Previews abrem com dependências completas e mostram estados relevantes.
- [ ] Toolchain/target usados pelo teste foram registrados; nenhuma API de preview posterior está sem disponibilidade.
