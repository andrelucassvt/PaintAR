import UIKit
import CoreData

class ShareFileController {
    
    // Função para exportar a PaintEntity como .txt
    func exportPaintEntityAsJson(paintEntity: PaintEntity) -> URL? {
        // Cria o dicionário com os dados para serem convertidos em JSON
        let jsonDict: [String: Any] = [
            "id": paintEntity.id?.uuidString ?? "N/A",
            "name": paintEntity.name ?? "Sem Nome",
            "date": paintEntity.date?.description ?? "Sem Data",
            "drawing": paintEntity.drawing?.base64EncodedString() ?? "Sem Dados"
        ]
        
        // Tenta converter o dicionário em JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            
            // Define o nome do arquivo JSON
            let fileName = "\(paintEntity.name!.lowercased()).json"
            
            // Salva o arquivo JSON e retorna o URL
            return saveJsonFile(content: jsonData, fileName: fileName)
        } catch {
            print("Erro ao criar o JSON: \(error.localizedDescription)")
            return nil
        }
    }

    
    // Função para salvar o conteúdo no arquivo .txt
    private func saveJsonFile(content: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL)
            return fileURL
        } catch {
            print("Erro ao salvar o arquivo: \(error)")
            return nil
        }
    }

    
    // Função para compartilhar o arquivo gerado
    func shareFile(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
}
