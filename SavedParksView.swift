//
//  SavedParksView.swift
//  TotLotter
//
//  Saved Parks screen accessed from the tab bar
//

import SwiftUI
import MapKit

struct SavedParksView: View {
    @StateObject var savedManager = SavedParksManager.shared
    @State var sortOption = "Nearest"
    @State var parkToDelete: Park? = nil
    @State var showDeleteConfirm = false
    @State var selectedPark: Park? = nil
    @State var showParkDetail = false

    var sortedParks: [Park] {
        switch sortOption {
        case "Top Rated":
            return savedManager.topRatedFirst
        case "Recent":
            return savedManager.recentFirst
        default:
            return savedManager.nearbyFirst
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TOP BAR
                ZStack {
                    Color(hex: "#1AAEA6")
                    HStack {
                        AppLogo(size: 28)

                        Text("Saved Parks")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "#0d7a74"), radius: 0, x: 1, y: 2)

                        Spacer()

                        Text("\(savedManager.savedParks.count) saved")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#5a3800"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#F9C12E"))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 60)
                .overlay(
                    Rectangle()
                        .frame(height: 3)
                        .foregroundColor(Color(hex: "#F9C12E")),
                    alignment: .bottom)

                // SORT ROW
                HStack(spacing: 8) {
                    Text("Sort by")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#888888"))

                    ForEach(["Nearest", "Top Rated", "Recent"], id: \.self) { option in
                        Button(action: {
                            sortOption = option
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Text(option)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(sortOption == option ? .white : Color(hex: "#0d5c58"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(sortOption == option ? Color(hex: "#1AAEA6") : Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            sortOption == option ? Color(hex: "#1AAEA6") : Color(hex: "#C8E0F0"),
                                            lineWidth: 1.5))
                        }
                        .accessibilityLabel("Sort by \(option)")
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // CONTENT
                if savedManager.savedParks.isEmpty {
                    // EMPTY STATE
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#C8E0F0"))
                                .frame(width: 80, height: 80)
                            Image(systemName: "heart.slash")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "#5BA8D8"))
                        }

                        Text("No saved parks yet!")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#0d5c58"))

                        Text("Tap the ♥ heart on any park to save it here for quick access.")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#888888"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        NavigationLink(destination: HomeView()) {
                            Text("Explore parks →")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#1AAEA6"))
                                .cornerRadius(14)
                                .shadow(color: Color(hex: "#0d7a74"), radius: 0, x: 0, y: 3)
                        }
                        .accessibilityLabel("Go explore parks")

                        Spacer()
                    }
                    .padding(.top, 80)
                } else {
                    // PARK LIST
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(
                                Array(sortedParks.enumerated()),
                                id: \.element.id) { index, park in

                                SavedParkCard(
                                    park: park,
                                    savedManager: savedManager,
                                    onTap: {
                                        selectedPark = park
                                        showParkDetail = true
                                    })

                                if (index + 1) % 3 == 0 &&
                                    index < sortedParks.count - 1 {
                                    AdBannerContainer()
                                        .frame(height: 66)
                                        .padding(.vertical, 4)
                                }
                            }

                            // Bottom padding so last card clears tab bar
                            Color.clear
                                .frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .background(Color(hex: "#F5F0E8"))
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showParkDetail) {
                if let park = selectedPark {
                    ParkDetailView(park: park)
                }
            }
        }
    }
}

// MARK: - SavedParkCard

struct SavedParkCard: View {
    let park: Park
    @ObservedObject var savedManager: SavedParksManager
    var onTap: () -> Void = {}
    @State var showDeleteConfirm = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // PHOTO SECTION
                ZStack(alignment: .topLeading) {
                    ParkPhotoView(
                        photoReference: park.photoReference,
                        width: UIScreen.main.bounds.width - 32,
                        height: 160,
                        topLeftRadius: 16,
                        bottomLeftRadius: 0,
                        topRightRadius: 16,
                        bottomRightRadius: 0)

                    // Gradient overlay at bottom of photo
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom)
                            .frame(height: 60)
                    }
                    .frame(height: 160)

                    // Top left: Top Rated + Open Now badges
                    VStack(alignment: .leading, spacing: 4) {
                        if park.rating >= 4.5 {
                            Text("⭐ Top Rated")
                                .font(.system(size: 10, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#5a3800"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#F9C12E"))
                                .cornerRadius(8)
                        }
                        if park.isOpen {
                            Text("Open now")
                                .font(.system(size: 10, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#5BAD3E"))
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)

                    // Top right: distance badge
                    VStack {
                        HStack {
                            Spacer()
                            Text(park.distance)
                                .font(.system(size: 11, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#0d6b66"))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.92))
                                .cornerRadius(10)
                                .padding(10)
                        }
                        Spacer()
                    }
                    .frame(height: 160)
                }

                // CONTENT SECTION
                VStack(alignment: .leading, spacing: 6) {
                    // Name + unsave button
                    HStack(alignment: .top) {
                        Text(park.name)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#0d5c58"))
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            showDeleteConfirm = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#F07060"))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "#F07060"), lineWidth: 1.5))
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Remove \(park.name) from saved parks")
                    }

                    // Address
                    Text(park.address)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    // Rating + amenity tags
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#F9C12E"))
                            Text(String(format: "%.1f", park.rating))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#F9C12E"))
                            Text("(\(park.reviewCount))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        ForEach(park.amenities.prefix(2), id: \.self) { amenity in
                            Text(amenity)
                                .font(.system(size: 9, design: .rounded))
                                .fontWeight(.bold)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#d0f0ee"))
                                .foregroundColor(Color(hex: "#0d6b66"))
                                .cornerRadius(8)
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color(hex: "#f0ece4"))
                        .frame(height: 1)

                    // Get Directions button
                    HStack(spacing: 8) {
                        Button(action: {
                            openDirections(for: park)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                Text("Get directions")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(hex: "#1AAEA6"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#0d7a74"), radius: 0, x: 0, y: 2)
                        }
                        .accessibilityLabel("Get directions to \(park.name)")
                    }
                }
                .padding(12)
                .background(Color.white)
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#C8E0F0"), lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Remove this park?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible) {
            Button("Remove from saved", role: .destructive) {
                savedManager.unsavePark(park)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \(park.name) from your saved parks?")
        }
    }

    func openDirections(for park: Park) {
        let location = CLLocation(latitude: park.latitude, longitude: park.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = park.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
