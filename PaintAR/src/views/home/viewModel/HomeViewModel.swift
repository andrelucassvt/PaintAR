//
//  HomeViewModel.swift
//  PaintAR
//
//  Created by André  Lucas on 28/02/25.
//

import Foundation
import CoreData

enum HomeState {
    case loading
    case loaded([PaintEntity])
    case error(error: String)
}

class HomeViewModel: ObservableObject {
    private let coreDataController = CoreDataController()
    @Published var paints: [PaintEntity] = []
    @Published var state: HomeState = .loading
    @Published var showImportView = false
    @Published var importActivated = false
    
    init() {
        fetchPaints()
    }
    
    func addImportFile(path: String) {
        showImportView = false
        guard let fileURL = URL(string: path) else {
            print("URL inválida")
            return
        }
        
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let decodedData = try JSONDecoder().decode(PaintModelJson.self, from: jsonData)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                guard let date = formatter.date(from: decodedData.date) else {
                    print("Erro: Formato de data inválido - \(decodedData.date)")
                    return
                }
                
                guard let drawingData = Data(base64Encoded: decodedData.drawing) else {
                    print("Erro: Não foi possível decodificar o drawing como Base64")
                    return
                }
                
                let entityResult = PaintEntity(
                    context: CoreDataController.shared.context,
                    name: decodedData.name,
                    date: date,
                    drawing: drawingData
                )
                
                savePaint(paint: entityResult)
            } catch {
                print("Erro ao ler JSON: \(error.localizedDescription)")
            }
        } else {
            print("Falha ao acessar o arquivo com segurança.")
        }
    }

    func savePaint(paint: PaintEntity) {
        self.state = .loading
        DispatchQueue.main.async {
            self.paints.append(paint)
            do {
                try CoreDataController.shared.context.save()
                self.state = .loaded(self.paints) // ou outro estado desejado
            } catch {
                print("Erro ao salvar no Core Data: \(error.localizedDescription)")
                self.state = .error(error: error.localizedDescription)
            }
        }
    }
    func fetchPaints(isLoading: Bool = true) {
        if(isLoading){
            self.state = .loading
        }
        DispatchQueue.main.async {
            var paints = self.coreDataController.fetchAllPaints()
            paints.sort { $0.date ?? Date() > $1.date ?? Date() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.paints = paints
                self.state = .loaded(paints)
            }
        
        }
    }
    
    

    func deletePaint(_ paint: PaintEntity) {
        if let index = paints.firstIndex(where: { $0.id == paint.id }) {
                paints.remove(at: index) 
            }
        
        self.state = .loaded(paints)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.coreDataController.deletePaint(paint: paint)
        }
        
    }
}
