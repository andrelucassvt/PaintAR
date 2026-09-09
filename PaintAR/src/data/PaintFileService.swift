import Foundation

struct PaintFileService {
    func export(_ paint: Paint) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(PaintExchangeModel(paint: paint))
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let baseName = sanitizedBaseName(from: paint.name)
        var fileURL = directory.appendingPathComponent(baseName).appendingPathExtension("json")

        if fileManager.fileExists(atPath: fileURL.path) {
            let suffix = String(paint.id.uuidString.prefix(8)).lowercased()
            fileURL = directory
                .appendingPathComponent("\(baseName)-\(suffix)")
                .appendingPathExtension("json")
        }

        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func decode(fileAt url: URL) throws -> PaintExchangeModel {
        let accessedSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PaintExchangeModel.self, from: data)
    }

    private func sanitizedBaseName(from name: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)
        let sanitizedName = name
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")

        return sanitizedName.isEmpty ? "desenho" : sanitizedName.lowercased()
    }
}
