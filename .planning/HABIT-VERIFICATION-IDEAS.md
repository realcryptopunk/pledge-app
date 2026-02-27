# Habit Verification Ideas

Verifiable tracking methods beyond HealthKit, location, and manual.

## Vision Framework (VNDetectHumanBodyPoseRequest)

- **Rep counting** — pushups, squats, situps, jumping jacks. Track body keypoint transitions (e.g., elbow angle extended → bent → extended = 1 rep)
- **Yoga/stretching poses** — verify user held a specific pose for X seconds
- **Meditation posture** — detect sitting still with minimal keypoint movement over duration

## CoreMotion (accelerometer/gyroscope)

- **Jump rope** — rhythmic vertical acceleration pattern
- **Walking form** — cadence and stride detection
- **Meditation/stillness** — phone placed flat, no movement for X minutes
- **Morning routine** — phone picked up before target time (first motion of day)

## Screen Time / Device Usage

- **No social media** — restricted apps stayed under X minutes
- **Phone-free morning** — no unlock before 8am
- **Reading time** — Books/Kindle app in foreground for X minutes
- **Digital sunset** — phone not used after 10pm

## Camera/Photo-based

- **Meal logging** — require a photo of each meal (Vision food detection)
- **Skincare routine** — front camera face detection at specific times
- **Clean desk** — photo comparison of workspace
- **Journaling** — photo of handwritten journal page (VNRecognizeTextRequest)

## Other Sensors

- **Cold shower** — CoreMotion bathroom detection + HealthKit heart rate spike
- **Hydration** — NFC tap on smart water bottle
- **Cooking at home** — home location + no food delivery app during dinner window
