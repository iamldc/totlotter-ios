//
//  ProfileView.swift
//  TotLotter
//
//  Profile screen accessed from the tab bar (Screen 6)
//  Created by Limbert Camilo on 5/8/26.
//

import StoreKit
import SwiftUI

struct ProfileView: View {
    @StateObject var savedManager = SavedParksManager.shared
    @StateObject var reviewsManager = ReviewsManager.shared
    @StateObject var tipStore = TipStore.shared
    @State var showAccountData = false
    @State var showTipSheet = false
    @State var locationOn = true
    @State var notificationsOn = true
    @State var showShareSheet = false
    @AppStorage("profileEmoji") var selectedEmoji = "🧒"
    @AppStorage("profileName") var displayName = "Park Explorer"
    @State var showEmojiPicker = false
    @State var showNameEditor = false
    @AppStorage("zipSearchCount") var zipSearchCount = 0
    @AppStorage("profileRadius") var profileRadius = 8

    var hasSavedFirstPark: Bool { savedManager.savedParks.count >= 1 }
    var isPlaygroundPro: Bool { savedManager.savedParks.count >= 5 }
    var isSplashHunter: Bool {
        savedManager.savedParks.contains { park in
            park.amenities.joined(separator: " ").lowercased().contains("splash") ||
            park.types.joined(separator: " ").lowercased().contains("splash")
        }
    }
    var isTopReviewer: Bool { reviewsManager.reviews.count >= 3 }
    var isTrailblazer: Bool { zipSearchCount >= 3 }

    var earnedBadgeCount: Int {
        [hasSavedFirstPark, isPlaygroundPro, isSplashHunter, isTopReviewer, isTrailblazer]
            .filter { $0 }.count
    }

    var activityTitle: String {
        let parksSaved = savedManager.savedParks.count
        let reviewsWritten = reviewsManager.reviews.count
        let totalActivity = parksSaved + reviewsWritten

        switch totalActivity {
        case 0:
            return "🌱 Just getting started!"
        case 1...2:
            return "🗺️ New park explorer"
        case 3...5:
            return "🛝 Growing adventurer"
        case 6...10:
            return "⭐ Experienced explorer"
        case 11...20:
            return "🏅 Park enthusiast"
        default:
            return "🏆 TotLotter champion!"
        }
    }

    var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Exploring since " + formatter.string(from: Date())
    }

    var badges: [(String, String, Bool, Color)] {
        [
            ("🌟", "First\nExplorer", hasSavedFirstPark, Color(hex: "F9C12E")),
            ("🛝", "Playground\nPro", isPlaygroundPro, Color(hex: "1AAEA6")),
            ("💦", "Splash\nHunter", isSplashHunter, Color(hex: "5BA8D8")),
            ("🏆", "Top\nReviewer", isTopReviewer, Color(hex: "F07060")),
            ("🗺️", "Trail-\nblazer", isTrailblazer, Color(hex: "5BAD3E"))
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                profileHeader
                ScrollView {
                    VStack(spacing: 0) {
                        statsRow
                        badgesSection
                        settingsSection
                        tipJarBanner
                        versionNote
                        Spacer().frame(height: 32)
                    }
                }
                .background(Color(hex: "F5F0E8"))
            }
            .background(Color(hex: "F5F0E8"))
            .navigationBarHidden(true)
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(
                    selectedEmoji: $selectedEmoji,
                    displayName: $displayName)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [
                    """
                    🛝 Discover TotLotter — the
                    free app that helps families
                    find the perfect park nearby!

                    ✅ Real park photos & ratings
                    ✅ Filter by splash pads,
                       nature trails & playgrounds
                    ✅ Save your favorite parks
                    ✅ Leave reviews for other families

                    Download TotLotter free on
                    the App Store!
                    https://apps.apple.com/app/totlotter

                    Made with ♥ for park-loving families
                    """
                ])
            }
            .sheet(isPresented: $showAccountData) {
                AccountDataView()
            }
            .sheet(isPresented: $showTipSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("☕")
                            .font(.system(size: 60))

                        Text("Support TotLotter!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0d5c58"))

                        Text("TotLotter is free for all families. A small tip helps us keep improving the app and adding new parks and features!")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(hex: "888"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        if tipStore.products.isEmpty {
                            ProgressView()
                                .tint(Color(hex: "1AAEA6"))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(tipStore.products, id: \.id) { product in
                                    Button(action: {
                                        Task { await tipStore.purchase(product) }
                                    }) {
                                        HStack {
                                            Text(tipStore.emoji(for: product))
                                                .font(.system(size: 24))
                                            VStack(alignment: .leading) {
                                                Text(product.displayPrice)
                                                    .font(.system(.headline, design: .rounded))
                                                    .fontWeight(.bold)
                                                Text(tipStore.label(for: product))
                                                    .font(.system(.caption, design: .rounded))
                                            }
                                            .foregroundColor(Color(hex: "5a3800"))
                                            Spacer()
                                            if tipStore.isPopular(product) {
                                                Text("Most popular")
                                                    .font(.system(size: 9, design: .rounded))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Color(hex: "7a5200"))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(Color.white.opacity(0.5))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(14)
                                        .frame(maxWidth: .infinity)
                                        .background(tipStore.isPopular(product) ? Color(hex: "F9C12E") : Color(hex: "fffbf0"))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(hex: "F9C12E"), lineWidth: 2))
                                    }
                                    .disabled(tipStore.isLoading)
                                    .accessibilityLabel("Tip \(product.displayPrice)")
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Text("Tips are voluntary and unlock no additional content. Thank you for your support! 🙏")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Spacer()
                    }
                    .padding(.top, 32)
                    .navigationTitle("Support Us")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showTipSheet = false
                            }
                            .foregroundColor(Color(hex: "1AAEA6"))
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Profile Header (top bar + avatar unified)

    private var profileHeader: some View {
        ZStack(alignment: .top) {
            Color(hex: "1AAEA6")

            VStack(spacing: 0) {
                HStack {
                    AppLogo(size: 28)
                    Text("My Profile")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(
                            color: Color(hex: "0d7a74"),
                            radius: 0, x: 1, y: 2)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)

                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F9C12E"))
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 3))
                                .shadow(
                                    color: .black.opacity(0.15),
                                    radius: 8, x: 0, y: 4)
                            Text(selectedEmoji)
                                .font(.system(size: 42))
                        }

                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                                    .shadow(
                                        color: .black.opacity(0.1),
                                        radius: 4, x: 0, y: 2)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "1AAEA6"))
                            }
                        }
                        .accessibilityLabel("Edit profile")
                        .offset(x: 2, y: 2)
                    }

                    Text(displayName)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(
                            color: Color(hex: "0d7a74"),
                            radius: 0, x: 0, y: 1)

                    Text(activityTitle)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "5a3800"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Color(hex: "F9C12E")
                                .opacity(0.9))
                        .cornerRadius(20)
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 20)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundColor(Color(hex: "F9C12E")),
            alignment: .bottom)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(savedManager.savedParks.count)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1AAEA6"))
                Text("Parks\nSaved")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "888"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "e8e0d0"))
                .frame(width: 1, height: 44)

            VStack(spacing: 4) {
                Text("\(reviewsManager.reviews.count)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1AAEA6"))
                Text("Reviews\nWritten")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "888"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "e8e0d0"))
                .frame(width: 1, height: 44)

            VStack(spacing: 4) {
                Text("\(zipSearchCount)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1AAEA6"))
                Text("ZIP Codes\nExplored")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "888"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "C8E0F0"), lineWidth: 2))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Badges Section

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Your park badges")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0d5c58"))
                Spacer()
                Text("\(earnedBadgeCount)/5")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "888"))
            }
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                ForEach(badges, id: \.1) { badge in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(badge.2 ? badge.3.opacity(0.12) : Color(hex: "f5f5f5"))
                                .frame(width: 54, height: 54)

                            Circle()
                                .stroke(badge.2 ? badge.3 : Color(hex: "e0e0e0"), lineWidth: 2.5)
                                .frame(width: 54, height: 54)

                            Text(badge.0)
                                .font(.system(size: 24))
                                .opacity(badge.2 ? 1.0 : 0.3)

                            if !badge.2 {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(hex: "bbb"))
                                            .background(
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 16, height: 16))
                                    }
                                }
                                .frame(width: 54, height: 54)
                            }
                        }
                        .frame(width: 54, height: 54)

                        Text(badge.1)
                            .font(.system(size: 9, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(badge.2 ? Color(hex: "0d5c58") : Color(hex: "bbb"))
                            .multilineTextAlignment(.center)
                            .frame(width: 58)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .onChange(of: earnedBadgeCount) { _, newCount in
                if newCount > 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "C8E0F0"), lineWidth: 2)))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Preferences")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0d5c58"))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ProfileSettingRow(
                    iconBackground: Color(hex: "d0f0ee"),
                    iconName: "location.fill",
                    iconColor: Color(hex: "1AAEA6"),
                    title: "Location access",
                    subtitle: "Used only to find nearby parks",
                    isLast: false
                ) {
                    Toggle("", isOn: $locationOn)
                        .labelsHidden()
                        .tint(Color(hex: "1AAEA6"))
                }

                ProfileSettingRow(
                    iconBackground: Color(hex: "fef3c7"),
                    iconName: "bell.fill",
                    iconColor: Color(hex: "c8920a"),
                    title: "Park notifications",
                    subtitle: "Weather alerts & new parks nearby",
                    isLast: false
                ) {
                    Toggle("", isOn: $notificationsOn)
                        .labelsHidden()
                        .tint(Color(hex: "1AAEA6"))
                }

                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "dceeff"))
                            .frame(width: 32, height: 32)
                        Image(systemName: "scope")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "1a6fa8"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default search radius")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0d5c58"))
                        Text("Currently \(profileRadius) miles — also adjustable on map screen")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(Color(hex: "aaa"))
                    }

                    Spacer()

                    Menu {
                        ForEach([1, 3, 5, 8, 10, 15, 20], id: \.self) { miles in
                            Button("\(miles) miles") {
                                profileRadius = miles
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(profileRadius) mi")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "1AAEA6"))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "1AAEA6"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "d0f0ee"))
                        .cornerRadius(10)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)

                ProfileSettingRow(
                    iconBackground: Color(hex: "d0f5d8"),
                    iconName: "square.and.arrow.up",
                    iconColor: Color(hex: "3a8a2a"),
                    title: "Share TotLotter",
                    subtitle: "Tell a fellow park parent!",
                    isLast: false,
                    action: { showShareSheet = true }
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "C8E0F0"))
                }

                ProfileSettingRow(
                    iconBackground: Color(hex: "fde8e5"),
                    iconName: "person.badge.shield.checkmark.fill",
                    iconColor: Color(hex: "F07060"),
                    title: "Account & Data",
                    subtitle: "Privacy, data & account deletion",
                    isLast: true,
                    action: { showAccountData = true }
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "C8E0F0"))
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "C8E0F0"), lineWidth: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tip Jar Banner

    private var tipJarBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "F9C12E"))
                    .frame(width: 42, height: 42)
                Text("☕")
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Love TotLotter?")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "5a3800"))
                Text("Support us with a small tip and keep the app free for all families!")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "c8920a"))
                    .lineLimit(2)
            }

            Spacer()

            Button("Tip us ☕") {
                showTipSheet = true
            }
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(Color(hex: "5a3800"))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "F9C12E"))
            .cornerRadius(10)
            .shadow(color: Color(hex: "c8920a"), radius: 0, x: 0, y: 2)
            .accessibilityLabel("Support TotLotter with a tip")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "fffbf0"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F9C12E"), lineWidth: 2.5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Version Note

    private var versionNote: some View {
        Text("TotLotter v1.0 · © 2026 · Made with ♥ for families")
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(Color(hex: "cccccc"))
            .multilineTextAlignment(.center)
            .padding(.top, 16)
            .padding(.bottom, 24)
    }
}

// MARK: - Emoji Picker View

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Binding var displayName: String
    @Environment(\.dismiss) var dismiss
    @State var nameInput: String = ""

    var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Exploring since " + formatter.string(from: Date())
    }

    let emojis = [
        "🧒", "👶", "🧑", "👦", "👧",
        "👨‍👩‍👧", "👨‍👩‍👦", "👪", "👨‍👧", "👩‍👦",
        "🌟", "🎈", "🛝", "🌳", "🦁",
        "🐻", "🦊", "🐸", "🦋", "🌈"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F9C12E"))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "1AAEA6"), lineWidth: 3))
                        Text(selectedEmoji)
                            .font(.system(size: 50))
                    }

                    Text(memberSinceText)
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "888"))
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Display name")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "888888"))
                        .padding(.horizontal, 16)

                    TextField("Your name or nickname", text: $nameInput)
                        .font(.system(.body, design: .rounded))
                        .padding(12)
                        .background(Color(hex: "F5F0E8"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "C8E0F0"), lineWidth: 2))
                        .padding(.horizontal, 16)
                }

                Text("Choose your avatar")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0d5c58"))

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 5),
                    spacing: 12
                ) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                        }) {
                            ZStack {
                                Circle()
                                    .fill(selectedEmoji == emoji ? Color(hex: "d0f0ee") : Color(hex: "F5F0E8"))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedEmoji == emoji ? Color(hex: "1AAEA6") : Color.clear,
                                                lineWidth: 2))
                                Text(emoji)
                                    .font(.system(size: 28))
                            }
                        }
                        .accessibilityLabel("Select \(emoji) as profile avatar")
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                Button(action: {
                    if !nameInput.trimmingCharacters(in: .whitespaces).isEmpty {
                        displayName = nameInput
                    }
                    dismiss()
                }) {
                    Text("Save profile")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "1AAEA6"))
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "0d7a74"), radius: 0, x: 0, y: 3)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .accessibilityLabel("Save profile changes")
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "1AAEA6"))
                }
            }
            .onAppear {
                nameInput = displayName
            }
        }
    }
}

// MARK: - Setting Row

private struct ProfileSettingRow<Trailing: View>: View {
    let iconBackground: Color
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLast: Bool
    let action: (() -> Void)?
    let trailingContent: Trailing

    init(
        iconBackground: Color,
        iconName: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isLast: Bool,
        action: (() -> Void)? = nil,
        @ViewBuilder trailingContent: () -> Trailing
    ) {
        self.iconBackground = iconBackground
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.isLast = isLast
        self.action = action
        self.trailingContent = trailingContent()
    }

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    rowLayout
                }
                .buttonStyle(.plain)
            } else {
                rowLayout
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundColor(Color(hex: "f5f0e8"))
            }
        }
    }

    private var rowLayout: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0d5c58"))
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(hex: "aaaaaa"))
            }

            Spacer()

            trailingContent
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Card Position

private enum ProfileCardPosition {
    case left, middle, right
}

// MARK: - Rounded Corner Shape

private struct ProfileRoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

// MARK: - Stat Card

private struct ProfileStatCard: View {
    let number: Int
    let label: String
    let numberColor: Color
    let position: ProfileCardPosition

    private let borderColor = Color(hex: "C8E0F0")
    private let borderWidth: CGFloat = 1.5

    var body: some View {
        VStack(spacing: 2) {
            Text("\(number)")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(numberColor)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "888888"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(ProfileRoundedCornerShape(radius: clipRadius, corners: corners))
        .overlay(borderOverlay)
    }

    private var clipRadius: CGFloat {
        position == .middle ? 0 : 14
    }

    private var corners: UIRectCorner {
        switch position {
        case .left:   return [.topLeft, .bottomLeft]
        case .middle: return .allCorners
        case .right:  return [.topRight, .bottomRight]
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch position {
        case .left:
            ProfileRoundedCornerShape(radius: 14, corners: [.topLeft, .bottomLeft])
                .stroke(borderColor, lineWidth: borderWidth)
        case .middle:
            VStack(spacing: 0) {
                borderColor.frame(height: borderWidth)
                Spacer()
                borderColor.frame(height: borderWidth)
            }
        case .right:
            ProfileRoundedCornerShape(radius: 14, corners: [.topRight, .bottomRight])
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

// MARK: - Badge View

private struct ProfileBadgeView: View {
    let emoji: String
    let label: String
    let circleColor: Color
    let borderColor: Color
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2.5))
                Text(emoji)
                    .font(.system(size: 22))
            }
            .opacity(isLocked ? 0.5 : 1.0)

            Text(label)
                .font(.system(size: 10, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(isLocked ? Color(hex: "bbbbbb") : Color(hex: "0d5c58"))
                .frame(width: 70)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
