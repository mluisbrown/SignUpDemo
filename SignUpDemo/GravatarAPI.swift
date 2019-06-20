import Foundation
import Combine
import CryptoKit
import UIKit

struct GravatarAPI {
    private static func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    let getAvatar: (String) -> AnyPublisher<UIImage, SignUpError>
}

extension GravatarAPI {
    static let live: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        let emailHash = MD5(string: email.lowercased())
        let url = URL(string: "https://www.gravatar.com/avatar/\(emailHash)?s=256&d=404")!

        let request = URLRequest(url: url)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> UIImage in
                let (data, response) = result
                guard let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode,
                    let image = UIImage(data: data) else { throw SignUpError.unknown }

                return image
            }
            .mapError { error -> SignUpError in
                switch error.self {
                case is URLError:
                    return .network(error)
                default:
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }

    static let mockFailure: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        return Publishers.Once(Result<UIImage, SignUpError>.failure(.unknown))
            .eraseToAnyPublisher()
    }

    static let mockSuccess: GravatarAPI = GravatarAPI { email -> AnyPublisher<UIImage, SignUpError> in
        return Publishers.Once(
            Result<UIImage, SignUpError>.success(
                UIImage(
                    systemName: "person.circle",
                    withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 100)
                )!
            )
        )
        .eraseToAnyPublisher()
    }
}
