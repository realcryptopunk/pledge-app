import UIKit

// MARK: - PhotoVerificationService

class PhotoVerificationService {

    // TODO: Wire Gemini Vision API for real verification
    //
    // Prompt template for Gemini:
    // """
    // Analyze this photo. The user claims they are doing [habit].
    // Does the photo show evidence of this activity?
    //
    // Look for these specific clues:
    // - Cold Shower: wet hair, shower stall, water droplets, fogged mirror, towel
    // - Meditate: seated position, calm environment, closed eyes, yoga mat
    // - Journal: open notebook, pen in hand, handwriting visible
    // - Read: book or e-reader visible, reading posture
    // - Drink Water: glass/bottle of water, drinking gesture
    // - No Junk Food: healthy meal visible, clean kitchen, salad/fruit
    //
    // Respond with:
    // - verified / not_verified
    // - confidence: 0.0 to 1.0
    // - reason: brief explanation
    // """

    /// Mock verification that returns success after a 2-second delay.
    func verifyPhoto(image: UIImage, habitType: HabitType) async -> PhotoVerificationResult {
        // Simulate network + AI processing time
        try? await Task.sleep(for: .seconds(2))

        let message = mockMessage(for: habitType)
        return PhotoVerificationResult(
            isVerified: true,
            confidence: Double.random(in: 0.85...0.98),
            reason: message
        )
    }

    private func mockMessage(for type: HabitType) -> String {
        switch type {
        case .coldShower:
            return ["Ice warrior confirmed!", "Brrr! That's dedication!", "Cold shower hero detected!"].randomElement()!
        case .meditate:
            return ["Inner peace achieved!", "Zen master mode activated!", "Calm mind verified!"].randomElement()!
        case .journal:
            return ["Thoughts captured!", "Journaling champion!", "Words on paper confirmed!"].randomElement()!
        case .read:
            return ["Bookworm verified!", "Knowledge seeker confirmed!", "Reading habit locked in!"].randomElement()!
        case .water:
            return ["Hydration station!", "Water warrior confirmed!", "Stay hydrated champion!"].randomElement()!
        case .noJunkFood:
            return ["Clean eating verified!", "Healthy choice confirmed!", "No junk detected!"].randomElement()!
        default:
            return "Habit verified! Great work!"
        }
    }
}
