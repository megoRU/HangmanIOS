import Foundation
import SwiftUI

final class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    @AppStorage("name") private var name: String = ""
    @AppStorage("avatarImage") private var avatarData: Data?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private(set) var currentGameId: String?
    weak var delegate: WebSocketManagerDelegate?
    
    private var isConnected = false
    
    private var mode: MultiplayerMode = .duel
    private var lang: String = "EN"
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect(mode: MultiplayerMode, language: String) {
        self.mode = mode
        self.lang = language
        
        guard let url = URL(string: "wss://hangman.megoru.ru/ws") else {
            delegate?.didReceiveError("Неверный URL WebSocket")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    func joinMulti(gameId: String) {
        guard isConnected else { return }
        let msg: [String: Any] = [
            "type": "JOIN_MULTI",
            "gameId": gameId,
            "name": name.isEmpty ? NSNull() : name,
            "image": avatarData?.base64EncodedString() ?? NSNull()
        ]
        print("📤 Отправляем JOIN_MULTI:", msg)
        send(json: msg)
    }
    
    /// Отправить на сервер команду выхода из игры
    func leaveGame(gameId: String?) {
        guard isConnected else { return }
        var msg: [String: Any] = ["type": "LEAVE_GAME"]
        if let gameId = gameId {
            msg["gameId"] = gameId
        }
        print("🔌 Отправка LEAVE_GAME: \(msg)")
        send(json: msg)
    }
    
    // MARK: URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        print("✅ WebSocket подключен")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.sendFindOrCreate()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
    
    // MARK: Sending messages
    
    private func sendFindOrCreate() {
        guard isConnected else {
            print("⚠️ Не подключено, пропускаем FIND/CREATE")
            return
        }
        var msgDict: [String: Any]
        let nameValue: Any = name.isEmpty ? NSNull() : name
        let imageValue: Any = avatarData?.base64EncodedString() ?? NSNull()
        
        switch mode {
        case .duel:
            msgDict = ["type": "FIND_GAME", "lang": lang.lowercased(), "name": nameValue, "image": imageValue]
        case .friends:
            msgDict = ["type": "CREATE_MULTI", "lang": lang.lowercased(), "name": nameValue, "image": imageValue]
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
    
    public func send(json: [String: Any]) {
        guard isConnected, let webSocketTask = webSocketTask else { return }
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
    
    // MARK: Receiving messages
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    print(error.localizedDescription)
                    self.delegate?.didReceiveError("Ошибка приёмки: \(error.localizedDescription)")
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
                
                do {
                    let payload = try JSONDecoder().decode(MatchFoundPayload.self, from: data)
                    print("✅ MATCH_FOUND, wordLength:", payload.wordLength, "players:", payload.players.count)
                    self.currentGameId = payload.gameId
                    self.delegate?.didFindMatch(wordLength: payload.wordLength, players: payload.players)
                } catch {
                    print("❌ Ошибка декодирования MATCH_FOUND:", error)
                    self.delegate?.didReceiveError("Ошибка обработки данных с сервера.")
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
                    var guessedSet: Set<String>? = nil
                    if let guessed = json["guessed"] as? [String] {
                        guessedSet = Set(guessed)
                    }
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
                
                do {
                    let payload = try JSONDecoder().decode(PlayerJoinedPayload.self, from: data)
                    print("✅ PLAYER_JOINED, players:", payload.players.count)
                    self.currentGameId = payload.gameId
                    self.delegate?.didReceivePlayerJoined(
                        attemptsLeft: payload.attemptsLeft,
                        wordLength: payload.wordLength,
                        players: payload.players,
                        gameId: payload.gameId,
                        guessed: Set(payload.guessed)
                    )
                } catch {
                    print("❌ Ошибка декодирования PLAYER_JOINED:", error)
                    self.delegate?.didReceiveError("Ошибка обработки данных с сервера.")
                }
                
            case "PLAYER_LEFT":
                DispatchQueue.main.async {
                    if let name = json["name"] as? String {
                        print("✅ PLAYER_LEFT, name: \(name)")
                        self.delegate?.didReceivePlayerLeft(name: name)
                    }
                }
                
            case "GAME_OVER":
                if let result = json["result"] as? String,
                   let word = json["word"] as? String {
                    print("✅ Игра завершилась, result:", result)
                    self.delegate?.didReceiveGameOver(win: result == "WIN", word: word)
                }
                
            case "GAME_OVER_COOP":
                if let result = json["result"] as? String,
                   let word = json["word"] as? String,
                   let wordLength = json["wordLength"] as? Int {
                    print("✅ Совместная игра завершилась, result:", result)
                    self.delegate?.didReceiveCoopGameOver(result: result, word: word, wordLength: wordLength)
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
}
