//
//  WebSocketManagerDelegate.swift
//  Hangman
//
//  Created by mego on 31.07.2025.
//

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveWaiting()
    func didFindMatch(wordLength: Int, players: [Player])
    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool, guessed: Set<String>?)
    func didReceiveGameOver(win: Bool, word: String)
    func didReceivePlayerLeft(name: String)
    func didReceiveError(_ message: String)
    func didReceiveWaitingFriend()
    func didCreateRoom(gameId: String)
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>)
    func didReceiveCoopGameOver(result: String, word: String, newWord: String)
    func didReceiveGameCanceled(word: String)
}
