import Foundation
import TonConnectTransport

/// Reconnect layer on top of the honest NativeEventSource (the transport
/// never reconnects itself — the whole reconnect policy lives here, additively).
///
/// Single resource manager: exactly ONE live source under the lock.
/// Every reconnect trigger (transport onError, heartbeat watchdog) goes through
/// openSource(), which FIRST closes the current stream and then creates a new
/// one — there are never two live SSE streams for one client_id.
///
/// Cadence: first pause 2s, every following one 5s, indefinitely while the
/// session lives; a successful onOpen resets the step. A deliberate design of
/// this package, inspired by the JS SDK's numbers but NOT a 1:1 parity: the SDK
/// keeps a flat 2s for SSE reconnect (defaultReconnectDelay) and a separate flat
/// 5s for POST resend (defaultResendDelay); our POST /message is single-attempt,
/// and 2s→5s is specifically the SSE-reconnect cadence. The delay is not
/// observable by the wallet/bridge — spec parity is intact.
///
/// Quiet degradation: a dead host retries on the cadence with a
/// real pause (never a 0-delay loop — we do not DoS the bridge) and without log
/// spam; session/event ids are never printed.
final class ReconnectGateway: @unchecked Sendable {

    private let bridgeUrl: String
    private let clientId: String
    private let sessionConfiguration: URLSessionConfiguration
    private let clock: any ReconnectClock
    /// Watchdog threshold: 30s by default — [ASSUMED]: neither the spec nor
    /// the SDK documents the heartbeat interval; the number comes from a live smoke test.
    private let heartbeatTimeout: TimeInterval

    /// Exposed to the engine: parsed events and the stream-open signal.
    var onMessage: ((_ id: String?, _ data: String) -> Void)?
    var onOpen: (() -> Void)?

    private let lock = NSLock()
    private var source: NativeEventSource?
    private var lastEventId: String?
    private var reconnectStep = 0
    private var reconnectPending = false
    private var isClosed = false
    /// The watchdog's "ticket number": every reset issues a new one; only the timer
    /// holding the current number fires, stale ones stay silent.
    private var watchdogGeneration = 0

    init(bridgeUrl: String,
         clientId: String,
         initialLastEventId: String? = nil,
         sessionConfiguration: URLSessionConfiguration = .ephemeral,
         clock: any ReconnectClock = SystemReconnectClock(),
         heartbeatTimeout: TimeInterval = 30) {
        self.bridgeUrl = bridgeUrl
        self.clientId = clientId
        self.sessionConfiguration = sessionConfiguration
        self.clock = clock
        self.heartbeatTimeout = heartbeatTimeout
        self.lastEventId = initialLastEventId // restore/wake resume from the saved frame
    }

    func start() { openSource() }

    func close() {
        lock.lock()
        isClosed = true
        watchdogGeneration += 1 // silence the watchdog
        let current = source
        source = nil
        lock.unlock()
        current?.close()
    }

    // MARK: - single resource manager

    /// The ONLY place an SSE stream is created: close the old one first, then
    /// create the new one. last_event_id goes through the source's init, NOT
    /// through eventsURL (single source of truth).
    private func openSource() {
        lock.lock()
        if isClosed { lock.unlock(); return }
        let old = source
        source = nil
        let url = RPCEnvelope.eventsURL(bridgeUrl: bridgeUrl, clientId: clientId, lastEventId: nil)
        let next = NativeEventSource(url: url,
                                     lastEventId: lastEventId,
                                     sessionConfiguration: sessionConfiguration)
        next.onOpen = { [weak self] in self?.handleOpen() }
        next.onMessage = { [weak self] id, data in self?.handleMessage(id: id, data: data) }
        next.onRawData = { [weak self] _ in self?.resetWatchdog() } // any bytes
        next.onError = { [weak self] _ in self?.scheduleReconnect() } // quiet, no logging
        source = next
        lock.unlock()
        old?.close()
        next.connect()
    }

    private func handleOpen() {
        lock.lock()
        reconnectStep = 0 // a successful open resets the cadence
        lock.unlock()
        resetWatchdog()
        onOpen?()
    }

    private func handleMessage(id: String?, data: String) {
        lock.lock()
        if let id { lastEventId = id } // the next reconnect resumes from this frame
        lock.unlock()
        resetWatchdog()
        onMessage?(id, data)
    }

    // MARK: - reconnect cadence

    private func scheduleReconnect() {
        lock.lock()
        guard !isClosed, !reconnectPending else { lock.unlock(); return }
        reconnectPending = true // single-flight: watchdog+onError do not duplicate
        let delay = reconnectStep == 0 ? 2.0 : 5.0
        reconnectStep += 1
        lock.unlock()
        Task { [weak self] in
            guard let self else { return }
            try? await self.clock.sleep(seconds: delay)
            self.lock.withLock { self.reconnectPending = false }
            self.openSource() // re-checks isClosed under the lock itself
        }
    }

    // MARK: - heartbeat watchdog

    /// Re-arm the watchdog on ANY stream activity: open, an event, raw bytes
    /// (a legacy heartbeat without data: produces no event but does send bytes).
    private func resetWatchdog() {
        lock.lock()
        guard !isClosed else { lock.unlock(); return }
        watchdogGeneration += 1
        let generation = watchdogGeneration
        lock.unlock()
        Task { [weak self] in
            guard let self else { return }
            try? await self.clock.sleep(seconds: self.heartbeatTimeout)
            let stale = self.lock.withLock {
                generation != self.watchdogGeneration || self.isClosed
            }
            // Silence beyond the threshold is a "quiet death" of the connection
            // (a NAT timeout URLSession never reports): logically the same as onError.
            if !stale { self.scheduleReconnect() }
        }
    }
}
