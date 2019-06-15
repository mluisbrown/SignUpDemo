import Foundation

enum SignUpError: Error {
    case network(Error)
    case unknown

    var localizedDescription: String {
        switch self {
        case let .network(error):
            return error.localizedDescription
        case .unknown:
            return "Sign Up Failed. Please try again."
        }
    }
}
