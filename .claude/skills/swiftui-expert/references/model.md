---
name: model
description: Cria ou revisa Models e DTOs Swift seguindo o padrão MVVM do projeto. Use quando o usuário pedir entidade, struct Codable, identidade, transformação de payload, dados mockados ou correção de um contrato de API.
argument-hint: <NomeDaModel> (ex: Product)
---

# Model e DTO

Crie tipos de dados pequenos, previsíveis e independentes de SwiftUI. Antes de codar, confirme se o tipo representa domínio, transporte de API, persistência ou apenas fixture; esses papéis não precisam ser a mesma struct.

## Decisões

- Prefira `struct` para valores de domínio e mantenha propriedades `let` quando a imutabilidade for válida.
- Adote `Codable` somente onde há serialização; `Identifiable`, `Equatable`, `Hashable` e `Sendable` somente quando o uso exigir e todas as propriedades suportarem o contrato.
- Use tipos semânticos (`URL`, `Date`, `Decimal`, enums) em vez de `String` genérico. Não use `Double` para dinheiro sem uma decisão explícita de precisão.
- Se a API tiver nomes, nulabilidade ou envelopes diferentes do domínio, crie DTOs e mapeie em um boundary de Repository/Service.
- Use `CodingKeys` quando o contrato realmente divergir. `convertFromSnakeCase` pode resolver nomes simples, mas não deve mascarar acrônimos ou chaves especiais.
- Dados de preview devem ser determinísticos, realistas e livres de rede, tokens e PII.

## Modelo de domínio

```swift
import Foundation

struct Product: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let price: Decimal
    let imageURL: URL?
}
```

Não adicione `Sendable` apenas para silenciar um warning. Use-o quando o valor atravessar atores/tasks; corrija propriedades não enviáveis ou faça a transformação antes da fronteira.

## DTO e mapeamento

```swift
import Foundation

struct ProductResponse: Decodable, Sendable {
    let id: String
    let displayName: String
    let priceInCents: Int

    func mapToDomain() -> Product {
        Product(
            id: id,
            name: displayName,
            price: Decimal(priceInCents) / 100,
            imageURL: nil
        )
    }
}
```

Adapte nomes e conversões ao contrato real. Validações que protegem invariantes do domínio pertencem ao mapeamento/use case, não a uma View.

## Preview data

```swift
import Foundation

extension Product {
    static let mock = Product(
        id: "product-1",
        name: "Caderno",
        price: 29.90,
        imageURL: URL(string: "https://example.com/caderno.png")
    )

    static let mockList: [Product] = [
        .mock,
        Product(id: "product-2", name: "Caneta", price: 7.50, imageURL: nil)
    ]
}
```

Se URLs externas tornarem o preview frágil, use `nil` ou um asset local; o preview nunca deve baixar a URL.

## Checklist

- [ ] O papel do tipo (domínio, DTO, persistência ou fixture) está claro.
- [ ] Conformances existem por necessidade real e são compatíveis com as propriedades.
- [ ] Não há `import SwiftUI` nem lógica de apresentação.
- [ ] Nomes, nulabilidade, datas, moedas e envelopes refletem o contrato real.
- [ ] `CodingKeys` só existe quando necessário e cobre todas as chaves especiais.
- [ ] Modelos que atravessam concorrência são `Sendable` por composição segura.
- [ ] Mocks são determinísticos, variados e não contêm dados sensíveis.
