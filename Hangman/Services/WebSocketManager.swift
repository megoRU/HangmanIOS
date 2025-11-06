import Foundation
import SwiftUI
import Combine

final class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    
    @AppStorage("name") private var name: String = "noname"
    @AppStorage("avatarImage") private var avatarData: Data?
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("playerId") private var playerId: String?
    @AppStorage("currentGameId") private var currentGameId: String?
    
    var webSocketTask: URLSessionWebSocketTask?
    
    private var urlSession: URLSession!
    private var rejoinGameId: String?
    private var disconnectionTime: Date?
    @Published var isConnected = false
    private var currentMode: MultiplayerMode?
    private var wasSearchingCompetitive = false
    private var isWaitingForCoopPartner = false
    private var pingTimer: Timer?
    
    let serverMessageSubject = PassthroughSubject<ServerMessage, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillResignActive() {
        print("💤 Приложение уходит в фон.")

        // 2.1. Для Coompetitive в режиме поиска: любой выход из игры (назад/сворачивание) отправлять close session
        if wasSearchingCompetitive {
            print("👋🏼 Игрок был в поиске соревновательной игры. Разрываем сессию.")
            disconnect()
            return
        }

        // 3. Для Cooperative в режиме ожидания друга: если игрок вышел, ничего не делаем при сворачивании.
        // Реконнект произойдет в appDidBecomeActive.
        if isWaitingForCoopPartner {
            print("⏳ Игрок в лобби ожидания друга. Ничего не делаем при сворачивании.")
            return
        }

        if currentGameId != nil {
            print("👋🏼 Игрок был в активной игре. Разрываем соединение для возможного реконнекта.")
            disconnect()
        }
    }

    @objc private func appDidBecomeActive() {
        print("☀️ Приложение стало активным.")

        if self.wasSearchingCompetitive {
            print("🔁 Игрок вернулся после сворачивания во время поиска соревновательной игры. Начинаем поиск заново.")
            if !isConnected { connect() }
            return
        }

        if self.isWaitingForCoopPartner {
            print("🔁 Игрок вернулся в лобби ожидания друга. Создаем комнату заново.")
            if !isConnected { connect() }
            return
        }

        if !isConnected && currentGameId != nil {
            if let disconnectionTime = self.disconnectionTime {
                let timeSinceDisconnection = Date().timeIntervalSince(disconnectionTime)
                if timeSinceDisconnection <= 30 {
                    print("🔌 [RECONNECT] Соединение с активной игрой было разорвано \(String(format: "%.1f", timeSinceDisconnection))с назад. Пытаемся переподключиться...")
                    rejoinGameId = currentGameId
                    connect()
                } else {
                    print("🔌 [RECONNECT] Окно для переподключения (30с) истекло. Прошло \(String(format: "%.1f", timeSinceDisconnection))с. Очищаем состояние.")
                    // clearGameStale() // PlayerId не должен удаляться
                }
                self.disconnectionTime = nil
            } else {
                print("🔌 [RECONNECT] Соединение с активной игрой было разорвано, пытаемся переподключиться (время разрыва неизвестно)...")
                rejoinGameId = currentGameId
                connect()
            }
        }
    }
    
    func connect() {
        if isConnected {
            print("ℹ️ WebSocket уже подключен.")
            return
        }
        
        print("🔌 WebSocket подключается...")
        guard let url = URL(string: "wss://hangman.megoru.ru/ws") else {
            print("❌ Неверный URL WebSocket")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }
    
    func findGame(mode: MultiplayerMode) {
        connect()

        if self.playerId == nil {
            self.playerId = UUID().uuidString
            print("🆔 PlayerId не найден, создан новый: \(self.playerId!)")
        }
        self.currentMode = mode
        if mode == .duel {
            self.wasSearchingCompetitive = true
        }
        
        $isConnected
            .first(where: { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.sendFindOrCreate(mode: mode)
            }
            .store(in: &cancellables)
    }
    
    func reconnect(gameId: String) {
        if let playerId = playerId {
            let payload = ReconnectPayload(gameId: gameId, playerId: playerId)
            send(payload)
        } else {
            print("ℹ️ PlayerId is nil RECONNECT невозможен!")
        }
    }
    
    func disconnect() {
        guard isConnected else {
            print("ℹ️ WebSocket уже отключен.")
            return
        }
        print("🔌 WebSocket отключается.")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        webSocketTask = nil
    }
    
    func joinMulti(gameId: String) {
        connect()

        if self.playerId == nil {
            self.playerId = UUID().uuidString
            print("🆔 PlayerId не найден, создан новый: \(self.playerId!)")
        }

        $isConnected
            .first(where: { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let payload = JoinMultiPayload(
                    gameId: gameId,
                    playerId: self.playerId ?? "",
                    name: self.name,
                    image: self.avatarData?.base64EncodedString() ?? ""
                )
                self.send(payload)
            }
            .store(in: &cancellables)
    }
    
    func leaveGame(gameId: String?) {
        guard isConnected, let ws = webSocketTask, ws.state == .running else {
            print("⚠️ Нельзя отправить LEAVE_GAME, сокет закрыт")
            return
        }
        let payload = LeaveGamePayload(gameId: gameId)
        send(payload)
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        print("✅ WebSocket подключен")
        startPing()

        if let gameIdToRejoin = self.rejoinGameId {
            print("🔁 Пытаемся переподключиться к игре \(gameIdToRejoin)")
            reconnect(gameId: gameIdToRejoin)
            self.rejoinGameId = nil
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        stopPing()
        if closeCode != .goingAway && currentGameId != nil {
            print("❌ WebSocket отключен непреднамеренно, код: \(closeCode.rawValue). Запускаем 30-секундный таймер на переподключение.")
            disconnectionTime = Date()
        } else {
            print("❌ WebSocket отключен штатно.")
        }
    }
    
    // MARK: - Sending messages
     private func startPing() {
        stopPing()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        print("📤 Отправляем PING")
        webSocketTask?.sendPing { error in
            if let error = error {
                print("❌ Ошибка отправки PING: \(error)")
            }
        }
    }
    
    private func sendFindOrCreate(mode: MultiplayerMode) {
        guard let currentPlayerId = self.playerId else {
            print("❌ Ошибка: playerId отсутствует при попытке найти или создать игру.")
            return
        }

        let lang = selectedLanguage.lowercased()
        let name = self.name
        let image = avatarData?.base64EncodedString() ?? ""

        switch mode {
        case .duel:
            let payload = FindGamePayload(lang: lang, name: name, image: image, playerId: currentPlayerId)
            send(payload)
        case .friends:
            let payload = CreateMultiPayload(lang: lang, name: name, image: image, playerId: currentPlayerId)
            send(payload)
        case .code_friend:
            print("🟢 Режим code_friend — ждём ручного ввода Game ID")
            return
        }
    }
    
    func sendMove(letter: Character, gameId: String) {
        guard isConnected else { return }
        let payload = MovePayload(gameId: gameId, letter: String(letter).uppercased())
        send(payload)
    }
    
    func send<T: Encodable>(_ message: T) {
        guard let webSocketTask = webSocketTask, webSocketTask.state == .running else {
            print("⚠️ Попытка отправки, но сокет не в состоянии running")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📤 Отправляем: \(jsonString)")
                webSocketTask.send(.string(jsonString)) { error in
                    if let error = error {
                        print("❌ Ошибка отправки: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("❌ Ошибка кодирования: \(error.localizedDescription)")
        }
    }

    
    // MARK: - Receiving messages
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                let nsError = error as NSError
                // 50: ENETDOWN, 54: ECONNRESET, 57: ENOTCONN, 60: ETIMEDOUT, 9: EBADF
                let networkErrors = [50, 54, 57, 60, 9]

                if nsError.domain == NSPOSIXErrorDomain && networkErrors.contains(nsError.code) {
                    if self.currentGameId != nil {
                         print("ℹ️ WebSocket receive loop failed during a game, likely due to network loss/backgrounding. Error: \(error.localizedDescription). Reconnect will be attempted on app activation.")
                    } else {
                        print("ℹ️ WebSocket receive loop ended (normal closure): \(error.localizedDescription)")
                    }
                }
                self.isConnected = false
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.listen()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        print("📩 Получено сообщение: \(text)")

        guard let data = text.data(using: .utf8) else {
            print("⚠️ Ошибка: не удалось преобразовать текст в Data")
            return
        }

        struct MessageType: Decodable {
            let type: String
        }

        do {
            let decoder = JSONDecoder()
            let messageType = try decoder.decode(MessageType.self, from: data)
            print("🔍 Тип сообщения: \(messageType.type)")

            let message: ServerMessage
            switch messageType.type {
            case "WAITING":
                message = .waiting
            case "MATCH_FOUND":
                print("🧩 Распарсиваю MATCH_FOUND")
                message = .matchFound(try decoder.decode(MatchFoundPayload.self, from: data))
            case "GAME_CANCELED":
                print("🚫 Распарсиваю GAME_CANCELED")
                message = .gameCanceled(try decoder.decode(GameCanceledPayload.self, from: data))
            case "STATE_UPDATE":
                print("🔄 Распарсиваю STATE_UPDATE")
                message = .stateUpdate(try decoder.decode(StateUpdatePayload.self, from: data))
            case "ROOM_CREATED":
                print("🏠 Распарсиваю ROOM_CREATED")
                message = .roomCreated(try decoder.decode(RoomCreatedPayload.self, from: data))
            case "PLAYER_JOINED":
                print("👤 Распарсиваю PLAYER_JOINED")
                message = .playerJoined(try decoder.decode(PlayerJoinedPayload.self, from: data))
            case "PLAYER_LEFT":
                print("🚶 Распарсиваю PLAYER_LEFT")
                message = .playerLeft(try decoder.decode(PlayerLeftPayload.self, from: data))
            case "GAME_OVER":
                print("🏁 Распарсиваю GAME_OVER")
                message = .gameOver(try decoder.decode(GameOverPayload.self, from: data))
            case "GAME_OVER_COOP":
                print("🤝 Распарсиваю GAME_OVER_COOP")
                message = .gameOverCoop(try decoder.decode(CoopGameOverPayload.self, from: data))
            case "RESTORED":
                print("♻️ Распарсиваю RESTORED")
                message = .restored(try decoder.decode(RestoredPayload.self, from: data))
            case "ERROR":
                print("❗ Распарсиваю ERROR")
                message = .error(try decoder.decode(ErrorPayload.self, from: data))
            default:
                print("⚠️ Неизвестный тип сообщения: \(messageType.type)")
                return
            }

            DispatchQueue.main.async {
                print("✅ Отправляю сообщение в subject: \(message)")
                self.serverMessageSubject.send(message)
            }
        } catch {
            print("❌ Ошибка декодирования: \(error)")
            if let decodingError = error as? DecodingError {
                print("   Детали: \(decodingError)")
            }
        }
    }
}
