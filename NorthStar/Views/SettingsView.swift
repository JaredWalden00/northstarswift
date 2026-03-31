import SwiftUI

struct SettingsView: View {
    @AppStorage("serverBaseURL") private var baseURL = "http://localhost:8000"
    @AppStorage("serverAPIKey") private var apiKey = ""

    let client: APIClient
    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Configuration") {
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

                Section("About") {
                    LabeledContent("App", value: "NorthStar")
                    LabeledContent("Endpoints", value: "OCR, Detection, Health")
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
