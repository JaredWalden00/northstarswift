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

    private let service: DetectService

    init(client: APIClient) {
        self.service = DetectService(client: client)
    }

    func runDetection() async {
        guard let image = selectedImage else { return }
        isLoading = true
        errorMessage = nil
        detectResult = nil

        do {
            let options = skipDedup ? DetectOptions(skipDedup: true) : nil
            detectResult = try await service.detect(image: image, options: options)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resetScene() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await service.resetScene()
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
    }
}
