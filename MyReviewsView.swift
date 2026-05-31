//
//  MyReviewsView.swift
//  TotLotter
//
//  Shows the user's submitted park reviews
//  Created by Limbert Camilo on 5/6/26.
//

import SwiftUI

struct MyReviewsView: View {
    @StateObject var reviewsManager = ReviewsManager.shared
    @State var reviewToDelete: ParkReview? = nil
    @State var showDeleteConfirm = false
    @State var selectedPark: Park? = nil
    @State var showParkDetail = false

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if reviewsManager.reviews.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(reviewsManager.reviews) { review in
                            Button(action: {
                                selectedPark = parkFromReview(review)
                                showParkDetail = true
                            }) {
                                MyReviewCard(
                                    review: review,
                                    onDelete: {
                                        reviewToDelete = review
                                        showDeleteConfirm = true
                                    })
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("View park details for \(review.parkName)")
                        }
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .background(Color(hex: "F5F0E8"))
        .ignoresSafeArea(edges: .top)
        .navigationDestination(isPresented: $showParkDetail) {
            if let park = selectedPark {
                ParkDetailView(park: park)
            }
        }
        .confirmationDialog(
            "Delete this review?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete review", role: .destructive) {
                if let review = reviewToDelete {
                    reviewsManager.deleteReview(review)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let review = reviewToDelete {
                Text("Delete your review for \(review.parkName)? This cannot be undone.")
            }
        }
    }

    private func parkFromReview(_ review: ParkReview) -> Park {
        Park(
            id: review.parkId,
            name: review.parkName,
            address: review.parkAddress,
            latitude: 0.0,
            longitude: 0.0,
            rating: Double(review.rating),
            reviewCount: 0,
            isOpen: false,
            types: [],
            distance: "See map for distance",
            distanceValue: 999,
            amenities: review.confirmedAmenities,
            emoji: "🌳",
            cardColorHex: "#d0f5d8",
            photoReference: review.parkPhotoReference
        )
    }

    private var topBar: some View {
        ZStack {
            Color(hex: "1AAEA6")
            HStack {
                AppLogo(size: 28)
                Text("My Reviews")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(
                        color: Color(hex: "0d7a74"),
                        radius: 0, x: 1, y: 2)
                Spacer()
                Text("\(reviewsManager.reviews.count) review\(reviewsManager.reviews.count == 1 ? "" : "s")")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "5a3800"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "F9C12E"))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundColor(Color(hex: "F9C12E")),
            alignment: .bottom)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "fef3c7"))
                        .frame(width: 90, height: 90)
                    Image(systemName: "star.bubble")
                        .font(.system(size: 38))
                        .foregroundColor(Color(hex: "F9C12E"))
                }

                Text("No reviews yet!")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0d5c58"))

                Text("When you rate a park your reviews will appear here. Help other families find the best parks!")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "888888"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 80)
            Spacer()
        }
    }
}

// MARK: - Review Card

struct MyReviewCard: View {
    let review: ParkReview
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ParkPhotoView(
                    photoReference: review.parkPhotoReference,
                    width: UIScreen.main.bounds.width - 32,
                    height: 100,
                    topLeftRadius: 16,
                    bottomLeftRadius: 0,
                    topRightRadius: 16,
                    bottomRightRadius: 0)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom)
                    .frame(height: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.parkName)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(review.parkAddress)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(review.starString)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "F9C12E"))

                    Text(review.ratingLabel)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "F9C12E"))

                    Spacer()

                    Text(review.formattedDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)
                }

                if !review.reviewText.isEmpty {
                    Text(review.reviewText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color(hex: "444444"))
                        .lineLimit(3)
                }

                if !review.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(review.selectedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "d0f0ee"))
                                    .foregroundColor(Color(hex: "0d6b66"))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

                HStack {
                    Text("Submitted \(review.formattedDate)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)

                    Spacer()

                    Text("View park →")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1AAEA6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "d0f0ee"))
                        .cornerRadius(8)

                    Button(action: onDelete) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Delete")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(Color(hex: "F07060"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "fde8e5"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete review for \(review.parkName)")
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "C8E0F0"), lineWidth: 2))
        .shadow(
            color: .black.opacity(0.06),
            radius: 8, x: 0, y: 3)
    }
}

struct MyReviewsView_Previews: PreviewProvider {
    static var previews: some View {
        MyReviewsView()
    }
}
