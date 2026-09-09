---
name: repository
description: Cria ou revisa Repositories SwiftUI MVVM com protocolo, implementação, mapping e doubles determinísticos entre ViewModel e Service. Use para novas fontes de dados, operações CRUD, cache ou testes de integração da camada de dados.
argument-hint: <NomeDoRepository> (ex: User, Product)
---

# Repository

O Repository é o boundary entre caso de uso/apresentação e uma ou mais fontes de dados. Ele traduz DTOs, paginação e erros de transporte; não decide layout, alertas ou loading.

## Contrato

- Mantenha `Protocol + implementação concreta`, conforme o padrão deste repositório.
- Exponha somente operações necessárias, com argumentos tipados (`id`, filtros, cursor ou DTO), e preserve a semântica de `async throws`.
- O ViewModel depende do protocolo; a implementação recebe `APIClientProtocol`, storage ou clock por `init`.
- Não crie `APIClient()` dentro de cada método e não esconda um singleton obrigatório em um default sem decisão de composição.
- Não adicione `Sendable` ao protocolo por reflexo. Use-o quando o contrato atravessar atores e todas as implementações, Models e closures forem realmente seguras.
- Mapeie DTO → domínio neste boundary; não deixe detalhes de JSON/HTTP vazarem para a View.

```swift
import Foundation

protocol ProductRepositoryProtocol {
    func fetchAll(page: Int, limit: Int) async throws -> [Product]
    func delete(id: String) async throws
}

final class ProductRepository: ProductRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchAll(page: Int, limit: Int) async throws -> [Product] {
        let response = try await apiClient.request(
            endpoint: .productList(page: page, limit: limit),
            responseType: ProductResponse.self
        )
        return response.items.map { $0.mapToDomain() }
    }

    func delete(id: String) async throws {
        try await apiClient.request(
            endpoint: .deleteProduct(id: id),
            responseType: EmptyResponse.self
        )
    }
}
```

O snippet assume tipos/endpoint do projeto (`ProductResponse`, `APIClientProtocol`, `EmptyResponse`). Se a API retorna diretamente `[Product]`, remova o mapping; não invente um envelope.

## Cache e múltiplas fontes

Quando houver cache, defina a política (cache-first, network-first, stale-while-revalidate), validade, invalidação e concorrência. Um actor é adequado para estado de cache compartilhado; um `Dictionary` mutável em uma classe `Sendable` não é. O Repository deve deixar claro qual fonte venceu e se dados antigos são aceitáveis.

## Doubles

Para ViewModel, use `MockProductRepository`/stub no target de testes e previews, com fixture nova por caso. Inclua sucesso, erro tipado, atraso/cancelamento e registro de argumentos apenas quando o teste precisa provar o contrato. Para testar o Repository, use um `MockAPIClient` que possa inspecionar Endpoint, método, query, body e resultado.

```swift
import Foundation

final class MockProductRepository: ProductRepositoryProtocol {
    var items = Product.mockList
    var error: Error?

    func fetchAll(page: Int, limit: Int) async throws -> [Product] {
        if let error { throw error }
        return items
    }

    func delete(id: String) async throws {
        if let error { throw error }
        items.removeAll { $0.id == id }
    }
}
```

Se o double for usado entre atores, converta-o em `actor` e ajuste os acessos async; não marque esta classe mutável como `Sendable` sem proteção.

## Checklist

- [ ] Protocolo e implementação expõem somente operações usadas.
- [ ] Dependências entram no inicializador; nenhum singleton/APIClient oculto cria estado órfão.
- [ ] DTOs são mapeados no boundary e erros de transporte continuam tipados.
- [ ] O contrato de paginação, cursor, cache e invalidação está explícito.
- [ ] `Sendable` só aparece quando isolamento e composição o sustentam.
- [ ] Doubles são determinísticos, isolados por teste e cobrem sucesso, erro e cancelamento.
- [ ] Testes do ViewModel não acessam APIClient; testes do Repository usam APIClient fake.
