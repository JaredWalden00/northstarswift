import SwiftUI

@MainActor
@Observable
final class CaptureViewModel {
    var capturedImage: UIImage?
    var isCapturing = false
    var isProcessing = false
    var errorMessage: String?

    // OCR results
    var ocrResult: OCRResponse?
    var ocrEngine: String?

    // Detection results
    var detectResult: DetectResponse?
    var detectEngine: String?

    /// What to do after capturing: nothing, OCR, or detect.
    var autoProcess: AutoProcess = .none

    /// Read OCR text aloud after processing.
    var speakResults = true

    private let captureService: CaptureService
    private let ocrServerService: OCRService
    private let detectServerService: DetectService
    private let visionOCR = VisionOCRService()
    private let visionDetect = VisionDetectService()
    private let speech = SpeechService.shared
    private let mode: () -> ProcessingMode

    enum AutoProcess: String, CaseIterable, Identifiable {
        case none = "None"
        case ocr = "Run OCR"
        case detect = "Run Detection"
        case both = "OCR + Detection"

        var id: String { rawValue }
    }

    init(client: APIClient, mode: @escaping () -> ProcessingMode) {
        self.captureService = CaptureService(client: client)
        self.ocrServerService = OCRService(client: client)
        self.detectServerService = DetectService(client: client)
        self.mode = mode
    }

    // MARK: - Capture

    func capture(endpoint: String) async {
        isCapturing = true
        errorMessage = nil
        clearResults()
        speech.stop()

        do {
            capturedImage = try await captureService.capture(endpoint: endpoint)
        } catch {
            errorMessage = error.localizedDescription
            isCapturing = false
            return
        }

        isCapturing = false

        // Auto-process if configured
        guard let image = capturedImage else { return }
        switch autoProcess {
        case .none:
            break
        case .ocr:
            await runOCR(on: image)
        case .detect:
            await runDetection(on: image)
        case .both:
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.runOCR(on: image) }
                group.addTask { await self.runDetection(on: image) }
            }
        }

        // Speak results after processing
        speakOCRIfEnabled()
    }

    // MARK: - OCR

    func runOCR(on image: UIImage) async {
        isProcessing = true
        ocrResult = nil
        ocrEngine = nil

        let currentMode = mode()

        switch currentMode {
        case .server:
            await runServerOCR(image)
        case .onDevice:
            await runVisionOCR(image)
        case .auto:
            await runServerOCR(image)
            if ocrResult == nil {
                await runVisionOCR(image)
            }
        }

        isProcessing = false

        // Speak if triggered manually (not from capture flow which handles it)
        speakOCRIfEnabled()
    }

    private func runServerOCR(_ image: UIImage) async {
        do {
            ocrResult = try await ocrServerService.ocr(image: image)
            ocrEngine = "Server (PaddleOCR)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runVisionOCR(_ image: UIImage) async {
        do {
            ocrResult = try await visionOCR.ocr(image: image)
            ocrEngine = "On-Device (Apple Vision)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Detection

    func runDetection(on image: UIImage) async {
        isProcessing = true
        detectResult = nil
        detectEngine = nil

        let currentMode = mode()

        switch currentMode {
        case .server:
            await runServerDetect(image)
        case .onDevice:
            await runVisionDetect(image)
        case .auto:
            await runServerDetect(image)
            if detectResult == nil {
                await runVisionDetect(image)
            }
        }

        isProcessing = false
    }

    private func runServerDetect(_ image: UIImage) async {
        do {
            detectResult = try await detectServerService.detect(image: image)
            detectEngine = "Server (YOLOv8)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runVisionDetect(_ image: UIImage) async {
        do {
            detectResult = try await visionDetect.detect(image: image)
            detectEngine = "On-Device (Apple Vision)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Text to Speech

    func speakOCRIfEnabled() {
        guard speakResults, let result = ocrResult else { return }

        let fullText = result.pages.map(\.fullText).joined(separator: ". ")
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        speech.speak(fullText)
    }

    func stopSpeaking() {
        speech.stop()
    }

    var isSpeaking: Bool {
        speech.isSpeaking
    }

    // MARK: - Clear

    func clear() {
        capturedImage = nil
        clearResults()
        errorMessage = nil
        speech.stop()
    }

    private func clearResults() {
        ocrResult = nil
        ocrEngine = nil
        detectResult = nil
        detectEngine = nil
    }
}
