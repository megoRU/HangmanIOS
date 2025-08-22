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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        print("☀️ Приложение стало активным.")
        if !isConnected && currentGameId != nil {
            if let disconnectionTime = self.disconnectionTime {
                let timeSinceDisconnection = Date().timeIntervalSince(disconnectionTime)
                if timeSinceDisconnection <= 30 {
                    print("🔌 Соединение было разорвано \(String(format: "%.1f", timeSinceDisconnection))с назад. Пытаемся переподключиться...")
                    rejoinGameId = currentGameId
                    connect()
                } else {
                    print("🔌 Окно для переподключения (30с) истекло. Прошло \(String(format: "%.1f", timeSinceDisconnection))с. Очищаем состояние.")
                    clearGameStale()
                }
                self.disconnectionTime = nil
            } else {
                print("🔌 Соединение было разорвано, пытаемся переподключиться (время разрыва неизвестно)...")
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
    
    func findGame(mode: MultiplayerMode, playerId: String) {
        self.playerId = playerId
        
        sendFindOrCreate(mode: mode, playerId: playerId)
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
    
    func clearGameStale() {
        print("🗑️ Очистка состояния игры: gameId и playerId")
        currentGameId = nil
        playerId = nil
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
    
    private func sendFindOrCreate(mode: MultiplayerMode, playerId: String) {
        var msgDict: [String: Any]
        let nameValue: Any = name.isEmpty ? NSNull() : name
        let imageValue: Any = avatarData?.base64EncodedString() ?? NSNull()
        
        switch mode {
        case .duel:
            msgDict = ["type": "FIND_GAME",
                       "lang": selectedLanguage.lowercased(),
                       "name": nameValue,
                       "image": imageValue,
                       "playerId": playerId]
        case .friends:
            msgDict = ["type": "CREATE_MULTI",
                       "lang": selectedLanguage.lowercased(),
                       "name": nameValue,
                       "image": imageValue,
                       "playerId": playerId]
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
                // 57: ENOTCONN (Socket is not connected), 9: EBADF (Bad file descriptor)
                if nsError.domain == NSPOSIXErrorDomain && (nsError.code == 57 || nsError.code == 9) {
                    print("ℹ️ WebSocket receive loop ended (normal closure): \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        print("🔴 WebSocket receive error: \(error.localizedDescription)")
                        self.delegate?.didReceiveError("Ошибка приёмки: \(error.localizedDescription)")
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
                    self.playerId = nil
                    self.currentGameId = nil
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
