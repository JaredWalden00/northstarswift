import SwiftUI

struct DetectView: View {
    @Bindable var viewModel: DetectViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    imageSection
                    actionButtons
                    if viewModel.isLoading {
                        ProgressView("Detecting...")
                    }
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                    if let result = viewModel.detectResult {
                        resultSection(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Detection")
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(
                    sourceType: viewModel.imagePickerSource,
                    selectedImage: $viewModel.selectedImage
                )
            }
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        if let image = viewModel.selectedImage {
            let imageSize = image.size
            GeometryReader { geo in
                let displaySize = fitSize(imageSize: imageSize, containerWidth: geo.size.width)
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: displaySize.width, height: displaySize.height)

                    if let result = viewModel.detectResult, result.changed {
                        DetectBoundingBoxOverlay(
                            objects: result.objects,
                            imageSize: imageSize,
                            displaySize: displaySize
                        )
                    }
                }
                .frame(width: geo.size.width, height: displaySize.height)
            }
            .aspectRatio(imageSize.width / imageSize.height, contentMode: .fit)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Select an image to detect objects")
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button { viewModel.pickFromLibrary() } label: {
                    Label("Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { viewModel.pickFromCamera() } label: {
                        Label("Camera", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if viewModel.selectedImage != nil {
                    Button {
                        Task { await viewModel.runDetection() }
                    } label: {
                        Label("Detect", systemImage: "eye")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
            }

            HStack {
                Toggle("Skip dedup", isOn: $viewModel.skipDedup)
                    .font(.caption)

                Spacer()

                Button {
                    Task { await viewModel.resetScene() }
                } label: {
                    Label("Reset Scene", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private func resultSection(_ result: DetectResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.headline)
                Spacer()
                if let engine = viewModel.usedEngine {
                    Label(engine, systemImage: result.device.contains("Apple") ? "iphone" : "server.rack")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            HStack {
                Label(
                    result.changed ? "Scene Changed" : "No Change",
                    systemImage: result.changed ? "arrow.triangle.2.circlepath" : "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(result.changed ? .orange : .green)
                Spacer()

                Text("\(String(format: "%.0f", result.timingMs)) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Device: \(result.device)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if result.changed {
                if !result.objects.isEmpty {
                    Text("Objects (\(result.objects.count))")
                        .font(.subheadline).bold()

                    ForEach(result.objects) { obj in
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text(obj.label)
                                .font(.callout)
                            Spacer()
                            Text(String(format: "%.1f%%", obj.confidence * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !result.appeared.isEmpty {
                    Label("Appeared (\(result.appeared.count))", systemImage: "plus.circle.fill")
                        .font(.subheadline).bold()
                        .foregroundStyle(.green)

                    ForEach(result.appeared) { obj in
                        Text("  \(obj.label) (\(String(format: "%.0f%%", obj.confidence * 100)))")
                            .font(.callout)
                    }
                }

                if !result.disappeared.isEmpty {
                    Label("Disappeared (\(result.disappeared.count))", systemImage: "minus.circle.fill")
                        .font(.subheadline).bold()
                        .foregroundStyle(.red)

                    ForEach(result.disappeared) { obj in
                        Text("  \(obj.label) (\(String(format: "%.0f%%", obj.confidence * 100)))")
                            .font(.callout)
                    }
                }
            }

            Button("Clear", role: .destructive) {
                viewModel.clear()
            }
        }
    }

    // MARK: - Helpers

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private func fitSize(imageSize: CGSize, containerWidth: CGFloat) -> CGSize {
        let scale = containerWidth / imageSize.width
        return CGSize(width: containerWidth, height: imageSize.height * scale)
    }
}
