# Exemplo: Liquid Glass com fallback

Pedido: “Aplique Liquid Glass no card de resumo”. Leia `references/availability.md`, `references/liquid-glass.md`, `references/accessibility.md` e `references/view.md` antes de editar.

Liquid Glass só é adotado por pedido explícito. O fallback iOS 15 precisa continuar legível e acessível.

```swift
import SwiftUI

struct SummaryGlassCard: View {
    let title: String
    let value: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(value).font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .modifier(GlassCardModifier(reduceTransparency: reduceTransparency))
    }
}

private struct GlassCardModifier: ViewModifier {
    let reduceTransparency: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency {
            content.glassEffect(.regular, in: .rect(cornerRadius: 20))
        } else {
            content.background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
    }
}
```

Para dois ou mais elementos glass próximos, envolva-os em `GlassEffectContainer` e use o mesmo `spacing` do layout. Para morphing, compartilhe `@Namespace` e `glassEffectID`; anime o container, não cada efeito isolado.

## Checklist

- [ ] `glassEffect` está protegido por `#available(iOS 26, *)`.
- [ ] Layout, padding e estilo vêm antes do glass.
- [ ] Fallback funciona no iOS 15 e com transparência reduzida.
- [ ] Controles têm labels semânticos e `.interactive()` apenas quando são interativos.
- [ ] Container/namespace/ID foram usados quando há agrupamento ou morphing.
