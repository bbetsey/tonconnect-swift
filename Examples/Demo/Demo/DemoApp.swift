import SwiftUI
import TonConnectCore

@main
struct DemoApp: App {
    @StateObject private var tonConnect = CompositionRoot.makeTonConnect()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(tonConnect) }
    }
}
