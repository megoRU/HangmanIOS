import Foundation

struct HangmanResponse: Codable {
    let word: String
}

class WordService {
    
    static let shared = WordService()
    
    private init() {}
    
    func fetchWord(language: String, category: String?, completion: @escaping (Result<String, Error>) -> Void) {
        var urlComponents = URLComponents(string: "https://api.megoru.ru/api/word")
        var queryItems = [URLQueryItem(name: "language", value: language)]
        if let category = category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        queryItems.append(URLQueryItem(name: "lenght", value: "12"))
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(HangmanResponse.self, from: data)
                completion(.success(decoded.word.uppercased()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
