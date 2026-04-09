import Foundation
internal import Combine

// MARK: - Supabase Realtime via Phoenix Channels WebSocket

class SupabaseRealtimeService: NSObject, ObservableObject {
    static let shared = SupabaseRealtimeService()

    /// Emite el record completo de un merchant cada vez que Supabase notifica un UPDATE
    let merchantUpdatePublisher = PassthroughSubject<[String: Any], Never>()

    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )
    private var heartbeatTimer: Timer?
    private var ref = 0
    private var isConnected = false
    private var reconnectDelay: TimeInterval = 2.0

    private let wsURL = "wss://fkkddxibqlmunuqzdrsm.supabase.co/realtime/v1/websocket"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZra2RkeGlicWxtdW51cXpkcnNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MDI4OTUsImV4cCI6MjA5MTI3ODg5NX0.smyrNinvVQ_RwaKpekXzZ4Xo8O5a5DbNuVZcwcuLjeg"

    private override init() { super.init() }

    // MARK: - Conexión

    func connect() {
        guard !isConnected else { return }
        guard let url = URL(string: "\(wsURL)?apikey=\(apiKey)&vsn=1.0.0") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true

        print("🔌 [Realtime] Conectando a Supabase Realtime…")
        listenForMessages()
    }

    func disconnect() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("🔌 [Realtime] Desconectado")
    }

    // MARK: - Suscripción

    private func joinMerchantsChannel() {
        let message: [String: Any] = [
            "topic": "realtime:public:merchants",
            "event": "phx_join",
            "payload": [
                "config": [
                    "postgres_changes": [
                        ["event": "UPDATE", "schema": "public", "table": "merchants"]
                    ]
                ]
            ],
            "ref": nextRef()
        ]
        send(message)
        print("📡 [Realtime] Suscrito a cambios en merchants")
    }

    // MARK: - Envío

    private func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(text)) { error in
            if let error {
                print("⚠️ [Realtime] Error enviando: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Recepción

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message { self.handle(text) }
                if case .data(let data) = message,
                   let text = String(data: data, encoding: .utf8) { self.handle(text) }
                self.listenForMessages()
            case .failure(let error):
                print("⚠️ [Realtime] Error recibiendo: \(error.localizedDescription)")
                self.scheduleReconnect()
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let event = json["event"] as? String ?? ""

        switch event {
        case "phx_reply":
            let topic = json["topic"] as? String ?? ""
            if let payload = json["payload"] as? [String: Any],
               let status = payload["status"] as? String {
                print("✅ [Realtime] Canal \(topic): \(status)")
            }

        case "postgres_changes":
            guard let payload = json["payload"] as? [String: Any],
                  let changeData = payload["data"] as? [String: Any],
                  let record = changeData["record"] as? [String: Any] else { return }

            let name = record["business_name"] as? String ?? "?"
            let onRoute = record["is_on_route"] as? Bool ?? false
            print("📍 [Realtime] UPDATE merchant '\(name)' isOnRoute=\(onRoute)")

            DispatchQueue.main.async {
                self.merchantUpdatePublisher.send(record)
            }

        default:
            break
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.send([
                "topic": "phoenix",
                "event": "heartbeat",
                "payload": [:] as [String: Any],
                "ref": self.nextRef()
            ])
        }
    }

    // MARK: - Reconexión con backoff exponencial

    private func scheduleReconnect() {
        isConnected = false
        heartbeatTimer?.invalidate()
        let delay = reconnectDelay
        reconnectDelay = min(reconnectDelay * 2, 60.0)
        print("🔄 [Realtime] Reconectando en \(Int(delay))s…")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }

    private func nextRef() -> String {
        ref += 1
        return "\(ref)"
    }
}

// MARK: - URLSessionWebSocketDelegate

extension SupabaseRealtimeService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("✅ [Realtime] WebSocket abierto")
        reconnectDelay = 2.0
        startHeartbeat()
        joinMerchantsChannel()
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("🔌 [Realtime] WebSocket cerrado: \(closeCode.rawValue)")
        isConnected = false
        scheduleReconnect()
    }
}
