import Foundation
import SwiftUI

final class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
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
    private var isConnected = false
    private var currentMode: MultiplayerMode?
    private var wasSearchingCompetitive = false
    private var isWaitingForCoopPartner = false
    
    weak var delegate: WebSocketManagerDelegate?
    
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

        // 1.1. Для Coompetitive в режиме игры: любой выход из игры (назад/сворачивание) отправлять LEAVE_GAME
        // 3.1. Для Cooperative в режиме игры: сворачивание или выход отправлять LEAVE_GAME
        if currentGameId != nil {
            print("👋🏼 Игрок был в активной игре. Отправляем LEAVE_GAME.")
            leaveGame(gameId: currentGameId)
        }
    }

    @objc private func appDidBecomeActive() {
        print("☀️ Приложение стало активным.")

        if self.wasSearchingCompetitive {
            print("🔁 Игрок вернулся после сворачивания во время поиска соревновательной игры. Начинаем поиск заново.")
            if !isConnected { connect() } else { delegate?.webSocketDidConnect() }
            return
        }

        if self.isWaitingForCoopPartner {
            print("🔁 Игрок вернулся в лобби ожидания друга. Создаем комнату заново.")
            if !isConnected { connect() } else { delegate?.webSocketDidConnect() }
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
                    delegate?.didReceiveError("Время для переподключения истекло.")
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
            print("ℹ️ Уже подключены к WebSocket, немедленно вызываем webSocketDidConnect")
            DispatchQueue.main.async {
                self.delegate?.webSocketDidConnect()
            }
            return
        }
        
        print("🔌 WebSocket подключается...")
        guard let url = URL(string: "wss://hangman.megoru.ru/ws") else {
            delegate?.didReceiveError("Неверный URL WebSocket")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }
    
    func findGame(mode: MultiplayerMode) {
        if self.playerId == nil {
            self.playerId = UUID().uuidString
            print("🆔 PlayerId не найден, создан новый: \(self.playerId!)")
        }
        self.currentMode = mode
        if mode == .duel {
            self.wasSearchingCompetitive = true
        }
        
        sendFindOrCreate(mode: mode)
    }
    
    func reconnect(gameId: String) {
        if let playerId = playerId {
            sendReconnect(gameId: gameId, playerId: playerId)
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
        delegate = nil
    }
    
    func joinMulti(gameId: String) {
        guard isConnected else { return }
        let msg: [String: Any] = [
            "type": "JOIN_MULTI",
            "gameId": gameId,
            "playerId": playerId ?? NSNull(),
            "name": name.isEmpty ? NSNull() : name,
            "image": avatarData?.base64EncodedString() ?? NSNull()
        ]
        print("📤 Отправляем JOIN_MULTI:", msg)
        send(json: msg)
    }
    
    func leaveGame(gameId: String?) {
        guard isConnected, let ws = webSocketTask, ws.state == .running else {
            print("⚠️ Нельзя отправить LEAVE_GAME, сокет закрыт")
            return
        }
        var msg: [String: Any] = ["type": "LEAVE_GAME"]
        if let gameId = gameId {
            msg["gameId"] = gameId
        }
        print("🔌 Отправка LEAVE_GAME: \(msg)")
        send(json: msg)
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        print("✅ WebSocket подключен")

        DispatchQueue.main.async {
            self.delegate?.webSocketDidConnect()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let gameIdToRejoin = self.rejoinGameId {
                print("🔁 Пытаемся переподключиться к игре \(gameIdToRejoin)")
                self.sendReconnect(gameId: gameIdToRejoin, playerId: self.playerId ?? NSNull())
                self.rejoinGameId = nil
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        if closeCode != .goingAway && currentGameId != nil {
            print("❌ WebSocket отключен непреднамеренно, код: \(closeCode.rawValue). Запускаем 30-секундный таймер на переподключение.")
            disconnectionTime = Date()
        } else {
            print("❌ WebSocket отключен штатно.")
        }
    }
    
    // MARK: - Sending messages
    
    private func sendFindOrCreate(mode: MultiplayerMode) {
        var msgDict: [String: Any]
        let nameValue: Any = name.isEmpty ? NSNull() : name
        let imageValue: Any = avatarData?.base64EncodedString() ?? NSNull()
        
        guard let currentPlayerId = self.playerId else {
            print("❌ Ошибка: playerId отсутствует при попытке найти или создать игру.")
            return
        }

        switch mode {
        case .duel:
            msgDict = ["type": "FIND_GAME",
                       "lang": selectedLanguage.lowercased(),
                       "name": nameValue,
                       "image": imageValue,
                       "playerId": currentPlayerId]
        case .friends:
            msgDict = ["type": "CREATE_MULTI",
                       "lang": selectedLanguage.lowercased(),
                       "name": nameValue,
                       "image": imageValue,
                       "playerId": currentPlayerId]
        case .code_friend:
            print("🟢 Режим code_friend — ждём ручного ввода Game ID")
            return
        }
        print("📤 Отправляем:", msgDict)
        send(json: msgDict)
    }
    
    func sendMove(letter: Character, gameId: String) {
        guard isConnected else { return }
        let msgDict: [String: Any] = [
            "type": "MOVE",
            "gameId": gameId,
            "letter": String(letter).uppercased()
        ]
        print("📤 Отправляем:", msgDict)
        send(json: msgDict)
    }
    
    func sendReconnect(gameId: String, playerId: Any) {
        guard isConnected else { return }
        let msg: [String: Any] = [
            "type": "RECONNECT",
            "gameId": gameId,
            "playerId": playerId
        ]
        print("📤 Отправляем RECONNECT:", msg)
        send(json: msg)
    }
    
    public func send(json: [String: Any]) {
        guard let webSocketTask,
              webSocketTask.state == .running else {
            print("⚠️ Попытка отправки, но сокет не в состоянии running")
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(message) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveError("Ошибка отправки: \(error.localizedDescription)")
                }
            }
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
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        DispatchQueue.main.async {
            switch type {
            case "WAITING":
                print("✅ WAITING")
                self.delegate?.didReceiveWaiting()
                
            case "MATCH_FOUND":
                struct MatchFoundPayload: Decodable {
                    let gameId: String
                    let wordLength: Int
                    let players: [Player]
                }
                self.decodePayload(MatchFoundPayload.self, data: data) { payload in
                    print("✅ MATCH_FOUND, wordLength:", payload.wordLength, "players:", payload.players.count)
                    self.currentGameId = payload.gameId
                    self.wasSearchingCompetitive = false
                    self.isWaitingForCoopPartner = false
                    self.delegate?.didFindMatch(gameId: payload.gameId, wordLength: payload.wordLength, players: payload.players)
                }
                
            case "GAME_CANCELED":
                if let word = json["word"] as? String {
                    print("✅ GAME_CANCELED, word:", word)
                    self.delegate?.didReceiveGameCanceled(word: word)
                }
                
            case "STATE_UPDATE":
                if let maskedWord = json["maskedWord"] as? String,
                   let attemptsLeft = json["attemptsLeft"] as? Int {
                    print("✅ STATE_UPDATE, maskedWord:", maskedWord)
                    let duplicate = json["duplicate"] as? Bool ?? false
                    let guessedSet = (json["guessed"] as? [String]).map { Set($0) }
                    self.delegate?.didReceiveStateUpdate(maskedWord: maskedWord, attemptsLeft: attemptsLeft, duplicate: duplicate, guessed: guessedSet)
                }
                
            case "ROOM_CREATED":
                if let gameId = json["gameId"] as? String {
                    print("✅ Игра создана, gameId:", gameId)
                    self.currentGameId = gameId
                    self.isWaitingForCoopPartner = true
                    self.delegate?.didCreateRoom(gameId: gameId)
                    self.delegate?.didReceiveWaitingFriend()
                }
                
            case "PLAYER_JOINED":
                struct PlayerJoinedPayload: Decodable {
                    let attemptsLeft: Int
                    let wordLength: Int
                    let players: [Player]
                    let gameId: String
                    let guessed: [String]
                }
                self.decodePayload(PlayerJoinedPayload.self, data: data) { payload in
                    print("✅ PLAYER_JOINED, players:", payload.players.count)
                    self.currentGameId = payload.gameId
                    if payload.players.count >= 2 {
                        self.isWaitingForCoopPartner = false
                    }
                    self.delegate?.didReceivePlayerJoined(
                        attemptsLeft: payload.attemptsLeft,
                        wordLength: payload.wordLength,
                        players: payload.players,
                        gameId: payload.gameId,
                        guessed: Set(payload.guessed)
                    )
                }
                
            case "PLAYER_LEFT":
                if let name = json["name"] as? String {
                    print("✅ PLAYER_LEFT, name:", name)
                    self.delegate?.didReceivePlayerLeft(name: name)
                }
                
            case "GAME_OVER":
                if let result = json["result"] as? String,
                   let word = json["word"] as? String {
                    print("✅ Игра завершилась, result:", result)
                    self.delegate?.didReceiveGameOver(win: result == "WIN", word: word)
                    // self.playerId = nil // ID игрока должен сохраняться
                    self.currentGameId = nil
                    self.currentMode = nil
                    self.wasSearchingCompetitive = false
                    self.isWaitingForCoopPartner = false
                }
                
            case "GAME_OVER_COOP":
                struct CoopGameOverPayload: Decodable {
                    let result: String
                    let word: String
                    let attemptsLeft: Int
                    let wordLength: Int
                    let players: [Player]
                    let gameId: String
                    let guessed: [String]
                }
                self.decodePayload(CoopGameOverPayload.self, data: data) { payload in
                    print("✅ Совместная игра завершилась, result:", payload.result)
                    self.currentGameId = payload.gameId
                    self.isWaitingForCoopPartner = false
                    self.delegate?.didReceiveCoopGameOver(
                        result: payload.result,
                        word: payload.word,
                        attemptsLeft: payload.attemptsLeft,
                        wordLength: payload.wordLength,
                        players: payload.players,
                        gameId: payload.gameId,
                        guessed: Set(payload.guessed)
                    )
                }
                
            case "RESTORED":
                struct RestoredPayload: Decodable {
                    let gameId: String
                    let wordLength: Int
                    let maskedWord: String
                    let attemptsLeft: Int
                    let guessed: [String]
                    let players: [Player]
                }
                self.decodePayload(RestoredPayload.self, data: data) { payload in
                    print("✅ RESTORED, gameId:", payload.gameId)
                    self.currentGameId = payload.gameId
                    if self.currentMode != .duel && payload.players.count < 2 {
                        self.isWaitingForCoopPartner = true
                    } else {
                        self.isWaitingForCoopPartner = false
                    }
                    self.delegate?.didRestoreGame(
                        gameId: payload.gameId,
                        wordLength: payload.wordLength,
                        maskedWord: payload.maskedWord,
                        attemptsLeft: payload.attemptsLeft,
                        guessed: Set(payload.guessed),
                        players: payload.players
                    )
                }
                
            case "ERROR":
                if let msg = json["msg"] as? String {
                    self.delegate?.didReceiveError(msg)
                }
                
            default:
                break
            }
        }
    }
    
    // Вспомогательная функция для декодирования payload
    private func decodePayload<T: Decodable>(_ type: T.Type, data: Data, completion: (T) -> Void) {
        do {
            let payload = try JSONDecoder().decode(type, from: data)
            completion(payload)
        } catch {
            print("❌ Ошибка декодирования \(type):", error.localizedDescription)
            if let decodingError = error as? DecodingError {
                print("❌ Детали ошибки декодирования:", decodingError)
            }
            self.delegate?.didReceiveError("Ошибка обработки данных с сервера. Детали в консоли.")
        }
    }
}
