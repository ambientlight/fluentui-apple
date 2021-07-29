//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit
import SwiftUI

/// Properties available to customize the state of the avatar
@objc public protocol MSFAvatarState {
    var accessibilityLabel: String? { get set }
    var backgroundColor: UIColor? { get set }
    var foregroundColor: UIColor? { get set }
    var hasPointerInteraction: Bool { get set }
    var hasRingInnerGap: Bool { get set }
    var image: UIImage? { get set }
    var imageBasedRingColor: UIImage? { get set }
    var isOutOfOffice: Bool { get set }
    var isRingVisible: Bool { get set }
    var isTransparent: Bool { get set }
    var presence: MSFAvatarPresence { get set }
    var primaryText: String? { get set }
    var ringColor: UIColor? { get set }
    var secondaryText: String? { get set }
    var size: MSFAvatarSize { get set }
    var style: MSFAvatarStyle { get set }
}

/// Properties available to customize the state of the avatar
class MSFAvatarStateImpl: NSObject, ObservableObject, MSFAvatarState {
    @Published var backgroundColor: UIColor?
    @Published var foregroundColor: UIColor?
    @Published var hasPointerInteraction: Bool = false
    @Published var hasRingInnerGap: Bool = true
    @Published var image: UIImage?
    @Published var imageBasedRingColor: UIImage?
    @Published var isOutOfOffice: Bool = false
    @Published var isRingVisible: Bool = false
    @Published var isTransparent: Bool = true
    @Published var presence: MSFAvatarPresence = .none
    @Published var primaryText: String?
    @Published var ringColor: UIColor?
    @Published var secondaryText: String?

    var size: MSFAvatarSize {
        get {
            return tokens.size
        }
        set {
            tokens.size = newValue
        }
    }

    var style: MSFAvatarStyle {
        get {
            return tokens.style
        }
        set {
            tokens.style = newValue
        }
    }

    var tokens: MSFAvatarTokens

    init(style: MSFAvatarStyle,
         size: MSFAvatarSize) {
        self.tokens = MSFAvatarTokens(style: style,
                                      size: size)
        super.init()
    }
}

/// View that represents the avatar
public struct AvatarView: View {
    @Environment(\.theme) var theme: FluentUIStyle
    @Environment(\.windowProvider) var windowProvider: FluentUIWindowProvider?
    @ObservedObject var tokens: MSFAvatarTokens
    @ObservedObject var state: MSFAvatarStateImpl

    public init(style: MSFAvatarStyle,
                size: MSFAvatarSize) {
        let state = MSFAvatarStateImpl(style: style,
                                       size: size)
        self.state = state
        self.tokens = state.tokens
    }

    // This initializer should be used by internal container views. These containers should first initialize
    // MSFAvatarStateImpl using style and size, and then use that state and this initializer in their ViewBuilder.
    internal init(_ avatarState: MSFAvatarStateImpl) {
        state = avatarState
        tokens = avatarState.tokens
    }

    public var body: some View {
        let style = tokens.style
        let presence = state.presence
        let shouldDisplayPresence = presence != .none
        let isRingVisible = state.isRingVisible
        let hasRingInnerGap = state.hasRingInnerGap
        let isTransparent = state.isTransparent
        let isOutOfOffice = state.isOutOfOffice
        let initialsString: String = ((style == .overflow) ? state.primaryText ?? "" : AvatarView.initialsText(fromPrimaryText: state.primaryText,
                                                                                                               secondaryText: state.secondaryText))
        let shouldUseCalculatedColors = !initialsString.isEmpty && style != .overflow

        let ringInnerGap: CGFloat = isRingVisible && hasRingInnerGap ? tokens.ringInnerGap : 0
        let ringThickness: CGFloat = isRingVisible ? tokens.ringThickness : 0
        let ringOuterGap: CGFloat = isRingVisible ? tokens.ringOuterGap : 0
        let avatarImageSize: CGFloat = tokens.avatarSize!
        let ringInnerGapSize: CGFloat = avatarImageSize + (ringInnerGap * 2)
        let ringSize: CGFloat = ringInnerGapSize + ( ringThickness * 2)
        let ringOuterGapSize: CGFloat = ringSize + (ringOuterGap * 2)
        let presenceIconSize: CGFloat = tokens.presenceIconSize!
        let presenceIconOutlineSize: CGFloat = presenceIconSize + (tokens.presenceIconOutlineThickness * 2)

        // Calculates the positioning of the presence icon ensuring its center is always on top of the avatar circle's edge
        let ringInnerGapRadius: CGFloat = (ringInnerGapSize / 2)
        let ringInnerGapHypotenuse: CGFloat = sqrt(2 * pow(ringInnerGapRadius, 2))
        let presenceIconHypotenuse: CGFloat = sqrt(2 * pow(presenceIconOutlineSize / 2, 2))
        let presenceFrameHypotenuse: CGFloat = ringInnerGapHypotenuse + ringInnerGapRadius + presenceIconHypotenuse
        let presenceIconFrameSideRelativeToInnerRing: CGFloat = sqrt(pow(presenceFrameHypotenuse, 2) / 2)

        // Creates positioning coordinates for the presence cutout (enabling the transparency of the presence icon)
        let outerGapAndRingThicknesCombined: CGFloat = ringOuterGap + ringThickness
        let presenceIconFrameDiffRelativeToOuterRing: CGFloat = ringOuterGapSize - (presenceIconFrameSideRelativeToInnerRing + outerGapAndRingThicknesCombined)
        let presenceCutoutOriginCoordinates: CGFloat = ringOuterGapSize - presenceIconFrameDiffRelativeToOuterRing - presenceIconOutlineSize
        let presenceIconFrameSideRelativeToOuterRing: CGFloat = presenceIconFrameSideRelativeToInnerRing + outerGapAndRingThicknesCombined
        let overallFrameSide = max(ringOuterGapSize, presenceIconFrameSideRelativeToOuterRing)

        let foregroundColor = state.foregroundColor ?? ( !shouldUseCalculatedColors ?
                                                            tokens.foregroundDefaultColor! :
                                                            AvatarView.initialsCalculatedColor(fromPrimaryText: state.primaryText,
                                                                                               secondaryText: state.secondaryText,
                                                                                               colorOptions: tokens.foregroundCalculatedColorOptions))
        let backgroundColor = state.backgroundColor ?? ( !shouldUseCalculatedColors ?
                                                            tokens.backgroundDefaultColor! :
                                                            AvatarView.initialsCalculatedColor(fromPrimaryText: state.primaryText,
                                                                                               secondaryText: state.secondaryText,
                                                                                               colorOptions: tokens.backgroundCalculatedColorOptions))
        let ringGapColor = Color(tokens.ringGapColor).opacity(isTransparent ? 0 : 1)
        let ringColor = !isRingVisible ? Color.clear : Color(state.ringColor ?? ( !shouldUseCalculatedColors ?
                                                                                    tokens.ringDefaultColor! :
                                                                                    backgroundColor))

        let shouldUseDefaultImage = (state.image == nil && initialsString.isEmpty && style != .overflow)
        let avatarImageInfo: (image: UIImage?, renderingMode: Image.TemplateRenderingMode) = {
            if style == .outlined || style == .outlinedPrimary {
                return (UIImage.staticImageNamed("person_48_regular"), .template)
            } else if shouldUseDefaultImage {
                return (UIImage.staticImageNamed("person_48_filled"), .template)
            } else {
                return (state.image, .original)
            }
        }()
        let avatarImageSizeRatio: CGFloat = (shouldUseDefaultImage) ? 0.7 : 1

        let accessibilityLabel: String = {
            if let overriddenAccessibilityLabel = state.accessibilityLabel {
                return overriddenAccessibilityLabel
            }

            let defaultAccessibilityText = state.primaryText ?? state.secondaryText ?? ""
            return (state.isOutOfOffice ?
                        String.localizedStringWithFormat("Accessibility.AvatarView.LabelFormat".localized, defaultAccessibilityText, "Presence.OOF".localized) :
                        defaultAccessibilityText)
        }()

        @ViewBuilder
        var avatarContent: some View {
            if let image = avatarImageInfo.image {
                Image(uiImage: image)
                    .renderingMode(avatarImageInfo.renderingMode)
                    .resizable()
                    .foregroundColor(Color(foregroundColor))
            } else {
                if #available(iOS 14.0, *) {
                    Text(initialsString)
                        .foregroundColor(Color(foregroundColor))
                        .font(Font(tokens.textFont))
                } else {
                    Text(initialsString)
                        .foregroundColor(Color(foregroundColor))
                        .font(Font(tokens.textFont))
                        // Workaround for iOS 13 only: disabling animations as a "flickering"
                        // happens as the text is truncated during the animation
                        .animation(.none)
                }
            }
        }

        // The avatarRingView is not available in the .group style.
        // This variable is not going to be computed in that scenario.
        @ViewBuilder
        var avatarRingView: some View {
            if let imageBasedRingColor = state.imageBasedRingColor {
                // The potentially maximum size of the ring view must be used in order to avoid abrupt
                // transitions during the animation as the ImagePaint scale value is not animatable.
                let ringMaxSize = avatarImageSize + (tokens.ringInnerGap + tokens.ringThickness) * 2
                let scaleFactor = ringMaxSize / imageBasedRingColor.size.width

                // ImagePaint is being used as creating a Color struct from a UIColor created with
                // the patternImage initializer (https://developer.apple.com/documentation/uikit/uicolor/1621933-init)
                // does not render any content.
                Circle()
                    .strokeBorder(ImagePaint(image: Image(uiImage: imageBasedRingColor),
                                             scale: scaleFactor),
                                  lineWidth: ringThickness)
            } else {
                Circle()
                    .strokeBorder(ringColor,
                                  lineWidth: ringThickness)
            }
        }

        @ViewBuilder
        var avatarBody: some View {
            if tokens.style == .group {
                avatarContent
                    .background(Rectangle()
                                    .frame(width: tokens.avatarSize, height: tokens.avatarSize, alignment: .center)
                                    .foregroundColor(Color(backgroundColor)))
                    .frame(width: tokens.avatarSize, height: tokens.avatarSize, alignment: .center)
                    .contentShape(RoundedRectangle(cornerRadius: tokens.borderRadius))
                    .clipShape(RoundedRectangle(cornerRadius: tokens.borderRadius))
            } else {
                Circle()
                    .foregroundColor(ringGapColor)
                    .frame(width: ringOuterGapSize, height: ringOuterGapSize, alignment: .center)
                    .overlay(avatarRingView
                                .frame(width: ringSize, height: ringSize, alignment: .center)
                                .overlay(Circle()
                                            .foregroundColor(Color(backgroundColor))
                                            .frame(width: avatarImageSize, height: avatarImageSize, alignment: .center)
                                            .overlay(avatarContent
                                                        .frame(width: avatarImageSize * avatarImageSizeRatio,
                                                               height: avatarImageSize * avatarImageSizeRatio,
                                                               alignment: .center)
                                                        .contentShape(Circle())
                                                        .clipShape(Circle())
                                                        .transition(.opacity),
                                                     alignment: .center)
                                )
                                .contentShape(Circle()),
                             alignment: .center)
                    .modifyIf(shouldDisplayPresence, { thisView in
                            thisView.mask(PresenceCutout(presenceCutoutOriginCoordinates: presenceCutoutOriginCoordinates,
                                                         presenceIconOutlineSize: presenceIconOutlineSize)
                                            .fill(style: FillStyle(eoFill: true)))
                                .overlay(Circle()
                                            .foregroundColor(Color(tokens.ringGapColor).opacity(isTransparent ? 0 : 1))
                                            .frame(width: presenceIconOutlineSize, height: presenceIconOutlineSize, alignment: .center)
                                            .overlay(presence.image(isOutOfOffice: isOutOfOffice)
                                                        .interpolation(.high)
                                                        .resizable()
                                                        .frame(width: presenceIconSize, height: presenceIconSize, alignment: .center)
                                                        .foregroundColor(presence.color(isOutOfOffice: isOutOfOffice)))
                                            .contentShape(Circle())
                                            .frame(width: presenceIconFrameSideRelativeToOuterRing, height: presenceIconFrameSideRelativeToOuterRing,
                                                   alignment: .bottomTrailing),
                                         alignment: .topLeading)
                                .frame(width: overallFrameSide, height: overallFrameSide, alignment: .topLeading)
                    })
            }
        }

        // iPad Pointer Interaction support
        var avatarBodyWithPointerInteraction: AnyView {
            if #available(iOS 13.4, *) {
                if state.hasPointerInteraction {
                    return AnyView(avatarBody.hoverEffect())
                }
            }

            return AnyView(avatarBody)
        }

        return avatarBodyWithPointerInteraction
            .animation(.linear(duration: animationDuration))
            .accessibilityElement(children: .ignore)
            .accessibility(addTraits: .isImage)
            .accessibility(label: Text(accessibilityLabel))
            .accessibility(value: Text(presence.string() ?? ""))
            .designTokens(tokens,
                          from: theme,
                          with: windowProvider)
    }

    private let animationDuration: Double = 0.1

    private struct PresenceCutout: Shape {
        var presenceCutoutOriginCoordinates: CGFloat
        var presenceIconOutlineSize: CGFloat

        var animatableData: AnimatablePair<CGFloat, CGFloat> {
            get {
                AnimatablePair(presenceCutoutOriginCoordinates, presenceIconOutlineSize)
            }

            set {
                presenceCutoutOriginCoordinates = newValue.first
                presenceIconOutlineSize = newValue.second
            }
        }

        func path(in rect: CGRect) -> Path {
            var cutoutFrame = Rectangle().path(in: rect)
            cutoutFrame.addPath(Circle().path(in: CGRect(x: presenceCutoutOriginCoordinates,
                                                         y: presenceCutoutOriginCoordinates,
                                                         width: presenceIconOutlineSize,
                                                         height: presenceIconOutlineSize)))
            return cutoutFrame
        }
    }

    private static func initialsHashCode(fromPrimaryText primaryText: String?, secondaryText: String?) -> Int {
        var combined: String
        if let secondaryText = secondaryText, let primaryText = primaryText, secondaryText.count > 0 {
            combined = primaryText + secondaryText
        } else if let primaryText = primaryText {
            combined = primaryText
        } else {
            combined = ""
        }

        let combinedHashable = combined as NSString
        return Int(abs(javaHashCode(combinedHashable)))
    }

    private static func initialsCalculatedColor(fromPrimaryText primaryText: String?, secondaryText: String?, colorOptions: [UIColor]? = nil) -> UIColor {
        guard let colors = colorOptions else {
            return .black
        }

        // Set the color based on the primary text and secondary text
        let hashCode = initialsHashCode(fromPrimaryText: primaryText, secondaryText: secondaryText)
        return colors[hashCode % colors.count]
    }

    private static func initialsText(fromPrimaryText primaryText: String?, secondaryText: String?) -> String {
        var initials = ""

        if let primaryText = primaryText, primaryText.count > 0 {
            initials = initialLetters(primaryText)
        } else if let secondaryText = secondaryText, secondaryText.count > 0 {
            // Use first letter of the secondary text
            initials = String(secondaryText.prefix(1))
        }

        return initials.uppercased()
    }

    private static func initialLetters(_ text: String) -> String {
        var initials = ""

        // Use the leading character from the first two words in the user's name
        let nameComponents = text.components(separatedBy: " ")
        for nameComponent: String in nameComponents {
            let trimmedName = nameComponent.trimmed()
            if trimmedName.count < 1 {
                continue
            }
            let initial = trimmedName.index(trimmedName.startIndex, offsetBy: 0)
            let initialLetter = String(trimmedName[initial])
            let initialUnicodeScalars = initialLetter.unicodeScalars
            let initialUnicodeScalar = initialUnicodeScalars[initialUnicodeScalars.startIndex]
            // Discard name if first char is not a letter
            let isInitialLetter: Bool = initialLetter.count > 0 && CharacterSet.letters.contains(initialUnicodeScalar)
            if isInitialLetter && initials.count < 2 {
                initials += initialLetter
            }
        }

        return initials
    }

    /// To ensure iOS and Android achieve the same result when generating string hash codes (e.g. to determine avatar colors) we've copied Java's String implementation of `hashCode`.
    /// Must use Int32 as JVM specification is 32-bits for ints
    /// - Returns: hash code of string
    private static func javaHashCode(_ text: NSString) -> Int32 {
        var hash: Int32 = 0
        for i in 0..<text.length {
            // Allow overflows, mimicking Java behavior
            hash = 31 &* hash &+ Int32(text.character(at: i))
        }
        return hash
    }
}

/// UIKit wrapper that exposes the SwiftUI Avatar implementation
@objc open class MSFAvatar: NSObject, FluentUIWindowProvider {

    @objc open var view: UIView {
        return hostingController.view
    }

    @objc open var state: MSFAvatarState {
        return self.avatarview.state
    }

    @objc public convenience init(style: MSFAvatarStyle = .default,
                                  size: MSFAvatarSize = .large) {
        self.init(style: style,
                  size: size,
                  theme: nil)
    }

    @objc public init(style: MSFAvatarStyle = .default,
                      size: MSFAvatarSize = .large,
                      theme: FluentUIStyle? = nil) {
        super.init()

        avatarview = AvatarView(style: style,
                                size: size)
        hostingController = UIHostingController(rootView: AnyView(avatarview
                                                                    .windowProvider(self)
                                                                    .modifyIf(theme != nil, { avatarview in
                                                                        avatarview.customTheme(theme!)
                                                                    })))
        hostingController.disableSafeAreaInsets()
        view.backgroundColor = UIColor.clear
    }

    var window: UIWindow? {
        return self.view.window
    }

    private var hostingController: UIHostingController<AnyView>!

    private var avatarview: AvatarView!
}