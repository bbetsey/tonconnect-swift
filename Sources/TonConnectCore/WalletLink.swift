import Foundation

/// Building the links that open a wallet app.
///
/// Two families live here, and the difference is not cosmetic:
///
/// * a regular universal link (`https://app.tonkeeper.com/ton-connect`) carries
///   our parameters as ordinary query items;
/// * a Telegram Mini App link (`https://t.me/wallet?attach=wallet`, `tg://…`)
///   does not — Telegram never hands arbitrary query parameters to the Mini App.
///   Everything the wallet must read travels inside a single `startapp` value in
/// Telegram's own substitution encoding (observed on a live wallet: a plain query
///   opened the wallet on its default screen, with no request on it at all).
///
/// SDK parity: `@tonconnect/sdk` utils/url.ts (isTelegramUrl,
/// encodeTelegramUrlParameters) and universal-link.ts (generateTGUniversalLink,
/// convertToDirectLink); `@tonconnect/ui` url-strategy-helpers.ts
/// (redirectToTelegram, addReturnStrategy).
///
/// `package` on purpose: both engines and the UI build wallet links, but this is
/// not something an integrator should have to know about.
package enum WalletLink {

    // MARK: - which family

    /// SDK parity (utils/url.ts isTelegramUrl): the tg:// scheme or the t.me host.
    package static func isTelegram(_ link: String) -> Bool {
        guard let components = URLComponents(string: link) else { return false }
        return isTelegram(components)
    }

    package static func isTelegram(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return isTelegram(components)
    }

    private static func isTelegram(_ components: URLComponents) -> Bool {
        components.scheme == "tg" || components.host == "t.me"
    }

    // MARK: - Telegram transport

    /// SDK parity (convertToDirectLink): `?attach=wallet` means "attach the Mini
    /// App to a chat"; to open the app itself the parameter is dropped and
    /// `/start` is appended to the path. A link without `attach` is left alone.
    package static func convertToDirectLink(_ components: inout URLComponents) {
        let items = components.queryItems ?? []
        let remaining = items.filter { $0.name != "attach" }
        guard remaining.count != items.count else { return }
        components.path += "/start"
        components.queryItems = remaining.isEmpty ? nil : remaining
    }

    /// Percent-encodes everything except [A-Za-z0-9.-_] — exactly the alphabet
    /// the substitution map below knows how to protect.
    package static func strictPercentEncode(_ value: String) -> String {
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-_")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    /// SDK parity (utils/url.ts encodeTelegramUrlParameters) — the substitution
    /// ORDER is load-bearing: dots/dashes/underscores first, then the separators,
    /// then every remaining percent sign becomes the `--` marker.
    package static func encodeTelegramParameters(_ parameters: String) -> String {
        parameters
            .replacingOccurrences(of: ".", with: "%2E")
            .replacingOccurrences(of: "-", with: "%2D")
            .replacingOccurrences(of: "_", with: "%5F")
            .replacingOccurrences(of: "&", with: "-")
            .replacingOccurrences(of: "=", with: "__")
            .replacingOccurrences(of: "%", with: "--")
    }

    // MARK: - return strategy

    /// Appends `ret=<strategy>` to a link we are about to open — the wallet sends
    /// the user back to us after approval/rejection.
    ///
    /// For a Telegram link the ret rides INSIDE the `startapp` payload as a
    /// `-ret__back` suffix (SDK parity: addReturnStrategy). A link with no payload
    /// of its own — waking an already connected wallet — still gets a bare
    /// `startapp=tonconnect` first, exactly as redirectToTelegram does.
    package static func appendingReturnStrategy(_ ret: String, to url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard isTelegram(components) else {
            components.queryItems = (components.queryItems ?? []) +
                [URLQueryItem(name: "ret", value: ret)]
            return components.url ?? url
        }
        var items = components.queryItems ?? []
        let index: Int
        if let existing = items.firstIndex(where: { $0.name == "startapp" }) {
            index = existing
        } else {
            items.append(URLQueryItem(name: "startapp", value: "tonconnect"))
            index = items.count - 1
        }
        items[index].value = (items[index].value ?? "") + "-" + encodeTelegramParameters("ret=\(ret)")
        components.queryItems = items
        return components.url ?? url
    }
}
