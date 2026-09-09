# Acessibilidade SwiftUI

Trate acessibilidade como requisito funcional, não como acabamento. Audite cada tela com VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, contraste, Voice Control e navegação por teclado/assistive devices quando aplicável.

## Controles e semântica

- Use `Button`, `Toggle`, `Picker`, `Slider`, `TextField` e `Link` para ações/entrada. Reserve `onTapGesture` para localização ou contagem de toques; se inevitável, adicione traits e um rótulo.
- Um botão de ícone precisa de texto semântico: `Button("Adicionar", systemImage: "plus", action: add)`. `.labelStyle(.iconOnly)` altera apenas a aparência.
- Esconda imagens decorativas com `Image(decorative:)` ou `.accessibilityHidden(true)`; dê `accessibilityLabel` a imagens informativas.
- Agrupe elementos relacionados com `.accessibilityElement(children: .combine)` somente quando uma leitura única fizer sentido. Não esconda estados, valores ou ações úteis.
- Use `accessibilityValue`, `accessibilityHint`, traits de seleção/erro e `accessibilityIdentifier` separado do texto que o usuário ouve.

## Tamanho, texto e cor

- Prefira estilos de fonte do sistema e `@ScaledMetric(relativeTo:)` para dimensões que acompanham Dynamic Type.
- Nunca dependa somente de cor: adicione ícone, texto, forma, padrão ou stroke. Respeite `accessibilityDifferentiateWithoutColor`.
- Evite frames fixos para texto. Use `.leading`/`.trailing`, quebra de linha e layouts que possam mudar de horizontal para vertical.
- Mantenha controles confortáveis (44 pt é um alvo recomendado para iOS), com espaçamento que evite toques acidentais.

## Movimento e transparência

Leia `@Environment(\.accessibilityReduceMotion)` e substitua animações grandes por cross-fade, redução de distância ou nenhuma animação quando necessário. Se a UI depende de blur/material, considere `accessibilityReduceTransparency` e ofereça uma superfície opaca legível.

## Estados e testes

- Loading, vazio e erro devem ter mensagem, contexto e ação acessíveis; não comunique estado só por spinner ou cor.
- Após uma ação que muda o conteúdo, mova o foco ou anuncie a mudança apenas quando isso ajudar o fluxo, evitando anúncios repetitivos.
- Teste tamanhos de texto acessíveis, alto contraste, VoiceOver e Reduce Motion em previews/Accessibility Inspector. Verificação automatizada de labels complementa, mas não substitui, a auditoria manual.

## Checklist

- [ ] Toda ação é um controle nativo ou tem semântica equivalente.
- [ ] Ícones e imagens decorativas têm tratamento correto; labels não são strings técnicas.
- [ ] Texto e dimensões respondem a Dynamic Type sem clipping ou frame fixo.
- [ ] Informação não depende apenas de cor; contraste e estados são legíveis.
- [ ] Reduce Motion/Transparency e ordem de foco foram considerados.
- [ ] Estados loading/vazio/erro têm leitura e ação compreensíveis.
