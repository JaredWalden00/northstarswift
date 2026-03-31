import SwiftUI

@main
struct NorthStarApp: App {
    @State private var client = APIClient()

    var body: some Scene {
        WindowGroup {
            ContentView(client: client)
                .task {
                    let baseURL = UserDefaults.standard.string(forKey: "serverBaseURL") ?? "http://localhost:8000"
                    let apiKey = UserDefaults.standard.string(forKey: "serverAPIKey") ?? ""
                    await client.updateConfig(baseURL: baseURL, apiKey: apiKey)
                }
        }
    }
}
