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

    // MARK: - Conversations (35 Conversations for Multi-Page DM Paging)

    static let conversations: [Conversation] = users.prefix(35).enumerated().map { index, user in
        let messageContent: MessageContent = {
            switch index % 4 {
            case 0:
                return .text(mockMessageTexts[index % mockMessageTexts.count])
            case 1:
                return .image(URL(string: "https://picsum.photos/seed/chat_\(index)/600/800")!)
            case 2:
                return .audio(URL(string: "https://example.com/audio_\(index).m4a")!, duration: 4.2)
            default:
                return .like
            }
        }()

        return Conversation(
            id: "conv_\(index)",
            participants: [currentUser, user],
            lastMessage: Message(
                id: "msg_last_\(index)",
                conversationId: "conv_\(index)",
                sender: index % 2 == 0 ? user : currentUser,
                content: messageContent,
                status: .read,
                replyToId: nil,
                createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600)
            ),
            unreadCount: index < 4 ? Int.random(in: 1...4) : 0,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(timeIntervalSinceNow: -Double(index) * 3600),
            isMuted: index == 4 || index == 18
        )
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
