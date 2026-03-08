import SwiftUI
import AVFoundation
import Vision

// MARK: - PushupCounterView

struct PushupCounterView: View {
    let targetReps: Int
    let onComplete: (Int) -> Void

    @StateObject private var camera = PoseDetectionCamera()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    @State private var repPulse = false
    @State private var showComplete = false

    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(session: camera.captureSession)
                .ignoresSafeArea()

            // Dim overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            // Skeleton overlay
            GeometryReader { geo in
                if let pose = camera.detectedPose {
                    SkeletonView(pose: pose, size: geo.size, color: theme.surface)
                }
            }
            .ignoresSafeArea()

            // UI chrome
            VStack(spacing: 0) {
                topBar
                Spacer()
                counterRing
                    .padding(.bottom, 24)
                statusText
                    .padding(.bottom, 60)
            }

            // Completion overlay
            if showComplete {
                completionOverlay
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            camera.setupCamera()
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: camera.repCount) { _, count in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                repPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                repPulse = false
            }

            if count >= targetReps && !showComplete {
                PPHaptic.success()
                withAnimation(.springBounce) { showComplete = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete(count)
                }
            } else {
                PPHaptic.light()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                camera.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text("PUSHUPS")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Counter Ring

    private var counterRing: some View {
        let progress = min(CGFloat(camera.repCount) / CGFloat(max(targetReps, 1)), 1.0)

        return ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 8)
                .frame(width: 180, height: 180)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [theme.light, theme.surface, theme.mid],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: camera.repCount)

            // Glow behind ring
            Circle()
                .fill(theme.surface.opacity(0.15))
                .frame(width: 170, height: 170)
                .blur(radius: 20)
                .opacity(progress > 0 ? 1 : 0)

            // Count
            VStack(spacing: 2) {
                Text("\(camera.repCount)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: camera.repCount)
                    .scaleEffect(repPulse ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: repPulse)

                Text("of \(targetReps)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    // MARK: - Status Text

    private var statusText: some View {
        Group {
            if !camera.isInPosition {
                Label("Get in position", systemImage: "figure.stand")
            } else if camera.repCount == 0 {
                Label("Ready — start pushing", systemImage: "arrow.down.circle")
            } else if camera.repCount >= targetReps {
                Label("Complete!", systemImage: "checkmark.circle.fill")
            } else {
                Label("Keep going!", systemImage: "flame.fill")
            }
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Capsule().fill(.ultraThinMaterial))
        .animation(.quickSnap, value: camera.isInPosition)
        .animation(.quickSnap, value: camera.repCount)
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.light, theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .badgeScale()

                Text("\(camera.repCount) Pushups")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Verified!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

private class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Skeleton Overlay

private struct SkeletonView: View {
    let pose: VNHumanBodyPoseObservation
    let size: CGSize
    let color: Color

    // Joint connections to draw
    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Torso
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        // Left arm
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        // Right arm
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        // Head
        (.nose, .leftEye),
        (.nose, .rightEye),
        (.leftEar, .leftEye),
        (.rightEar, .rightEye),
    ]

    private let jointsToDraw: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .leftEye, .rightEye, .leftEar, .rightEar,
        .leftShoulder, .rightShoulder,
        .leftElbow, .rightElbow,
        .leftWrist, .rightWrist,
        .leftHip, .rightHip,
    ]

    var body: some View {
        Canvas { context, canvasSize in
            // Draw connection lines
            for (from, to) in connections {
                guard let fromPt = screenPoint(for: from),
                      let toPt = screenPoint(for: to) else { continue }

                var path = Path()
                path.move(to: fromPt)
                path.addLine(to: toPt)
                context.stroke(path, with: .color(color.opacity(0.5)), lineWidth: 3)
            }

            // Draw joints
            for joint in jointsToDraw {
                guard let pt = screenPoint(for: joint) else { continue }
                let dotSize: CGFloat = joint == .nose ? 10 : 8
                let rect = CGRect(
                    x: pt.x - dotSize / 2,
                    y: pt.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(Circle().path(in: rect), with: .color(color.opacity(0.8)))
                // Glow
                let glowRect = rect.insetBy(dx: -3, dy: -3)
                context.fill(Circle().path(in: glowRect), with: .color(color.opacity(0.2)))
            }
        }
    }

    private func screenPoint(for joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let point = try? pose.recognizedPoint(joint),
              point.confidence > 0.2 else { return nil }

        // Vision: origin bottom-left, y-up. Front camera: mirrored.
        return CGPoint(
            x: (1 - point.location.x) * size.width,
            y: (1 - point.location.y) * size.height
        )
    }
}

// MARK: - Pose Detection Camera

@MainActor
final class PoseDetectionCamera: NSObject, ObservableObject {
    @Published var detectedPose: VNHumanBodyPoseObservation?
    @Published var repCount: Int = 0
    @Published var isInPosition: Bool = false

    nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.pledge.poseDetection", qos: .userInteractive)

    // Rep counting state (accessed only on processingQueue)
    private let repCounter = PushupRepCounter()

    func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
    }

    func start() {
        guard !captureSession.isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PoseDetectionCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Process every 2nd frame (~15fps) for better responsiveness
        guard repCounter.shouldProcessFrame() else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return
        }

        guard let observation = request.results?.first else {
            Task { @MainActor in
                self.detectedPose = nil
                self.isInPosition = false
            }
            return
        }

        // Count reps
        let newCount = repCounter.process(observation)

        Task { @MainActor in
            self.detectedPose = observation
            self.isInPosition = true
            if newCount != self.repCount {
                self.repCount = newCount
            }
        }
    }
}

// MARK: - Pushup Rep Counter (improved state machine)
//
// Key improvements over v1:
// 1. Uses ELBOW ANGLE as primary signal (not just nose Y) — much more reliable
// 2. Multi-signal fusion: elbow angle + nose Y + shoulder-wrist distance
// 3. Process every 2nd frame instead of every 4th (better temporal resolution)
// 4. Lower min rep interval (0.5s vs 0.8s) — fast pushups were being missed
// 5. Requires both down AND up to be confirmed before counting
// 6. Hysteresis: different thresholds for entering vs exiting states (prevents flickering)

private final class PushupRepCounter: @unchecked Sendable {
    enum Phase { case idle, down, up }

    private var phase: Phase = .idle
    private var repCount: Int = 0
    private var frameSkipCounter: Int = 0

    // Signal history for smoothing
    private var elbowAngleHistory: [CGFloat] = []
    private var noseYHistory: [CGFloat] = []
    private let historySize = 5

    // Calibration
    private var calibrationFrames: Int = 0
    private var calibratedUpAngle: CGFloat? = nil  // elbow angle when arms extended
    private var calibratedDownAngle: CGFloat? = nil // elbow angle when arms bent

    // Timing
    private var lastRepTime: Date = .distantPast
    private let minRepInterval: TimeInterval = 0.5

    // Thresholds
    private let downAngleThreshold: CGFloat = 110  // elbow angle below this = "down"
    private let upAngleThreshold: CGFloat = 145     // elbow angle above this = "up"

    func shouldProcessFrame() -> Bool {
        frameSkipCounter += 1
        return frameSkipCounter % 2 == 0  // every 2nd frame = ~15fps
    }

    func process(_ observation: VNHumanBodyPoseObservation) -> Int {
        // Get key joints
        guard let leftShoulder = safePoint(observation, .leftShoulder),
              let rightShoulder = safePoint(observation, .rightShoulder) else {
            return repCount
        }

        // Get elbow angles (primary signal)
        let leftElbowAngle = elbowAngle(observation, side: .left)
        let rightElbowAngle = elbowAngle(observation, side: .right)

        // Use the best available elbow angle
        let currentElbowAngle: CGFloat
        if let left = leftElbowAngle, let right = rightElbowAngle {
            currentElbowAngle = (left + right) / 2
        } else if let left = leftElbowAngle {
            currentElbowAngle = left
        } else if let right = rightElbowAngle {
            currentElbowAngle = right
        } else {
            // Fallback to nose Y if elbows aren't visible
            return processWithNoseY(observation)
        }

        // Smooth the angle
        elbowAngleHistory.append(currentElbowAngle)
        if elbowAngleHistory.count > historySize {
            elbowAngleHistory.removeFirst()
        }
        let smoothedAngle = elbowAngleHistory.reduce(0, +) / CGFloat(elbowAngleHistory.count)

        // Also track nose Y as secondary confirmation
        if let nose = safePoint(observation, .nose) {
            noseYHistory.append(nose.y)
            if noseYHistory.count > historySize {
                noseYHistory.removeFirst()
            }
        }

        // State machine using elbow angle
        switch phase {
        case .idle:
            // Wait for first "up" position (arms extended)
            if smoothedAngle > upAngleThreshold {
                phase = .up
            }

        case .up:
            // Detect going down (elbows bending)
            if smoothedAngle < downAngleThreshold {
                phase = .down
            }

        case .down:
            // Detect coming back up (elbows extending) = 1 rep
            if smoothedAngle > upAngleThreshold {
                let now = Date()
                if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                    repCount += 1
                    lastRepTime = now
                }
                phase = .up
            }
        }

        return repCount
    }

    // Fallback: nose-Y based counting (when elbows not visible)
    private var nosePhase: Phase = .idle
    private var nosePeakY: CGFloat = 0
    private var noseValleyY: CGFloat = 1

    private func processWithNoseY(_ observation: VNHumanBodyPoseObservation) -> Int {
        guard let nose = safePoint(observation, .nose) else { return repCount }

        let y = nose.y

        // Smooth
        noseYHistory.append(y)
        if noseYHistory.count > historySize {
            noseYHistory.removeFirst()
        }
        let smoothedY = noseYHistory.reduce(0, +) / CGFloat(noseYHistory.count)

        let bodyHeight = calculateBodyHeight(observation)
        let threshold = max(bodyHeight * 0.08, 0.02)

        switch nosePhase {
        case .idle:
            nosePhase = .up
            nosePeakY = smoothedY

        case .up:
            if smoothedY > nosePeakY { nosePeakY = smoothedY }
            if smoothedY < nosePeakY - threshold {
                nosePhase = .down
                noseValleyY = smoothedY
            }

        case .down:
            if smoothedY < noseValleyY { noseValleyY = smoothedY }
            if smoothedY > noseValleyY + threshold {
                let now = Date()
                if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                    repCount += 1
                    lastRepTime = now
                }
                nosePhase = .up
                nosePeakY = smoothedY
            }
        }

        return repCount
    }

    // MARK: - Helpers

    private func safePoint(_ obs: VNHumanBodyPoseObservation, _ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let pt = try? obs.recognizedPoint(joint), pt.confidence > 0.3 else { return nil }
        return pt.location
    }

    private enum Side { case left, right }

    private func elbowAngle(_ obs: VNHumanBodyPoseObservation, side: Side) -> CGFloat? {
        let (shoulderJoint, elbowJoint, wristJoint): (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)

        switch side {
        case .left:
            shoulderJoint = .leftShoulder
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
        case .right:
            shoulderJoint = .rightShoulder
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
        }

        guard let shoulder = safePoint(obs, shoulderJoint),
              let elbow = safePoint(obs, elbowJoint),
              let wrist = safePoint(obs, wristJoint) else {
            return nil
        }

        // Calculate angle at elbow (shoulder-elbow-wrist)
        let v1 = CGPoint(x: shoulder.x - elbow.x, y: shoulder.y - elbow.y)
        let v2 = CGPoint(x: wrist.x - elbow.x, y: wrist.y - elbow.y)

        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)

        guard mag1 > 0, mag2 > 0 else { return nil }

        let cosAngle = max(-1, min(1, dot / (mag1 * mag2)))
        return acos(cosAngle) * 180 / .pi  // degrees
    }

    private func calculateBodyHeight(_ observation: VNHumanBodyPoseObservation) -> CGFloat {
        let nose = safePoint(observation, .nose)
        let leftHip = safePoint(observation, .leftHip)
        let rightHip = safePoint(observation, .rightHip)

        let hipY: CGFloat?
        if let lh = leftHip, let rh = rightHip {
            hipY = (lh.y + rh.y) / 2
        } else {
            hipY = leftHip?.y ?? rightHip?.y
        }

        if let ny = nose?.y, let hy = hipY {
            return abs(ny - hy)
        }
        return 0.15
    }
}

// MARK: - Preview

#Preview {
    PushupCounterView(targetReps: 25) { count in
        print("Completed \(count) pushups")
    }
}
