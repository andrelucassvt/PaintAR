---
name: payment
description: Cria o fluxo completo de pagamento/assinatura com StoreKit 2 seguindo o padrao do projeto SwiftUI (iOS 17+ / macOS 14+). Gera SubscriptionProduct, StoreKitService, SubscriptionManager, PaywallView, SubscriptionStatusView e PremiumGuard. Use quando o usuario pedir para adicionar assinatura, paywall, compra in-app ou sistema de premium.
argument-hint: (sem argumentos — a skill faz perguntas guiadas)
---

Crie o fluxo completo de pagamento com StoreKit 2 seguindo o padrao MVVM do projeto.
Requisito minimo: **iOS 17+ / macOS 14+** (usa `@Observable`).

---

## Perguntas iniciais (se nao informadas)

1. **Plataforma**: iOS ou macOS?
2. **Planos de assinatura**: quais planos existem? (ex: mensal, trimestral, anual)
   - Para cada plano, qual o **Product ID** cadastrado no App Store Connect? (ex: `com.empresa.app.monthly`)
   - Algum plano tem badge de destaque? (ex: "Melhor valor" no plano anual)
3. **Features premium**: quais funcionalidades serao bloqueadas para usuarios free?
4. **Nome do app**: usado nas strings de localizacao (ex: `CleanMacForDevs`)

---

## Arquitetura do fluxo de pagamento

```
App (@main)
└── .environment(SubscriptionManager.shared)
    └── .task { await subscriptionManager.loadInitialState() }

SubscriptionManager (@Observable, @MainActor, Singleton)
├── isPremium: Bool
├── products: [Product]
├── purchaseState: ViewState<Void>
├── currentProductID: String?
└── storeKitService: StoreKitServiceProtocol

StoreKitService (StoreKit 2)
├── fetchProducts() → [Product]
├── purchase(Product) → Transaction?
├── restorePurchases()
└── currentEntitlement() → Transaction?

Views
├── PaywallView         — tela principal de compra
├── SubscriptionStatusView — badge na sidebar/menu
└── PremiumGuard<Content>  — wrapper que bloqueia conteudo premium
    └── .premiumRequired()  — modifier de conveniencia
```

---

## Arquivos a criar

### 1. `Models/SubscriptionProduct.swift`

```swift
import Foundation

enum SubscriptionProduct: String, CaseIterable, Identifiable {
    // TODO: Substitua pelos Product IDs reais do App Store Connect
    case monthly  = "com.empresa.app.monthly"
    case annual   = "com.empresa.app.annual"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("subscription.plan.monthly", comment: "")
        case .annual:
            return NSLocalizedString("subscription.plan.annual", comment: "")
        }
    }

    /// Badge exibido no card do plano (ex: "Melhor valor"). nil = sem badge.
    var badge: String? {
        switch self {
        case .monthly:
            return nil
        case .annual:
            return NSLocalizedString("subscription.badge.best_value", comment: "")
        }
    }

    static var allProductIDs: Set<String> {
        Set(allCases.map(\.rawValue))
    }
}
```

> Adapte os `case`s conforme os planos definidos. Use sempre o Product ID exato do App Store Connect.

---

### 2. `Services/StoreKitService.swift`

```swift
import Foundation
import StoreKit

// MARK: - Protocol

protocol StoreKitServiceProtocol: Sendable {
    func fetchProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> StoreKit.Transaction?
    func restorePurchases() async throws
    func currentEntitlement() async -> StoreKit.Transaction?
}

// MARK: - Implementation

final class StoreKitService: StoreKitServiceProtocol, @unchecked Sendable {

    // MARK: - Fetch Products

    func fetchProducts() async throws -> [Product] {
        try await Product.products(for: SubscriptionProduct.allProductIDs)
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerification(verification)
            await transaction.finish()
            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    // MARK: - Current Entitlement

    func currentEntitlement() async -> StoreKit.Transaction? {
        for productID in SubscriptionProduct.allProductIDs {
            guard let result = await Transaction.currentEntitlement(for: productID) else {
                continue
            }
            if let transaction = try? checkVerification(result) {
                return transaction
            }
        }
        return nil
    }

    // MARK: - Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Errors

enum StoreKitError: LocalizedError {
    case failedVerification
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return NSLocalizedString("subscription.error.verification", comment: "")
        case .purchaseFailed:
            return NSLocalizedString("subscription.error.purchase", comment: "")
        }
    }
}
```

---

### 3. `Services/SubscriptionManager.swift`

```swift
import Foundation
import StoreKit

/// Singleton que centraliza o estado de assinatura e escuta atualizacoes de transacoes.
/// Injete via `.environment(SubscriptionManager.shared)` no App entry point.
@MainActor
@Observable
final class SubscriptionManager {

    static let shared = SubscriptionManager()

    // MARK: - Estado

    private(set) var isPremium: Bool = false
    private(set) var products: [Product] = []
    private(set) var purchaseState: ViewState<Void> = .idle
    private(set) var currentProductID: String?

    // MARK: - Dependencias

    private let storeKitService: StoreKitServiceProtocol

    // MARK: - Transaction listener

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init(storeKitService: StoreKitServiceProtocol = StoreKitService()) {
        self.storeKitService = storeKitService
    }

    // MARK: - API Publica

    /// Chame no `.task {}` do App entry point para inicializar o estado.
    func loadInitialState() async {
        startTransactionListener()
        await checkEntitlement()
        await fetchProducts()
    }

    func fetchProducts() async {
        do {
            let fetched = try await storeKitService.fetchProducts()
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .loading
        do {
            if let transaction = try await storeKitService.purchase(product) {
                isPremium = true
                currentProductID = transaction.productID
                purchaseState = .success(())
            } else {
                purchaseState = .idle // cancelado ou pendente
            }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }

    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await storeKitService.restorePurchases()
            await checkEntitlement()
            if isPremium {
                purchaseState = .success(())
            } else {
                purchaseState = .error(NSLocalizedString("subscription.error.no_active", comment: ""))
            }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }

    func dismissPurchaseResult() {
        purchaseState = .idle
    }

    // MARK: - Helpers

    func checkEntitlement() async {
        if let transaction = await storeKitService.currentEntitlement() {
            isPremium = true
            currentProductID = transaction.productID
        } else {
            isPremium = false
            currentProductID = nil
        }
    }

    func product(for subscriptionProduct: SubscriptionProduct) -> Product? {
        products.first { $0.id == subscriptionProduct.rawValue }
    }

    // MARK: - Listener de transacoes em background

    private func startTransactionListener() {
        transactionListener = Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self.checkEntitlement()
                }
            }
        }
    }
}
```

---

### 4. `Features/Subscription/PaywallView.swift`

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: SubscriptionProduct = .annual

    var body: some View {
        VStack(spacing: 0) {
            // Botao fechar
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .padding([.top, .trailing], 16)
            }

            VStack(spacing: 20) {
                headerSection

                Divider()

                plansAndFeaturesSection

                Spacer(minLength: 0)

                legalLinksSection
                    .padding(.bottom, 12)
            }
        }
        // TODO: Ajuste o frame para o tamanho desejado (macOS) ou remova (iOS sheet)
        .frame(width: 680, height: 460)
        .alert(
            NSLocalizedString("alert.error", comment: ""),
            isPresented: .constant(subscriptionManager.purchaseState.errorMessage != nil),
            actions: {
                Button(NSLocalizedString("alert.ok", comment: "")) {
                    subscriptionManager.dismissPurchaseResult()
                }
            },
            message: {
                if let message = subscriptionManager.purchaseState.errorMessage {
                    Text(message)
                }
            }
        )
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
        .task {
            await subscriptionManager.fetchProducts()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow.gradient)

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("paywall.title", comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(NSLocalizedString("paywall.subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 4)
    }

    // MARK: - Planos + Features

    private var plansAndFeaturesSection: some View {
        HStack(alignment: .top, spacing: 32) {
            featuresSection
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                plansSection
                purchaseButton
                restoreButton
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("paywall.features.title", comment: ""))
                .font(.headline)
                .padding(.bottom, 2)

            // TODO: Substitua pelas features reais do app
            featureRow(icon: "star.fill",    text: NSLocalizedString("paywall.feature.1", comment: ""))
            featureRow(icon: "bolt.fill",    text: NSLocalizedString("paywall.feature.2", comment: ""))
            featureRow(icon: "lock.open.fill", text: NSLocalizedString("paywall.feature.3", comment: ""))
            featureRow(icon: "infinity",     text: NSLocalizedString("paywall.feature.unlimited", comment: ""))
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Cards de plano

    private var plansSection: some View {
        VStack(spacing: 10) {
            ForEach(SubscriptionProduct.allCases) { plan in
                planCard(for: plan)
            }
        }
    }

    private func planCard(for plan: SubscriptionProduct) -> some View {
        let product = subscriptionManager.product(for: plan)
        let isSelected = selectedProduct == plan

        return Button { selectedProduct = plan } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.headline)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.green, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    if let product {
                        Text(product.displayPrice + " / " + periodLabel(for: plan))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(NSLocalizedString("paywall.loading_price", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Botao de compra

    private var purchaseButton: some View {
        Button {
            guard let product = subscriptionManager.product(for: selectedProduct) else { return }
            Task { await subscriptionManager.purchase(product) }
        } label: {
            Group {
                if subscriptionManager.purchaseState.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Text(NSLocalizedString("paywall.subscribe", comment: ""))
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(
            subscriptionManager.purchaseState.isLoading ||
            subscriptionManager.product(for: selectedProduct) == nil
        )
    }

    // MARK: - Restaurar

    private var restoreButton: some View {
        Button(NSLocalizedString("paywall.restore", comment: "")) {
            Task { await subscriptionManager.restorePurchases() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .disabled(subscriptionManager.purchaseState.isLoading)
    }

    // MARK: - Links legais

    private var legalLinksSection: some View {
        HStack(spacing: 16) {
            // TODO: Substitua pelas URLs reais
            Link(NSLocalizedString("paywall.legal.privacy_policy", comment: ""),
                 destination: URL(string: "https://exemplo.com/privacidade")!)
            Text("·")
            Link(NSLocalizedString("paywall.legal.terms_of_use", comment: ""),
                 destination: URL(string: "https://exemplo.com/termos")!)
            Text("·")
            Link(NSLocalizedString("paywall.legal.eula", comment: ""),
                 destination: URL(string: "https://www.apple.com/legal/macapps/stdeula/")!)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    // MARK: - Helpers

    private func periodLabel(for plan: SubscriptionProduct) -> String {
        switch plan {
        case .monthly:
            return NSLocalizedString("paywall.period.month", comment: "")
        case .annual:
            return NSLocalizedString("paywall.period.year", comment: "")
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
```

---

### 5. `Features/Subscription/SubscriptionStatusView.swift`

Badge exibido na sidebar ou menu mostrando o estado free/premium.

```swift
import SwiftUI

struct SubscriptionStatusView: View {

    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    var body: some View {
        Button {
            if !subscriptionManager.isPremium {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                    .foregroundStyle(subscriptionManager.isPremium ? .yellow : .secondary)

                Text(subscriptionManager.isPremium
                     ? NSLocalizedString("subscription.status.premium", comment: "")
                     : NSLocalizedString("subscription.status.free", comment: ""))
                    .font(.caption)
                    .fontWeight(.medium)

                if !subscriptionManager.isPremium {
                    Spacer()
                    Text(NSLocalizedString("subscription.status.upgrade", comment: ""))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.tint, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environment(subscriptionManager)
        }
    }
}

#Preview("Free") {
    SubscriptionStatusView()
        .environment(SubscriptionManager())
        .frame(width: 220)
        .padding()
}
```

---

### 6. `Shared/Views/PremiumGuard.swift`

Wrapper generico que bloqueia conteudo premium com overlay e CTA para o paywall.

```swift
import SwiftUI

/// Envolve qualquer conteudo atras de uma verificacao de assinatura.
/// Usuarios free veem um overlay com botao para abrir o paywall.
///
/// Uso direto:
///   PremiumGuard { MinhaView() }
///
/// Uso via modifier:
///   MinhaView().premiumRequired()
struct PremiumGuard<Content: View>: View {

    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if subscriptionManager.isPremium {
            content()
        } else {
            lockedOverlay
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                        .environment(subscriptionManager)
                }
        }
    }

    private var lockedOverlay: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text(NSLocalizedString("premium.locked.title", comment: ""))
                .font(.title2)
                .fontWeight(.semibold)

            Text(NSLocalizedString("premium.locked.message", comment: ""))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                showPaywall = true
            } label: {
                Text(NSLocalizedString("premium.locked.cta", comment: ""))
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - View Extension

extension View {
    /// Envolve esta view atras de um gate de assinatura premium.
    func premiumRequired() -> some View {
        PremiumGuard { self }
    }
}
```

---

## Integracao no App entry point

Adicione ao arquivo `<AppName>App.swift`:

```swift
import SwiftUI

@main
struct <AppName>App: App {

    @State private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            // TODO: Substitua pela sua RootView
            ContentView()
                .environment(subscriptionManager)
                .task {
                    await subscriptionManager.loadInitialState()
                }
        }
    }
}
```

## Proteger features premium

Para bloquear qualquer View atras da assinatura:

```swift
// Opcao A — modifier
MinhaFeatureView()
    .premiumRequired()

// Opcao B — wrapper explicito
PremiumGuard {
    MinhaFeatureView()
}
```

---

## Strings de localizacao necessarias

Adicione ao `Localizable.xcstrings` (ou `Localizable.strings`):

```
// Planos
"subscription.plan.monthly"      = "Mensal";
"subscription.plan.annual"       = "Anual";
"subscription.badge.best_value"  = "Melhor valor";

// Erros
"subscription.error.verification" = "Falha na verificacao da compra.";
"subscription.error.purchase"     = "Nao foi possivel completar a compra.";
"subscription.error.no_active"    = "Nenhuma assinatura ativa encontrada.";

// Status
"subscription.status.premium"    = "Premium";
"subscription.status.free"       = "Gratis";
"subscription.status.upgrade"    = "Upgrade";

// Paywall
"paywall.title"                  = "Desbloqueie tudo";
"paywall.subtitle"               = "Acesso ilimitado a todos os recursos.";
"paywall.features.title"         = "O que voce obtem";
"paywall.feature.1"              = "TODO: feature 1";
"paywall.feature.2"              = "TODO: feature 2";
"paywall.feature.3"              = "TODO: feature 3";
"paywall.feature.unlimited"      = "Uso ilimitado";
"paywall.loading_price"          = "Carregando preco...";
"paywall.subscribe"              = "Assinar agora";
"paywall.restore"                = "Restaurar compras";
"paywall.period.month"           = "mes";
"paywall.period.year"            = "ano";
"paywall.legal.privacy_policy"   = "Privacidade";
"paywall.legal.terms_of_use"     = "Termos de uso";
"paywall.legal.eula"             = "EULA";

// Premium locked
"premium.locked.title"           = "Recurso Premium";
"premium.locked.message"         = "Assine para desbloquear este recurso e muito mais.";
"premium.locked.cta"             = "Ver planos";

// Alerts
"alert.error"                    = "Erro";
"alert.ok"                       = "OK";
```

---

## Configuracao no App Store Connect

1. Acesse **App Store Connect → Seu App → In-App Purchases → Subscriptions**
2. Crie um **Subscription Group** (ex: `Premium`)
3. Adicione cada plano como **Auto-Renewable Subscription**
4. Copie os **Product IDs** gerados e substitua nos `case`s do `SubscriptionProduct` enum
5. Para testes locais, configure um **StoreKit Configuration File** no Xcode:
   - `File → New → File → StoreKit Configuration File`
   - Adicione os produtos com os mesmos IDs
   - Selecione o arquivo em `Edit Scheme → Run → Options → StoreKit Configuration`

---

## Apos criar os arquivos

Verifique:

1. `Utilities/ViewState.swift` existe no projeto — se nao, crie-o (ver skill `view-model`)
2. O `SubscriptionManager` e injetado via `.environment()` no App entry point
3. Os Product IDs no enum `SubscriptionProduct` batem exatamente com o App Store Connect
4. O `.premiumRequired()` modifier esta aplicado nas Views que exigem assinatura
5. As strings de localizacao foram adicionadas ao `Localizable.xcstrings`
6. O arquivo de configuracao StoreKit foi criado para testes locais

---

## Regras

- `SubscriptionManager` usa `@Observable` — requer **iOS 17+ / macOS 14+**
- Injecao via `.environment(SubscriptionManager.self)` — nunca `@EnvironmentObject`
- `SubscriptionManager` e singleton (`shared`) — nunca instancie multiplas vezes
- `StoreKitService` marcado como `@unchecked Sendable` — sem estado mutavel interno
- Nunca exiba preco hardcoded — use sempre `product.displayPrice` do StoreKit
- `purchaseState` usa `ViewState<Void>` — nunca booleans avulsos para loading/error
- Todo conteudo premium deve ser envolvido com `PremiumGuard` ou `.premiumRequired()`
- Listener de transacoes (`Transaction.updates`) iniciado em background no `loadInitialState()`

---

## Checklist de Revisao

- [ ] Product IDs no `SubscriptionProduct` batem com o App Store Connect
- [ ] `SubscriptionManager.shared` injetado no App entry point via `.environment()`
- [ ] `.task { await subscriptionManager.loadInitialState() }` no App entry point
- [ ] `StoreKitService` implementa `StoreKitServiceProtocol` (testavel via mock)
- [ ] `purchaseState` usa `ViewState<Void>` (nao booleans avulsos)
- [ ] `PaywallView` mostra preco via `product.displayPrice` (nao hardcoded)
- [ ] Botao de compra desabilitado enquanto `purchaseState.isLoading`
- [ ] Alert de erro conectado a `purchaseState.errorMessage`
- [ ] `.onChange(of: isPremium)` fecha o paywall automaticamente apos compra
- [ ] `.premiumRequired()` aplicado em todas as features premium
- [ ] Strings de localizacao adicionadas ao `Localizable.xcstrings`
- [ ] StoreKit Configuration File criado para testes locais no Xcode
- [ ] Listener de transacoes iniciado (`Transaction.updates`)
- [ ] `checkEntitlement()` chamado no `loadInitialState()` e no listener
