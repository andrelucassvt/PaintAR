//
//  AppDelegate.swift
//  PaintAR
//
//  Created by André  Lucas on 27/02/25.
//

import SwiftUI
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    MobileAds.shared.start(completionHandler: nil)

    return true
  }
}

@main
struct PaintARApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var dataController = CoreDataController()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataController.context)
        }
    }
}


