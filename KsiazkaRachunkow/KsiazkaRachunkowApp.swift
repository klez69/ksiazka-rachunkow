import SwiftUI
import SwiftData

@main
struct KsiazkaRachunkowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Rachunek.self)
    }
}
