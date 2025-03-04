//
//  AppDelegate.swift
//  PaintAR
//
//  Created by André  Lucas on 27/02/25.
//

import SwiftUI

@main
struct AppDelegate: App {
    private var dataController = CoreDataController()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataController.context)
        }
    }
}
