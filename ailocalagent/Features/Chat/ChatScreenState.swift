import Foundation

enum ChatScreenState: Equatable {
    case loadingModel
    case idle
    case generating
    case error(message: String)
}
