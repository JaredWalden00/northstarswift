import SwiftUI

struct ContentView: View {
    let client: APIClient
    @AppStorage("processingMode") private var processingModeRaw = ProcessingMode.auto.rawValue

    private var processingMode: ProcessingMode {
        ProcessingMode(rawValue: processingModeRaw) ?? .auto
    }

    var body: some View {
        TabView {
            RemoteCaptureView(viewModel: CaptureViewModel(client: client, mode: { [self] in processingMode }))
                .tabItem {
                    Label("Capture", systemImage: "camera.on.rectangle")
                }

            OCRView(viewModel: OCRViewModel(client: client, mode: { [self] in processingMode }))
                .tabItem {
                    Label("OCR", systemImage: "doc.text.viewfinder")
                }

            DetectView(viewModel: DetectViewModel(client: client, mode: { [self] in processingMode }))
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
