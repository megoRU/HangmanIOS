import Foundation

// This protocol was removed during refactoring and is now being restored to fix compilation errors.
// It defines the communication contract between the WebSocketManager and its delegate (typically a ViewModel).
protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect()
    func didReceiveWaiting()
    func didReceiveWaitingFriend()
    func didFindMatch(gameId: String, wordLength: Int, players: [Player])
    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool, guessed: Set<String>?)
    func didReceiveGameOver(win: Bool, word: String)
    func didReceiveGameCanceled(word: String)
    func didReceivePlayerLeft(name: String)
    func didReceiveError(_ message: String)
    func didCreateRoom(gameId: String)
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>)
    func didReceiveCoopGameOver(result: String, word: String, attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>)
    func didRestoreGame(gameId: String, wordLength: Int, maskedWord: String, attemptsLeft: Int, guessed: Set<String>, players: [Player])
}
