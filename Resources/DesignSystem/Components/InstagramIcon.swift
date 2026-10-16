//
//  InstagramIcon.swift
//  Instagram
//
//  Created for Instagram iOS Design System.
//  Type-safe Icon and Sticker Design System Components.
//  Strict zero-warning policy, modern Swift concurrency, and theme inversion support.
//

import SwiftUI

// MARK: - AppIcon Definition

enum AppIcon: Equatable, Sendable {

    // MARK: - Selectable Navigation & Action (Theme Inverted)
    // Light Mode: unselected -> Outline ("Rỗng"), selected -> Filled
    // Dark Mode: unselected -> Filled, selected -> Outline ("Rỗng")
    case home(selected: Bool = false)
    case reels(selected: Bool = false)
    case search(selected: Bool = false)
    case profile(selected: Bool = false)
    case create(selected: Bool = false)
    case createPost(selected: Bool = false)
    case like(selected: Bool = false)
    case save(selected: Bool = false)
    case grid(selected: Bool = false)
    case grid2026(selected: Bool = false)
    case activity(selected: Bool = false)
    case star(selected: Bool = false)
    case repost(selected: Bool = false)
    case highlight(selected: Bool = false)
    case tag(selected: Bool = false)
    case exclusive(selected: Bool = false)

    // MARK: - 24px Action Icons (Outline Native)
    case comment
    case share
    case share2026(selected: Bool = false)
    case options
    case close
    case chevronLeft
    case chevronRight
    case chevronUp
    case chevronUpAlt
    case chevronDown
    case camera
    case picture
    case menu
    case threads
    case download
    case text
    case plus
    case arrowTopRight
    case emoji
    case filters
    case stickers
    case addUsers
    case people
    case partnership
    case branded
    case next

    // MARK: - 16px Badges & Compact Icons
    case verifiedBadge
    case verifiedBadgeSmall
    case taggedBadge
    case soundOn
    case soundOff
    case lock
    case lockOpen
    case pinned
    case donation16
    case gift16
    case quietMode16
    case plays16
    case soundwave16
    case hashtag16
    case link16
    case facebook16

    // MARK: - 32px Jumbo Icons
    case instagramLogo32
    case like32(selected: Bool = false)
    case share32
    case share2026_32
    case music32
    case options32
    case comment32

    // MARK: - Controlled Fallback For System Utility Icons
    case system(name: String)

    // MARK: - Asset Resolution Logic
    func assetName(for colorScheme: ColorScheme? = nil) -> String? {
        switch self {
        case .home(let selected):
            return resolve(outline: "ic_24_home_outline", filled: "ic_24_home_filled", selected: selected)
        case .reels(let selected):
            return resolve(outline: "ic_24_reels_outline", filled: "ic_24_reels_filled", selected: selected)
        case .search(let selected):
            return resolve(outline: "ic_24_search_outline", filled: "ic_24_search_filled", selected: selected)
        case .profile(let selected):
            return resolve(outline: "ic_24_profile_outline", filled: "ic_24_profile_filled", selected: selected)
        case .create(let selected):
            return resolve(outline: "ic_24_create_outline", filled: "ic_24_creat_filled", selected: selected)
        case .createPost(let selected):
            return resolve(outline: "ic_24_create_post_outline", filled: "ic_24_create_post_filled", selected: selected)
        case .like(let selected):
            return resolve(outline: "ic_24_like_outline", filled: "ic_24_like_filled", selected: selected)
        case .save(let selected):
            return resolve(outline: "ic_24_save_outline", filled: "ic_24_save_filled", selected: selected)
        case .grid(let selected):
            return resolve(outline: "ic_24_grid_outline", filled: "ic_24_grid_filled", selected: selected)
        case .grid2026(let selected):
            return resolve(outline: "ic_24_grid_2026_outline", filled: "ic_24_grid_2026_filled", selected: selected)
        case .activity(let selected):
            return resolve(outline: "ic_24_notifications_off_outline", filled: "ic_24_activity_filled", selected: selected)
        case .star(let selected):
            return resolve(outline: "ic_24_star_round_outline", filled: "ic_24_star_filled", selected: selected)
        case .repost(let selected):
            return resolve(outline: "ic_24_repost_outline", filled: "ic_24_repost_filled", selected: selected)
        case .highlight(let selected):
            return resolve(outline: "ic_24_hightlight_outline", filled: "ic_24_hightlight_added_filled", selected: selected)
        case .tag(let selected):
            return resolve(outline: "ic_24_tag_outline", filled: "ic_24_tag_filled", selected: selected)
        case .exclusive(let selected):
            return resolve(outline: "ic_24_exclusive_outline", filled: "ic_24_exclusive_filled", selected: selected)

        case .comment:
            return "ic_24_comment_outline"
        case .share:
            return "ic_24_share_outline"
        case .share2026(let selected):
            return resolve(outline: "ic_24_share_2026_outline", filled: "ic_24_share_2026_filled", selected: selected)
        case .options:
            return "ic_24_options_outline"
        case .close:
            return "ic_24_close_outline"
        case .chevronLeft:
            return "ic_24_chevron_left_outline"
        case .chevronRight:
            return "ic_24_chevron_right_outline"
        case .chevronUp:
            return "ic_24_chevron_up_outline"
        case .chevronUpAlt:
            return "ic_24_chevron_up_alt_outline"
        case .chevronDown:
            return "ic_16_chevron_down_outline"
        case .camera:
            return "ic_24_camera_outline"
        case .picture:
            return "ic_24_picture_outline"
        case .menu:
            return "ic_24_menu_outline"
        case .threads:
            return "ic_24_threads_outline"
        case .download:
            return "ic_24_download_outline"
        case .text:
            return "ic_24_text_outline"
        case .plus:
            return "ic_24_plus_outline"
        case .arrowTopRight:
            return "ic_16_arrow_top_right_outline"
        case .emoji:
            return "ic_16_poll_outline"
        case .filters:
            return "ic_24_filters_filled"
        case .stickers:
            return "ic_24_stickers_outline"
        case .addUsers:
            return "ic_24_add_user_outline"
        case .people:
            return "ic_24_people_outline"
        case .partnership:
            return "ic_24_partnership_outline"
        case .branded:
            return "ic_24_branded_outline"
        case .next:
            return "ic_24_next_outline"

        case .verifiedBadge:
            return "ic_16_verified_badge_filled"
        case .verifiedBadgeSmall:
            return "ic_16_verified_badge_small_filled"
        case .taggedBadge:
            return "ic_16_tagged_filled"
        case .soundOn:
            return "ic_16_sound_on_filled"
        case .soundOff:
            return "ic_16_no_sound_filled"
        case .lock:
            return "ic_16_lock_outline"
        case .lockOpen:
            return "ic_16_lock_open_filled"
        case .pinned:
            return "ic_16_pinned_filled"
        case .donation16:
            return "ic_16_donation_filled"
        case .gift16:
            return "ic_16_gift_filled"
        case .quietMode16:
            return "ic_16_quiet_mode_filled"
        case .plays16:
            return "ic_16_plays_outline"
        case .soundwave16:
            return "ic_16_soundwave_outline"
        case .hashtag16:
            return "ic_16_hashtag_outline"
        case .link16:
            return "ic_16_link_outline"
        case .facebook16:
            return "ic_16_facebook_outline"

        case .instagramLogo32:
            return "ic_32_instagram_outline"
        case .like32(let selected):
            return resolve(outline: "ic_32_like_outline", filled: "ic_32_like_filled", selected: selected)
        case .share32:
            return "ic_32_share_outline"
        case .share2026_32:
            return "ic_32_share_2026_outline"
        case .music32:
            return "ic_32_music_outline"
        case .options32:
            return "ic_32_options_outline"
        case .comment32:
            return "ic_32_comment_outline"

        case .system:
            return nil
        }
    }

    private func resolve(outline: String, filled: String, selected: Bool) -> String {
        return selected ? filled : outline
    }
}

// MARK: - AppSticker Definition

enum AppSticker: String, CaseIterable, Sendable {
    // 18 Sheet Stickers
    case addYours = "sticker_sheet_add_yours"
    case addYoursTemplates = "sticker_sheet_add_yours_templates"
    case avatar = "sticker_sheet_avatar"
    case donation = "sticker_sheet_donation"
    case emoji = "sticker_sheet_emoji"
    case gif = "sticker_sheet_gif"
    case hashtag = "sticker_sheet_hashtag"
    case heartBlue = "sticker_sheet_heart_blue"
    case heartPink = "sticker_sheet_heart_pink"
    case link = "sticker_sheet_link"
    case location = "sticker_sheet_location"
    case mention = "sticker_sheet_mention"
    case music = "sticker_sheet_music"
    case notify = "sticker_sheet_notify"
    case poll = "sticker_sheet_poll"
    case questionReaction = "sticker_sheet_question_reaction"
    case questions = "sticker_sheet_questions"
    case quiz = "sticker_sheet_quiz"

    // 7 Interactive Badges
    case linkGradient = "sticker_badge_link_gradient"
    case linkSolidColor = "sticker_badge_link_solid_color"
    case linkTranslucent = "sticker_badge_link_translucent_background"
    case mentionGradient = "sticker_badge_mention_gradient"
    case mentionRainbow = "sticker_badge_mention_rainbow"
    case mentionSolidColor = "sticker_badge_mention_solid_color"
    case mentionTranslucent = "sticker_badge_mention_translucent_background"
}

// MARK: - InstagramIcon SwiftUI Component

struct InstagramIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: AppIcon
    var size: CGFloat
    var color: Color?

    init(
        _ icon: AppIcon,
        size: CGFloat = DS.Size.iconDefault,
        color: Color? = nil
    ) {
        self.icon = icon
        self.size = size
        self.color = color
    }

    var body: some View {
        Group {
            if case .system(let systemName) = icon {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color ?? ColorTokens.textPrimary)
            } else if let asset = icon.assetName(for: colorScheme) {
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color ?? ColorTokens.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
    }
}

// MARK: - InstagramStickerView SwiftUI Component

struct InstagramStickerView: View {
    let sticker: AppSticker
    var height: CGFloat

    init(_ sticker: AppSticker, height: CGFloat = 36) {
        self.sticker = sticker
        self.height = height
    }

    var body: some View {
        Image(sticker.rawValue)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
