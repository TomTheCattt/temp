//
//  MockData.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockData

/// Central fake data store for UI development and pagination testing.
nonisolated enum MockData {

    // MARK: - Test Account Credentials

    /// Default test account for development/testing.
    /// Use these credentials on the login screen, or enable mock API mode for auto-login.
    static let testEmail = "tom@example.com"
    static let testPassword = "password123"

    // MARK: - Users

    static let currentUser = User(
        id: "user_current",
        username: "tomthecat",
        fullName: "Tom The Cat",
        email: "tom@example.com",
        phone: "+84901234567",
        avatarURL: URL(string: "https://i.pravatar.cc/300?u=tomthecat"),
        bio: "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
        website: "https://tomthecat.dev",
        isVerified: true,
        isPrivate: false,
        followersCount: 1234,
        followingCount: 567,
        postsCount: 34,
        createdAt: Date(timeIntervalSinceNow: -365 * 24 * 3600),
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false
    )

    static let users: [User] = {
        // Base 20 curated users
        var list: [User] = [
            User(id: "user_1", username: "jane_doe", fullName: "Jane Doe", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=jane"), bio: "Photographer 📸 | Canon EOS R5", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 892, followingCount: 234, postsCount: 67,
                 createdAt: Date(timeIntervalSinceNow: -200 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
            User(id: "user_2", username: "john_smith", fullName: "John Smith", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=john"), bio: "Travel 🌍 | Food 🍕 | Nomadic lifestyle", website: "https://johnsmith.com",
                 isVerified: true, isPrivate: false, followersCount: 45_000, followingCount: 890, postsCount: 312,
                 createdAt: Date(timeIntervalSinceNow: -500 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_3", username: "sara_design", fullName: "Sara Design", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=sara"), bio: "UI/UX Designer ✨ | Design systems & motion", website: nil,
                 isVerified: false, isPrivate: true, followersCount: 2341, followingCount: 456, postsCount: 89,
                 createdAt: Date(timeIntervalSinceNow: -150 * 24 * 3600), isFollowing: false, isFollowedBy: true, isBlocked: false),
            User(id: "user_4", username: "mike_dev", fullName: "Mike Developer", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=mike"), bio: "SwiftUI | Kotlin | Rust enthusiast", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 567, followingCount: 123, postsCount: 23,
                 createdAt: Date(timeIntervalSinceNow: -90 * 24 * 3600), isFollowing: false, isFollowedBy: false, isBlocked: false),
            User(id: "user_5", username: "lisa_art", fullName: "Lisa Art", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=lisa"), bio: "Digital Artist 🎨 | Procreate illustrations", website: "https://lisaart.co",
                 isVerified: true, isPrivate: false, followersCount: 120_000, followingCount: 345, postsCount: 567,
                 createdAt: Date(timeIntervalSinceNow: -800 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
            User(id: "user_6", username: "an_le", fullName: "Lê Hoàng An", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=an_le"), bio: "Architecture & Interior 🏛️ Saigon based", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 12_400, followingCount: 420, postsCount: 156,
                 createdAt: Date(timeIntervalSinceNow: -340 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_7", username: "minh_tri", fullName: "Trần Minh Trí", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=minh_tri"), bio: "Coffee addict ☕️ • Tech reviewer 📱", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 3_890, followingCount: 512, postsCount: 84,
                 createdAt: Date(timeIntervalSinceNow: -180 * 24 * 3600), isFollowing: false, isFollowedBy: false, isBlocked: false),
            User(id: "user_8", username: "lan_huong", fullName: "Nguyễn Lan Hương", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=lan_huong"), bio: "Fashion & Lifestyle 👗 Hanoi | Inquiries: collab@huong.vn", website: "https://lanhuong.vn",
                 isVerified: true, isPrivate: false, followersCount: 68_500, followingCount: 310, postsCount: 430,
                 createdAt: Date(timeIntervalSinceNow: -620 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
            User(id: "user_9", username: "alex_walker", fullName: "Alex Walker", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=alex_walker"), bio: "Outdoor adventures 🏔️ Trekking & Camping across SE Asia", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 8_920, followingCount: 640, postsCount: 198,
                 createdAt: Date(timeIntervalSinceNow: -410 * 24 * 3600), isFollowing: false, isFollowedBy: true, isBlocked: false),
            User(id: "user_10", username: "emma_chef", fullName: "Emma Cook", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=emma_chef"), bio: "Plant-based recipes 🌱 Healthy sourdough & matcha", website: "https://emmacooks.com",
                 isVerified: true, isPrivate: false, followersCount: 34_200, followingCount: 280, postsCount: 510,
                 createdAt: Date(timeIntervalSinceNow: -730 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_11", username: "quoc_bao", fullName: "Phạm Quốc Bảo", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=quoc_bao"), bio: "Mobile Engineer 🚀 Building iOS & macOS apps", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 1_450, followingCount: 230, postsCount: 42,
                 createdAt: Date(timeIntervalSinceNow: -95 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_12", username: "thuy_tien", fullName: "Đặng Thủy Tiên", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=thuy_tien"), bio: "Ceramics & Handmade Pottery 🏺 Da Nang workshop", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 15_800, followingCount: 410, postsCount: 220,
                 createdAt: Date(timeIntervalSinceNow: -280 * 24 * 3600), isFollowing: false, isFollowedBy: true, isBlocked: false),
            User(id: "user_13", username: "david_music", fullName: "David Chen", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=david_music"), bio: "Music Producer 🎧 Lo-fi beats & vinyl collector", website: "https://spotify.com",
                 isVerified: true, isPrivate: false, followersCount: 92_000, followingCount: 195, postsCount: 340,
                 createdAt: Date(timeIntervalSinceNow: -580 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
            User(id: "user_14", username: "mai_anh", fullName: "Vũ Mai Anh", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=mai_anh"), bio: "Book reviewer 📚 | Cat mom 🐱 | Cozy corner", website: nil,
                 isVerified: false, isPrivate: true, followersCount: 5_600, followingCount: 380, postsCount: 115,
                 createdAt: Date(timeIntervalSinceNow: -140 * 24 * 3600), isFollowing: false, isFollowedBy: false, isBlocked: false),
            User(id: "user_15", username: "hoang_nam", fullName: "Ngô Hoàng Nam", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=hoang_nam"), bio: "Street photography 🎞️ 35mm film only", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 22_300, followingCount: 520, postsCount: 275,
                 createdAt: Date(timeIntervalSinceNow: -390 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_16", username: "chloe_fit", fullName: "Chloe Nguyen", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=chloe_fit"), bio: "Fitness & Yoga Coach 🧘‍♀️ Mindful body & soul", website: "https://chloefit.vn",
                 isVerified: true, isPrivate: false, followersCount: 41_000, followingCount: 290, postsCount: 380,
                 createdAt: Date(timeIntervalSinceNow: -490 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
            User(id: "user_17", username: "tuan_kien", fullName: "Lý Tuấn Kiệt", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=tuan_kien"), bio: "Specialty Coffee Roaster ☕️ Origin stories", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 4_300, followingCount: 310, postsCount: 95,
                 createdAt: Date(timeIntervalSinceNow: -120 * 24 * 3600), isFollowing: false, isFollowedBy: true, isBlocked: false),
            User(id: "user_18", username: "sophia_baker", fullName: "Sophia Miller", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=sophia_baker"), bio: "Artisan Bakery 🥐 French pastries & tarts", website: nil,
                 isVerified: false, isPrivate: false, followersCount: 53_000, followingCount: 215, postsCount: 460,
                 createdAt: Date(timeIntervalSinceNow: -650 * 24 * 3600), isFollowing: false, isFollowedBy: false, isBlocked: false),
            User(id: "user_19", username: "duc_huy", fullName: "Bùi Đức Huy", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=duc_huy"), bio: "Product Designer 📐 Figma & Design systems", website: "https://duchuy.design",
                 isVerified: false, isPrivate: false, followersCount: 7_800, followingCount: 440, postsCount: 160,
                 createdAt: Date(timeIntervalSinceNow: -230 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
            User(id: "user_20", username: "ngoc_ha", fullName: "Hoàng Ngọc Hà", email: nil, phone: nil,
                 avatarURL: URL(string: "https://i.pravatar.cc/300?u=ngoc_ha"), bio: "Travel blogger ✈️ 32 countries and counting", website: "https://ngocha.travel",
                 isVerified: true, isPrivate: false, followersCount: 88_000, followingCount: 670, postsCount: 620,
                 createdAt: Date(timeIntervalSinceNow: -820 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
        ]

        // Expanded users 21 to 60 for rich multi-page follower/following testing
        let extendedUserConfigs: [(username: String, fullName: String, bio: String, verified: Bool, following: Bool, followedBy: Bool)] = [
            ("phuong_thao", "Đỗ Phương Thảo", "Fashion stylist & content creator ✨ Hanoi", false, true, true),
            ("viet_anh", "Vũ Việt Anh", "Filmmaker 🎬 Colorist & Director", true, true, true),
            ("bao_ngoc", "Trần Bảo Ngọc", "Pastry chef 🍰 Sweet tooth adventures", false, false, true),
            ("khanh_vy", "Lê Khánh Vy", "IELTS Instructor 🎙️ Host & YouTuber", true, true, true),
            ("thanh_tung", "Nguyễn Thanh Tùng", "Indie game developer 🕹️ Unity & Godot", false, false, false),
            ("minh_hang", "Đinh Minh Hằng", "Florist & Botanical artist 🌸 Saigon", false, true, true),
            ("quang_huy", "Hoàng Quang Huy", "Architect 🏛️ Minimalist modern living", false, true, false),
            ("kim_ngan", "Phan Kim Ngân", "Digital Marketing Specialist 📊", false, false, true),
            ("van_hieu", "Lưu Văn Hiếu", "Mechanical keyboard enthusiast ⌨️", false, false, false),
            ("tra_my", "Võ Trà My", "Eco-conscious lifestyle 🌿 Zero waste", true, true, true),
            ("tien_dat", "Trần Tiến Đạt", "Barista & Aeropress champion ☕️", false, true, true),
            ("huong_giang", "Nguyễn Hương Giang", "Contemporary Dancer 🩰 Stage performer", true, false, true),
            ("dinh_khoi", "Lê Đình Khôi", "Car enthusiast & reviewer 🏎️ Track days", false, true, false),
            ("phuong_linh", "Bùi Phương Linh", "Watercolor illustrations & prints 🎨", false, false, true),
            ("quang_minh", "Vũ Quang Minh", "Fintech Engineer 💳 Crypto & AI", false, false, false),
            ("thuy_dung", "Dương Thùy Dung", "Yoga teacher 🧘‍♀️ Daily mindfulness", false, true, true),
            ("tan_phat", "Hồ Tấn Phát", "Street food explorer 🍜 Saigon bites", false, true, false),
            ("thanh_ha", "Trịnh Thanh Hà", "Voice actress 🎙️ Audiobooks & Dubbing", false, false, true),
            ("xuan_truong", "Lương Xuân Trường", "Marathon runner 🏃‍♂️ 42km finisher", false, true, true),
            ("yen_nhi", "Nguyễn Yến Nhi", "Vintage clothing collector 👗 Thrifting", false, false, false),
            ("lucas_scott", "Lucas Scott", "Cinematographer 🎥 Los Angeles based", true, true, false),
            ("clara_b", "Clara Bennet", "Ceramicist 🏺 Hand thrown porcelain", false, false, true),
            ("oliver_k", "Oliver Klein", "Sound designer & synth collector 🎹", false, true, true),
            ("mia_zhang", "Mia Zhang", "Concept artist & visual development 🎨", true, true, false),
            ("noah_f", "Noah Fischer", "Alpine mountaineer 🏔️ Chamonix guide", false, false, true),
            ("elena_r", "Elena Rostova", "Violinist 🎻 Classical & neo-folk", true, true, true),
            ("liam_p", "Liam Parker", "Custom motorcycle builder 🏍️ Berlin", false, false, false),
            ("hannah_m", "Hannah Morales", "Botanical researcher 🌿 Orchid grower", false, true, true),
            ("ethan_w", "Ethan Wright", "Landscape architect 🌳 Urban greening", false, true, false),
            ("zoe_c", "Zoe Campbell", "Surfer & ocean photographer 🌊 Bali", true, true, true),
            ("samuel_t", "Samuel Thorne", "Woodworker 🪚 Live edge tables", false, false, true),
            ("nora_a", "Nora Al-Mansoor", "Documentary photographer 📷 Desert tales", true, true, false),
            ("leo_d", "Leo Dubois", "Sommelier 🍷 Biodynamic vineyards", false, true, true),
            ("maya_j", "Maya Joshi", "Textile designer 🧵 Handwoven fabrics", false, false, true),
            ("hugo_v", "Hugo Vargas", "Graffiti muralist 🎨 City walls", false, true, false),
            ("charlotte_h", "Charlotte Hall", "Pastry consultant 🥐 Sourdough master", true, true, true),
            ("gabriel_s", "Gabriel Silva", "Capoeira master & rhythm coach 🥁", false, false, true),
            ("ingrid_l", "Ingrid Lindholm", "Nordic interior curator 🕯️ Stockholm", false, true, true),
            ("kai_tanaka", "Kai Tanaka", "Ramen artisan 🍜 Tokyo hidden gems", true, true, false),
            ("camila_p", "Camila Perez", "Botanical tattoo artist 🌿 Fine lines", false, false, false)
        ]

        for (idx, cfg) in extendedUserConfigs.enumerated() {
            let userId = "user_\(idx + 21)"
            list.append(
                User(
                    id: userId,
                    username: cfg.username,
                    fullName: cfg.fullName,
                    email: nil,
                    phone: nil,
                    avatarURL: URL(string: "https://i.pravatar.cc/300?u=\(cfg.username)"),
                    bio: cfg.bio,
                    website: nil,
                    isVerified: cfg.verified,
                    isPrivate: idx % 6 == 0,
                    followersCount: Int.random(in: 600...150_000),
                    followingCount: Int.random(in: 120...980),
                    postsCount: Int.random(in: 15...320),
                    createdAt: Date(timeIntervalSinceNow: -Double(idx + 25) * 86400 * 10),
                    isFollowing: cfg.following,
                    isFollowedBy: cfg.followedBy,
                    isBlocked: false
                )
            )
        }

        return list
    }()

    // MARK: - Video URLs (Fallback Guaranteed)

    /// Proven stable sample video URLs already present in the codebase.
    /// Used as guaranteed working fallbacks if external vertical 9:16 streams fail.
    static let fallbackVideoURLs: [String] = [
        "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
        "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_5MB.mp4",
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_10MB.mp4"
    ]

    /// High quality vertical 9:16 sample videos
    static let vertical9x16VideoURLs: [String] = [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
    ]

    /// Primary video URLs list for backward compatibility
    static var sampleVideoURLs: [String] {
        fallbackVideoURLs
    }

    /// Safe resolver for Reel video URL with automatic fallback
    static func reelVideoURL(index: Int) -> URL {
        let candidate = vertical9x16VideoURLs[index % vertical9x16VideoURLs.count]
        if let url = URL(string: candidate) {
            return url
        }
        let fallback = fallbackVideoURLs[index % fallbackVideoURLs.count]
        return URL(string: fallback) ?? URL(string: "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4")!
    }

    /// Guaranteed fallback URL for Reel video
    static func reelFallbackVideoURL(index: Int) -> URL {
        let fallback = fallbackVideoURLs[index % fallbackVideoURLs.count]
        return URL(string: fallback) ?? URL(string: "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4")!
    }

    // MARK: - Posts (100 Posts for Multi-Page Feed & Explore Slicing)

    static let posts: [Post] = (0..<100).map { index in
        // Distribute posts so currentUser owns indices divisible by 3 (34 posts total for rich 3x3 profile grid)
        let author = (index % 3 == 0) ? currentUser : users[index % users.count]
        let isCarousel = (index % 4 == 0) // Every 4th post is a multi-media Carousel post
        let isVideo = !isCarousel && (index % 3 == 1) // Video post when not carousel

        let mediaItems: [MediaItem] = {
            if isCarousel {
                let itemCount = (index % 3) + 2 // 2 to 4 items in carousel
                return (0..<itemCount).map { subIndex in
                    let isSubVideo = (subIndex == 1)
                    return MediaItem(
                        id: "media_\(index)_\(subIndex)",
                        url: isSubVideo
                            ? URL(string: fallbackVideoURLs[(index + subIndex) % fallbackVideoURLs.count])!
                            : URL(string: "https://picsum.photos/seed/post\(index)_\(subIndex)/1080/1080")!,
                        thumbnailURL: URL(string: "https://picsum.photos/seed/post\(index)_\(subIndex)/400/400"),
                        type: isSubVideo ? .video : .image,
                        width: 1080,
                        height: 1080,
                        duration: isSubVideo ? 12.0 : nil
                    )
                }
            } else if isVideo {
                return [
                    MediaItem(
                        id: "media_\(index)_0",
                        url: URL(string: fallbackVideoURLs[index % fallbackVideoURLs.count])!,
                        thumbnailURL: URL(string: "https://picsum.photos/seed/post\(index)/400/400"),
                        type: .video,
                        width: 1080,
                        height: 1080,
                        duration: Double.random(in: 10...45)
                    )
                ]
            } else {
                return [
                    MediaItem(
                        id: "media_\(index)_0",
                        url: URL(string: "https://picsum.photos/seed/post\(index)/1080/1080")!,
                        thumbnailURL: URL(string: "https://picsum.photos/seed/post\(index)/400/400"),
                        type: .image,
                        width: 1080,
                        height: 1080,
                        duration: nil
                    )
                ]
            }
        }()

        let locations = [
            PostLocation(name: "Ho Chi Minh City, Vietnam", latitude: 10.8231, longitude: 106.6297),
            PostLocation(name: "Hanoi Old Quarter", latitude: 21.0285, longitude: 105.8542),
            PostLocation(name: "Da Nang Beach", latitude: 16.0544, longitude: 108.2022),
            PostLocation(name: "Dalat Pine Hills", latitude: 11.9404, longitude: 108.4583),
            PostLocation(name: "Hoi An Ancient Town", latitude: 15.8801, longitude: 108.3380),
            PostLocation(name: "Phu Quoc Island", latitude: 10.2899, longitude: 103.9840),
            PostLocation(name: "Nha Trang Bay", latitude: 12.2388, longitude: 109.1967),
            PostLocation(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
            nil
        ]

        // Tiered comments count for rich pagination testing:
        // Divisible by 10: 45-85 comments (multi-page testing: pages 1, 2, 3, 4)
        // Divisible by 5: 22-35 comments (2-page testing: pages 1, 2)
        // Others: 3-18 comments
        let commentsCount: Int = {
            if index % 10 == 0 {
                return Int.random(in: 45...85)
            } else if index % 5 == 0 {
                return Int.random(in: 22...35)
            } else {
                return Int.random(in: 3...18)
            }
        }()

        return Post(
            id: "post_\(index)",
            author: author,
            caption: mockCaptions[index % mockCaptions.count],
            mediaItems: mediaItems,
            location: locations[index % locations.count],
            likesCount: Int.random(in: 25...8500),
            commentsCount: commentsCount,
            createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600 * 2),
            isLiked: index % 2 == 0,
            isSaved: index % 4 == 0,
            isSponsored: index == 3 || index == 27 || index == 63
        )
    }

    // MARK: - Stories

    static let stories: [Story] = {
        // Current user's story
        let myStory = Story(
            id: "story_me",
            author: currentUser,
            items: [
                StoryItem(
                    id: "story_item_me_0",
                    mediaURL: URL(string: "https://picsum.photos/seed/mystory0/1080/1920")!,
                    type: .image,
                    duration: 5,
                    createdAt: Date(timeIntervalSinceNow: -1800),
                    sticker: StoryStickerInfo(type: .location, data: "Ho Chi Minh City")
                ),
                StoryItem(
                    id: "story_item_me_1",
                    mediaURL: URL(string: fallbackVideoURLs[0])!,
                    type: .video,
                    duration: 15,
                    createdAt: Date(timeIntervalSinceNow: -900),
                    sticker: nil
                )
            ],
            isViewed: true,
            createdAt: Date(timeIntervalSinceNow: -1800),
            expiresAt: Date(timeIntervalSinceNow: 22 * 3600)
        )

        // Other users' stories
        let otherStories: [Story] = users.prefix(20).enumerated().map { index, user in
            let itemCount = (index % 3) + 2 // 2-4 items per story
            let items: [StoryItem] = (0..<itemCount).map { itemIndex in
                let isVideo = itemIndex % 3 == 1 // Every 2nd item in a story is video
                let sticker: StoryStickerInfo? = {
                    switch (index + itemIndex) % 5 {
                    case 0: return StoryStickerInfo(type: .location, data: "District 1, Saigon")
                    case 1: return StoryStickerInfo(type: .mention, data: "@\(users[(index + 1) % users.count].username)")
                    case 2: return StoryStickerInfo(type: .music, data: "Trending Song • Artist")
                    case 3: return StoryStickerInfo(type: .poll, data: "Coffee or Tea?")
                    default: return nil
                    }
                }()
                return StoryItem(
                    id: "story_item_\(index)_\(itemIndex)",
                    mediaURL: isVideo
                        ? URL(string: fallbackVideoURLs[(index + itemIndex) % fallbackVideoURLs.count])!
                        : URL(string: "https://picsum.photos/seed/story\(index)_\(itemIndex)/1080/1920")!,
                    type: isVideo ? .video : .image,
                    duration: isVideo ? 15 : 5,
                    createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600 - Double(itemIndex) * 600),
                    sticker: sticker
                )
            }
            return Story(
                id: "story_\(index)",
                author: user,
                items: items,
                isViewed: index > 2,
                createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600),
                expiresAt: Date(timeIntervalSinceNow: Double(24 - index) * 3600)
            )
        }

        return [myStory] + otherStories
    }()

    // MARK: - Comments (Seed comments for posts)

    static let comments: [Comment] = {
        var result: [Comment] = []
        for i in 0..<30 {
            let postId = "post_\(i % 10)"
            let commentId = "comment_\(i)"
            let author = users[i % users.count]
            let hasReply = (i % 3 == 0)

            let replies: [Comment] = hasReply ? [
                Comment(
                    id: "reply_\(i)_0",
                    postId: postId,
                    author: users[(i + 1) % users.count],
                    text: mockReplyTexts[i % mockReplyTexts.count],
                    likesCount: Int.random(in: 1...15),
                    isLiked: false,
                    replies: [],
                    parentId: commentId,
                    createdAt: Date(timeIntervalSinceNow: -Double(i) * 1800 - 300)
                )
            ] : []

            result.append(
                Comment(
                    id: commentId,
                    postId: postId,
                    author: author,
                    text: mockCommentTexts[i % mockCommentTexts.count],
                    likesCount: Int.random(in: 0...60),
                    isLiked: i % 4 == 0,
                    replies: replies,
                    parentId: nil,
                    createdAt: Date(timeIntervalSinceNow: -Double(i) * 1800)
                )
            )
        }
        return result
    }()

    static func comments(forPostId postId: String) -> [Comment] {
        comments.filter { $0.postId == postId }
    }

    // MARK: - Reels (50 Reels for Infinite Vertical Paging)

    static let reels: [Reel] = (0..<50).map { index in
        // Distribute reels so currentUser owns indices divisible by 3 (17 reels total)
        let author = (index % 3 == 0) ? currentUser : users[index % users.count]
        return Reel(
            id: "reel_\(index)",
            author: author,
            videoURL: reelVideoURL(index: index),
            fallbackVideoURL: reelFallbackVideoURL(index: index),
            thumbnailURL: URL(string: "https://picsum.photos/seed/reel\(index)/1080/1920"),
            caption: mockReelCaptions[index % mockReelCaptions.count],
            audioTrack: index % 2 == 0 ? AudioTrack(
                id: "audio_\(index)",
                name: "Original Audio",
                artistName: author.username,
                coverURL: author.avatarURL,
                isOriginal: true
            ) : AudioTrack(
                id: "audio_trending_\(index)",
                name: "Trending Sound #\(index)",
                artistName: "Various Artists",
                coverURL: URL(string: "https://picsum.photos/seed/audio\(index)/100/100"),
                isOriginal: false
            ),
            likesCount: Int.random(in: 100...80_000),
            commentsCount: Int.random(in: 10...750),
            sharesCount: Int.random(in: 5...350),
            viewsCount: Int.random(in: 1000...650_000),
            duration: Double.random(in: 8...60),
            isLiked: index % 3 == 0,
            isSaved: index % 5 == 0,
            createdAt: Date(timeIntervalSinceNow: -Double(index) * 7200)
        )
    }

    // MARK: - Notifications (50 Notifications Across Time Segments)

    static let notifications: [AppNotification] = (0..<50).map { index in
        let types: [NotificationType] = [.like, .comment, .follow, .mention]
        let type = types[index % types.count]
        let actor = users[index % users.count]
        let isToday = index < 5
        let isYesterday = index >= 5 && index < 15
        let isThisWeek = index >= 15 && index < 30

        let timeOffset: Double = {
            if isToday {
                return Double(index + 1) * 600 // within last 1 hour
            } else if isYesterday {
                return 86400 + Double(index) * 1800 // yesterday
            } else if isThisWeek {
                return 86400 * 3 + Double(index) * 3600 // 3-7 days ago
            } else {
                return 86400 * 18 + Double(index) * 7200 // earlier
            }
        }()

        let commentText: String? = {
            switch type {
            case .comment:
                return ["Amazing shot! 🔥", "Super aesthetic ✨", "Love this so much 😍", "Incredible work! 👏"][index % 4]
            case .mention:
                return "tagged you in a comment: check this out!"
            default:
                return nil
            }
        }()

        let isRead: Bool = {
            if isToday {
                return false // Today items unread
            } else if isYesterday {
                return index % 3 == 0 // Some read, some unread
            } else {
                return true // Older items read
            }
        }()

        return AppNotification(
            id: "notif_\(index + 1)",
            type: type,
            actor: actor,
            postId: (type == .like || type == .comment || type == .mention) ? "post_\(index % 30)" : nil,
            postThumbnailURL: (type == .like || type == .comment || type == .mention) ? URL(string: "https://picsum.photos/seed/post\(index % 30)/400/400") : nil,
            commentText: commentText,
            isRead: isRead,
            createdAt: Date(timeIntervalSinceNow: -timeOffset)
        )
    }

    // MARK: - Conversations & Seeded Messages (35 Conversations for Multi-Page DM Paging)

    private struct SeedConversationData {
        let conversation: Conversation
        let history: [Message] // Stored in newest-first order (history[0] == conversation.lastMessage)
    }

    private struct DialogueStep {
        let isFromCurrentUser: Bool
        let senderUser: User?
        let content: MessageContent
        let replySnippet: String?
        let reactions: [String: String]

        init(
            isMe: Bool,
            sender: User? = nil,
            content: MessageContent,
            reply: String? = nil,
            reactions: [String: String] = [:]
        ) {
            self.isFromCurrentUser = isMe
            self.senderUser = sender
            self.content = content
            self.replySnippet = reply
            self.reactions = reactions
        }
    }

    private static func buildConversationData(
        id: String,
        participants: [User],
        steps: [DialogueStep],
        baseDate: Date,
        unreadCount: Int,
        isGroup: Bool = false,
        groupName: String? = nil,
        groupAvatarURL: URL? = nil,
        isMuted: Bool = false,
        stepSpacing: TimeInterval = 180
    ) -> SeedConversationData {
        guard !steps.isEmpty else {
            fatalError("Steps cannot be empty for conversation \(id)")
        }

        let total = steps.count
        var history: [Message] = []

        // In steps array: index 0 is oldest (opener), index total - 1 is newest (lastMessage).
        for (idx, step) in steps.enumerated() {
            let offset = Double(total - 1 - idx) * stepSpacing
            let msgDate = baseDate.addingTimeInterval(-offset)
            let isLast = (idx == total - 1)

            let sender: User = {
                if let s = step.senderUser { return s }
                if step.isFromCurrentUser { return currentUser }
                return participants.first { $0.id != currentUser.id } ?? participants.first ?? currentUser
            }()

            let status: MessageStatus = {
                if isLast && unreadCount > 0 && sender.id != currentUser.id {
                    return .delivered
                }
                return .read
            }()

            let msg = Message(
                id: "msg_\(id)_\(idx)",
                conversationId: id,
                sender: sender,
                content: step.content,
                status: status,
                replyToId: nil,
                replyToSnippet: step.replySnippet,
                reactions: step.reactions,
                createdAt: msgDate
            )
            history.append(msg)
        }

        // Reverse history so index 0 is the newest message (lastMessage)
        let reversedHistory = Array(history.reversed())
        let lastMessage = reversedHistory.first

        let conv = Conversation(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            isGroup: isGroup,
            groupName: groupName,
            groupAvatarURL: groupAvatarURL,
            updatedAt: lastMessage?.createdAt ?? baseDate,
            isMuted: isMuted
        )

        return SeedConversationData(conversation: conv, history: reversedHistory)
    }

    private static let seedData: [SeedConversationData] = buildSeedConversations()

    /// All 35 pre-seeded conversations matching parent inbox and detail chat 1:1.
    static let conversations: [Conversation] = seedData.map(\.conversation)

    /// Pre-seeded messages for all conversations, guaranteed newest-first with matching lastMessage.
    static let seededMessages: [String: [Message]] = Dictionary(
        uniqueKeysWithValues: seedData.map { ($0.conversation.id, $0.history) }
    )

    /// Centralized Instagram Notes pool.
    static let seededNotes: [InstagramNote] = {
        let currentUserNote = InstagramNote(
            id: "note_current",
            user: currentUser,
            text: "Đang code Instagram 💻",
            createdAt: .now,
            isCurrentUser: true
        )
        let notesPool = [
            "Coffee vibes ☕️",
            "Cháy deadline 🔥",
            "Chill cuối tuần 🎶",
            "On the way ✈️",
            "Gym time 💪",
            "Working remotely 🌴"
        ]
        let friendNotes = users.prefix(6).enumerated().map { index, user in
            InstagramNote(
                id: "note_\(user.id)",
                user: user,
                text: notesPool[index % notesPool.count],
                createdAt: Date(timeIntervalSinceNow: -Double(index * 3600)),
                isCurrentUser: false
            )
        }
        return [currentUserNote] + friendNotes
    }()

    private static let olderHistoryTemplates = [
        "Cậu có tài liệu dự án tuần trước gửi lại giúp mình nhé?",
        "Đây là link Google Drive tổng hợp toàn bộ files nè.",
        "Cảm ơn cậu nhiều! Để tối nay mình xem qua.",
        "Có điểm nào cần chỉnh sửa cứ nhắn mình nha.",
        "Mọi thứ nhìn chỉn chu lắm, xuất sắc!",
        "Thứ Hai tuần tới mình vẫn họp review thiết kế đúng không?",
        "Đúng rồi, 10h sáng ở phòng họp tầng 3 nhé.",
        "Đã note vào lịch rồi. Hẹn gặp cậu đầu tuần!",
        "Chúc cậu cuối tuần vui vẻ nhé! 🌟",
        "Cảm ơn cậu, cuối tuần nhiều năng lượng nha! ✨"
    ]

    /// Generates authentic preceding messages when user scrolls up to load more pages.
    static func generateOlderMessages(
        conversationId: String,
        page: Int,
        perPage: Int,
        oldestDate: Date,
        partner: User
    ) -> [Message] {
        var olderBatch: [Message] = []
        let spacing: Double = 300 // 5 minutes apart
        for i in 1...perPage {
            let sender = (i % 2 == 1) ? partner : currentUser
            let text = olderHistoryTemplates[((page - 1) * perPage + i) % olderHistoryTemplates.count]
            let date = oldestDate.addingTimeInterval(-Double(i) * spacing)
            olderBatch.append(
                Message(
                    id: "msg_\(conversationId)_p\(page)_\(i)",
                    conversationId: conversationId,
                    sender: sender,
                    content: .text(text),
                    status: .read,
                    replyToId: nil,
                    createdAt: date
                )
            )
        }
        return olderBatch
    }

    private static func buildSeedConversations() -> [SeedConversationData] {
        var list: [SeedConversationData] = []

        // 1. conv_0: Jane Doe (Photography & Lightroom presets)
        let jane = users[0]
        list.append(
            buildConversationData(
                id: "conv_0",
                participants: [currentUser, jane],
                steps: [
                    DialogueStep(isMe: false, content: .text("Chào Tom! Bộ ảnh chụp hoàng hôn sông Sài Gòn hôm trước màu lên đẹp quá 📸")),
                    DialogueStep(isMe: true, content: .text("Cảm ơn Jane nha! Mình chụp bằng lens 35mm f/1.4 lúc 5h chiều ấy.")),
                    DialogueStep(isMe: false, content: .text("Màu trong trẻo thật sự. Cậu có dùng filter CPL không?")),
                    DialogueStep(isMe: true, content: .text("Có chứ, mình dùng filter CPL để giảm phản xạ mặt nước ✨")),
                    DialogueStep(isMe: false, content: .text("Chuẩn bài luôn! Chiều nay mình vừa đi săn góc mới ở Thủ Thiêm nè.")),
                    DialogueStep(isMe: false, content: .image(URL(string: "https://picsum.photos/seed/sunset_jane/600/800")!)),
                    DialogueStep(isMe: true, content: .text("Góc này đỉnh quá! Tone màu pastel nhìn êm mắt thật sự 😍"), reply: "Hình ảnh"),
                    DialogueStep(isMe: false, content: .text("Mai rảnh không, cà phê góc Nhà hát Thành phố rồi trao đổi preset Lightroom nhé? ☕️"), reactions: ["user_current": "❤️"]),
                    DialogueStep(isMe: true, content: .text("Mai 9h sáng quán Okkio Tự Do nhé! Hẹn gặp cậu.")),
                    DialogueStep(isMe: false, content: .like, reactions: ["user_current": "❤️"]),
                    DialogueStep(isMe: false, content: .text("Hẹn gặp mai nhé! See you tomorrow 👋"))
                ],
                baseDate: Date(timeIntervalSinceNow: -15 * 60),
                unreadCount: 0
            )
        )

        // 2. conv_1: John Smith (Food & Travel - Unread: 2)
        let john = users[1]
        list.append(
            buildConversationData(
                id: "conv_1",
                participants: [currentUser, john],
                steps: [
                    DialogueStep(isMe: false, content: .text("Hey Tom! Are you still working around District 1 today?")),
                    DialogueStep(isMe: true, content: .text("Hey John! Yes, I'm at the workspace near Ben Thanh market.")),
                    DialogueStep(isMe: false, content: .text("Awesome! I just discovered this incredible specialty coffee spot nearby.")),
                    DialogueStep(isMe: false, content: .post(postId: "post_1"), reactions: ["user_current": "🔥"]),
                    DialogueStep(isMe: true, content: .text("That espresso bar looks insane! Have you tried their Ethiopian pour-over?")),
                    DialogueStep(isMe: false, content: .audio(URL(string: "https://example.com/audio_john.m4a")!, duration: 4.2)),
                    DialogueStep(isMe: true, content: .text("Sounds super delicious! Let's definitely grab a cup after work.")),
                    DialogueStep(isMe: false, content: .text("Great! What time do you wrap up your sprint today?")),
                    DialogueStep(isMe: false, content: .text("Let's meet at 5:30 PM if you're free! ☕️"))
                ],
                baseDate: Date(timeIntervalSinceNow: -35 * 60),
                unreadCount: 2
            )
        )

        // 3. conv_2: Sara Design (Design System & Motion Gesture)
        let sara = users[2]
        list.append(
            buildConversationData(
                id: "conv_2",
                participants: [currentUser, sara],
                steps: [
                    DialogueStep(isMe: false, content: .text("Hi Tom! Mình vừa push bộ Design System Tokens mới lên Figma nè ✨")),
                    DialogueStep(isMe: true, content: .text("Tuyệt vời Sara ơi! Để mình kéo file về mapping qua Struct Tokens trong Swift.")),
                    DialogueStep(isMe: false, content: .text("Cậu kiểm tra xem spacing 4pt/8pt và màu Semantic Dark Mode đã chuẩn chưa nhé.")),
                    DialogueStep(isMe: true, content: .text("Khớp 100% rồi! Bản cập nhật mới mượt mà lắm, test trên ProMotion 120Hz nhìn thích mắt cực.")),
                    DialogueStep(isMe: false, content: .reel(reelId: "reel_1"), reactions: ["user_current": "👏"]),
                    DialogueStep(isMe: false, content: .text("Hiệu ứng interactive gesture mới làm mẫu nè, cậu thấy thế nào?"), reply: "Instagram Reel"),
                    DialogueStep(isMe: true, content: .text("Animations spring damping 0.7 chuẩn IG gốc luôn! Team engineering sẽ implement ngay chiều nay 🚀")),
                    DialogueStep(isMe: true, content: .like)
                ],
                baseDate: Date(timeIntervalSinceNow: -75 * 60),
                unreadCount: 0
            )
        )

        // 4. conv_3: Mike Developer (Swift Concurrency & PR review - Unread: 1)
        let mike = users[3]
        list.append(
            buildConversationData(
                id: "conv_3",
                participants: [currentUser, mike],
                steps: [
                    DialogueStep(isMe: true, content: .text("Mike ơi, cái crash memory spike khi render video 60 FPS đã fix triệt để chưa?")),
                    DialogueStep(isMe: false, content: .text("Đã fix xong rồi Tom! Mình bọc @autoreleasepool và tái sử dụng CVPixelBufferPool.")),
                    DialogueStep(isMe: true, content: .text("Tuyệt vời, RAM giảm được bao nhiêu % vậy cậu?")),
                    DialogueStep(isMe: false, content: .text("Từ hơn 380MB tụt xuống đều đặn dưới 65MB, 60 FPS mượt mà không rớt frame nào.")),
                    DialogueStep(isMe: true, content: .text("Đỉnh chóp! PR đã merge vào nhánh main chưa?")),
                    DialogueStep(isMe: false, content: .text("Mình vừa mở PR #142 nè, cậu review và approve giúp mình nhé! 🚀"))
                ],
                baseDate: Date(timeIntervalSinceNow: -2 * 3600),
                unreadCount: 1
            )
        )

        // 5. conv_4: Group Chat Mobile Saigon Devs 🚀
        list.append(
            buildConversationData(
                id: "conv_4",
                participants: [currentUser, jane, mike, john],
                steps: [
                    DialogueStep(isMe: false, sender: jane, content: .text("Hello cả team Mobile! Chiều nay ai rảnh đi meetup iOS không?")),
                    DialogueStep(isMe: false, sender: mike, content: .text("Meetup ở đâu thế Jane? Mấy giờ bắt đầu?")),
                    DialogueStep(isMe: false, sender: jane, content: .text("Ở Innovation Hub Q3, chủ đề Swift 6 Strict Concurrency lúc 6h30 tối.")),
                    DialogueStep(isMe: false, sender: john, content: .text("Nghe hấp dẫn đó, lát mình xong việc ở cty sẽ chạy qua luôn.")),
                    DialogueStep(isMe: true, content: .text("Mình cũng đăng ký vé rồi, lát gặp mọi người ở đó nhé! 🍻"), reactions: ["user_1": "❤️", "user_4": "🔥"]),
                    DialogueStep(isMe: false, sender: mike, content: .text("Chốt kèo nha cả nhà! 👍"))
                ],
                baseDate: Date(timeIntervalSinceNow: -3.5 * 3600),
                unreadCount: 0,
                isGroup: true,
                groupName: "Mobile Saigon Devs 🚀",
                groupAvatarURL: URL(string: "https://picsum.photos/seed/groupsaigon/400/400"),
                isMuted: true
            )
        )

        // 6. conv_5: Lisa Art (Digital Artist)
        let lisa = users[4]
        list.append(
            buildConversationData(
                id: "conv_5",
                participants: [currentUser, lisa],
                steps: [
                    DialogueStep(isMe: false, content: .text("Tom ơi, tranh minh họa phong cảnh Sài Gòn mình vừa vẽ xong đây nè 🎨")),
                    DialogueStep(isMe: false, content: .image(URL(string: "https://picsum.photos/seed/lisa_art/600/800")!)),
                    DialogueStep(isMe: true, content: .text("Đẹp xuất sắc luôn Lisa! Nét vẽ ánh sáng phản chiếu mặt đường nhìn có hồn quá."), reactions: ["user_5": "🥰"]),
                    DialogueStep(isMe: false, content: .text("Cảm ơn Tom nhiều nha! Mình vẽ trên iPad Pro bằng Procreate mất gần 8 tiếng đó.")),
                    DialogueStep(isMe: true, content: .audio(URL(string: "https://example.com/audio_lisa.m4a")!, duration: 3.5)),
                    DialogueStep(isMe: false, content: .like)
                ],
                baseDate: Date(timeIntervalSinceNow: -5 * 3600),
                unreadCount: 0
            )
        )

        // 7. conv_6: Lê Hoàng An (Kiến trúc & Nội thất)
        let an = users[5]
        list.append(
            buildConversationData(
                id: "conv_6",
                participants: [currentUser, an],
                steps: [
                    DialogueStep(isMe: false, content: .text("Chào Tom! Bản concept thiết kế văn phòng mới theo phong cách Industrial hoàn thiện rồi nè.")),
                    DialogueStep(isMe: false, content: .image(URL(string: "https://picsum.photos/seed/interior_an/600/800")!)),
                    DialogueStep(isMe: true, content: .text("Không gian thoáng và nhiều ánh sáng tự nhiên quá An ơi! Tone xi măng với gỗ nhìn hiện đại.")),
                    DialogueStep(isMe: false, content: .text("Bản render 3D chi tiết mình gửi qua email cậu rồi nhé! 🏛️"))
                ],
                baseDate: Date(timeIntervalSinceNow: -7 * 3600),
                unreadCount: 0
            )
        )

        // 8. conv_7: Trần Minh Trí (Tech Reviewer - Unread: 1)
        let tri = users[6]
        list.append(
            buildConversationData(
                id: "conv_7",
                participants: [currentUser, tri],
                steps: [
                    DialogueStep(isMe: false, content: .text("Hôm nay mình vừa unbox chiếc máy ảnh Fujifilm X-T5, màu phim classic chrome chụp mê thật.")),
                    DialogueStep(isMe: true, content: .text("X-T5 chụp đường phố thì hết nước chấm rồi Trí. Cậu ghép với lens 27mm f/2.8 pancake à?")),
                    DialogueStep(isMe: false, content: .text("Chuẩn luôn! Nhỏ gọn đút túi áo khoác đi dạo tiện cực kỳ.")),
                    DialogueStep(isMe: false, content: .text("Cậu lên iOS 18.1 chưa, pin dùng ổn không?"))
                ],
                baseDate: Date(timeIntervalSinceNow: -10 * 3600),
                unreadCount: 1
            )
        )

        // 9. conv_8: Nguyễn Lan Hương (Fashion)
        let huong = users[7]
        list.append(
            buildConversationData(
                id: "conv_8",
                participants: [currentUser, huong],
                steps: [
                    DialogueStep(isMe: false, content: .text("Tom ơi, bộ sưu tập áo dài mùa thu Hà Nội của bên mình vừa lên kệ nè 👗")),
                    DialogueStep(isMe: false, content: .story(storyId: "story_1")),
                    DialogueStep(isMe: true, content: .text("Chất liệu lụa tơ tằm nhìn sang trọng và tinh tế quá Hương ơi!")),
                    DialogueStep(isMe: true, content: .text("Chúc buổi shooting chiều nay thành công rực rỡ nhé! ✨"))
                ],
                baseDate: Date(timeIntervalSinceNow: -14 * 3600),
                unreadCount: 0
            )
        )

        // 10. conv_9: Alex Walker (Outdoor & Trekking)
        let alex = users[8]
        list.append(
            buildConversationData(
                id: "conv_9",
                participants: [currentUser, alex],
                steps: [
                    DialogueStep(isMe: false, content: .text("Hey Tom! Are you ready for the Bidoup mountain trek next month?")),
                    DialogueStep(isMe: true, content: .text("Excited for it! I just got my new trekking boots and 50L backpack.")),
                    DialogueStep(isMe: false, content: .text("Awesome! The weather forecast looks crisp and clear up on the ridge.")),
                    DialogueStep(isMe: false, content: .text("Cuối tuần sau lên đường nha! 🏔️"))
                ],
                baseDate: Date(timeIntervalSinceNow: -20 * 3600),
                unreadCount: 0
            )
        )

        // 11. conv_10: Emma Cook (Plant-based & Sourdough)
        let emma = users[9]
        list.append(
            buildConversationData(
                id: "conv_10",
                participants: [currentUser, emma],
                steps: [
                    DialogueStep(isMe: false, content: .text("Hi Tom! Mình vừa ra lò mẻ bánh mì sourdough men tự nhiên 72 giờ nè.")),
                    DialogueStep(isMe: false, content: .image(URL(string: "https://picsum.photos/seed/sourdough_emma/600/800")!)),
                    DialogueStep(isMe: true, content: .text("Vỏ bánh giòn rụm lỗ khí đẹp mê ly luôn Emma! Mùi bơ thơm phức.")),
                    DialogueStep(isMe: false, content: .text("Bánh nở đẹp lắm, lát mình gửi cậu thử! 🥐"))
                ],
                baseDate: Date(timeIntervalSinceNow: -26 * 3600),
                unreadCount: 0
            )
        )

        // 12 -> 35: Users 10 to 33 (Tailored rich topics, strict chronological order)
        let additionalTopics = [
            ("Quốc Bảo", "Mobile Engineer", "Bản cập nhật Swift Package Manager trên Xcode 16 tối ưu thời gian build đáng kể.", "Mình cũng thấy clean build giảm được gần 35% thời gian luôn! 🚀", false),
            ("Thủy Tiên", "Ceramics Artist", "Bộ sưu tập ly gốm mộc vuốt tay mẻ mới men tro củi nung xong rồi nè.", "Màu men mộc mạc và vân rạn tự nhiên nhìn nghệ thuật lắm Tiên ơi! 🏺", false),
            ("David Chen", "Music Producer", "Track Lo-fi beat mới mix xong với sample tiếng mưa Sài Gòn nè.", "Giai điệu chill và bass ấm áp nghe vào buổi tối thư thái cực kỳ 🎧", false),
            ("Mai Anh", "Book Reviewer", "Cuốn sách về tâm lý học hành vi người dùng trong app cậu giới thiệu đọc cuốn thật sự.", "Đoạn phân tích micro-interactions tạo dopamine đọc thấm thía cậu nhỉ? 📚", true), // Unread: 1
            ("Hoàng Long", "Calisthenics", "Sáng nay set tập xà đơn 5 hiệp kết hợp muscle up cảm giác cơ bắp kích hoạt tốt lắm.", "Form chuẩn đét luôn Long ơi, kiên trì tập luyện nhìn phong độ hẳn! 💪", false),
            ("Thu Hà", "Coffee Roaster", "Hạt Geisha sơ chế yếm khí từ Cầu Đất hương hoa nhài và vị ngọt hậu sâu lắm.", "Cuối tuần mình ghé quán trải nghiệm ly pour-over nhé Hà ơi! ☕️", false),
            ("Tuấn Anh", "Film Director", "Thước phim 35mm quay bối cảnh chợ hoa Đầm Sen tráng scan ra màu hoài niệm ghê.", "Chất phim Kodak Portra 400 da người lên màu ấm áp không lẫn vào đâu được 🎞️", false),
            ("Bảo Ngọc", "Yoga Instructor", "Bài tập thở Pranayama sáng nay giúp giải tỏa stress và căng cơ hiệu quả lắm.", "Cảm ơn bài hướng dẫn của Ngọc nhé, tập xong thấy đầu óc nhẹ nhõm hẳn 🧘‍♀️", false),
            ("Quang Huy", "UI Designer", "Cậu thấy style Bento Grid layout ứng dụng vào màn hình Profile thế nào?", "Style này phân cấp thông tin rõ ràng và hiện đại, rất hợp xu hướng! 🎨", false),
            ("Phương Thảo", "Content Creator", "Video reel chia sẻ tips học Swift concurrency của cậu lên xu hướng 100k views rồi nè!", "Woa cảm ơn Thảo đã chia sẻ nha, động lực làm thêm nhiều clip hữu ích nữa! ✨", false),
            ("Văn Hùng", "Backend Dev", "API streaming tin nhắn qua WebSocket đã triển khai heartbeat keep-alive ổn định rồi.", "Tuyệt vời, latency round-trip đo được dưới 18ms, kết nối realtime mượt mà! ⚡️", false),
            ("Thanh Trúc", "Illustrator", "Sticker pack chú mèo máy mình vẽ tặng cộng đồng iOS dev vừa duyệt xong nè.", "Sticker cute xỉu Trúc ơi, team mình add vào xài liền đây! 🐱", false),
            ("Đức Minh", "Product Manager", "Sprint retrospective tuần này team mình hoàn thành 100% story points đề ra.", "Cảm ơn Minh đã lead sprint mượt mà và clear hết mọi blockers cho anh em! 🎯", false),
            ("Khánh Linh", "Travel Blogger", "Chuyến đi săn mây ở đỉnh Tà Xùa bình minh đẹp tựa chốn bồng lai tiên cảnh.", "Nhìn ảnh mà mê quá Linh ơi, nhất định mùa đông này mình phải đi một chuyến! ☁️", false)
        ]

        let startIndex = 10
        for i in 0..<24 {
            let userIndex = startIndex + (i % (users.count - startIndex))
            let user = users[userIndex]
            let topicIndex = i % additionalTopics.count
            let topic = additionalTopics[topicIndex]
            let isUnread = topic.4 && (i == 3) // Only index 14 is unread from Mai Anh
            let baseHours = Double(30 + i * 4)
            let baseDate = Date(timeIntervalSinceNow: -baseHours * 3600)

            let steps: [DialogueStep] = [
                DialogueStep(isMe: false, content: .text("Chào Tom! Hôm nay công việc bên cậu tiến triển thế nào rồi?")),
                DialogueStep(isMe: true, content: .text("Chào \(user.fullName.components(separatedBy: " ").last ?? user.username)! Mình đang tập trung hoàn thiện dự án.")),
                DialogueStep(isMe: false, content: .text(topic.2)),
                DialogueStep(isMe: true, content: .text(topic.3)),
                DialogueStep(isMe: isUnread ? false : (i % 2 == 0), content: isUnread ? .text("Cậu có thời gian thì xem qua rồi góp ý thêm cho mình nha!") : (i % 2 == 0 ? .like : .text("Hẹn sớm gặp lại cậu nhé! 👍")))
            ]

            let convId = "conv_\(startIndex + 1 + i)"
            list.append(
                buildConversationData(
                    id: convId,
                    participants: [currentUser, user],
                    steps: steps,
                    baseDate: baseDate,
                    unreadCount: isUnread ? 1 : 0,
                    isMuted: (i == 7)
                )
            )
        }

        return list
    }


    // MARK: - Private: Mock text arrays

    private static let mockCaptions = [
        "Beautiful morning in Saigon! ☀️ #photography #nature #saigon",
        "Coffee and Swift concurrency ☕️💻 #developer #ios #swift",
        "Exploring hidden alleys in Hanoi 🌍✈️ #travel #vietnam",
        nil,
        "Design is not just what it looks like. Design is how it works. 🎨",
        "Weekend chill playlist on repeat 🎶 #chill #weekend",
        "Excited to reveal what we've been crafting! 🚀 #startup",
        "Grateful for everyday moments 🙏 #mindfulness #blessed",
        "Sunset over West Lake 🌅 #hanoi #sunset",
        "Good food, great conversations 💛 #friends #lifestyle",
        "Fresh pottery pieces right out of the kiln 🏺 #ceramic",
        "Film photography walk along Saigon river 🎞️ #35mm"
    ] as [String?]

    private static let mockCommentTexts = [
        "This is stunning! 🔥",
        "Love the composition and light 📸",
        "So aesthetic! ✨",
        "Where is this spot? I need to go!",
        "Incredible vibes 😍",
        "Such inspiring work! 👏",
        "Beautiful tone curve! 🎨",
        "Keep creating great things! 🚀"
    ]

    private static let mockReplyTexts = [
        "Thanks so much! 🙏",
        "It's right near District 1! Let me DM you the address 📍",
        "Appreciate the support! 🙌",
        "Totally agree with you! ✨"
    ]

    private static let mockMessageTexts = [
        "Hey! How is the new build going?",
        "Did you see that new reel? So hilarious 😂",
        "Let's grab specialty coffee this weekend! ☕️",
        "Thanks for sending the Figma assets!",
        "See you tomorrow at the office 👋",
        "The animation transitions look super smooth! ✨"
    ]

    private static let mockReelCaptions: [String?] = [
        "Wait for the beat drop... 😂 #viral #reels",
        "Quick tutorial: SwiftUI interactive gestures ✨ #iosdev #swift",
        nil,
        "Day in the life: Coffee roaster in Da Lat ☕️ #dayinmylife",
        "View from the peak at sunrise 🏔️ #outdoor #hiking",
        "POV: When your pull request gets approved on first review ✅🚀",
        "Secret sourdough recipe in 60 seconds 🥐 #baking",
        "Film loading technique you should know 🎞️ #photography"
    ]
}
