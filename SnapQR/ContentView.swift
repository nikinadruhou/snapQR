import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    var body: some View {
        VStack {
            Text("SnapQR")
                .font(.largeTitle)
                .padding()

            Button("Scan QR Code") {
                scanQRCode()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }

    func scanQRCode() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "/tmp/snapqr.png"]
        task.launch()
        task.waitUntilExit()

        let imageUrl = URL(fileURLWithPath: "/tmp/snapqr.png")
        guard let ciImage = CIImage(contentsOf: imageUrl) else {
            showResult("Failed to load image.")
            return
        }

        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []

        var message = "No QR code found."
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature {
                message = qrFeature.messageString ?? message
                break
            }
        }

        showResult(message)
    }

    func showResult(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "QR Code Result"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
