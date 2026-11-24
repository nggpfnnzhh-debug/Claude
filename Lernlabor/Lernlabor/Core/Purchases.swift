import Foundation
import Observation
import StoreKit

/// Kauf der Vollversion über StoreKit 2. Apple prüft die Käufe auf dem Gerät,
/// ein eigener Server ist nicht nötig.
@Observable
@MainActor
final class Purchases {
    static let fullVersionID = "de.podolskis.lernlabor.vollversion"

    private(set) var product: Product?
    private(set) var hasFullVersion = false
    private(set) var isWorking = false
    /// Hinweis für die Person, z. B. nach dem Wiederherstellen
    var message: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        guard LaunchOptions.screenshotScreen == nil else { return }
        // Käufe, die außerhalb dieses Bildschirms passieren: Kaufanfrage der Familie,
        // eingelöste Codes, Rückerstattungen
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refresh()
        }
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.fullVersionID]).first
        } catch {
            message = "Der Preis konnte nicht geladen werden. Prüf die Internetverbindung."
        }
    }

    /// Prüft, ob die Vollversion zur Apple-ID gehört (gekauft, per Code eingelöst, nicht erstattet).
    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.fullVersionID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        hasFullVersion = owned
    }

    func buy() async {
        if product == nil { await loadProduct() }
        guard let product else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                    message = nil
                } else {
                    message = "Der Kauf konnte nicht bestätigt werden. Bitte versuch es noch einmal."
                }
            case .pending:
                message = "Der Kauf wartet noch auf eine Bestätigung, zum Beispiel durch die Familie."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "Der Kauf hat nicht geklappt. Bitte versuch es noch einmal."
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refresh()
            message = hasFullVersion
                ? "Deine Vollversion ist wieder da."
                : "Zu deiner Apple-ID wurde kein Kauf gefunden."
        } catch {
            message = "Das Wiederherstellen hat nicht geklappt. Bitte versuch es noch einmal."
        }
    }
}
