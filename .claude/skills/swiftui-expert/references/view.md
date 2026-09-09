---
name: view
description: Cria ou revisa uma View SwiftUI iOS 15+ com estado, componentes, navegação, acessibilidade, localização e previews isolados. Use para telas, formulários, listas, estados de loading/erro/vazio ou componentes de UI.
argument-hint: <NomeDaView> (ex: ProductDetail, Profile)
---

# Views SwiftUI

Comece identificando quem possui cada estado e se a tela está dentro de uma navegação existente. Não envolva uma tela filha em um segundo `NavigationView`; o container de composição deve controlar a navegação.

## Ownership e inicialização

- `@State private` para valores locais criados pela View.
- `@StateObject private` para o ViewModel criado pela View; `@ObservedObject` para ViewModel recebido.
- `@Binding` somente quando a criança realmente grava no estado do pai.
- Passe valores, bindings e callbacks estreitos para Components. Um componente com ciclo async próprio merece seu próprio ViewModel.
- Injete dependências reais no composition root. Defaults concretos podem existir apenas quando forem seguros e determinísticos para o produto.

```swift
import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel: ProductListViewModel

    init(viewModel: ProductListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .accessibilityHidden(true)
                    Text("Nenhum produto", comment: "Estado vazio da lista de produtos")
                }
            case .loading:
                ProgressView("Carregando…")
            case .success(let products):
                productList(products)
            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.load() }
                }
            }
        }
        .navigationTitle(Text("Produtos", comment: "Título da lista de produtos"))
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private func productList(_ products: [Product]) -> some View {
        List(products) { product in
            ProductRowView(product: product)
        }
    }
}
```

O componente de estado vazio acima é compatível com iOS 15. Em targets iOS 17+, `ContentUnavailableView` pode ser adotado atrás de uma decisão de disponibilidade. O restante do exemplo assume que `ProductListViewModel` tem os métodos correspondentes.

## Views e componentes

Mantenha `body` como descrição estrutural. Extraia um `View` quando houver branching/layout significativo, estado ou ciclo de vida próprio, dependências mais estreitas, preview útil ou complexidade que oculte o fluxo do pai. Uma computed `some View` pequena e sem estado continua adequada.

Passe dados nesta ordem de menor para maior acoplamento:

1. `let` imutável;
2. callback (`() -> Void` ou async quando apropriado);
3. `@Binding`;
4. `@ObservedObject` de um modelo realmente pertencente ao componente.

Evite `AnyView` para branching comum; use `@ViewBuilder`, `Group` ou uma subview concreta. Não injete um ViewModel pai apenas para ler um campo.

## Estados e ações

- O `switch` deve tratar todos os casos de `ViewState`.
- Loading inicial, refresh e paginação devem ter affordances diferentes quando o conteúdo já existe.
- Ações longas começam em `.task`, `.task(id:)`, `.refreshable` ou `Task` criado dentro de uma closure síncrona de botão. Não use `Task` manual em `onAppear` sem guardar/cancelar sua referência.
- Ações destrutivas usam `.confirmationDialog` e `Button(role: .destructive)`; erros acionáveis informam como tentar novamente.
- Use `Button`, `Toggle`, `Picker`, `TextField` e `Link` em vez de transformar uma imagem ou `HStack` em controle com gesto.

## Layout, acessibilidade e localização

- Prefira stacks, `List`/lazy containers e alinhamentos `.leading`/`.trailing`; evite tamanhos fixos para texto.
- Use estilos de fonte do sistema ou fonte customizada relativa a um estilo. Teste Dynamic Type e layouts em largura estreita.
- Dê rótulo a controles de ícone, esconda imagens decorativas e agrupe apenas quando isso melhorar a leitura do VoiceOver.
- Respeite Reduce Motion, Reduce Transparency, contraste e diferenciação sem cor. Um alvo de toque confortável é parte do design.
- Passe literais diretamente a `Text`/`Button`/`Label` para String Catalogs; use `FormatStyle` para datas, números e moedas. Veja `references/accessibility.md` e `references/localization.md`.

## Previews

Previews devem montar ViewModels com Repository/Service fake local e nunca executar rede, Keychain real ou banco de produção. Cubra estados significativos (`success`, vazio, loading, erro) com fixtures determinísticas. `#Preview` exige o toolchain correspondente; em projetos anteriores use `PreviewProvider` sem mudar o deployment target.

## Checklist

- [ ] A View não cria dependências live em `body`/preview nem aninha `NavigationView` sem necessidade.
- [ ] Ownership (`@State`, `@StateObject`, `@ObservedObject`, `@Binding`) corresponde ao ciclo de vida real.
- [ ] `ViewState` é exaustivo; refresh/paginação preservam conteúdo quando adequado.
- [ ] Todas as ações são controles semânticos, com labels, hints e roles apropriados.
- [ ] Texto, números e datas respeitam localização, RTL e Dynamic Type.
- [ ] Listas têm identidade estável e trabalho pesado fora do `body`.
- [ ] Previews são isolados, deterministicamente reproduzíveis e cobrem os estados pedidos.
- [ ] APIs posteriores ao iOS 15 estão isoladas conforme `references/availability.md`.
