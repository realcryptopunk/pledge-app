import SwiftUI
import AVFoundation
import CoreLocation

// MARK: - BeRealVerificationView

struct BeRealVerificationView: View {
    let todayHabit: TodayHabit
    let onVerified: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    @StateObject private var camera = CameraModel()
    @State private var countdownValue: Int? = nil
    @State private var capturedImage: UIImage? = nil
    @State private var isSubmitting = false
    @State private var verificationResult: PhotoVerificationResult? = nil
    @State private var showResult = false
    @State private var locationString: String? = nil

    private let photoService = PhotoVerificationService()
    private let locationManager = CLLocationManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = capturedImage {
                reviewPhase(image: image)
            } else {
                cameraPhase
            }

            // Top bar
            VStack {
                topBar
                Spacer()
            }
        }
        .statusBarHidden()
        .onAppear {
            camera.start()
            fetchLocation()
        }
        .onDisappear {
            camera.stop()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                PPHaptic.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Prove it")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(todayHabit.habit.name) \(todayHabit.habit.icon)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Invisible spacer to balance layout
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Camera Phase

    private var cameraPhase: some View {
        ZStack {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Countdown overlay
            if let count = countdownValue {
                Text("\(count)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .id(count)
            }

            // Bottom controls
            VStack {
                Spacer()

                Button {
                    startCountdown()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 74, height: 74)
                        Circle()
                            .fill(.white)
                            .frame(width: 62, height: 62)
                    }
                }
                .disabled(countdownValue != nil)
                .opacity(countdownValue != nil ? 0.4 : 1)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Review Phase

    private func reviewPhase(image: UIImage) -> some View {
        ZStack {
            // Photo with overlays
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Timestamp + location overlay (bottom-left, burned in like BeReal)
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timestampString())
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 4)

                        if let loc = locationString {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                Text(loc)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.8), radius: 4)
                        }
                    }
                    .padding(16)
                    Spacer()
                }
                .padding(.bottom, 120)
            }

            // Result overlay
            if showResult, let result = verificationResult {
                resultOverlay(result: result)
                    .transition(.scale.combined(with: .opacity))
            }

            // Bottom buttons
            if !showResult {
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
        }
    }

    // MARK: - Result Overlay

    private func resultOverlay(result: PhotoVerificationResult) -> some View {
        VStack(spacing: 16) {
            Image(systemName: result.isVerified ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(result.isVerified ? .pledgeGreen : .pledgeRed)

            Text(result.isVerified ? "Verified!" : "Not Verified")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(result.reason)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Text("\(Int(result.confidence * 100))% confidence")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            Button {
                PPHaptic.success()
                if result.isVerified {
                    onVerified()
                }
                dismiss()
            } label: {
                Text(result.isVerified ? "Done" : "Try Again")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(result.isVerified ? Color.pledgeGreen : Color.white)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.4), radius: 20)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 20) {
            // Retake
            Button {
                PPHaptic.light()
                withAnimation(.quickSnap) {
                    capturedImage = nil
                    verificationResult = nil
                    showResult = false
                }
                camera.start()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Retake")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }

            // Submit
            Button {
                PPHaptic.medium()
                submitForReview()
            } label: {
                HStack(spacing: 6) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isSubmitting ? "Analyzing..." : "Submit for AI Review")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.buttonTop, theme.buttonBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .disabled(isSubmitting)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func startCountdown() {
        countdownValue = 3
        PPHaptic.medium()

        func tick(value: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if value > 1 {
                    withAnimation(.springBounce) {
                        countdownValue = value - 1
                    }
                    PPHaptic.light()
                    tick(value: value - 1)
                } else {
                    // Capture
                    withAnimation(.springBounce) {
                        countdownValue = nil
                    }
                    PPHaptic.heavy()
                    camera.capture { image in
                        withAnimation(.springBounce) {
                            capturedImage = image
                        }
                        camera.stop()
                    }
                }
            }
        }

        tick(value: 3)
    }

    private func submitForReview() {
        guard let image = capturedImage else { return }
        isSubmitting = true

        Task {
            let result = await photoService.verifyPhoto(image: image, habitType: todayHabit.habit.type)
            await MainActor.run {
                verificationResult = result
                isSubmitting = false
                withAnimation(.springBounce) {
                    showResult = true
                }
            }
        }
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a · MMM d, yyyy"
        return formatter.string(from: Date())
    }

    private func fetchLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() == .authorizedAlways {
            if let location = locationManager.location {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                    if let place = placemarks?.first {
                        let city = place.locality ?? ""
                        let area = place.subLocality ?? place.name ?? ""
                        locationString = area.isEmpty ? city : "\(area), \(city)"
                    }
                }
            }
        }
    }
}

// MARK: - Camera Model

class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    func start() {
        guard session.inputs.isEmpty else {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        // Mirror front camera
        if let connection = output.connection(with: .video) {
            connection.isVideoMirrored = true
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func capture(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        DispatchQueue.main.async {
            self.captureCompletion?(image)
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
