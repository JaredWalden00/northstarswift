import SwiftUI

@MainActor
@Observable
final class OCRViewModel {
    var selectedImage: UIImage?
    var ocrResult: OCRResponse?
    var isLoading = false
    var errorMessage: String?
    var showImagePicker = false
    var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    private let service: OCRService

    init(client: APIClient) {
        self.service = OCRService(client: client)
    }

    func runOCR() async {
        guard let image = selectedImage else { return }
        isLoading = true
        errorMessage = nil
        ocrResult = nil

        do {
            ocrResult = try await service.ocr(image: image)
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
        ocrResult = nil
        errorMessage = nil
    }
}
