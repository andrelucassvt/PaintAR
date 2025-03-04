//
//  PaintModel.swift
//  PaintAR
//
//  Created by André  Lucas on 28/02/25.
//

import Foundation
import CoreData


extension PaintEntity {
    convenience init(context: NSManagedObjectContext,name: String, date: Date, drawing: Data) {
        self.init(context: context) // Chama o init correto do Core Data
        self.id = UUID() 
        self.name = name
        self.date = date
        self.drawing = drawing
    }
}



struct PaintModelJson: Codable {
    let id: UUID
    let name: String
    let date: String
    let drawing: String
}

