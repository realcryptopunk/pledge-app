import UIKit

// MARK: - Gemini Vision Photo Verification (via Edge Function Proxy)

class PhotoVerificationService {

    // Edge function URL — Gemini API key lives server-side, never in iOS source.
    // Prompt logic also lives server-side in the gemini-proxy edge function.
    private var edgeFunctionURL: URL {
        URL(string: "\(EnvConfig.supabaseURL)/functions/v1/gemini-proxy")!
    }

    func verifyPhoto(image: UIImage, habitType: HabitType) async -> PhotoVerificationResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return PhotoVerificationResult(isVerified: false, confidence: 0, reason: "Failed to process image")
        }

        let base64Image = imageData.base64EncodedString()

        // Send image + habit type to edge function; prompt is built server-side
        let body: [String: Any] = [
            "image_base64": base64Image,
            "habit_type": habitType.rawValue
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return PhotoVerificationResult(isVerified: false, confidence: 0, reason: "Failed to build request")
        }

        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(EnvConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
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
            return ["Ice warrior confirmed!", "Cold shower hero!", "That takes guts! Verified!"].randomElement()!
        case .meditate:
            return ["Inner peace achieved!", "Zen mode activated!", "Calm mind verified!"].randomElement()!
        case .journal:
            return ["Thoughts captured!", "Journaling champ!", "Words on paper - verified!"].randomElement()!
        case .read:
            return ["Bookworm verified!", "Knowledge seeker!", "Reading habit locked in!"].randomElement()!
        default:
            return "Habit verified! Great work!"
        }
    }

    // MARK: - Fallback (Edge function failure)

    private func fallbackResult(for type: HabitType) -> PhotoVerificationResult {
        return PhotoVerificationResult(
            isVerified: true,
            confidence: 0.6,
            reason: "Verified (offline mode) - \(celebrationMessage(for: type))"
        )
    }
}
