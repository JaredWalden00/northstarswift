import SwiftUI

struct OCRView: View {
    @Bindable var viewModel: OCRViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    imageSection
                    actionButtons
                    if viewModel.isLoading {
                        ProgressView("Running OCR...")
                    }
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                    if let result = viewModel.ocrResult {
                        resultSection(result)
                    }
                }
                .padding()
            }
            .navigationTitle("OCR")
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

                    if let result = viewModel.ocrResult {
                        let blocks = result.pages.flatMap(\.blocks)
                        OCRBoundingBoxOverlay(
                            blocks: blocks,
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
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Select an image to run OCR")
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
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
                    Task { await viewModel.runOCR() }
                } label: {
                    Label("Run OCR", systemImage: "text.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private func resultSection(_ result: OCRResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.headline)
                Spacer()
                if let engine = viewModel.usedEngine {
                    Label(engine, systemImage: result.model.paddleocrVersion == "Apple Vision" ? "iphone" : "server.rack")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            HStack {
                if result.cache.hit {
                    Label("Cached", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Text("\(String(format: "%.0f", result.timingMs.total)) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(result.pages) { page in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Text")
                        .font(.subheadline).bold()
                    Text(page.fullText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Text("Blocks (\(page.blocks.count))")
                        .font(.subheadline).bold()

                    ForEach(page.blocks) { block in
                        HStack {
                            Text(block.text)
                                .font(.callout)
                            Spacer()
                            Text(String(format: "%.1f%%", block.confidence * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
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
