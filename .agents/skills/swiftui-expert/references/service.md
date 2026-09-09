---
name: service
description: Roteia a criação ou revisão de serviços Swift para networking, autenticação e storage local em um app SwiftUI MVVM. Use para APIClient, Endpoint, erros HTTP, Keychain, UserDefaults ou integração de infraestrutura.
argument-hint: networking | auth | storage | endpoint
---

# Services

Services encapsulam infraestrutura e não conhecem Views, `ViewState` ou alertas. Escolha a referência específica antes de escrever código:

| Necessidade | Referência |
|---|---|
| APIClient, Endpoint, URLSession, headers, decoding, retries | `references/networking.md` |
| Token, logout, refresh, Keychain, dados sensíveis | `references/storage-security.md` e `references/networking.md` |
| UserDefaults, arquivos e preferências simples | `references/storage-security.md` |
| Estado compartilhado, actors, Sendable, cancelamento | `references/concurrency.md` |

## Regras comuns

- Injete base URL, URLSession, encoder/decoder, clock, token store e outras dependências no inicializador.
- Use protocolos quando o consumidor precisa de um seam de teste; não crie abstrações para cada função trivial sem benefício.
- Propague erros tipados para o Repository/ViewModel. Mensagens de UX e localização pertencem à camada de apresentação.
- Proteja estado mutável compartilhado com actor ou isolamento equivalente. Não declare uma classe com `Sendable` para mascarar uma corrida.
- Não registre tokens, senhas, corpos sensíveis ou dados pessoais; redija logs e configure ATS apenas para requisitos documentados.
- Verifique status HTTP, conteúdo vazio, cancelamento e limites de timeout/retry conforme o contrato do serviço.

## Checklist de roteamento

- [ ] O serviço foi classificado como networking, auth ou storage antes da implementação.
- [ ] A fonte de verdade e o owner do estado foram definidos.
- [ ] Dependências e doubles entram por inicializador/protocolo quando necessário.
- [ ] Disponibilidade do sistema, toolchain e frameworks foi confirmada.
- [ ] A referência específica foi lida e sua verificação será executada.
