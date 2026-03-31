import Foundation
import UIKit

struct DetectService {
    let client: APIClient

    func detect(image: UIImage, options: DetectOptions? = nil) async throws -> DetectResponse {
        let b64 = ImageUtils.toBase64(image)
        let body = DetectRequest(imageB64: b64, options: options)
        return try await client.request(path: "/v1/detect", method: "POST", body: body)
    }

    func resetScene() async throws -> SceneResetResponse {
        return try await client.request(path: "/v1/detect/reset", method: "POST")
    }
}
