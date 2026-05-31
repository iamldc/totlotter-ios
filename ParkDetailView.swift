//
//  ParkDetailView.swift
//  TotLotter
//
//  Park detail screen opened when a user taps a park card.
//

import StoreKit
import SwiftUI
import MapKit

// MARK: - ParkDetailView

struct ParkDetailView: View {
    let park: Park
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTip: Int? = nil
    @State private var showTipNudge = true
    @State private var tipJarVisible = false
    @State private var tipJarPulsed = false
    @State private var tipJarGlow = false
    @State var showRateReview = false
    @State private var showShareSheet = false
    @StateObject var savedManager = SavedParksManager.shared
    @StateObject var reviewsManager = ReviewsManager.shared
    @StateObject var tipStore = TipStore.shared
    @State var showPurchaseError = false
    @State var purchaseErrorMessage = ""
    @State private var heroPhotoURL: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            if tipStore.showThankYou {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(10)

                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 64))
                    Text("Thank you!")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0d5c58"))
                    Text("Your tip helps keep TotLotter free for all families. You're a park hero! 🌟")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "888888"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
                .zIndex(11)
            }

            ScrollViewReader { _ in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        parkTitleSection
                        amenitiesSection
                        reviewsSection
                        tipJarSection
                            .id("tipJar")
                            .padding(.bottom, 24)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        if showTipNudge {
                            tipNudgeView
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        stickyFooter
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showRateReview) {
            RateReviewView(park: park)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "\(park.name) — rated ★\(String(format: "%.1f", park.rating))\nFind kid-friendly parks with TotLotter!"
            ])
        }
        .background(Color(hex: "F5F0E8"))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showTipNudge = false
                }
            }
        }
        .task {
            let service = PlacesService()
            heroPhotoURL = await service.fetchPhoto(for: park.id)
        }
        .onChange(of: tipStore.showThankYou) { _, showing in
            if showing {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .onChange(of: tipStore.purchaseState) { _, state in
            if case .failed(_) = state {
                purchaseErrorMessage = "Purchase failed. Please try again."
                showPurchaseError = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showPurchaseError = false
                    tipStore.purchaseState = .idle
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                ParkPhotoView(
                    photoReference: heroPhotoURL,
                    width: geo.size.width,
                    height: 220,
                    topLeftRadius: 0,
                    bottomLeftRadius: 0,
                    topRightRadius: 0,
                    bottomRightRadius: 0,
                    accessibilityLabel: "Photo of \(park.name)",
                    parkName: park.name
                )

                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)

                HStack(alignment: .bottom) {
                    Spacer()
                    if park.rating >= 4.5 {
                        Text("Top Rated")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "5a3800"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F9C12E"))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .overlay(alignment: .topLeading) {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "0d5c58"))
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Go back")
                .padding(.top, 50)
                .padding(.leading, 10)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button(action: {
                        savedManager.toggleSave(park)
                    }) {
                        Image(systemName: savedManager.isSaved(park) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(savedManager.isSaved(park) ? Color(hex: "#F07060") : Color(hex: "#0d5c58"))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel(savedManager.isSaved(park) ? "Remove from saved parks" : "Save this park")

                    Button(action: { showShareSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "0d5c58"))
                        }
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Share this park")
                }
                .padding(.top, 50)
                .padding(.trailing, 10)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Park Title Section

    private var parkTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(park.name)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0d5c58"))

            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "1AAEA6"))
                Text(park.address)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Color(hex: "888888"))
                    .lineLimit(2)
            }

            HStack(alignment: .center, spacing: 4) {
                Text("★ \(String(format: "%.1f", park.rating))")
                    .font(.system(size: 18, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "F9C12E"))

                Text("· \(park.reviewCount) reviews")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color(hex: "888888"))

                Spacer()

                Text(park.distance)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0d6b66"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "d0f0ee"))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    // MARK: - Amenities Section

    private func confirmedAmenities(for park: Park) -> [(String, String, Color)] {
        var amenities: [(String, String, Color)] = []

        let types = park.amenities
            .map { $0.lowercased() }
            .joined(separator: " ")
        let allText = (park.amenities
            .joined(separator: " ") + " " +
            types).lowercased()

        amenities.append(("Park", "tree.fill", Color(hex: "5BAD3E")))

        if allText.contains("playground") || allText.contains("play") {
            amenities.append(("Playground", "figure.play", Color(hex: "1AAEA6")))
        }

        if allText.contains("splash") || allText.contains("water") {
            amenities.append(("Splash Pad", "drop.fill", Color(hex: "5BA8D8")))
        }

        if allText.contains("picnic") {
            amenities.append(("Picnic Area", "fork.knife", Color(hex: "F9C12E")))
        }

        if allText.contains("sport") || allText.contains("field") {
            amenities.append(("Sports Field", "sportscourt.fill", Color(hex: "F07060")))
        }

        if allText.contains("dog") {
            amenities.append(("Dog Friendly", "pawprint.fill", Color(hex: "96C83A")))
        }

        if allText.contains("trail") || allText.contains("walk") {
            amenities.append(("Walking Trail", "figure.walk", Color(hex: "5BAD3E")))
        }

        if allText.contains("wheel") || allText.contains("access") {
            amenities.append(("Wheelchair Access", "figure.roll", Color(hex: "5BA8D8")))
        }

        return amenities
    }

    private var amenitiesSection: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return VStack(alignment: .leading, spacing: 12) {
            Text("What's here for your family")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0d5c58"))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(confirmedAmenities(for: park), id: \.0) { amenity in
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(amenity.2.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: amenity.1)
                                .font(.system(size: 15))
                                .foregroundColor(amenity.2)
                        }
                        Text(amenity.0)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0d5c58"))
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(amenity.2.opacity(0.3), lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 16)

            Text("💡 Know more about this park? Rate it and help other families plan their visit!")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Color(hex: "888888"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        let parkReviews = reviewsManager.reviewsForPark(park.id)
        return VStack(alignment: .leading, spacing: 12) {
            Text("What families are saying")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0d5c58"))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if parkReviews.isEmpty {
                VStack(spacing: 6) {
                    Text("No reviews yet")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "888888"))
                    Text("Be the first to rate this park!")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color(hex: "aaaaaa"))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 12) {
                    ForEach(parkReviews.prefix(5)) { review in
                        ReviewCard(
                            initials: "Me",
                            avatarColor: Color(hex: "d0f0ee"),
                            name: "You",
                            stars: review.rating,
                            reviewText: review.reviewText,
                            date: review.formattedDate
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F8F9FA"))
    }

    // MARK: - Tip Jar Section

    private var tipJarSection: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let frame = geometry.frame(in: .global)
                let screenHeight = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.screen.bounds.height ?? 852
                let isVisible = frame.minY < screenHeight - 100 && frame.maxY > 100

                Color.clear
                    .onAppear {}
                    .onChange(of: isVisible) { _, visible in
                        if visible && !tipJarPulsed {
                            tipJarPulsed = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(
                                    .easeInOut(duration: 0.6)
                                    .repeatCount(3, autoreverses: true)
                                ) {
                                    tipJarGlow = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    tipJarGlow = false
                                }
                            }
                        }
                    }
            }
            .frame(height: 0)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color(hex: "F9C12E"))
                            .frame(width: 36, height: 36)
                        Text("☕")
                            .font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enjoying TotLotter?")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "5a3800"))
                        Text("Help us keep parks free to discover!")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(hex: "c8920a"))
                    }
                    Spacer()
                }

                if tipStore.products.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView()
                            .tint(Color(hex: "1AAEA6"))
                        Text("Loading tip options...")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "888"))
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack(spacing: 8) {
                        ForEach(tipStore.products, id: \.id) { product in
                            VStack(spacing: 0) {
                                if tipStore.isPopular(product) {
                                    Text("Most popular")
                                        .font(.system(size: 9, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: "7a5200"))
                                        .frame(height: 16)
                                } else {
                                    Text("")
                                        .font(.system(size: 9))
                                        .frame(height: 16)
                                }
                                Button(action: {
                                    Task { await tipStore.purchase(product) }
                                }) {
                                    VStack(spacing: 3) {
                                        Text(tipStore.emoji(for: product))
                                            .font(.system(size: 20))
                                        Text(product.displayPrice)
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(hex: "5a3800"))
                                        Text(tipStore.label(for: product))
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(Color(hex: tipStore.isPopular(product) ? "7a5200" : "c8920a"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 72)
                                    .background(tipStore.isPopular(product) ? Color(hex: "F9C12E") : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                tipStore.isPopular(product) ? Color(hex: "c8920a") : Color(hex: "F9C12E"),
                                                lineWidth: 1.5)
                                    )
                                }
                                .disabled(tipStore.isLoading)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                if showPurchaseError {
                    Text(purchaseErrorMessage)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "F07060"))
                        .cornerRadius(10)
                        .transition(.opacity)
                }

                Text("Tips are voluntary and unlock no additional content.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(hex: "aaaaaa"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(Color(hex: "fffbf0"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(hex: "F9C12E").opacity(tipJarGlow ? 1.0 : 0.4),
                        lineWidth: tipJarGlow ? 3.5 : 2.5
                    )
            )
            .scaleEffect(tipJarGlow ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.6), value: tipJarGlow)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Tip Nudge

    private var tipNudgeView: some View {
        HStack(spacing: 6) {
            Text("☕")
                .font(.system(size: 12))
            Text("Enjoying TotLotter? Support us!")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "5a3800"))
            Spacer()
            Button(action: {
                withAnimation(.easeOut(duration: 0.3)) {
                    showTipNudge = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "c8920a"))
            }
            .accessibilityLabel("Dismiss tip nudge")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "fffbf0"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "F9C12E"), lineWidth: 1.5)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Sticky Footer

    private var stickyFooter: some View {
        HStack(spacing: 10) {
            Button(action: {
                openDirections(for: park)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                    Text("Get directions")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "1AAEA6"))
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(
                    color: Color(hex: "0d7a74"),
                    radius: 0,
                    x: 0, y: 3)
            }
            .accessibilityLabel("Get directions to \(park.name)")

            Button(action: { showRateReview = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                    Text("Rate park")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "F9C12E"))
                .foregroundColor(Color(hex: "5a3800"))
                .cornerRadius(14)
                .shadow(
                    color: Color(hex: "c8920a"),
                    radius: 0,
                    x: 0, y: 3)
            }
            .accessibilityLabel("Rate \(park.name)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "F5F0E8"))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color(hex: "e8e0d0")),
            alignment: .top)
        .ignoresSafeArea(edges: .bottom)
    }

    private func openDirections(for park: Park) {
        if park.latitude != 0.0 {
            let location = CLLocation(latitude: park.latitude, longitude: park.longitude)
            let mapItem = MKMapItem(location: location, address: nil)
            mapItem.name = park.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else {
            let query = park.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? park.name
            if let url = URL(string: "maps://?q=\(query)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let initials: String
    let avatarColor: Color
    let name: String
    let stars: Int
    let reviewText: String
    let date: String

    private var starString: String {
        String(repeating: "★", count: stars) + String(repeating: "☆", count: max(0, 5 - stars))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 28, height: 28)
                    Text(initials)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0d5c58"))
                }

                Text(name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "333333"))

                Spacer()

                Text(starString)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "F9C12E"))
            }

            Text(reviewText)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "444444"))
                .lineLimit(3)

            Text(date)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Color(hex: "bbbbbb"))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "C8E0F0"), lineWidth: 2)
        )
    }
}
