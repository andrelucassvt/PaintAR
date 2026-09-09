# Localização e internacionalização

Localização é parte do contrato da View. Xcode extrai literais passados a APIs localizáveis do SwiftUI; a implementação também precisa suportar plural, locale, RTL e formatos regionais.

## Strings

- Passe literais diretamente a `Text`, `Button`, `Label`, `navigationTitle` e alertas. Não envolva um literal de View em `NSLocalizedString` ou `String(localized:)` antecipadamente.
- `String` vindo de API ou runtime não é automaticamente uma chave localizada. Para um conjunto conhecido, modele uma enum com `LocalizedStringResource`; para erro técnico, faça o mapeamento em uma camada de apresentação.
- Use interpolação em uma única frase, nunca concatene fragmentos localizados com `+`. Forneça `comment:` quando contexto ou placeholders não forem óbvios.
- Prefira String Catalog (`.xcstrings`) e símbolos gerados quando o projeto já os utiliza. Não altere o sistema de localização inteiro em uma mudança não relacionada.

## Formatos e layout

Use `FormatStyle`/`.formatted()` para datas, números, unidades e moedas; não fixe `DateFormatter` ou `String(format:)` para texto de usuário. O formato deve respeitar locale, calendário, moeda e plural.

```swift
Text(order.createdAt, format: .dateTime.year().month().day())
Text(total, format: .currency(code: currencyCode))
Text("\(items.count) itens")
```

Não componha sentenças assumindo ordem inglesa. Use `.leading`/`.trailing`, permita expansão de texto e considere `ViewThatFits` ou mudança de orientação em larguras pequenas. Teste árabe/hebraico e alemão, além de Português do Brasil quando esse for o locale do produto.

## Camadas que não são View

Quando um Model/Service precisa carregar texto de usuário, prefira uma chave/`LocalizedStringResource` ou um erro tipado que a View possa mapear. Não resolva a string na criação do objeto se o locale pode mudar antes da renderização. Em Package/framework, informe o `Bundle` correto conforme o toolchain.

## Checklist

- [ ] Literais de View usam APIs localizáveis e não são concatenados.
- [ ] String Catalog/`.strings` segue a convenção já existente e tem comentários úteis.
- [ ] Interpolação cobre plural e ordem de palavras de cada idioma.
- [ ] Datas, números, moedas e unidades usam formato locale-aware.
- [ ] Layout suporta RTL, Dynamic Type e traduções maiores sem clipping.
- [ ] Erros técnicos são mapeados para mensagens de usuário localizáveis.
- [ ] Previews e testes exercitam pelo menos um locale alternativo.
