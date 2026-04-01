import SwiftUI

@MainActor
@Observable
final class DetectViewModel {
    var selectedImage: UIImage?
    var detectResult: DetectResponse?
    var isLoading = false
    var errorMessage: String?
    var showImagePicker = false
    var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    var skipDedup = false

    /// Which engine actually processed the last request.
    var usedEngine: String?

    private let serverService: DetectService
    private let visionService = VisionDetectService()
    private let mode: () -> ProcessingMode

    init(client: APIClient, mode: @escaping () -> ProcessingMode) {
        self.serverService = DetectService(client: client)
        self.mode = mode
    }

    func runDetection() async {
        guard let image = selectedImage else { return }
        isLoading = true
        errorMessage = nil
        detectResult = nil
        usedEngine = nil

        let currentMode = mode()

        switch currentMode {
        case .server:
            await runServerDetect(image: image)

        case .onDevice:
            await runVisionDetect(image: image)

        case .auto:
            await runServerDetect(image: image)
            if detectResult == nil {
                let serverError = errorMessage
                errorMessage = nil
                await runVisionDetect(image: image)
                if detectResult != nil {
                    errorMessage = "Server unavailable, used on-device Vision. (\(serverError ?? "connection failed"))"
                }
            }
        }

        isLoading = false
    }

    private func runServerDetect(image: UIImage) async {
        do {
            let options = skipDedup ? DetectOptions(skipDedup: true) : nil
            detectResult = try await serverService.detect(image: image, options: options)
            usedEngine = "Server (YOLOv8)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runVisionDetect(image: UIImage) async {
        do {
            detectResult = try await visionService.detect(image: image)
            usedEngine = "On-Device (Apple Vision)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetScene() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await serverService.resetScene()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func pickFromLibrary() {
        imagePickerSource = .photoLibrary
        showImagePicker = true
    }

    func pickFromCamera() {
        imagePickerSource = .camera
        showImagePicker = true
    }

    func clear() {
        selectedImage = nil
        detectResult = nil
        errorMessage = nil
        usedEngine = nil
    }
}
