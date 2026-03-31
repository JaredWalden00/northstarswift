import SwiftUI

struct ServerStatusView: View {
    @Bindable var viewModel: ServerViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Server Health") {
                    statusRow(
                        title: "Liveness",
                        value: viewModel.healthStatus ?? "Unknown",
                        isGood: viewModel.isHealthy
                    )
                    statusRow(
                        title: "Readiness",
                        value: viewModel.readyStatus ?? "Unknown",
                        isGood: viewModel.isReady
                    )
                }

                if viewModel.isReady {
                    Section("Engine Info") {
                        if let version = viewModel.paddleocrVersion {
                            LabeledContent("PaddleOCR", value: "v\(version)")
                        }
                        if let device = viewModel.yoloDevice {
                            LabeledContent("YOLO Device", value: device.uppercased())
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.callout)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.fetchMetrics() }
                    } label: {
                        Label("Fetch Prometheus Metrics", systemImage: "chart.bar")
                    }
                    .disabled(viewModel.isLoading)
                }

                if let metrics = viewModel.metricsText {
                    Section("Metrics") {
                        Text(metrics)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Server")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    private func statusRow(title: String, value: String, isGood: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(isGood ? .green : .red)
                    .frame(width: 10, height: 10)
                Text(value)
                    .foregroundStyle(isGood ? .primary : .secondary)
            }
        }
    }
}
