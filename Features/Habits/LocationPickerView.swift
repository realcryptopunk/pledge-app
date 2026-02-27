import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Binding var radius: Double?
    @Binding var locationName: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    // MARK: - State

    @State private var position: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearchResults = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName: String?
    @State private var selectedRadius: Double = 150

    private let radiusPresets: [Double] = [100, 150, 200, 300, 500]

    // MARK: - Computed

    private var hasSelection: Bool {
        selectedCoordinate != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        searchBar
                        mapSection
                        if hasSelection {
                            radiusSection
                            selectedLocationSection
                        }
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Search results overlay
                if showSearchResults && !searchResults.isEmpty {
                    searchResultsList
                }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        applySelection()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(hasSelection ? theme.surface : .secondary.opacity(0.4))
                    .disabled(!hasSelection)
                }
            }
        }
        .onAppear {
            // If editing an existing location, restore it
            if let lat = latitude, let lng = longitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                selectedCoordinate = coord
                selectedName = locationName
                selectedRadius = radius ?? 150
                position = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                ))
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField("Search for a place", text: $searchText)
                .pledgeCallout()
                .foregroundColor(.primary)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Map Section

    private var mapSection: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coord = selectedCoordinate {
                    Annotation("", coordinate: coord) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(theme.surface)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                    }

                    MapCircle(center: coord, radius: selectedRadius)
                        .foregroundStyle(theme.surface.opacity(0.15))
                        .stroke(theme.surface.opacity(0.4), lineWidth: 1.5)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onTapGesture { screenCoord in
                if let coordinate = proxy.convert(screenCoord, from: .local) {
                    PPHaptic.light()
                    selectedCoordinate = coordinate
                    reverseGeocode(coordinate)
                    withAnimation(.quickSnap) {
                        position = .region(MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: max(selectedRadius * 4, 1000),
                            longitudinalMeters: max(selectedRadius * 4, 1000)
                        ))
                    }
                }
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        VStack {
            Spacer().frame(height: 80)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectSearchResult(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown")
                                    .pledgeCallout()
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                if let subtitle = item.placemark.formattedAddress {
                                    Text(subtitle)
                                        .pledgeCaption()
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if item != searchResults.last {
                            Rectangle()
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                }
                .cleanCard()
            }
            .frame(maxHeight: 300)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.black.opacity(0.001)) // Tap target for dismissal
        .onTapGesture {
            withAnimation(.quickSnap) {
                showSearchResults = false
            }
        }
    }

    // MARK: - Radius Section

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RADIUS")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(radiusPresets, id: \.self) { preset in
                    Button {
                        PPHaptic.selection()
                        withAnimation(.quickSnap) {
                            selectedRadius = preset
                            // Update map to reflect new radius
                            if let coord = selectedCoordinate {
                                position = .region(MKCoordinateRegion(
                                    center: coord,
                                    latitudinalMeters: max(preset * 4, 1000),
                                    longitudinalMeters: max(preset * 4, 1000)
                                ))
                            }
                        }
                    } label: {
                        Text("\(Int(preset))m")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedRadius == preset ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedRadius == preset
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedRadius == preset ? Color.white.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cleanCard()
    }

    // MARK: - Selected Location Section

    private var selectedLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECTED LOCATION")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.surface)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedName ?? "Dropped Pin")
                        .pledgeHeadline()
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let coord = selectedCoordinate {
                        Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }

                    Text("\(Int(selectedRadius))m radius")
                        .pledgeCaption()
                        .foregroundColor(theme.surface)
                }

                Spacer()
            }
        }
        .cleanCard()
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        // Use a reasonable default region for search
        if let coord = selectedCoordinate {
            request.region = MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                searchResults = []
                showSearchResults = false
                return
            }

            searchResults = Array(response.mapItems.prefix(8))
            withAnimation(.quickSnap) {
                showSearchResults = true
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selectedCoordinate = coordinate
        selectedName = item.name ?? item.placemark.name
        PPHaptic.medium()

        withAnimation(.quickSnap) {
            showSearchResults = false
            position = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: max(selectedRadius * 4, 1000),
                longitudinalMeters: max(selectedRadius * 4, 1000)
            ))
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                selectedName = "Dropped Pin"
                return
            }

            selectedName = placemark.name
                ?? placemark.thoroughfare
                ?? placemark.locality
                ?? "Dropped Pin"
        }
    }

    private func applySelection() {
        guard let coord = selectedCoordinate else { return }
        latitude = coord.latitude
        longitude = coord.longitude
        radius = selectedRadius
        locationName = selectedName ?? "Dropped Pin"
        PPHaptic.success()
        dismiss()
    }
}

// MARK: - MKPlacemark Extension

private extension MKPlacemark {
    var formattedAddress: String? {
        let components = [
            thoroughfare,
            subThoroughfare,
            locality,
            administrativeArea
        ].compactMap { $0 }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

#Preview {
    LocationPickerView(
        latitude: .constant(nil),
        longitude: .constant(nil),
        radius: .constant(150),
        locationName: .constant(nil)
    )
    .environmentObject(AppState())
}
