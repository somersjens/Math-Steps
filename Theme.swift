//
//  Theme.swift
//  Elephant Challenge: Math Memory
//
//  Character catalog: 10 animals, each with a clearly different colour and a
//  matching visual theme for the whole app. Characters are earned by collecting
//  cards; the requirements live in `GameConfig.characterUnlockRequirements`.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The game's currency. Every character collects the same trophy: on a correct
/// landing, on the menu totals, on the level cards and in the shop. One glyph,
/// used everywhere, so the same thing is never drawn two ways.
enum Currency {
    static let icon = "trophy.fill"
}

/// The trophy used anywhere a score is shown. It is the same symbol for every
/// character and takes its colour from the surrounding foreground style.
struct CurrencyIcon: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: Currency.icon)
            .font(.system(size: size, weight: .regular))
            .frame(width: size, height: size)
    }
}

#if canImport(UIKit)
/// Decode a catalog PNG once and, when it is larger than anything on screen,
/// shrink it before it is cached. Hanging layers and portraits are authored
/// around 1250px; the largest on-screen slot is the 280pt Premium hero.
nonisolated enum DisplayPreparedImage {
    static func make(named name: String, maxPixel: CGFloat) -> UIImage {
        let image = UIImage(named: name) ?? UIImage()
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        if longest > maxPixel + 1, longest > 0 {
            let scale = maxPixel / longest
            let size = CGSize(width: max(1, (pixelWidth * scale).rounded()),
                              height: max(1, (pixelHeight * scale).rounded()))
            if let thumb = image.preparingThumbnail(of: size) {
                return thumb
            }
        }
        return image.preparingForDisplay() ?? image
    }
}

/// Decode portrait sprites once. Opening the collection used to pay PNG
/// decompression for ten characters on the sheet's first frame.
enum CharacterArtworkCache {
    private static let lock = NSLock()
    private static var images: [String: UIImage] = [:]
    private static var thumbnails: [String: UIImage] = [:]

    /// Use the trait environment UIKit has made current for this rendering
    /// context. It can be unspecified during an early prewarm, in which case
    /// the conservative 3x fallback keeps the cache sharp on every iPhone.
    private static var displayScale: CGFloat {
        let scale = UITraitCollection.current.displayScale
        return scale > 0 ? scale : 3
    }

    /// Longest on-screen portrait is the Premium hero (280pt). Keep a little
    /// headroom for iPad 3x without uploading the full authored canvas.
    private static var displayPixelSide: CGFloat {
        min(1024, (320 * displayScale).rounded())
    }

    static func prewarm() {
        for character in CharacterCatalog.all {
            _ = front(named: character.imageName)
        }
    }

    /// Decode the five loose hanging layers for the selected animal so the
    /// menu and the first claw-game frame do not hitch on PNG decompression.
    /// The composite portrait is included because the collection hero reads it.
    static func prewarmHanging(for character: AnimalCharacter) {
        _ = front(named: character.imageName)
        for name in character.hanging.layerNames {
            _ = front(named: name)
        }
    }

    static func front(named name: String) -> UIImage {
        lock.lock()
        if let cached = images[name] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        let decoded = DisplayPreparedImage.make(named: name, maxPixel: displayPixelSide)
        lock.lock()
        if let cached = images[name] {
            lock.unlock()
            return cached
        }
        images[name] = decoded
        lock.unlock()
        return decoded
    }

    /// Grid cells are ~44pt. Uploading the full portrait sprite for every
    /// character on the collection sheet is wasted GPU bandwidth.
    static func thumbnail(named name: String, side: CGFloat) -> UIImage {
        let key = "\(name)-\(Int((side * 2).rounded()))"
        lock.lock()
        if let cached = thumbnails[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        let pixels = max(1, side * displayScale)
        let sized = DisplayPreparedImage.make(named: name, maxPixel: pixels)
        lock.lock()
        if let cached = thumbnails[key] {
            lock.unlock()
            return cached
        }
        thumbnails[key] = sized
        lock.unlock()
        return sized
    }
}
#endif

struct AnimalCharacter: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    /// Position in the catalog, 1-based. Hanging layers use a separate index
    /// (elephant is `1_*`, octopus `2_*`, crab `3_*`, then slot and hanging
    /// index match).
    let slot: Int

    // Colour components (0–1).
    let primaryRGB: (Double, Double, Double)
    let deepRGB: (Double, Double, Double)
    let skyRGB: (Double, Double, Double)
    let tintRGB: (Double, Double, Double)

    static func == (lhs: AnimalCharacter, rhs: AnimalCharacter) -> Bool {
        lhs.id == rhs.id
    }

    var color: Color { Color(red: primaryRGB.0, green: primaryRGB.1, blue: primaryRGB.2) }
    var deepColor: Color { Color(red: deepRGB.0, green: deepRGB.1, blue: deepRGB.2) }
    var skyColor: Color { Color(red: skyRGB.0, green: skyRGB.1, blue: skyRGB.2) }
    var tintColor: Color { Color(red: tintRGB.0, green: tintRGB.1, blue: tintRGB.2) }

    /// Facing the player: menus, cards, the shop and every portrait slot.
    /// All ten hanging canvases share one hook alignment, so one square frame
    /// renders any character at the same apparent size.
    var imageName: String { hanging.mainImageName }

    /// A standalone, menu-friendly portrait when one has been supplied for
    /// this animal. Keep this mapping explicit: the portrait numbering is
    /// independent from both the catalog slot and the hanging-layer prefix.
    var menuPortraitImageName: String? {
        switch id {
        case "dog": "1"
        case "lion": "2"
        case "octopus": "3"
        case "crab": "4"
        case "elephant": "5"
        case "bear": "6"
        case "fox": "7"
        case "frog": "8"
        case "penguin": "9"
        case "bunny": "10"
        default: nil
        }
    }

    /// The standalone portraits were authored on slightly different canvases.
    /// Keep their visible silhouettes centred without rewriting the source PNGs.
    /// Values are fractions of the requested portrait side so the correction is
    /// identical in the compact header, collection grid and large hero views.
    var menuPortraitOffset: CGSize {
        switch id {
        case "lion": CGSize(width: 0.003, height: 0.056)
        case "octopus": CGSize(width: -0.018, height: 0.035)
        case "crab": CGSize(width: 0.018, height: 0.003)
        case "elephant": CGSize(width: 0.006, height: 0.052)
        case "bear": CGSize(width: -0.001, height: 0.051)
        case "fox": CGSize(width: 0.011, height: 0.028)
        case "frog": CGSize(width: 0.001, height: 0.037)
        case "penguin": CGSize(width: 0.018, height: 0.026)
        case "bunny": CGSize(width: -0.010, height: 0.023)
        default: .zero // The dog's visible bounds are already centred.
        }
    }

    /// The penguin's broad raised wings make it read larger than the other
    /// portraits even though the source canvases have comparable dimensions.
    var menuPortraitScale: CGFloat {
        id == "penguin" ? 0.92 : 1
    }

    /// Layer names, arm pivots and grab reach for the hanging / claw artwork.
    var hanging: HangingCharacterRig { HangingCharacterRig.forID(id) }
    var artwork: Image {
#if canImport(UIKit)
        Image(uiImage: CharacterArtworkCache.front(named: imageName))
#else
        Image(imageName)
#endif
    }

    /// Sized for catalog cells so the collection sheet does not upload ten
    /// full-resolution portraits at 44pt.
    func cellArtwork(side: CGFloat) -> Image {
#if canImport(UIKit)
        Image(uiImage: CharacterArtworkCache.thumbnail(named: imageName, side: side))
#else
        artwork
#endif
    }

    /// Localized display name, resolved per language from the string catalog
    /// ("character.fox", "character.frog", …).
    var localizedName: String {
        L(key: "character.\(id)")
    }
}

/// Uses the standalone portrait where one exists, while allowing each screen
/// to retain its current artwork until that animal receives a portrait too.
/// Supplying the rendered point size also lets the image cache decode a small
/// header icon and a large Premium hero at appropriate resolutions.
struct CharacterMenuPortrait<Fallback: View>: View {
    let character: AnimalCharacter
    let side: CGFloat
    private let fallback: Fallback

    init(character: AnimalCharacter,
         side: CGFloat,
         @ViewBuilder fallback: () -> Fallback) {
        self.character = character
        self.side = side
        self.fallback = fallback()
    }

    @ViewBuilder
    var body: some View {
        if let imageName = character.menuPortraitImageName {
#if canImport(UIKit)
            Image(uiImage: CharacterArtworkCache.thumbnail(named: imageName, side: side))
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .scaleEffect(character.menuPortraitScale)
                .offset(x: side * character.menuPortraitOffset.width,
                        y: side * character.menuPortraitOffset.height)
#else
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .scaleEffect(character.menuPortraitScale)
                .offset(x: side * character.menuPortraitOffset.width,
                        y: side * character.menuPortraitOffset.height)
#endif
        } else {
            fallback
                .frame(width: side, height: side)
        }
    }
}

/// Per-animal hanging artwork: the five loose layers share one 1254² canvas
/// whose hook sits at the same top-centre, but the front limbs (or crab claws,
/// or octopus grab-tentacles) attach at different places. Grab rotation and
/// the nut's rest point are therefore authored per character, not shared.
struct HangingCharacterRig: Equatable {
    let mainImageName: String
    let claw: String
    let bottom: String
    let head: String
    let leftArm: String
    let rightArm: String
    /// Shoulder-ish pivot in the square canvas. Hidden behind the face as the
    /// limb rotates in to hold a walnut.
    let leftArmPivot: UnitPoint
    let rightArmPivot: UnitPoint
    /// Inward rotation of each front limb at full grip, in degrees.
    let armCloseDegrees: Double
    /// Distance from the hook (top of the canvas) to the palms, as a fraction
    /// of the square side. Descent, carry and targeting all use this point.
    let gripReach: CGFloat
    /// Resting contact of each grabbing limb, canvas-normalised. A nut under a
    /// paw, claw, tentacle or flipper still counts — not only one under the face.
    let leftGripX: CGFloat
    let rightGripX: CGFloat
    /// Keep this fraction of `bottom` from the canvas floor. Several bottom
    /// plates still contain a stray hook remnant at the very top.
    let bottomVisibleFraction: CGFloat

    var layerNames: [String] { [claw, bottom, head, leftArm, rightArm] }

    static func forID(_ id: String) -> HangingCharacterRig {
        if let rig = table[id] { return rig }
        assertionFailure("Missing hanging rig for \(id)")
        return table["elephant"]!
    }

    private static let table: [String: HangingCharacterRig] = [
        "elephant": .layers(1, leftPivot: (0.36, 0.76), rightPivot: (0.64, 0.76),
                            close: 17, grip: 0.92, grips: (0.353, 0.645)),
        "octopus": .layers(2, leftPivot: (0.38, 0.70), rightPivot: (0.62, 0.70),
                           close: 11, grip: 0.943, grips: (0.396, 0.628)),
        // Crab limbs are authored as claws, not arms.
        "crab": .layers(3, leftArm: "3_left_claw", rightArm: "3_right_claw",
                        leftPivot: (0.38, 0.80), rightPivot: (0.62, 0.80),
                        close: 15, grip: 0.952, grips: (0.383, 0.628)),
        "bear": .layers(4, leftPivot: (0.36, 0.79), rightPivot: (0.64, 0.79),
                        close: 22, grip: 0.936, grips: (0.342, 0.652)),
        // Source file is named `5_left_arn` (typo in the imageset).
        "fox": .layers(5, leftArm: "5_left_arn",
                       leftPivot: (0.38, 0.78), rightPivot: (0.62, 0.78),
                       close: 21, grip: 0.945, grips: (0.346, 0.655)),
        "frog": .layers(6, leftPivot: (0.39, 0.78), rightPivot: (0.61, 0.78),
                        close: 22, grip: 0.964, grips: (0.321, 0.673)),
        "penguin": .layers(7, leftPivot: (0.40, 0.75), rightPivot: (0.60, 0.75),
                           close: 22, grip: 0.951, grips: (0.302, 0.703)),
        "bunny": .layers(8, leftPivot: (0.36, 0.78), rightPivot: (0.64, 0.78),
                         close: 24, grip: 0.912, grips: (0.338, 0.659)),
        "dog": .layers(9, leftPivot: (0.37, 0.79), rightPivot: (0.63, 0.79),
                       close: 20, grip: 0.948, grips: (0.358, 0.656)),
        "lion": .layers(10, leftPivot: (0.37, 0.76), rightPivot: (0.63, 0.76),
                        close: 16, grip: 0.951, grips: (0.353, 0.640))
    ]

    private static func layers(
        _ index: Int,
        leftArm: String? = nil,
        rightArm: String? = nil,
        leftPivot: (CGFloat, CGFloat),
        rightPivot: (CGFloat, CGFloat),
        close: Double,
        grip: CGFloat,
        grips: (CGFloat, CGFloat),
        bottomVisibleFraction: CGFloat = 0.76
    ) -> HangingCharacterRig {
        HangingCharacterRig(
            mainImageName: "\(index)_main",
            claw: "\(index)_claw",
            bottom: "\(index)_bottom",
            head: "\(index)_head",
            leftArm: leftArm ?? "\(index)_left_arm",
            rightArm: rightArm ?? "\(index)_right_arm",
            leftArmPivot: UnitPoint(x: leftPivot.0, y: leftPivot.1),
            rightArmPivot: UnitPoint(x: rightPivot.0, y: rightPivot.1),
            armCloseDegrees: close,
            gripReach: grip,
            leftGripX: grips.0,
            rightGripX: grips.1,
            bottomVisibleFraction: bottomVisibleFraction
        )
    }
}

/// The hanging body rebuilt from the same four loose layers as the claw game.
/// The claw layer is deliberately absent. `bottom` is masked so leftover hook
/// pixels at the top of that plate cannot peek above the animal.
struct HooklessCharacterArtwork: View {
    let character: AnimalCharacter

    var body: some View {
        let rig = character.hanging
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                hangingLayer(rig.bottom)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: side * rig.bottomVisibleFraction)
                    }
                hangingLayer(rig.leftArm)
                hangingLayer(rig.rightArm)
                hangingLayer(rig.head)
            }
            .frame(width: side, height: side)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// The complete hanging character, rebuilt in the same layer order as the claw
/// game. Drawn outside the menu card so the hook and rope can sit in open air.
struct HangingCharacterArtwork: View {
    let character: AnimalCharacter

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                hangingLayer(character.hanging.claw)
                HooklessCharacterArtwork(character: character)
            }
            .frame(width: side, height: side)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Square portrait treatment used by compact character slots. Menus hang the
/// complete layered artwork; cards may explicitly request the body-only
/// composition above.
struct CroppedCharacterPortrait: View {
    let character: AnimalCharacter
    var elephantScale: CGFloat = 1.08
    var elephantYOffset: CGFloat = -0.045
    var otherCharacterScale: CGFloat = 1
    var usesHooklessElephant = false

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            Group {
                if usesHooklessElephant {
                    HooklessCharacterArtwork(character: character)
                } else {
                    HangingCharacterArtwork(character: character)
                }
            }
                .frame(width: side, height: side)
                .scaleEffect(elephantScale)
                .offset(y: side * elephantYOffset)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipped()
    }
}

/// A deterministic fallback for installations where the optional layered
/// character catalog is not bundled. Gameplay cards must never reserve a
/// conspicuous empty portrait slot just because one artwork set is absent.
enum CharacterArtworkAvailability {
    static func hasLayeredArtwork(for character: AnimalCharacter) -> Bool {
#if canImport(UIKit)
        UIImage(named: character.imageName) != nil
            && character.hanging.layerNames.allSatisfy { UIImage(named: $0) != nil }
#else
        true
#endif
    }
}

struct CharacterPlaceholderArtwork: View {
    let character: AnimalCharacter

    var body: some View {
        Image(systemName: "pawprint.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                LinearGradient(colors: [character.color, character.deepColor],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .accessibilityHidden(true)
    }
}

private func hangingLayer(_ name: String) -> some View {
#if canImport(UIKit)
    Image(uiImage: CharacterArtworkCache.front(named: name))
        .resizable()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
    Image(name)
        .resizable()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
}

enum CharacterCatalog {
    /// The character available from the very first card.
    static let freeCharacterID = CharacterUnlocks.starterCharacterID

    /// The localized fallback used when the player leaves their name empty.
    /// Resolve it through the character catalog so it can never drift from the
    /// name shown for the starter character in the active language.
    static var defaultPlayerName: String {
        character(id: freeCharacterID).localizedName
    }

    /// Order must match `CharacterUnlocks.orderedCharacterIDs`; a test asserts it.
    ///
    /// Every palette is sampled from that character's own artwork, so the reef,
    /// the menu and the motion trail behind a portrait all carry the colours
    /// the player is actually looking at.
    static let all: [AnimalCharacter] = [
        AnimalCharacter(id: "dog", name: "Dog", emoji: "🐶", slot: 9,
                        primaryRGB: (0.20, 0.66, 0.69), deepRGB: (0.06, 0.42, 0.46),
                        skyRGB: (0.89, 0.97, 0.98), tintRGB: (0.81, 0.95, 0.96)),
        AnimalCharacter(id: "lion", name: "Lion", emoji: "🦁", slot: 10,
                        primaryRGB: (0.95, 0.74, 0.20), deepRGB: (0.68, 0.45, 0.08),
                        skyRGB: (1.00, 0.96, 0.87), tintRGB: (1.00, 0.94, 0.77)),
        AnimalCharacter(id: "octopus", name: "Octopus", emoji: "🐙", slot: 1,
                        primaryRGB: (0.62, 0.40, 0.87), deepRGB: (0.35, 0.18, 0.60),
                        skyRGB: (0.93, 0.88, 0.99), tintRGB: (0.88, 0.79, 0.98)),
        AnimalCharacter(id: "crab", name: "Crab", emoji: "🦀", slot: 2,
                        primaryRGB: (0.90, 0.27, 0.10), deepRGB: (0.62, 0.13, 0.03),
                        skyRGB: (1.00, 0.90, 0.87), tintRGB: (1.00, 0.82, 0.77)),
        AnimalCharacter(id: "elephant", name: "Elephant", emoji: "🐘", slot: 3,
                        primaryRGB: (1.00, 0.59, 0.54), deepRGB: (0.76, 0.31, 0.28),
                        skyRGB: (1.00, 0.91, 0.89), tintRGB: (0.98, 0.77, 0.74)),
        AnimalCharacter(id: "bear", name: "Bear", emoji: "🐻", slot: 4,
                        primaryRGB: (0.72, 0.44, 0.16), deepRGB: (0.42, 0.20, 0.06),
                        skyRGB: (0.99, 0.94, 0.88), tintRGB: (0.98, 0.89, 0.79)),
        AnimalCharacter(id: "fox", name: "Fox", emoji: "🦊", slot: 5,
                        primaryRGB: (0.94, 0.60, 0.26), deepRGB: (0.68, 0.30, 0.07),
                        skyRGB: (1.00, 0.94, 0.87), tintRGB: (1.00, 0.89, 0.77)),
        AnimalCharacter(id: "frog", name: "Frog", emoji: "🐸", slot: 6,
                        primaryRGB: (0.45, 0.76, 0.18), deepRGB: (0.12, 0.47, 0.15),
                        skyRGB: (0.93, 0.99, 0.88), tintRGB: (0.88, 0.97, 0.80)),
        AnimalCharacter(id: "penguin", name: "Penguin", emoji: "🐧", slot: 7,
                        primaryRGB: (0.22, 0.36, 0.68), deepRGB: (0.08, 0.16, 0.38),
                        skyRGB: (0.89, 0.92, 0.98), tintRGB: (0.81, 0.86, 0.96)),
        AnimalCharacter(id: "bunny", name: "Bunny", emoji: "🐰", slot: 8,
                        primaryRGB: (0.94, 0.56, 0.60), deepRGB: (0.72, 0.29, 0.37),
                        skyRGB: (1.00, 0.87, 0.89), tintRGB: (0.99, 0.78, 0.80))
    ]

    static func character(id: String) -> AnimalCharacter {
        all.first { $0.id == id } ?? all[0]
    }

    /// The first half of the catalog: earned purely by collecting cards.
    static var cardCharacters: [AnimalCharacter] {
        all.filter { !CharacterUnlocks.premiumCharacterIDs.contains($0.id) }
    }

    /// The second half: still earnable with cards, but Premium grants them at once.
    static var premiumCharacters: [AnimalCharacter] {
        all.filter { CharacterUnlocks.premiumCharacterIDs.contains($0.id) }
    }

    /// The selected character, falling back to the starter when the selected
    /// one is not available (yet).
    static func current(isPremium: Bool) -> AnimalCharacter {
        let selected = character(id: GameSettings.characterID)
        if !CharacterUnlockStore.canUse(characterID: selected.id, isPremium: isPremium) {
            return character(id: freeCharacterID)
        }
        return selected
    }
}

/// Character access, derived from the player's card total so an unlock can
/// never be lost through a missed animation. Only the one-time celebration
/// receipt is stored separately.
enum CharacterUnlockStore {
    static var totalCards: Int {
        get { Progress.store.totalCards }
        set { Progress.store.totalCards = newValue }
    }

    /// Cards required for a character, or nil when it is not card-unlockable.
    static func requirement(for characterID: String) -> Int? {
        CharacterUnlocks.cardsRequired(for: characterID)
    }

    static func canUse(characterID: String, isPremium: Bool) -> Bool {
        if GameSettings.allCharactersUnlockedForSelfTest { return true }
        return CharacterUnlocks.isUnlocked(characterID: characterID,
                                           totalCards: totalCards,
                                           isPremium: isPremium)
    }

    static var selfTestUnlocksAll: Bool {
        GameSettings.allCharactersUnlockedForSelfTest
    }

    static func unlockAllForSelfTest() {
        GameSettings.allCharactersUnlockedForSelfTest = true
    }

    /// The next animal still to be earned, for the home screen and reminders.
    static func nextMilestone() -> (character: AnimalCharacter, remaining: Int)? {
        guard !selfTestUnlocksAll else { return nil }
        guard let next = CharacterUnlocks.nextMilestone(totalCards: totalCards) else { return nil }
        return (CharacterCatalog.character(id: next.characterID), next.remaining)
    }

    /// Characters that crossed their requirement but have not been celebrated.
    static func unannouncedUnlocks(at total: Int) -> [AnimalCharacter] {
        let announced = Progress.store.announcedUnlocks
        return CharacterUnlocks.unlockedCharacterIDs(totalCards: total)
            .filter { $0 != CharacterCatalog.freeCharacterID && !announced.contains($0) }
            .map { CharacterCatalog.character(id: $0) }
    }

    static func markAnnounced(_ characterID: String) {
        var announced = Progress.store.announcedUnlocks
        announced.insert(characterID)
        Progress.store.announcedUnlocks = announced
    }
}
