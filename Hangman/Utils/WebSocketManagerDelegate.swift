//
//  WebSocketManagerDelegate.swift
//  Hangman
//
//  Created by mego on 31.07.2025.
//

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveWaiting()
    func didFindMatch(wordLength: Int)
    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool)
    func didReceiveGameOver(win: Bool, word: String)
    func didReceivePlayerLeft(playerId: String)
    func didReceiveError(_ message: String)
    func didReceiveWaitingFriend()
    func didCreateRoom(gameId: String)
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: Int, gameId: String, guesses: [String])
}
