import SwiftUI
import AVFoundation
import Vision

// MARK: - Exercise Type

enum ExerciseType {
    case pushups
    case pullUps
    case jumpingJacks

    var displayName: String {
        switch self {
        case .pushups: return "PUSHUPS"
        case .pullUps: return "PULL-UPS"
        case .jumpingJacks: return "JUMPING JACKS"
        }
    }

    var completionLabel: String {
        switch self {
        case .pushups: return "Pushups"
        case .pullUps: return "Pull-Ups"
        case .jumpingJacks: return "Jumping Jacks"
        }
    }

    var readyPrompt: String {
        switch self {
        case .pushups: return "Ready — start pushing"
        case .pullUps: return "Ready — grab the bar"
        case .jumpingJacks: return "Ready — start jumping"
        }
    }

    var readyIcon: String {
        switch self {
        case .pushups: return "arrow.down.circle"
        case .pullUps: return "arrow.up.circle"
        case .jumpingJacks: return "figure.jumprope"
        }
    }

    init?(habitType: HabitType) {
        switch habitType {
        case .pushups: self = .pushups
        case .pullUps: self = .pullUps
        case .jumpingJacks: self = .jumpingJacks
        default: return nil
        }
    }
}

// MARK: - ExerciseCounterView

struct ExerciseCounterView: View {
    let exerciseType: ExerciseType
    let targetReps: Int
    let onComplete: (Int) -> Void

    @StateObject private var camera: ExercisePoseCamera
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    @State private var repPulse = false
    @State private var showComplete = false

    init(exerciseType: ExerciseType, targetReps: Int, onComplete: @escaping (Int) -> Void) {
        self.exerciseType = exerciseType
        self.targetReps = targetReps
        self.onComplete = onComplete
        self._camera = StateObject(wrappedValue: ExercisePoseCamera(exerciseType: exerciseType))
    }

    var body: some View {
        ZStack {
            // Camera feed
            ExerciseCameraPreview(session: camera.captureSession)
                .ignoresSafeArea()

            // Dim overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            // Skeleton overlay
            GeometryReader { geo in
                if let pose = camera.detectedPose {
                    ExerciseSkeletonView(pose: pose, size: geo.size, color: theme.surface)
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

            Text(exerciseType.displayName)
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
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 8)
                .frame(width: 180, height: 180)

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

            Circle()
                .fill(theme.surface.opacity(0.15))
                .frame(width: 170, height: 170)
                .blur(radius: 20)
                .opacity(progress > 0 ? 1 : 0)

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
                Label(exerciseType.readyPrompt, systemImage: exerciseType.readyIcon)
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

                Text("\(camera.repCount) \(exerciseType.completionLabel)")
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

private struct ExerciseCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> ExerciseCameraPreviewUIView {
        let view = ExerciseCameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: ExerciseCameraPreviewUIView, context: Context) {}
}

private class ExerciseCameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Skeleton Overlay

private struct ExerciseSkeletonView: View {
    let pose: VNHumanBodyPoseObservation
    let size: CGSize
    let color: Color

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
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
            for (from, to) in connections {
                guard let fromPt = screenPoint(for: from),
                      let toPt = screenPoint(for: to) else { continue }

                var path = Path()
                path.move(to: fromPt)
                path.addLine(to: toPt)
                context.stroke(path, with: .color(color.opacity(0.5)), lineWidth: 3)
            }

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
                let glowRect = rect.insetBy(dx: -3, dy: -3)
                context.fill(Circle().path(in: glowRect), with: .color(color.opacity(0.2)))
            }
        }
    }

    private func screenPoint(for joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let point = try? pose.recognizedPoint(joint),
              point.confidence > 0.2 else { return nil }

        return CGPoint(
            x: (1 - point.location.x) * size.width,
            y: (1 - point.location.y) * size.height
        )
    }
}

// MARK: - Exercise Pose Camera

@MainActor
final class ExercisePoseCamera: NSObject, ObservableObject {
    @Published var detectedPose: VNHumanBodyPoseObservation?
    @Published var repCount: Int = 0
    @Published var isInPosition: Bool = false

    nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.pledge.exercisePoseDetection", qos: .userInteractive)

    private let repCounter: ExerciseRepCounter

    init(exerciseType: ExerciseType) {
        self.repCounter = ExerciseRepCounter(exerciseType: exerciseType)
        super.init()
    }

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

extension ExercisePoseCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
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

// MARK: - Exercise Rep Counter

private final class ExerciseRepCounter: @unchecked Sendable {
    enum Phase { case waiting, up, down }

    private let exerciseType: ExerciseType
    private var phase: Phase = .waiting
    private var repCount: Int = 0
    private var frameSkipCounter: Int = 0

    // Shared timing
    private var lastRepTime: Date = .distantPast

    // Smoothing
    private let alpha: CGFloat = 0.25

    // Pushup state
    private var smoothedNoseY: CGFloat?
    private var peakY: CGFloat = 0
    private var valleyY: CGFloat = 1

    // Pull-up state
    private var smoothedWristY: CGFloat?
    private var peakWristY: CGFloat = 0
    private var valleyWristY: CGFloat = 1

    // Jumping jack state
    private var smoothedWristDist: CGFloat?
    private var peakDist: CGFloat = 0
    private var valleyDist: CGFloat = 1

    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
    }

    func shouldProcessFrame() -> Bool {
        frameSkipCounter += 1
        return frameSkipCounter % 4 == 0
    }

    func process(_ observation: VNHumanBodyPoseObservation) -> Int {
        switch exerciseType {
        case .pushups:
            return processPushup(observation)
        case .pullUps:
            return processPullUp(observation)
        case .jumpingJacks:
            return processJumpingJack(observation)
        }
    }

    // MARK: - Pushup Detection

    private func processPushup(_ observation: VNHumanBodyPoseObservation) -> Int {
        guard let nose = try? observation.recognizedPoint(.nose),
              nose.confidence > 0.5 else {
            return repCount
        }

        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let leftHipCheck = try? observation.recognizedPoint(.leftHip)
        let rightHipCheck = try? observation.recognizedPoint(.rightHip)
        let hasShoulders = (leftShoulder?.confidence ?? 0) > 0.4 && (rightShoulder?.confidence ?? 0) > 0.4
        let hasHip = (leftHipCheck?.confidence ?? 0) > 0.3 || (rightHipCheck?.confidence ?? 0) > 0.3
        guard hasShoulders && hasHip else { return repCount }

        let rawY = nose.location.y

        if let prev = smoothedNoseY {
            smoothedNoseY = alpha * rawY + (1 - alpha) * prev
        } else {
            smoothedNoseY = rawY
        }

        guard let y = smoothedNoseY else { return repCount }

        let bodyHeight = calculateBodyHeight(observation)
        let threshold = max(bodyHeight * 0.10, 0.025)
        let minRepInterval: TimeInterval = 0.8

        switch phase {
        case .waiting:
            phase = .up
            peakY = y

        case .up:
            if y > peakY { peakY = y }
            if y < peakY - threshold {
                phase = .down
                valleyY = y
            }

        case .down:
            if y < valleyY { valleyY = y }
            if y > valleyY + threshold {
                let now = Date()
                if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                    repCount += 1
                    lastRepTime = now
                }
                phase = .up
                peakY = y
            }
        }

        return repCount
    }

    // MARK: - Pull-Up Detection

    private func processPullUp(_ observation: VNHumanBodyPoseObservation) -> Int {
        guard let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              leftWrist.confidence > 0.3, rightWrist.confidence > 0.3 else {
            return repCount
        }

        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let hasShoulders = (leftShoulder?.confidence ?? 0) > 0.4 && (rightShoulder?.confidence ?? 0) > 0.4
        guard hasShoulders else { return repCount }

        let avgShoulderY = ((leftShoulder?.location.y ?? 0) + (rightShoulder?.location.y ?? 0)) / 2
        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2

        // Relative wrist position: positive = wrists above shoulders
        let relativeY = avgWristY - avgShoulderY

        if let prev = smoothedWristY {
            smoothedWristY = alpha * relativeY + (1 - alpha) * prev
        } else {
            smoothedWristY = relativeY
        }

        guard let y = smoothedWristY else { return repCount }

        let threshold: CGFloat = 0.12
        let minRepInterval: TimeInterval = 1.0

        switch phase {
        case .waiting:
            phase = .down
            valleyWristY = y

        case .down:
            // Track lowest relative position (wrists below shoulders)
            if y < valleyWristY { valleyWristY = y }
            // Detect upward movement — wrists going above shoulders
            if y > valleyWristY + threshold {
                phase = .up
                peakWristY = y
            }

        case .up:
            // Track highest relative position
            if y > peakWristY { peakWristY = y }
            // Detect downward movement — wrists dropping back below
            if y < peakWristY - threshold {
                let now = Date()
                if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                    repCount += 1
                    lastRepTime = now
                }
                phase = .down
                valleyWristY = y
            }
        }

        return repCount
    }

    // MARK: - Jumping Jack Detection

    private func processJumpingJack(_ observation: VNHumanBodyPoseObservation) -> Int {
        guard let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              leftWrist.confidence > 0.3, rightWrist.confidence > 0.3 else {
            return repCount
        }

        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let hasShoulders = (leftShoulder?.confidence ?? 0) > 0.4 && (rightShoulder?.confidence ?? 0) > 0.4
        guard hasShoulders else { return repCount }

        let shoulderWidth = abs((leftShoulder?.location.x ?? 0) - (rightShoulder?.location.x ?? 0))
        guard shoulderWidth > 0.01 else { return repCount }

        let wristDist = abs(leftWrist.location.x - rightWrist.location.x)
        // Normalize wrist distance by shoulder width
        let normalizedDist = wristDist / shoulderWidth

        if let prev = smoothedWristDist {
            smoothedWristDist = alpha * normalizedDist + (1 - alpha) * prev
        } else {
            smoothedWristDist = normalizedDist
        }

        guard let dist = smoothedWristDist else { return repCount }

        // Thresholds relative to shoulder width
        let apartThreshold: CGFloat = 2.0   // ~0.4 body width when shoulderWidth ~0.2
        let togetherThreshold: CGFloat = 1.0 // ~0.2 body width
        let minRepInterval: TimeInterval = 0.6

        switch phase {
        case .waiting:
            phase = .down
            valleyDist = dist

        case .down:
            // Wrists together phase — track minimum distance
            if dist < valleyDist { valleyDist = dist }
            // Detect wrists spreading apart
            if dist > apartThreshold {
                phase = .up
                peakDist = dist
            }

        case .up:
            // Wrists apart phase — track maximum distance
            if dist > peakDist { peakDist = dist }
            // Detect wrists coming back together
            if dist < togetherThreshold {
                let now = Date()
                if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                    repCount += 1
                    lastRepTime = now
                }
                phase = .down
                valleyDist = dist
            }
        }

        return repCount
    }

    // MARK: - Helpers

    private func calculateBodyHeight(_ observation: VNHumanBodyPoseObservation) -> CGFloat {
        let nose = try? observation.recognizedPoint(.nose)
        let leftHip = try? observation.recognizedPoint(.leftHip)
        let rightHip = try? observation.recognizedPoint(.rightHip)

        let noseY = (nose?.confidence ?? 0) > 0.2 ? nose!.location.y : nil
        let hipY: CGFloat?
        if let lh = leftHip, lh.confidence > 0.2, let rh = rightHip, rh.confidence > 0.2 {
            hipY = (lh.location.y + rh.location.y) / 2
        } else if let lh = leftHip, lh.confidence > 0.2 {
            hipY = lh.location.y
        } else if let rh = rightHip, rh.confidence > 0.2 {
            hipY = rh.location.y
        } else {
            hipY = nil
        }

        if let ny = noseY, let hy = hipY {
            return abs(ny - hy)
        }
        return 0.15
    }
}

// MARK: - Preview

#Preview {
    ExerciseCounterView(exerciseType: .pushups, targetReps: 25) { count in
        print("Completed \(count) reps")
    }
}
