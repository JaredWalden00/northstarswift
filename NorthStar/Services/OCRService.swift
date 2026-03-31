import Foundation
import UIKit

struct OCRService {
    let client: APIClient

    func ocr(image: UIImage, options: OcrOptions? = nil) async throws -> OCRResponse {
        let b64 = ImageUtils.toBase64(image)
        let body = OCRRequest(imageB64: b64, options: options)
        return try await client.request(path: "/v1/ocr", method: "POST", body: body)
    }

    func batchOCR(images: [UIImage]) async throws -> BatchOCRResponse {
        let b64s = images.map { ImageUtils.toBase64($0) }
        let body = BatchOCRRequest(imagesB64: b64s)
        return try await client.request(path: "/v1/ocr/batch", method: "POST", body: body)
    }
}
