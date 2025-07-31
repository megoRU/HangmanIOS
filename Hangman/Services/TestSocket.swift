//
//  TestSocket.swift
//  Hangman
//
//  Created by mego on 31.07.2025.
//

import Foundation

final class TestSocket: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard let url = URL(string: "wss://hangman.megoru.ru/ws/hangman") else {
            print("Invalid URL")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        print("WebSocket: resume called")
        listen()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print("WebSocket: disconnect called")
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                case .data(let data):
                    print("Received data: \(data.count) bytes")
                @unknown default:
                    print("Received unknown message")
                }
                self.listen()
            }
        }
    }
    
    // MARK: URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("WebSocket: didOpenWithProtocol:")
        
        // Отправляем FIND_GAME с языком "ru"
        sendFindGame(lang: "ru")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket: didCloseWith code: \(closeCode.rawValue)")
    }
    
    private func sendFindGame(lang: String) {
        let msgDict: [String: Any] = [
            "type": "FIND_GAME",
            "lang": lang
        ]
        send(json: msgDict)
    }
    
    private func send(json: [String: Any]) {
        guard let webSocketTask = webSocketTask else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
            } else {
                print("WebSocket sent message: \(json)")
            }
        }
    }
}
