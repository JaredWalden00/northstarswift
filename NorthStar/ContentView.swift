import SwiftUI

struct ContentView: View {
    let client: APIClient

    var body: some View {
        TabView {
            OCRView(viewModel: OCRViewModel(client: client))
                .tabItem {
                    Label("OCR", systemImage: "doc.text.viewfinder")
                }

            DetectView(viewModel: DetectViewModel(client: client))
                .tabItem {
                    Label("Detect", systemImage: "eye")
                }

            ServerStatusView(viewModel: ServerViewModel(client: client))
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }

            SettingsView(client: client)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
