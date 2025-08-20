//
//  WebSocketManagerDelegate.swift
//  Hangman
//
//  Created by mego on 31.07.2025.
//

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveWaiting()
    func didFindMatch(gameId: String, wordLength: Int, players: [Player])
    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool, guessed: Set<String>?)
    func didReceiveGameOver(win: Bool, word: String)
    func didReceivePlayerLeft(name: String)
    func didReceiveError(_ message: String)
    func didReceiveWaitingFriend()
    func didCreateRoom(gameId: String)
    func didReceiveMatchFound(gameId: String?, playerId: String?)
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>)
    func didReceiveCoopGameOver(result: String, word: String, attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>)
    func didReceiveGameCanceled(word: String)
    func didRestoreGame(gameId: String, wordLength: Int, maskedWord: String, attemptsLeft: Int, guessed: Set<String>, players: [Player])
}
