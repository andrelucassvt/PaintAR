import Foundation

enum PaintError: LocalizedError, Equatable {
    case invalidDate
    case invalidDrawingData
    case notFound
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            "Formato de data inválido."
        case .invalidDrawingData:
            "Dados do desenho inválidos."
        case .notFound:
            "Desenho não encontrado."
        case .persistenceFailed(let message):
            message
        }
    }
}
