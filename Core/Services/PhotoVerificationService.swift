import UIKit

// MARK: - Gemini Vision Photo Verification

class PhotoVerificationService {
    
    // Gemini 2.0 Flash REST API
    private let apiKey = "REDACTED_KEY"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    func verifyPhoto(image: UIImage, habitType: HabitType) async -> PhotoVerificationResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return PhotoVerificationResult(isVerified: false, confidence: 0, reason: "Failed to process image")
        }
        
        let base64Image = imageData.base64EncodedString()
        let prompt = buildPrompt(for: habitType)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 256
            ]
        ]
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return PhotoVerificationResult(isVerified: false, confidence: 0, reason: "Failed to build request")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return fallbackResult(for: habitType)
            }
            
            return parseGeminiResponse(data: data, habitType: habitType)
        } catch {
            return fallbackResult(for: habitType)
        }
    }
    
    // MARK: - Prompt Builder
    
    private func buildPrompt(for type: HabitType) -> String {
        let habitClues: String
        switch type {
        case .coldShower:
            habitClues = """
            The user claims they just took a COLD SHOWER. Look for:
            - Person near/in a shower or bathroom
            - Wet hair, water droplets on skin
            - Fogged mirror, towel, shower stall visible
            - Post-shower appearance (damp skin, wet clothing/towel)
            """
        case .meditate:
            habitClues = """
            The user claims they are MEDITATING. Look for:
            - Person sitting in calm/cross-legged position
            - Meditation cushion, yoga mat, quiet space
            - Eyes closed, relaxed posture
            - Meditation app on screen, candles, incense
            """
        case .journal:
            habitClues = """
            The user claims they are JOURNALING. Look for:
            - Open notebook, journal, or diary
            - Pen/pencil in hand or nearby
            - Handwriting visible on page
            - Writing desk setup
            """
        case .read:
            habitClues = """
            The user claims they are READING. Look for:
            - Book, e-reader (Kindle), or tablet with text
            - Person holding/looking at reading material
            - Reading posture (sitting, lying down with book)
            - Visible text on pages
            """
        default:
            habitClues = "The user claims they completed a habit. Look for any evidence of the activity."
        }
        
        return """
        You are a habit verification AI for the Pledge app. Analyze this photo to verify if the user is actually doing their habit.

        \(habitClues)

        RULES:
        - Be reasonably lenient — this isn't a court of law. If it looks plausible, verify it.
        - The photo is taken in-the-moment (like BeReal), so it may be slightly blurry or poorly framed.
        - Look for contextual clues, not perfection.
        - If the photo is completely unrelated (e.g., a screenshot, random object, black screen), reject it.

        Respond in EXACTLY this JSON format, nothing else:
        {"verified": true/false, "confidence": 0.0-1.0, "reason": "one short sentence"}
        """
    }
    
    // MARK: - Response Parser
    
    private func parseGeminiResponse(data: Data, habitType: HabitType) -> PhotoVerificationResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return fallbackResult(for: habitType)
        }
        
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let responseData = cleaned.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            if text.lowercased().contains("\"verified\": true") || text.lowercased().contains("\"verified\":true") {
                return PhotoVerificationResult(isVerified: true, confidence: 0.85, reason: celebrationMessage(for: habitType))
            }
            return PhotoVerificationResult(isVerified: false, confidence: 0.3, reason: "Couldn't verify from photo. Try again with a clearer shot.")
        }
        
        let verified = result["verified"] as? Bool ?? false
        let confidence = result["confidence"] as? Double ?? 0.5
        let reason = result["reason"] as? String ?? (verified ? celebrationMessage(for: habitType) : "Photo doesn't match the habit. Try again!")
        
        let displayReason = verified ? celebrationMessage(for: habitType) : reason
        
        return PhotoVerificationResult(
            isVerified: verified,
            confidence: confidence,
            reason: displayReason
        )
    }
    
    // MARK: - Celebration Messages
    
    private func celebrationMessage(for type: HabitType) -> String {
        switch type {
        case .coldShower:
            return ["🧊 Ice warrior confirmed!", "🚿 Cold shower hero!", "❄️ That takes guts! Verified!"].randomElement()!
        case .meditate:
            return ["🧘 Inner peace achieved!", "✨ Zen mode activated!", "🕊️ Calm mind verified!"].randomElement()!
        case .journal:
            return ["📝 Thoughts captured!", "✍️ Journaling champ!", "📓 Words on paper — verified!"].randomElement()!
        case .read:
            return ["📚 Bookworm verified!", "📖 Knowledge seeker!", "🔖 Reading habit locked in!"].randomElement()!
        default:
            return "✅ Habit verified! Great work!"
        }
    }
    
    // MARK: - Fallback (API failure)
    
    private func fallbackResult(for type: HabitType) -> PhotoVerificationResult {
        return PhotoVerificationResult(
            isVerified: true,
            confidence: 0.6,
            reason: "Verified (offline mode) — \(celebrationMessage(for: type))"
        )
    }
}
