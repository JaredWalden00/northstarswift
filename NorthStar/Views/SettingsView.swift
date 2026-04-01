import SwiftUI

struct SettingsView: View {
    @AppStorage("serverBaseURL") private var baseURL = "http://localhost:8000"
    @AppStorage("serverAPIKey") private var apiKey = ""
    @AppStorage("processingMode") private var processingModeRaw = ProcessingMode.auto.rawValue
    @AppStorage("captureEndpoint") private var captureEndpoint = "/v1/capture"

    let client: APIClient
    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isTesting = false

    private var processingMode: Binding<ProcessingMode> {
        Binding(
            get: { ProcessingMode(rawValue: processingModeRaw) ?? .auto },
            set: { processingModeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Processing Mode", selection: processingMode) {
                        ForEach(ProcessingMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Processing Engine")
                } footer: {
                    Text("**Auto**: tries the server first; if it fails, falls back to Apple Vision on-device.\n**Server Only**: always uses the remote API.\n**On-Device Only**: uses Apple Vision framework — works offline, no server needed.")
                }

                Section {
                    LabeledContent("Base URL") {
                        TextField("http://localhost:8000", text: $baseURL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("API Key") {
                        SecureField("Enter API key", text: $apiKey)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("Capture Endpoint") {
                        TextField("/v1/capture", text: $captureEndpoint)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                            .font(.callout.monospaced())
                    }
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Capture endpoint: a GET request is sent here to trigger a remote camera. Can be a path (appended to Base URL) or a full URL.")
                }

                Section {
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            Label("Test Connection", systemImage: "network")
                            Spacer()
                            if isTesting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isTesting)

                    if let result = testResult {
                        HStack {
                            Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testSuccess ? .green : .red)
                            Text(result)
                                .font(.callout)
                        }
                    }
                } footer: {
                    Text("Tests the /healthz endpoint to verify server connectivity.")
                }

                Section("On-Device Capabilities") {
                    Label("OCR (VNRecognizeTextRequest)", systemImage: "doc.text.viewfinder")
                    Label("Image Classification", systemImage: "tag")
                    Label("Face Detection", systemImage: "face.smiling")
                    Label("Barcode Detection", systemImage: "barcode")
                    Label("Rectangle Detection", systemImage: "rectangle.dashed")
                }

                Section("About") {
                    LabeledContent("App", value: "NorthStar")
                    LabeledContent("Engines", value: "PaddleOCR + YOLOv8 + Apple Vision")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: baseURL) { _, _ in syncConfig() }
            .onChange(of: apiKey) { _, _ in syncConfig() }
            .onAppear { syncConfig() }
        }
    }

    private func syncConfig() {
        Task {
            await client.updateConfig(baseURL: baseURL, apiKey: apiKey)
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        await syncConfig()

        let service = ServerService(client: client)
        do {
            let health = try await service.healthz()
            testSuccess = health.status == "ok"
            testResult = testSuccess ? "Connected! Server is healthy." : "Server responded but status: \(health.status)"
        } catch {
            testSuccess = false
            testResult = error.localizedDescription
        }

        isTesting = false
    }
}
