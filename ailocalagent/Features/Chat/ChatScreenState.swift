import Foundation

enum ChatScreenState: Equatable {
    case loadingModel
    case idle
    case generating
    case error(message: String)

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
