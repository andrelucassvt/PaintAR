import Foundation

struct PaintExchangeModel: Codable, Sendable {
    let id: UUID
    let name: String
    let date: String
    let drawing: String

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(id: UUID, name: String, date: String, drawing: String) {
        self.id = id
        self.name = name
        self.date = date
        self.drawing = drawing
    }

    init(paint: Paint) {
        id = paint.id
        name = paint.name
        date = Self.dateFormatter.string(from: paint.date)
        drawing = paint.drawingData.base64EncodedString()
    }

    func toPaint() throws -> Paint {
        guard let parsedDate = Self.dateFormatter.date(from: date) else {
            throw PaintError.invalidDate
        }

        guard let drawingData = Data(base64Encoded: drawing) else {
            throw PaintError.invalidDrawingData
        }

        return Paint(id: id, name: name, date: parsedDate, drawingData: drawingData)
    }
}
