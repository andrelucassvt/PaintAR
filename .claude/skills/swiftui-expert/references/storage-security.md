# Storage e segurança

Escolha o storage pelo risco e pelo ciclo de vida do dado. Keychain protege pequenos segredos; UserDefaults serve para preferências não sensíveis; arquivos/database precisam de política própria de proteção e migração.

## Keychain

Qualifique cada item por `service` e `account`, use uma classe de acessibilidade compatível com o fluxo e atualize o item existente com `SecItemUpdate`. Não armazene tokens, senhas ou códigos em UserDefaults, logs, URL, fixtures ou arquivos sem proteção.

```swift
import Foundation
import Security

protocol KeychainServiceProtocol {
    func save(_ value: String, account: String) throws
    func read(account: String) throws -> String
    func delete(account: String) throws
}

enum KeychainError: Error {
    case itemNotFound
    case operationFailed(OSStatus)
    case invalidData
}

final class KeychainService: KeychainServiceProtocol {
    private let service: String
    private let accessibility: CFString

    init(service: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.service = service
        self.accessibility = accessibility
    }

    func save(_ value: String, account: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = accessibility
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.operationFailed(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.operationFailed(status)
        }
    }

    func read(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard status == errSecSuccess, let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return value
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.operationFailed(status)
        }
    }
}
```

O valor de `accessibility` depende do produto: `WhenUnlockedThisDeviceOnly` é um default seguro para dados que não precisam ser lidos com o aparelho bloqueado; background/biometria exigem uma decisão explícita de acesso e testes no dispositivo. Nunca use uma classe “always” por conveniência.

## UserDefaults e arquivos

- Guarde apenas preferências e flags não confidenciais, com chaves tipadas e namespace do app.
- Injete `UserDefaults` (por exemplo, uma suíte de teste) e trate falha de encoding/decoding; não engula erro silenciosamente quando o dado é necessário.
- Para documentos, use URLs de diretórios do sistema, proteção de arquivo adequada e migração versionada. Não armazene tokens ou PII em JSON casual.
- Serviços de storage podem ser síncronos no Main Actor para pequenas preferências; use actor quando houver acesso concorrente, I/O ou cache mutável significativo.

## Networking e privacidade

ATS deve permanecer habilitado; exceções precisam de domínio, motivo e revisão. Redija logs de URL/body/headers, não registre Authorization, cookies ou identificadores pessoais e não envie dados de preview para serviços externos. Considere Privacy Manifest e coleta mínima quando o recurso usar APIs que exigem declaração.

## Checklist

- [ ] O dado foi classificado como segredo, preferência, documento ou cache.
- [ ] Keychain usa service/account, accessibility explícita e `SecItemUpdate`/`SecItemDelete` corretos.
- [ ] UserDefaults não contém credenciais, tokens, senhas ou PII sensível.
- [ ] Storage e doubles são injetáveis e têm política clara de erro/migração.
- [ ] Estado mutável concorrente tem actor/isolamento; não há `Sendable` ornamental.
- [ ] Logs, fixtures e ATS respeitam o princípio de menor exposição.
