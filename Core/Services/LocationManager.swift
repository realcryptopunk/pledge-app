import CoreLocation

// MARK: - Location Notification Names

extension Notification.Name {
    static let geofenceEntry = Notification.Name("GeofenceEntry")
    static let geofenceExit = Notification.Name("GeofenceExit")
}

// MARK: - LocationManager

@MainActor
class LocationManager: NSObject, ObservableObject {

    static let shared = LocationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager: CLLocationManager

    /// Maximum number of geofence regions iOS allows per app.
    static let maxMonitoredRegions = 20

    // MARK: - Init

    private override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        // Sync initial authorization state
        authorizationStatus = locationManager.authorizationStatus
        isAuthorized = locationManager.authorizationStatus == .authorizedAlways
    }

    // MARK: - Authorization

    /// Requests "Always" location authorization using the required two-step flow.
    /// iOS requires requesting "When In Use" first, then upgrading to "Always".
    func requestAuthorization() async {
        let status = locationManager.authorizationStatus

        if status == .authorizedAlways {
            isAuthorized = true
            return
        }

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()

            // Wait for the When In Use response before requesting Always
            await waitForAuthorizationChange()
        }

        let currentStatus = locationManager.authorizationStatus
        if currentStatus == .authorizedWhenInUse || currentStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            await waitForAuthorizationChange()
        }

        isAuthorized = locationManager.authorizationStatus == .authorizedAlways
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Waits for a single authorization status change via delegate callback.
    private func waitForAuthorizationChange() async {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
        }
    }

    private var authorizationContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Geofence Monitoring

    /// Starts monitoring a circular geofence region.
    /// Logs a warning if approaching the iOS 20-region limit.
    func startMonitoring(region: CLCircularRegion) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("[LocationManager] Geofence monitoring is not available on this device.")
            return
        }

        let currentCount = locationManager.monitoredRegions.count
        if currentCount >= Self.maxMonitoredRegions {
            print("[LocationManager] WARNING: Cannot add region — already at \(Self.maxMonitoredRegions) region limit.")
            return
        }
        if currentCount >= Self.maxMonitoredRegions - 2 {
            print("[LocationManager] WARNING: Approaching region limit (\(currentCount)/\(Self.maxMonitoredRegions)).")
        }

        locationManager.startMonitoring(for: region)
        print("[LocationManager] Started monitoring region: \(region.identifier) (total: \(currentCount + 1))")
    }

    /// Stops monitoring a specific geofence region.
    func stopMonitoring(region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
        print("[LocationManager] Stopped monitoring region: \(region.identifier)")
    }

    /// Stops monitoring all geofence regions.
    func stopMonitoringAll() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        print("[LocationManager] Stopped monitoring all regions.")
    }

    /// Number of currently monitored geofence regions.
    var monitoredRegionCount: Int {
        locationManager.monitoredRegions.count
    }

    // MARK: - Region Factory

    /// Creates a circular geofence region configured for both entry and exit notifications.
    /// - Parameters:
    ///   - identifier: Unique identifier for this region (typically the habit ID).
    ///   - latitude: Center latitude.
    ///   - longitude: Center longitude.
    ///   - radius: Radius in meters (minimum reliable: ~100m).
    /// - Returns: A configured CLCircularRegion.
    func makeRegion(identifier: String, latitude: Double, longitude: Double, radius: Double) -> CLCircularRegion {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(center: center, radius: clampedRadius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .geofenceEntry,
            object: nil,
            userInfo: ["regionIdentifier": region.identifier]
        )
        print("[LocationManager] Entered region: \(region.identifier)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .geofenceExit,
            object: nil,
            userInfo: ["regionIdentifier": region.identifier]
        )
        print("[LocationManager] Exited region: \(region.identifier)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            self.isAuthorized = status == .authorizedAlways

            // Resume any pending authorization continuation
            if let continuation = self.authorizationContinuation {
                self.authorizationContinuation = nil
                continuation.resume()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[LocationManager] Monitoring failed for region: \(region?.identifier ?? "unknown") — \(error.localizedDescription)")
    }
}
