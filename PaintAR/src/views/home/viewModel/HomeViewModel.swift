//
//  HomeViewModel.swift
//  PaintAR
//
//  Created by André Lucas on 28/02/25.
//

import Foundation
import CoreData

enum HomeState {
    case loading
    case loaded([PaintEntity])
    case error(String)
}

enum ActiveAlert: Identifiable {
    case error(String)
    case success
    
    var id: String {
        switch self {
        case .error: return "error"
        case .success: return "success"
        }
    }
}

class HomeViewModel: ObservableObject {
    private let coreDataController: CoreDataController
    @Published private(set) var paints: [PaintEntity] = []
    @Published private(set) var state: HomeState = .loading
    @Published var showImportView = false
    @Published var importActivated = false
    @Published var activeAlert: ActiveAlert?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    init(coreDataController: CoreDataController = .shared) {
        self.coreDataController = coreDataController
        fetchPaints()
    }
    
    func addImportFile(path: String) {
        showImportView = false
        guard let fileURL = URL(string: path) else {
            handleError("Invalid URL")
            return
        }
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            handleError("Failed to access file securely")
            return
        }
        
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decodedData = try JSONDecoder().decode(PaintModelJson.self, from: jsonData)
            
            guard let date = dateFormatter.date(from: decodedData.date) else {
                handleError("Invalid date format: \(decodedData.date)")
                return
            }
            
            guard let drawingData = Data(base64Encoded: decodedData.drawing) else {
                handleError("Failed to decode drawing from Base64")
                return
            }
            
            let newPaint = PaintEntity(
                context: coreDataController.context,
                name: decodedData.name,
                date: date,
                drawing: drawingData
            )
            
            if paints.contains(where: { $0.id == newPaint.id }) {
                handleError("Duplicate paint entity")
                return
            }
            
            savePaint(paint: newPaint) { result in
                switch result {
                case .success:
                    self.activeAlert = .success
                case .failure(let error):
                    self.handleError(error.localizedDescription)
                }
            }
            
        } catch {
            handleError("Failed to process import: \(error.localizedDescription)")
        }
    }
    
    func savePaint(paint: PaintEntity, completion: @escaping (Result<Void, Error>) -> Void) {
        state = .loading
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.paints.append(paint)
            do {
                try self.coreDataController.context.save()
                self.state = .loaded(self.paints)
                completion(.success(()))
            } catch {
                self.state = .error(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func fetchPaints(isLoading: Bool = true) {
        if isLoading {
            state = .loading
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fetchedPaints = self.coreDataController.fetchAllPaints()
            let sortedPaints = fetchedPaints.sorted { $0.date ?? Date() > $1.date ?? Date() }
            
            DispatchQueue.main.async {
                self.paints = sortedPaints
                self.state = .loaded(sortedPaints)
            }
        }
    }
    
    func deletePaint(_ paint: PaintEntity) {
        if let index = paints.firstIndex(where: { $0.id == paint.id }) {
            paints.remove(at: index)
            state = .loaded(paints)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.coreDataController.deletePaint(paint: paint)
            }
        }
    }
    
    public func handleError(_ message: String) {
        print("Error: \(message)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.activeAlert = .error(message)
        }
    }
}
