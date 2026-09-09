# Liquid Glass (iOS 26+)

## Table of Contents

- [Quando usar](#quando-usar)
- [Compatibilidade e acessibilidade](#compatibilidade-e-acessibilidade)
- [Card](#card)
- [Container e morphing](#container-e-morphing)
- [Botões e toolbar](#botões-e-toolbar)
- [Sheets e scroll edge](#sheets-e-scroll-edge)
- [Checklist](#checklist)

## Quando usar

Adote Liquid Glass somente quando o usuário pedir explicitamente glass, `glassEffect` ou o visual iOS 26. Não converta uma UI existente por iniciativa própria. O efeito deve reforçar hierarquia e interação, não substituir contraste, labels ou layout.

## Compatibilidade e acessibilidade

Todos os usos de APIs iOS 26 ficam atrás de `if #available(iOS 26, *)` e têm fallback funcional. Se `accessibilityReduceTransparency` estiver ativo, prefira uma superfície opaca/menos translúcida; preserve contraste e legibilidade. Não use `.interactive()` em conteúdo estático.

## Card

Faça layout, padding e estilo antes do efeito:

```swift
import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String

    var body: some View {
        cardContent
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(value).font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .modifier(GlassCardModifier())
    }
}

private struct GlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency {
            content.glassEffect(.regular, in: .rect(cornerRadius: 20))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.secondary.opacity(0.2)))
        }
    }
}
```

O fallback continua sendo um card legível no iOS 15 e quando o usuário reduz transparência.

## Container e morphing

Elementos glass próximos devem compartilhar `GlassEffectContainer` com o mesmo `spacing` do layout. Para morphing, use o mesmo `glassEffectID` e `@Namespace` nos dois estados; anime o container/pai, não cada material isoladamente.

```swift
if #available(iOS 26, *) {
    GlassEffectContainer(spacing: 12) {
        HStack(spacing: 12) {
            Button("Editar", systemImage: "pencil", action: edit)
                .glassEffect(.regular.interactive(), in: .capsule)
            Button("Compartilhar", systemImage: "square.and.arrow.up", action: share)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
    }
} else {
    fallbackToolbar
}
```

Não faça elementos glass amostrarem uns aos outros fora do container; o resultado visual e a identidade podem ficar inconsistentes.

## Botões e toolbar

Use labels semânticos com ícone e texto; deixe o contexto da toolbar decidir se a aparência deve ser icon-only. `.buttonStyle(.glass)`/`.glassProminent` são iOS 26+ e precisam de branch; um modifier próprio com material é mais fácil de reutilizar com fallback.

## Sheets e scroll edge

No iOS 26, o sistema pode fornecer material de sheet e efeitos de borda de scroll. Não empilhe backgrounds customizados escuros atrás de toolbars sem medir o resultado. Mantenha conteúdo, contraste e ações corretos no fallback iOS 15; não dependa do efeito para comunicar estado.

## Checklist

- [ ] Pedido explícito de Liquid Glass foi confirmado.
- [ ] Cada API iOS 26 tem `#available` e fallback equivalente.
- [ ] Efeito vem depois de layout, padding e estilo.
- [ ] Transparência reduzida, contraste, Dynamic Type e VoiceOver continuam corretos.
- [ ] Elementos próximos usam `GlassEffectContainer` com spacing coerente.
- [ ] `.interactive()` aparece apenas em controles interativos.
- [ ] Morphing usa ID/namespace/container compartilhados e animação no pai.
- [ ] Sheets/toolbars não têm background que conflite com o comportamento do sistema.
