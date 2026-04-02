const express = require("express");
const cors = require("cors");
const path = require("path");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.API_KEY || "test";

// Store the latest captured frame (JPEG buffer)
let latestFrame = null;
let lastCaptureTime = null;
let captureCount = 0;

// Middleware
app.use(cors());
app.use(express.json({ limit: "50mb" }));
app.use(express.static(path.join(__dirname, "public")));

// ─── Auth middleware for /v1/* routes ───
function requireAuth(req, res, next) {
  const key = req.headers["x-api-key"];
  if (!key || key !== API_KEY) {
    return res.status(401).json({ detail: "Missing or wrong X-API-Key" });
  }
  next();
}

// ─── Dashboard ───
// Served from public/index.html — opens webcam in browser, sends frames to server

// ─── POST /api/frame ───
// The browser dashboard posts JPEG frames here
app.post("/api/frame", (req, res) => {
  const { image } = req.body;
  if (!image) {
    return res.status(400).json({ detail: "Missing image field" });
  }

  // Strip data URL prefix if present
  const base64Data = image.replace(/^data:image\/\w+;base64,/, "");
  latestFrame = Buffer.from(base64Data, "base64");
  lastCaptureTime = new Date();
  captureCount++;

  res.json({ status: "ok", captureCount, timestamp: lastCaptureTime.toISOString() });
});

// ─── GET /v1/capture ───
// The iPhone app calls this to get the latest photo
app.get("/v1/capture", requireAuth, (req, res) => {
  if (!latestFrame) {
    return res.status(404).json({
      detail: "No frame captured yet. Open the dashboard in a browser and start the webcam.",
    });
  }

  // Return raw JPEG bytes
  res.set("Content-Type", "image/jpeg");
  res.set("X-Capture-Time", lastCaptureTime?.toISOString() || "");
  res.set("X-Capture-Count", String(captureCount));
  res.send(latestFrame);
});

// ─── GET /v1/capture/status ───
app.get("/v1/capture/status", requireAuth, (req, res) => {
  res.json({
    hasFrame: latestFrame !== null,
    captureCount,
    lastCaptureTime: lastCaptureTime?.toISOString() || null,
    frameSize: latestFrame ? latestFrame.length : 0,
  });
});

// ─── GET /healthz ───
app.get("/healthz", (req, res) => {
  res.json({ status: "ok" });
});

// ─── Start ───
app.listen(PORT, "0.0.0.0", () => {
  const interfaces = os.networkInterfaces();
  let localIP = "localhost";
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === "IPv4" && !iface.internal) {
        localIP = iface.address;
        break;
      }
    }
  }

  console.log("");
  console.log("  ╔══════════════════════════════════════════════════╗");
  console.log("  ║       NorthStar Capture Server                  ║");
  console.log("  ╠══════════════════════════════════════════════════╣");
  console.log(`  ║  Dashboard:  http://localhost:${PORT}              ║`);
  console.log(`  ║  Local IP:   http://${localIP}:${PORT}        ║`);
  console.log(`  ║  API Key:    ${API_KEY}                            ║`);
  console.log("  ╠══════════════════════════════════════════════════╣");
  console.log("  ║  iPhone App Settings:                           ║");
  console.log(`  ║    Base URL:  http://${localIP}:${PORT}        ║`);
  console.log("  ║    Capture:   /v1/capture                       ║");
  console.log(`  ║    API Key:   ${API_KEY}                            ║`);
  console.log("  ╚══════════════════════════════════════════════════╝");
  console.log("");
  console.log("  1. Open the dashboard URL in your PC browser");
  console.log("  2. Click 'Start Webcam' and allow camera access");
  console.log("  3. On your iPhone, set Base URL to your Local IP");
  console.log("  4. Tap 'Capture' in the app to grab a frame!");
  console.log("");
});
