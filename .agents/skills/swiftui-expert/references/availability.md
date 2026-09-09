# Disponibilidade de APIs e compatibilidade

Leia esta referência antes de usar uma API que possa depender do sistema ou do SDK. Nunca aumente o deployment target apenas para fazer um snippet compilar.

## Três versões diferentes

| Dimensão | Onde conferir | Pergunta |
|---|---|---|
| Deployment target | `project.pbxproj`, Xcode target, `Package.swift` | Qual é o menor iOS que o binário deve executar? |
| SDK/Xcode | `xcodebuild -version`, CI, `Package.resolved` | A assinatura e o módulo existem no toolchain usado? |
| Swift language mode | Build settings, `Package.swift` | Concurrency, macros e sintaxe estão habilitados? |

O projeto pode compilar com um SDK novo e ainda precisar executar em iOS 15. Em código distribuído a múltiplos targets, a menor disponibilidade compartilhada vence.

## Baseline deste repositório

| Alvo | Preferência | Regra |
|---|---|---|
| iOS 15 | `NavigationView`, `ObservableObject`, `@StateObject`, `@ObservedObject`, `NavigationLink(destination:)` | Use como padrão das features MVVM existentes |
| iOS 16+ | `NavigationStack`, `NavigationPath`, `navigationDestination` | Só se o target real for elevado ou houver fallback explícito |
| iOS 17+ | Observation (`@Observable`/`@Bindable`), `ContentUnavailableView` | Não substituir o baseline silenciosamente |
| iOS 18+ | APIs adicionais de layout, scroll e previews | Confirmar no SDK local e manter caminho iOS 15 quando necessário |
| iOS 26+ | Liquid Glass e APIs visuais relacionadas | Somente por pedido explícito, sempre com `#available` e fallback |

Esta tabela é um guia de decisão, não uma lista exaustiva. Para uma API específica, confirme a página da Apple no SDK/documentação local e leia a assinatura real.

## Padrão de adoção

```swift
if #available(iOS 17, *) {
    modernContent
} else {
    compatibleContent
}
```

Prefira encapsular a diferença em um componente ou modifier pequeno. O fallback precisa preservar conteúdo, ação, acessibilidade e estado — não apenas evitar um erro de compilação.

## Deprecated, soft-deprecated e legado

- **Deprecated formal:** migre quando o target permitir, respeitando a mensagem do compilador.
- **Soft-deprecated ou legado funcional:** não faça migração não relacionada sem evidência de benefício; registre a decisão e limite o diff.
- **Compatibilidade iOS 15:** `NavigationView` pode receber avisos em SDKs novos, mas permanece a escolha correta quando esse é o menor target do produto.
- Não trate “API moderna” como sinônimo de “API disponível no menor sistema”. O código deve ter disponibilidade, fallback e verificação correspondentes.

## Verificação

- [ ] A origem do deployment target foi lida no projeto real.
- [ ] Cada API posterior ao baseline tem anotação de disponibilidade ou está confinada a um target compatível.
- [ ] O fallback tem a mesma ação, dados e semântica de acessibilidade.
- [ ] Avisos de deprecated foram diferenciados de recomendações de estilo.
- [ ] Assinaturas foram confirmadas no SDK local/Apple Developer Documentation, não inferidas de memória.
