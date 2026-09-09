# Performance SwiftUI

## Table of Contents

- [Princípio](#princípio)
- [Workflow](#workflow)
- [Revisão de código](#revisão-de-código)
- [Listas e identidade](#listas-e-identidade)
- [Estado e invalidação](#estado-e-invalidação)
- [Imagens e layout](#imagens-e-layout)
- [Instruments](#instruments)
- [Checklist](#checklist)

## Princípio

Performance é uma hipótese mensurável. Um `body` grande ou uma coleção extensa merece revisão, mas não prova um gargalo por si só. Evite “otimizações” baseadas em detalhes internos não garantidos; preserve a legibilidade e meça a mesma interação antes e depois.

## Workflow

1. Registre sintoma, tela, ação, aparelho/OS, build configuration e tamanho dos dados.
2. Faça code review e marque hipóteses: trabalho em `body`, dependências amplas, identidade instável, feedback de geometria, imagens oversized e animações abrangentes.
3. Reproduza em Release e aparelho real quando possível; Simulator é útil para iteração, não para concluir energia/memória/frame pacing.
4. Capture SwiftUI Instruments com Time Profiler/Hangs/Hitches quando o sintoma persistir. Correlacione causa, tempo e frequência; não trate toda atualização como defeito.
5. Faça a menor correção que ataca a evidência e repita a medição. Registre CPU, tempo de atualização, hitches, frame drops e pico de memória quando disponíveis.

## Revisão de código

- Mova sorting, filtering, decoding, formatação e I/O para Model/Repository/Service ou uma função derivada atualizada quando as entradas mudarem. Não use `@State` como cache genérico sem owner/lifetime claro.
- Não crie formatters, decoders, objetos de rede ou `UUID()` dentro do `body`/row.
- Passe somente valores, bindings e ações que a subview lê; um `ObservableObject` global lido em toda row aumenta fan-out.
- Prefira `@ViewBuilder`/subviews concretas a `AnyView` em hot paths. `.equatable()` só ajuda quando igualdade é mais barata que renderizar e inclui todas as entradas relevantes.
- Limite `.animation(_:value:)` ao subtree que muda. Em scroll/geometry, atualize somente quando cruzar um threshold significativo.

## Listas e identidade

- Use `List`, `LazyVStack`, `LazyHStack` ou grids lazy quando construção/layout eager for material; não existe um limiar universal de itens.
- Use IDs estáveis que sobrevivem a inserção/remoção e não derivem de conteúdo mutável. Evite `.indices`, `\.offset`, `id: \.self` em dados mutáveis e `.id(UUID())`.
- Rows lazy podem ser recicladas; estado que precisa sobreviver fora da tela pertence ao Model/ViewModel, não apenas à row.
- `onAppear`/`onDisappear` são sinais de visibilidade, não garantias de lifetime. Prefira `.task(id:)` para trabalho cancelável.
- Mantenha quantidade constante de subviews de topo por elemento de `ForEach` e evite loops de geometria que escrevem estado a cada layout.

## Estado e invalidação

Narrow the read set: divida uma View grande em subviews que leem somente os campos necessários. Em `ObservableObject`, qualquer publicação pode invalidar observadores; use propriedades publicadas com escopo pequeno e não publique valores derivados redundantes. Aplique igualdade antes de publicar em eventos de alta frequência, mas não esconda mudanças semanticamente relevantes.

## Imagens e layout

- `AsyncImage` é um loader simples, não uma política completa de cache. Defina placeholder, erro, tamanho, cancelamento e cache conforme o produto.
- Não decodifique uma imagem original com `UIImage(data:)` em uma lista; faça downsampling para o tamanho de renderização fora do Main Actor e limite `NSCache` se houver cache próprio.
- Meça custo de blur/material, máscaras, sombras, GeometryReader e compositing antes de removê-los; simplifique o layout quando o trace apontar custo.
- Use dimensões adaptáveis e `@ScaledMetric` para acessibilidade; não troque Dynamic Type por frames fixos para “estabilizar” layout.

## Instruments

No SwiftUI template, procure Update Groups, Long View Body Updates, Representable Updates, Other Updates e Cause & Effect Graph. Use Time Profiler para localizar símbolos e Hangs/Hitches para separar bloqueio de CPU. Ferramentas de diagnóstico privadas como `_printChanges()`/`_logChanges()` podem ajudar em `#if DEBUG` se existirem no SDK, mas não são métricas de produção nem motivo para mudar arquitetura sozinhas.

## Saída de um diagnóstico

Entregue: (1) reprodução e baseline, (2) achados code-backed, (3) evidência de trace/métrica, (4) correções ordenadas por impacto/esforço, (5) métrica esperada e método para confirmar. Se não houver trace, diga claramente o que ainda é hipótese.

## Checklist

- [ ] Sintoma e baseline são reproduzíveis e a mesma interação será comparada.
- [ ] Release/aparelho real e instrumentos adequados foram considerados.
- [ ] `body`/rows não fazem trabalho caro, I/O ou alocação instável.
- [ ] IDs são estáveis e o estado importante sobrevive ao ciclo lazy.
- [ ] Dependências de estado são estreitas; geometry/animation não geram storm.
- [ ] Imagens têm tamanho, cancelamento e cache/downsampling proporcionais.
- [ ] Cada recomendação distingue hipótese de evidência e tem verificação posterior.
