# NorthStar

iOS app + PC capture server for remote OCR and object detection.

## Architecture

```
iPhone App  ──GET /v1/capture──►  Capture Server (PC:3000)  ──returns JPEG──►  iPhone App
    │                                                                              │
    └──POST /v1/ocr or /v1/detect──►  OCR/Detection Server (PC:8000)  ◄────────────┘
                                          (PaddleOCR + YOLOv8)

    OR if server unavailable:
    └──► Apple Vision (on-device, no server needed)
```

**Two servers, two jobs:**

| Server | Port | Purpose |
|--------|------|---------|
| Capture Server | `3000` | Grabs photos from your PC webcam and serves them to the iPhone |
| OCR/Detection Server | `8000` | Processes images with PaddleOCR and YOLOv8 |

The capture endpoint is set as a **full URL** so it can point to a different server than the Base URL.

## Quick Start

### 1. Start the Capture Server (PC)

```bash
cd capture-server
npm install
npm run start
```

The server prints your local IP:

```
  Dashboard:  http://localhost:3000
  Local IP:   http://192.168.1.55:3000
```

Open `http://localhost:3000` in your browser and click **Start Webcam**.

### 2. Configure the iPhone App

In the **Settings** tab:

| Setting | Value | Why |
|---------|-------|-----|
| **Base URL** | `http://<your-pc-ip>:8000` | Points OCR/Detection requests to the processing server |
| **API Key** | `test` (or your key from `.env`) | Auth for the OCR/Detection server |
| **Capture Endpoint** | `http://<your-pc-ip>:3000/v1/capture` | Full URL to the capture server |
| **Processing Mode** | Your choice (see below) | Which engine processes images |

> **Important:** The Base URL and Capture Endpoint point to **different ports**. Capture goes to `:3000`, OCR/Detection goes to `:8000`. The capture endpoint must be a full URL since it's a different server.

### 3. Use the App

Go to the **Capture** tab and tap **Capture**. The app:
1. Sends a GET to your capture server
2. Receives the latest webcam frame
3. Displays it with optional auto-processing

## Processing Modes

| Mode | Behavior |
|------|----------|
| **Auto** | Tries the remote server first; if it fails, falls back to Apple Vision on-device |
| **Server Only** | Always sends to the OCR/Detection server (errors if unreachable) |
| **On-Device Only** | Uses Apple Vision framework locally — works offline, no server needed |

## App Tabs

| Tab | Description |
|-----|-------------|
| **Capture** | Request a photo from the PC capture server, then process it |
| **OCR** | Pick/capture a photo on the iPhone, run text recognition |
| **Detect** | Pick/capture a photo on the iPhone, run object detection |
| **Server** | Health/readiness dashboard, Prometheus metrics |
| **Settings** | Configure URLs, API key, processing mode |

## Capture Server Features

- **Webcam** — browser-based camera access (no native drivers needed)
- **Manual Capture** — snap one frame on demand
- **Auto Capture** — continuously send frames at 0.5s–10s intervals
- **Drag & Drop** — upload any image file instead of using the webcam
- **GET /v1/capture** — returns the latest frame as JPEG (used by the iPhone app)
- **GET /v1/capture/status** — check if a frame is available
- **GET /healthz** — server health check

## On-Device Vision Capabilities

When using Apple Vision (Auto fallback or On-Device mode):

- **OCR** — `VNRecognizeTextRequest` with accurate recognition, language correction, auto language detection
- **Image Classification** — scene and object labels with confidence scores
- **Face Detection** — bounding boxes around detected faces
- **Barcode Detection** — reads barcodes with symbology identification
- **Rectangle Detection** — finds document-like rectangular regions

## API Endpoints (OCR/Detection Server)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/healthz` | GET | Liveness check |
| `/readyz` | GET | Readiness check (engine load status) |
| `/metrics` | GET | Prometheus metrics |
| `/v1/ocr` | POST | Single image OCR |
| `/v1/ocr/batch` | POST | Batch OCR (1-8 images) |
| `/v1/detect` | POST | Object detection with scene-change dedup |
| `/v1/detect/reset` | POST | Reset scene state |

All `/v1/*` endpoints require the `X-API-Key` header.

## Project Structure

```
northstar-swiftapp/
├── capture-server/              # Node.js webcam capture server
│   ├── package.json
│   ├── server.js
│   └── public/
│       └── index.html           # Browser dashboard with webcam UI
├── NorthStar.xcodeproj/         # Xcode project (open this on Mac)
├── NorthStar/
│   ├── NorthStarApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── OCRModels.swift
│   │   ├── DetectModels.swift
│   │   ├── ServerModels.swift
│   │   └── ProcessingMode.swift
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── OCRService.swift
│   │   ├── DetectService.swift
│   │   ├── ServerService.swift
│   │   ├── CaptureService.swift
│   │   ├── VisionOCRService.swift
│   │   └── VisionDetectService.swift
│   ├── ViewModels/
│   │   ├── OCRViewModel.swift
│   │   ├── DetectViewModel.swift
│   │   ├── ServerViewModel.swift
│   │   └── CaptureViewModel.swift
│   ├── Views/
│   │   ├── RemoteCaptureView.swift
│   │   ├── OCRView.swift
│   │   ├── DetectView.swift
│   │   ├── ServerStatusView.swift
│   │   ├── SettingsView.swift
│   │   ├── ImagePicker.swift
│   │   └── BoundingBoxOverlay.swift
│   └── Utilities/
│       └── ImageUtils.swift
└── README.md
```

## Requirements

- **iPhone app:** iOS 17+, Xcode 15+
- **Capture server:** Node.js 18+
- **OCR/Detection server:** Python with PaddleOCR + YOLOv8 (separate project)
