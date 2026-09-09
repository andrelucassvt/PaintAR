import SwiftUI

@main
struct PaintARApp: App {
    private let repository: any PaintRepository

    init() {
        repository = CoreDataPaintRepository(persistence: .shared)
    }

    var body: some Scene {
        WindowGroup {
            HomeView(repository: repository)
        }
    }
}
