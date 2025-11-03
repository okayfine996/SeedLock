//
//  CameraScannerView.swift
//  seedlock
//
//  Created by Fine Ke on 27/10/2025.
//

import SwiftUI
import AVFoundation
import Vision

/// Real-time camera scanner for mnemonic phrase recognition
struct CameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var recognizedText: String
    
    @StateObject private var cameraManager = CameraManager()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var detectedWords: [String] = []
    @State private var isProcessing = false
    @State private var lastProcessedHash: Int = 0
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Detection info
                if !detectedWords.isEmpty {
                    detectionOverlay
                }
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraManager.startScanning { result in
                handleScanResult(result)
            }
        }
        .onDisappear {
            cameraManager.stopScanning()
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - UI Components
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("camera_scanner.title".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Flash toggle
            Button(action: { cameraManager.toggleFlash() }) {
                Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    private var detectionOverlay: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("camera_scanner.detected".localized(detectedWords.count))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Words Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(Array(detectedWords.enumerated()), id: \.offset) { index, word in
                        ScannerWordCell(number: index + 1, word: word)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: 280)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.5), lineWidth: 2)
                )
        )
        .padding(.horizontal, 16)
    }
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Instructions
            Group {
                if detectedWords.isEmpty {
                    Text("camera_scanner.instruction".localized)
                        .font(.system(size: 15))
                } else if detectedWords.count < 12 {
                    Text("camera_scanner.need_more".localized(12 - detectedWords.count))
                        .font(.system(size: 15))
                } else if detectedWords.count > 24 {
                    // Too many words detected - show warning
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("camera_scanner.too_many".localized(detectedWords.count))
                            .font(.system(size: 15, weight: .semibold))
                    }
                } else {
                    // Check if valid word count (12-24 range)
                    let validCounts = [12, 15, 18, 21, 24]
                    if validCounts.contains(detectedWords.count) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            Text("camera_scanner.ready_count".localized(detectedWords.count))
                                .font(.system(size: 15, weight: .semibold))
                        }
                    } else {
                        // Not a valid count yet, show progress to next valid count
                        let nextValid = validCounts.first(where: { $0 > detectedWords.count }) ?? 24
                        Text("camera_scanner.continue_to".localized(nextValid - detectedWords.count, nextValid))
                            .font(.system(size: 15))
                    }
                }
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // Use button - show when we have a valid count
            let validCounts = [12, 15, 18, 21, 24]
            if validCounts.contains(detectedWords.count) {
                Button(action: {
                    recognizedText = detectedWords.joined(separator: " ")
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("camera_scanner.use_result".localized)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Handlers
    
    private func handleScanResult(_ text: String) {
        // Quick hash check to avoid reprocessing same text
        let textHash = text.hashValue
        guard textHash != lastProcessedHash else { return }
        
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            let mnemonic = OCRService.shared.extractMnemonic(from: text)
            var words = mnemonic.split(separator: " ").map(String.init)
            
            // Limit to maximum 24 words (BIP39 standard)
            if words.count > 24 {
                let originalCount = words.count
                words = Array(words.prefix(24))
                logWarning("OCR detected \(originalCount) words, truncated to 24")
            }
            
            await MainActor.run {
                // Only update if we have new words
                if !words.isEmpty && words != detectedWords {
                    detectedWords = words
                    lastProcessedHash = textHash
                }
                isProcessing = false
            }
        }
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject {
    @Published var isFlashOn = false
    
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var scanCallback: ((String) -> Void)?
    private var lastScanTime = Date()
    private let scanInterval: TimeInterval = 0.5 // Scan every 0.5 seconds (optimized for performance)
    private var isProcessingFrame = false // Debounce flag to prevent concurrent processing
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        // Use high quality for better OCR accuracy
        session.sessionPreset = .hd1280x720 // 720p: good balance between quality and performance
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        // Configure camera for better OCR
        if device.isFocusModeSupported(.continuousAutoFocus) {
            try? device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near // Better for close-up text
            }
            device.unlockForConfiguration()
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Use high priority queue for faster processing
        let processingQueue = DispatchQueue(label: "camera.frame.processing", qos: .userInitiated)
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func startScanning(callback: @escaping (String) -> Void) {
        self.scanCallback = callback
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopScanning() {
        session.stopRunning()
        scanCallback = nil
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if isFlashOn {
                device.torchMode = .off
                isFlashOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("❌ Flash toggle error: \(error)")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Debounce: Skip if already processing a frame
        guard !isProcessingFrame else { return }
        
        // Throttle scanning based on time interval
        guard Date().timeIntervalSince(lastScanTime) >= scanInterval else { return }
        
        // Mark as processing and update last scan time
        isProcessingFrame = true
        lastScanTime = Date()
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            // Always reset processing flag when done
            defer { self?.isProcessingFrame = false }
            
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else { return }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !text.isEmpty {
                self?.scanCallback?(text)
            }
        }
        
        // Balance speed and accuracy
        request.recognitionLevel = .accurate // Use accurate mode for better recognition
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false
        request.automaticallyDetectsLanguage = false
        request.minimumTextHeight = 0.015 // Minimum text height (helps filter noise)
        
        // Add custom words for iOS 16+ (significantly improves accuracy)
        if #available(iOS 16.0, *) {
            request.customWords = BIP39WordList.english // Use full BIP39 word list
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            // Reset processing flag on error
            isProcessingFrame = false
        }
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Scanner Word Cell Component

struct ScannerWordCell: View {
    let number: Int
    let word: String
    
    var body: some View {
        VStack(spacing: 6) {
            // Number
            Text("\(number)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.appSecondaryLabel)
            
            // Word
            Text(word)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appPrimary.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    CameraScannerView(recognizedText: .constant(""))
}

