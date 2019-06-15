import Foundation
import CryptoKit
import UIKit

struct GravatarAPI {
    private static func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    let getAvatar: (String, @escaping (Result<UIImage, SignUpError>) -> Void) -> Void
}

extension GravatarAPI {
    static let live: GravatarAPI = GravatarAPI { email, completion in
        let emailHash = GravatarAPI.MD5(string: email.lowercased())
        let url = URL(string: "https://www.gravatar.com/avatar/\(emailHash)?s=256&d=404")!

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, response, error in
            let result: Result<UIImage, SignUpError>
            let httpReponse = response as? HTTPURLResponse
            if let data = data,
                let httpReponse = httpReponse, 200..<300 ~= httpReponse.statusCode,
                let image = UIImage(data: data) {

                result = .success(image)
            } else if let error = error {
                result = .failure(.network(error))
            } else {
                result = .failure(.unknown)
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    static let mockFailure: GravatarAPI = GravatarAPI { email, completion in
        DispatchQueue.main.async {
            completion(.failure(.unknown))
        }
    }

    static let mockSuccess: GravatarAPI = GravatarAPI { email, completion in
        DispatchQueue.main.async {
            completion(.success(UIImage(systemName: "person")!))
        }
    }
}
