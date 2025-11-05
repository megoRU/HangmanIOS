import Foundation

// MARK: - Payloads

import Foundation

struct Player: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let image: String?
}

// MARK: - Incoming Messages

enum ServerMessage {
    case waiting
    case matchFound(MatchFoundPayload)
    case gameCanceled(GameCanceledPayload)
    case stateUpdate(StateUpdatePayload)
    case roomCreated(RoomCreatedPayload)
    case playerJoined(PlayerJoinedPayload)
    case playerLeft(PlayerLeftPayload)
    case gameOver(GameOverPayload)
    case gameOverCoop(CoopGameOverPayload)
    case restored(RestoredPayload)
    case error(ErrorPayload)
}

struct MatchFoundPayload: Codable {
    let gameId: String
    let wordLength: Int
    let players: [Player]
}

struct GameCanceledPayload: Codable {
    let word: String
}

struct StateUpdatePayload: Codable {
    let maskedWord: String
    let attemptsLeft: Int
    let duplicate: Bool
    let guessed: [String]?
}

struct RoomCreatedPayload: Codable {
    let gameId: String
}

struct PlayerJoinedPayload: Codable {
    let attemptsLeft: Int
    let wordLength: Int
    let players: [Player]
    let gameId: String
    let guessed: [String]
}

struct PlayerLeftPayload: Codable {
    let name: String
}

struct GameOverPayload: Codable {
    let result: String
    let word: String
}

struct CoopGameOverPayload: Codable {
    let result: String
    let word: String
    let attemptsLeft: Int
    let wordLength: Int
    let players: [Player]
    let gameId: String
    let guessed: [String]
}

struct RestoredPayload: Codable {
    let gameId: String
    let wordLength: Int
    let maskedWord: String
    let attemptsLeft: Int
    let guessed: [String]
    let players: [Player]
}

struct ErrorPayload: Codable {
    let msg: String
}

// MARK: - Outgoing Messages

enum ClientMessage {
    case findGame(FindGamePayload)
    case createMulti(CreateMultiPayload)
    case joinMulti(JoinMultiPayload)
    case move(MovePayload)
    case leaveGame(LeaveGamePayload)
    case reconnect(ReconnectPayload)
}

struct FindGamePayload: Codable {
    var type = "FIND_GAME"
    let lang: String
    let name: String
    let image: String
    let playerId: String
}

struct CreateMultiPayload: Codable {
    var type = "CREATE_MULTI"
    let lang: String
    let name: String
    let image: String
    let playerId: String
}

struct JoinMultiPayload: Codable {
    var type = "JOIN_MULTI"
    let gameId: String
    let playerId: String
    let name: String
    let image: String
}

struct MovePayload: Codable {
    var type = "MOVE"
    let gameId: String
    let letter: String
}

struct LeaveGamePayload: Codable {
    var type = "LEAVE_GAME"
    let gameId: String?
}

struct ReconnectPayload: Codable {
    var type = "RECONNECT"
    let gameId: String
    let playerId: String
}
