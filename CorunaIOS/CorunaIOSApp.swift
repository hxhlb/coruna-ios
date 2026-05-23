import SwiftUI

@main
struct CorunaIOSApp: App {
    @StateObject private var controller = ServerController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
        }
    }
}
