---
phase: 02-location-verification
plan: 01
subsystem: location-service
tags: [CoreLocation, geofence, singleton, permissions]
requires: []
provides: [LocationManager.shared, geofence-monitoring, location-authorization]
affects: [project.yml, Core/Services/]
tech-stack: [CoreLocation, CLLocationManager, CLCircularRegion, NotificationCenter]
key-files:
  - Core/Services/LocationManager.swift
  - project.yml
key-decisions:
  - Used NotificationCenter for geofence event broadcasting (consistent with app pattern, no Combine)
  - Two-step authorization flow with async/await continuation for WhenInUse -> Always upgrade
  - Clamped region radius to CLLocationManager.maximumRegionMonitoringDistance
  - Entitlements unchanged — CoreLocation requires only Info.plist keys, not entitlements
duration: ~5 minutes
completed: 2026-02-26
---

# 02-01 Summary: CoreLocation Service + Project Config

## Performance

| Metric | Value |
|--------|-------|
| Tasks completed | 2/2 |
| Build status | SUCCEEDED |
| Warnings introduced | 0 |
| Files created | 1 |
| Files modified | 1 |

## Accomplishments

1. **LocationManager singleton service** — Created `Core/Services/LocationManager.swift` following the established HealthKitManager singleton pattern (`@MainActor ObservableObject` with `static let shared`).
2. **CoreLocation permissions configured** — Added `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, and `UIBackgroundModes: location` to `project.yml`.

## Task Commits

| Task | Commit | Hash |
|------|--------|------|
| Task 1: Create LocationManager service | `feat(02-01): create LocationManager service` | `55d5b2f` |
| Task 2: Configure project for CoreLocation | `feat(02-01): configure CoreLocation permissions and background mode` | `bd981a7` |

## Files Created

- `Core/Services/LocationManager.swift` — Singleton location manager with geofence monitoring, authorization flow, and delegate callbacks

## Files Modified

- `project.yml` — Added location privacy description keys and background location mode

## Decisions Made

1. **NotificationCenter over Combine** — Used `Notification.Name.geofenceEntry` and `.geofenceExit` for broadcasting region events, consistent with the app's inter-service communication pattern.
2. **nonisolated delegate methods** — CLLocationManagerDelegate callbacks are marked `nonisolated` with `Task { @MainActor in }` dispatch to update published properties, avoiding Swift concurrency isolation warnings.
3. **Authorization continuation pattern** — Used `CheckedContinuation<Void, Never>` to bridge the delegate-based authorization callback into async/await, matching the HealthKitManager approach.
4. **Entitlements left unchanged** — CoreLocation does not require entitlement entries (unlike HealthKit). Background location is configured solely via UIBackgroundModes in Info.plist.
5. **Region radius clamping** — `makeRegion()` clamps radius to `maximumRegionMonitoringDistance` to prevent runtime errors from overly large regions.

## Deviations from Plan

- None. All tasks executed as specified.

## Issues Encountered

- None. Both tasks built successfully on first attempt.

## Next Phase Readiness

LocationManager.shared is ready to be consumed by:
- **Plan 02-02**: Model extensions and verification wiring can call `LocationManager.shared.startMonitoring(region:)` and observe `Notification.Name.geofenceEntry`/`.geofenceExit`.
- **Plan 02-03**: Location picker UI can use `LocationManager.shared.requestAuthorization()` and `makeRegion()`.
