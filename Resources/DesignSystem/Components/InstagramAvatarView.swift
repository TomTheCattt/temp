//
//  InstagramAvatarView.swift
//  Instagram
//
//  Created by Antigravity on 16/10/26.
//

import SwiftUI
import NukeUI

// MARK: - InstagramAvatarView

struct InstagramAvatarView: View {

    let url: URL?
    var size: CGFloat = DS.Size.avatarList
    var hasStory: Bool = false
    var isStoryViewed: Bool = false
    var showPlusBadge: Bool = false
    var onTap: (() -> Void)? = nil

    init(
        url: URL?,
        size: CGFloat = DS.Size.avatarList,
        hasStory: Bool = false,
        isStoryViewed: Bool = false,
        showPlusBadge: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.url = url
        self.size = size
        self.hasStory = hasStory
        self.isStoryViewed = isStoryViewed
        self.showPlusBadge = showPlusBadge
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                avatarContent
                    .padding(ringPadding)
                    .background(ringBackground)

                if showPlusBadge {
                    plusBadge
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    // MARK: - Avatar Image Content

    private var avatarContent: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(ColorTokens.buttonSecondary)
                    .overlay {
                        InstagramIcon(
                            .system(name: "person.fill"),
                            size: size * 0.45,
                            color: ColorTokens.textTertiary
                        )
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: - Story Ring

    private var ringPadding: CGFloat {
        hasStory ? DS.Spacing.xxxs : 0
    }

    @ViewBuilder
    private var ringBackground: some View {
        if hasStory {
            if isStoryViewed {
                Circle()
                    .strokeBorder(ColorTokens.stroke, lineWidth: DS.Stroke.medium)
            } else {
                Circle()
                    .strokeBorder(ColorTokens.storyGradient, lineWidth: DS.Stroke.medium)
            }
        }
    }

    // MARK: - Plus Badge

    private var plusBadge: some View {
        InstagramIcon(
            .system(name: "plus.circle.fill"),
            size: max(14, size * 0.32),
            color: ColorTokens.brandBlue
        )
        .background(Circle().fill(ColorTokens.backgroundPrimary))
        .offset(x: 2, y: 2)
    }
}
