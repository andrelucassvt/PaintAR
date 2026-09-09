# Networking HTTP

Use `URLSession` async APIs with typed endpoints, injected configuration and a single validation boundary. Este guia assume iOS 15+; confirme a disponibilidade do método e o Swift language mode no projeto.

## Endpoint tipado

Mantenha path, método, query, body e autenticação próximos e sem strings concatenadas no Repository:

```swift
import Foundation

enum Endpoint: Sendable {
    case productList(page: Int, limit: Int)
    case product(id: String)
    case deleteProduct(id: String)

    var path: String {
        switch self {
        case .productList: "products"
        case .product(let id), .deleteProduct(let id): "products/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .productList, .product: .get
        case .deleteProduct: .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        guard case .productList(let page, let limit) = self else { return nil }
        return [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
    }

    var requiresAuth: Bool { true }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

Se endpoints precisam enviar payload, carregue um DTO `Encodable & Sendable` no caso ou use uma request tipada que o cliente encode dentro do mesmo isolamento. Não transforme `Encodable` em dicionário solto e não inclua credenciais na URL.

## Cliente e erros

Um `actor` é apropriado quando o cliente guarda decoder/encoder, token ou refresh mutável; uma classe imutável com `let` também pode ser suficiente. A escolha deve ser guiada pelo estado compartilhado, não pelo desejo de adicionar `Sendable`.

```swift
import Foundation

protocol APIClientProtocol {
    func request<T: Decodable & Sendable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T
}

actor APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: AccessTokenProviding?

    init(baseURL: URL, session: URLSession = .shared, tokenProvider: AccessTokenProviding? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let request = try await makeRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        if data.isEmpty, let empty = EmptyResponse() as? T { return empty }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    private func makeRequest(for endpoint: Endpoint) async throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.requiresAuth, let token = await tokenProvider?.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        switch response.statusCode {
        case 200..<300: return
        case 401: throw NetworkError.unauthorized
        case 408, 429, 500..<600: throw NetworkError.transient(statusCode: response.statusCode)
        default: throw NetworkError.http(statusCode: response.statusCode)
        }
    }
}
```

O snippet omite bodies POST/PUT para manter o contrato curto; adicione `Content-Type` somente quando houver body. Não capture `CancellationError` como `NetworkError` e não inclua body de resposta em logs de produção.

```swift
import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case http(statusCode: Int)
    case transient(statusCode: Int)
    case unauthorized
    case decodingFailed
}

struct EmptyResponse: Decodable, Sendable {}

protocol AccessTokenProviding: Sendable {
    func accessToken() async -> String?
}
```

Mapeie `NetworkError` para uma mensagem de UX na camada de apresentação. Use retry limitado/backoff somente para `transient` e apenas quando a operação for segura para repetir.

## Test doubles e verificação

O fake de API deve permitir inspecionar `Endpoint`, método, query, body e resultado. O fake de Repository pertence aos testes do ViewModel. Não misture as duas responsabilidades nem use `.shared` para esconder uma dependência.

- [ ] Base URL, sessão, timeout, decoder/encoder e token provider são injetáveis.
- [ ] Path não começa com `/`; query usa `URLQueryItem`.
- [ ] Status 2xx, 204, 401, erros transitórios, outros HTTP, decode e cancelamento têm comportamento definido.
- [ ] `Endpoint` e valores que cruzam atores são Sendable por composição segura.
- [ ] Secrets não aparecem em URL, body de log, fixtures ou mensagens de erro.
- [ ] Retry respeita idempotência, backoff e cancelamento.
- [ ] Testes cobrem construção de request e mapeamento de resposta sem rede real.
