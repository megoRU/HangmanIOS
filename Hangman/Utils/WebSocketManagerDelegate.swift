//
//  WebSocketManagerDelegate.swift
//  Hangman
//
//  Created by mego on 31.07.2025.
//

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool)
    func didReceiveGameOver(win: Bool, word: String)
    func didReceiveWaiting()
    func didFindMatch(wordLength: Int)
    func didReceiveError(_ message: String)
    func didReceivePlayerLeft(playerId: String)
}
