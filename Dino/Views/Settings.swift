import SwiftUI
#if DEBUG
import Darwin
#endif

/// One settings list: Game Center, language, preferences and a guarded reset.
struct DinoSettingsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @EnvironmentObject private var cloudSync: DinoCloudSync
    @EnvironmentObject private var friends: FriendsManager
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var showsPrivacy = false
    @State private var showsGameCenter = false
    @State private var showsLanguages = false
    @State private var showsCloudHelp = false
    @State private var showsDayParts = false
    @State private var challenge = ResetChallenge.make()
    @State private var resetAnswer = ""
    /// Full page size, kept while the keyboard is up so the reset card does not rebuild under the focused field.
    @State private var resetPageWidth: CGFloat = 0
    @State private var resetPageHeight: CGFloat = 0
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let spacious = geometry.size.width >= 650 && verticalSizeClass != .compact
                let resetHeight = resetPageHeight > 1 ? resetPageHeight : geometry.size.height
                ZStack {
                    if spacious {
                        let columns = geometry.size.width >= 740 && geometry.size.width > geometry.size.height
                        ScrollView {
                            VStack(spacing: 0) {
                                heading(spacious: true)
                                menu(spacious: true, columns: columns)
                                done(spacious: true)
                            }
                            .padding(.bottom, 22)
                            .frame(maxWidth: columns ? 900 : 820)
                            .padding(.horizontal, 24).frame(maxWidth: .infinity)
                            .modifier(ShortScrollCentering(height: geometry.size.height))
                        }.centersShortContent().bouncesOnlyWhenNeeded()
                            .accessibilityIdentifier("settings.options")
                    } else {
                        VStack(spacing: 0) {
                            heading(spacious: false)
                            ScrollView {
                                menu(spacious: false).padding(.horizontal, 16).padding(.bottom, 20)
                                    .frame(maxWidth: 760).frame(maxWidth: .infinity)
                            }.accessibilityIdentifier("settings.options")
                            done(spacious: false)
                                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 18)
                                .frame(maxWidth: .infinity)
                                .background(DinoStyle.paper.opacity(0.97))
                        }
                    }
                    if confirmReset {
                        Color.black.opacity(0.28).ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DinoAnswerFeedback.shared.playSelect()
                                confirmReset = false
                            }
                        ScrollView {
                            ResetConfirmationPage(minimumHeight: resetHeight) {
                                Color.clear
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        DinoAnswerFeedback.shared.playSelect()
                                        confirmReset = false
                                    }
                                    .accessibilityHidden(true)
                                resetCard(compact: resetHeight < 700, spacious: spacious)
                                    .padding(16)
                                    .zIndex(1)
                            }
                        }.bouncesOnlyWhenNeeded()
                            .frame(maxWidth: spacious ? 580 : 460)
                    }
                }.background(JungleBackground(quiet: true))
                    .onAppear { rememberResetPage(geometry.size) }
                    .onValueChange(of: geometry.size) { rememberResetPage($0) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsPrivacy) { DinoSocialPrivacyView().pagePresentation() }
            .sheet(isPresented: $showsGameCenter) { DinoFriendsView().gameEnvironment().pagePresentation() }
            .sheet(isPresented: $showsLanguages) { LanguagePicker().pagePresentation() }
            .sheet(isPresented: $showsDayParts) {
                DinoDayPartScheduleEditor(schedule: settings.dayPartSchedule)
                    .pagePresentation()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }.foregroundStyle(DinoStyle.ink)
            .onValueChange(of: confirmReset) { shown in
                if shown {
                    challenge = ResetChallenge.make()
                    resetAnswer = ""
                }
            }
    }

    private func heading(spacious: Bool) -> some View {
        Text("dino.settings")
            .font(.system(size: spacious ? 39 : 28, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity).padding(.top, 28).padding(.bottom, 18)
            .accessibilityIdentifier("settings.title")
    }

    private func done(spacious: Bool) -> some View {
        Button("dino.done") { dismiss() }
            .buttonStyle(DinoButtonStyle(customization: spacious))
            .environment(\.customizationTypeScale, spacious ? 1.3 : 1)
            .accessibilityIdentifier("settings.done")
            .padding(.top, spacious ? 20 : 0)
    }

    private func menu(spacious: Bool, columns: Bool = false) -> some View {
        Group {
            if columns {
                HStack(alignment: .top, spacing: 20) {
                    menuCard {
                        linkedRows(spacious: true)
                        rowDivider
                        privacyAndReset(spacious: true)
                    }
                    menuCard { preferenceRows(spacious: true) }
                }
            } else {
                menuCard {
                    linkedRows(spacious: spacious)
                    rowDivider
                    preferenceRows(spacious: spacious)
                    rowDivider
                    privacyAndReset(spacious: spacious)
                }.frame(maxWidth: spacious ? .infinity : 760)
            }
        }.frame(maxWidth: .infinity)
    }

    private func linkedRows(spacious: Bool) -> some View {
        Group {
            linkedRow(identifier: "settings.gameCenter", spacious: spacious) { showsGameCenter = true } icon: {
                Image(systemName: "person.crop.circle.fill")
            } title: {
                if let name = friends.playerDisplayName {
                    Text(verbatim: name).accessibilityIdentifier("settings.gameCenterName")
                } else {
                    Text("dino.settings.gameCenter").accessibilityIdentifier("settings.gameCenterSignedOut")
                }
            }
            rowDivider
            linkedRow(identifier: "settings.language", spacious: spacious) { showsLanguages = true } icon: {
                Text(verbatim: language.effective.flag)
            } title: {
                Text(verbatim: language.effective.displayName)
            }
            rowDivider
            navigationRow(title: "dino.settings.dayParts", symbol: "sun.horizon.fill",
                          identifier: "settings.dayParts", spacious: spacious) {
                showsDayParts = true
            }
        }
    }

    private func preferenceRows(spacious: Bool) -> some View {
        Group {
            preference("dino.settings.soundEffects", symbol: "speaker.wave.2.fill",
                       value: $settings.soundEffectsEnabled, identifier: "settings.soundEffects", spacious: spacious)
            rowDivider
            preference("dino.settings.speakQuestionTitle", symbol: "speaker.wave.2.bubble.fill",
                       value: $settings.speakQuestionTitles, identifier: "settings.speakQuestionTitle", spacious: spacious)
            rowDivider
            preference("dino.settings.haptics", symbol: "iphone.radiowaves.left.and.right",
                       value: $settings.hapticsEnabled, identifier: "settings.haptics", spacious: spacious)
            rowDivider
            preference("dino.settings.highContrast", symbol: "circle.lefthalf.filled",
                       value: $settings.highContrastEnabled, identifier: "settings.highContrast", spacious: spacious)
            rowDivider
            icloudRow(spacious: spacious)
        }
    }

    private func privacyAndReset(spacious: Bool) -> some View {
        Group {
            navigationRow(title: "dino.friends.privacy", symbol: "hand.raised.fill",
                          identifier: "settings.privacy", spacious: spacious) { showsPrivacy = true }
            rowDivider
            Button { confirmReset = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise").frame(width: 26)
                    Text("dino.resetProgress")
                    Spacer(minLength: 4)
                }
                .modifier(SettingsRowSizing(spacious: spacious))
                .foregroundStyle(DinoStyle.warning)
                .contentShape(Rectangle())
            }.buttonStyle(DinoPlainButtonStyle()).accessibilityIdentifier("settings.reset")
        }
    }

    private func menuCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
        .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 22))
        .padding(12)
        .background(.white.opacity(highContrast ? 1 : 0.8), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white,
                                                           lineWidth: highContrast ? 2 : 1.5))
    }

    private var rowDivider: some View {
        Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.5 : 0.08))
            .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)
    }

    private var solvedReset: Bool {
        Int(resetAnswer.filter(\.isNumber)) == challenge.answer
    }

    private func resetCard(compact: Bool, spacious: Bool) -> some View {
        VStack(spacing: compact ? 12 : 16) {
            DinoCharacter(size: compact ? 84 : spacious ? 136 : 108)
            Text("dino.resetTitle").font(.system(size: compact ? 24 : spacious ? 34 : 28, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text("dino.resetMessage").font(.system(size: spacious ? 19 : 15, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: challenge.prompt)
                .font(.system(size: compact ? 26 : 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("settings.reset.equation")
                .accessibilityValue(challenge.token)
            TextField("dino.resetAnswer", text: $resetAnswer)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.15),
                                                                   lineWidth: highContrast ? 2 : 1.5))
                .accessibilityIdentifier("settings.reset.answer")
            Button(action: resetApp) {
                Label("dino.resetProgress", systemImage: "arrow.counterclockwise")
            }.buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xC74343), compact: true))
                .disabled(!solvedReset)
                .accessibilityIdentifier("settings.reset.confirm")
            Button("dino.cancel") { confirmReset = false }
                .buttonStyle(DinoButtonStyle(compact: true))
                .accessibilityIdentifier("settings.reset.cancel")
        }.padding(4).dinoCard()
    }

    /// Keeps the open confirmation page stable. The keyboard shrinks height without changing width; a rotation changes both.
    private func rememberResetPage(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        let rotated = resetPageWidth > 1 && abs(size.width - resetPageWidth) > 80
        guard !confirmReset || rotated else { return }
        resetPageWidth = size.width
        resetPageHeight = size.height
    }

    private func resetApp() {
        guard solvedReset else { return }
        let date = Date()
        friends.disable()
        cloudSync.removeAllData(at: date)
        player.resetAllData(at: date)
        settings.resetPreferences()
        language.resetPreference()
        dismiss()
#if DEBUG
        // The development build closes after the reset has been flushed, allowing
        // a genuine cold-launch onboarding test. Release resets the root in place.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            Darwin.exit(EXIT_SUCCESS)
        }
#endif
    }

    /// Same height as the other switches. The longer explanation opens beside the info button.
    private func icloudRow(spacious: Bool) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Button { settings.icloudSyncEnabled.toggle() } label: {
                    Label("dino.settings.icloudSync", systemImage: "icloud.fill")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SettingsRowButtonStyle())
                .accessibilityHidden(true)
                Button { showsCloudHelp = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: spacious ? 22 : 17, weight: .semibold))
                        .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SettingsRowButtonStyle())
                .accessibilityIdentifier("settings.icloudInfo")
                .accessibilityLabel(Text("dino.settings.icloudSync"))
                .accessibilityHint(Text("dino.settings.icloudDescription"))
                .popover(isPresented: $showsCloudHelp, attachmentAnchor: .rect(.bounds)) {
                    Text("dino.settings.icloudDescription")
                        .font(.system(size: spacious ? 18 : 15, weight: .medium, design: .rounded))
                        .foregroundStyle(DinoStyle.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(width: spacious ? 340 : 280)
                        .accessibilityIdentifier("settings.icloudStatus")
                        .modifier(CloudHelpPopover())
                }
            }
            .layoutPriority(1)
            Button { settings.icloudSyncEnabled.toggle() } label: {
                Color.clear.frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(DinoPlainButtonStyle())
            .accessibilityHidden(true)
            Toggle(isOn: $settings.icloudSyncEnabled) { EmptyView() }
                .labelsHidden().toggleStyle(.switch).tint(DinoStyle.deepGreen)
                .accessibilityLabel(Text("dino.settings.icloudSync"))
                .simultaneousGesture(TapGesture().onEnded { DinoAnswerFeedback.shared.playSelect() })
        }
        .padding(.vertical, 10).modifier(SettingsRowSizing(spacious: spacious))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.icloudSync")
    }

    private func preference(_ key: LocalizedStringKey, symbol: String, value: Binding<Bool>, identifier: String, spacious: Bool) -> some View {
        Toggle(isOn: value) {
            Label(key, systemImage: symbol)
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.toggleStyle(SettingsToggleStyle()).padding(.vertical, 10).modifier(SettingsRowSizing(spacious: spacious))
            .accessibilityIdentifier(identifier)
    }

    private func linkedRow<Icon: View, Title: View>(identifier: String, spacious: Bool, action: @escaping () -> Void,
                                          @ViewBuilder icon: () -> Icon,
                                          @ViewBuilder title: () -> Title) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon().frame(minWidth: 26)
                title()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            }
            .modifier(SettingsRowSizing(spacious: spacious))
            .contentShape(Rectangle())
        }
        .buttonStyle(DinoPlainButtonStyle())
        .accessibilityIdentifier(identifier)
    }

    private func navigationRow(title: LocalizedStringKey, symbol: String, identifier: String,
                               spacious: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 26)
                Text(title).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            }
            .modifier(SettingsRowSizing(spacious: spacious))
            .contentShape(Rectangle())
        }.buttonStyle(DinoPlainButtonStyle()).accessibilityIdentifier(identifier)
    }
}

extension DinoSettingsView {
    @ViewBuilder func settingsPresentation() -> some View {
        if #available(iOS 18, *) {
            presentationSizing(SettingsPresentationSizing())
                .presentationDetents([.custom(SettingsPresentationDetent.self)])
        } else {
            presentationDetents([.large])
        }
    }
}

@available(iOS 18, *)
private struct SettingsPresentationDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        let maximum = context.maxDetentValue
        guard context.horizontalSizeClass == .regular, context.verticalSizeClass == .regular else { return maximum }
        return min(maximum, maximum > 1050 ? 990 : 630)
    }
}

@available(iOS 18, *)
private struct SettingsPresentationSizing: PresentationSizing {
    func proposedSize(for root: PresentationSizingRoot, context: PresentationSizingContext) -> ProposedViewSize {
        let page = PagePresentationSizing.page.proposedSize(for: root, context: context)
        guard let width = page.width, width >= 650 else { return page }
        let height = page.height ?? 990
        let preferredHeight: CGFloat = width >= 740 && width > height ? 630 : 990
        return ProposedViewSize(width: width, height: min(height, preferredHeight))
    }
}

private struct SettingsRowSizing: ViewModifier {
    let spacious: Bool

    func body(content: Content) -> some View {
        content.font(.system(size: spacious ? 22 : 17, weight: .semibold, design: .rounded))
            .padding(.horizontal, spacious ? 20 : 16)
            .frame(minHeight: spacious ? 72 : 60)
    }
}

/// Centers the reset card on a finite page. Flexible frames inside the scroll view have no height bound,
/// so focusing the answer field asks the keyboard to scroll to a non-finite position and the app closes.
private struct ResetConfirmationPage: Layout {
    var minimumHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 460, height: minimumHeight)).width
        let cardHeight = subviews.last?.sizeThatFits(ProposedViewSize(width: width, height: nil)).height ?? 0
        let height = max(minimumHeight, cardHeight)
        return CGSize(width: width, height: height.isFinite ? height : minimumHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let card = subviews.last else { return }
        let cardSize = card.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        if subviews.count > 1, let scrim = subviews.first {
            scrim.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
        }
        let height = cardSize.height.isFinite ? cardSize.height : bounds.height
        card.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                   proposal: ProposedViewSize(width: bounds.width, height: height))
    }
}

/// A product large enough that confirming a reset takes a calculator.
private struct ResetChallenge {
    let left: Int
    let right: Int
    let extra: Int
    var answer: Int { left * right + extra }
    var prompt: String { "\(left) × \(right) + \(extra)" }
    var token: String { "\(left)x\(right)+\(extra)" }

    static func make() -> ResetChallenge {
        ResetChallenge(left: awkward(237...986), right: awkward(128...874), extra: awkward(2408...9876))
    }

    private static func awkward(_ range: ClosedRange<Int>) -> Int {
        var value = Int.random(in: range)
        while value % 10 == 0 || value % 25 == 0 { value = Int.random(in: range) }
        return value
    }
}

/// A button that never scales its label. The plain style shrinks text when the button hugs its contents.
private struct SettingsRowButtonStyle: ButtonStyle {
    var playsSelectSound = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.dinoSelectSound(pressed: configuration.isPressed, enabled: playsSelectSound)
    }
}

/// Keeps the iCloud explanation a popover on iPhone, so the settings row stays one line.
private struct CloudHelpPopover: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover).presentationBackground(DinoStyle.paper)
        } else {
            content
        }
    }
}

/// The label fills the row and has its own action, including its empty space.
private struct SettingsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            Button { configuration.isOn.toggle() } label: {
                configuration.label.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }.buttonStyle(DinoPlainButtonStyle(playsSelectSound: false))
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .labelsHidden().toggleStyle(.switch).tint(DinoStyle.deepGreen)
        }
        .onValueChange(of: configuration.isOn) { _ in
            DinoAnswerFeedback.shared.playSelect()
        }
    }
}

/// Parents set the school’s hours for night, morning, afternoon and evening.
struct DinoDayPartScheduleEditor: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var settings: DinoSettings
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = LanguageManager.shared
    /// Edited locally so a time pick does not redraw the map behind this sheet.
    @State private var schedule: DinoDayPartSchedule
    private let returnsToGame: Bool
    private let onCommit: (DinoDayPartSchedule) -> Void

    init(schedule: DinoDayPartSchedule, returnsToGame: Bool = false,
         onCommit: @escaping (DinoDayPartSchedule) -> Void = { _ in }) {
        self.returnsToGame = returnsToGame
        self.onCommit = onCommit
        _schedule = State(initialValue: schedule)
    }

    var body: some View {
        let _ = language.effective.code
        GeometryReader { geometry in
            let spacious = geometry.size.width >= 650 && verticalSizeClass != .compact
            let leading: CGFloat = spacious ? 28 : 20
            let trailing: CGFloat = spacious ? 40 : 32
            let lineWidth = max(1, min(800, geometry.size.width) - (spacious ? 56 : leading + trailing))
            let timeWidth = min(160, max(96, lineWidth * 0.28))
            Group {
                if spacious {
                    ScrollView {
                        VStack(spacing: 0) {
                            scheduleHeading(lineWidth: lineWidth, spacious: true)
                            scheduleRows(timeWidth: timeWidth, spacious: true)
                            closeButton(spacious: true).frame(maxWidth: 540)
                        }
                        .padding(.horizontal, 28).padding(.bottom, 24)
                        .frame(maxWidth: 800).frame(maxWidth: .infinity)
                        .modifier(ShortScrollCentering(height: geometry.size.height))
                    }.centersShortContent().bouncesOnlyWhenNeeded()
                } else {
                    VStack(spacing: 0) {
                        scheduleHeading(lineWidth: lineWidth, spacious: false)
                            .padding(.leading, leading).padding(.trailing, trailing)
                        ScrollView {
                            scheduleRows(timeWidth: timeWidth, spacious: false)
                                .padding(.leading, leading).padding(.trailing, trailing)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        closeButton(spacious: false)
                            .padding(.leading, leading).padding(.trailing, trailing)
                            .padding(.top, 12).padding(.bottom, 18)
                            .background(DinoStyle.paper.opacity(0.97))
                    }
                }
            }.background(JungleBackground(quiet: true))
        }
        .toolbar(.hidden, for: .navigationBar)
        .foregroundStyle(DinoStyle.ink)
        .lightPalette()
        .onDisappear(perform: commit)
    }

    private func scheduleHeading(lineWidth: CGFloat, spacious: Bool) -> some View {
        VStack(spacing: 0) {
            Text("dino.settings.dayParts")
                .font(.system(size: spacious ? 39 : 28, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .accessibilityIdentifier("settings.dayParts.editor")
            Text("dino.settings.dayParts.help")
                .font(.system(size: spacious ? 20 : 15, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .accessibilityIdentifier("settings.dayParts.help")
            DinoDayPartLine(time: ClockTime(hour: 0), width: lineWidth, isDemonstration: false,
                            schedule: schedule, showsSelection: false)
                .padding(.top, 16)
                .frame(maxWidth: .infinity)
        }
    }

    private func scheduleRows(timeWidth: CGFloat, spacious: Bool) -> some View {
        VStack(spacing: spacious ? 12 : 10) {
            columnHeader(timeWidth: timeWidth, spacious: spacious)
            ForEach(DinoDayPart.allCases, id: \.self) { part in
                partRow(part, timeWidth: timeWidth, spacious: spacious)
            }
            if schedule != .standard {
                Button {
                    schedule = .standard
                } label: {
                    Label("dino.settings.dayParts.standard", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
                .accessibilityIdentifier("settings.dayParts.standard")
            }
        }.padding(.top, 16).padding(.bottom, 24)
    }

    private func closeButton(spacious: Bool) -> some View {
        Button(action: close) {
            Label(LocalizedStringKey(returnsToGame ? "dino.settings.dayParts.backToGame" : "dino.practice.backToLevels"),
                  systemImage: returnsToGame ? "play.fill" : "map.fill")
        }
        .buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
        .accessibilityIdentifier("settings.dayParts.close")
    }

    private func close() {
        commit()
        dismiss()
    }

    /// Writes once, when the sheet closes. A second call from the swipe sees the same value and skips the map redraw.
    private func commit() {
        guard settings.dayPartSchedule != schedule else { return }
        settings.dayPartSchedule = schedule
        onCommit(schedule)
    }

    private func columnHeader(timeWidth: CGFloat, spacious: Bool) -> some View {
        HStack(spacing: 0) {
            Text("dino.settings.dayParts.column")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            Text("dino.settings.dayParts.from")
                .frame(width: timeWidth)
            Text("dino.settings.dayParts.to")
                .frame(width: timeWidth)
        }
        .font(.system(size: spacious ? 20 : 14, weight: .bold, design: .rounded))
        .foregroundStyle(DinoStyle.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(minHeight: 48)
        .background(Color(dinoHex: 0xCBD1D6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("settings.dayParts.columns")
    }

    private func partRow(_ part: DinoDayPart, timeWidth: CGFloat, spacious: Bool) -> some View {
        HStack(spacing: 0) {
            Text(LocalizedStringKey(part.titleKey))
                .font(.system(size: spacious ? 20 : 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            boundaryMenu(part, ending: false, spacious: spacious)
                .frame(width: timeWidth)
            boundaryMenu(part, ending: true, spacious: spacious)
                .frame(width: timeWidth)
        }
        .frame(minHeight: spacious ? 76 : 68)
        .background(part.lineGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(highContrast ? DinoStyle.ink : .white.opacity(0.7), lineWidth: highContrast ? 2 : 1))
    }

    private func boundaryMenu(_ part: DinoDayPart, ending: Bool, spacious: Bool) -> some View {
        let edited = ending ? part.next() : part
        let current = schedule.start(of: edited)
        let options = schedule.validStarts(for: edited)
        let shown = ending ? schedule.clockText(endOf: part) : schedule.clockText(startOf: part)
        let edge = ending ? "to" : "from"
        return Menu {
                ForEach(options, id: \.self) { hour in
                    Button {
                        DinoAnswerFeedback.shared.playSelect()
                        var next = schedule
                        next.setStart(edited, hour)
                        guard next.isValid else { return }
                        schedule = next
                    } label: {
                        if hour == current {
                            Label(boundaryText(hour, ending: ending), systemImage: "checkmark")
                        } else {
                            Text(verbatim: boundaryText(hour, ending: ending))
                        }
                    }
                    .accessibilityIdentifier("settings.dayParts.\(part.rawValue).\(edge).\(ending && hour == 0 ? 24 : hour)")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(verbatim: shown)
                        .font(.system(size: spacious ? 21 : 16, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(DinoStyle.ink)
                .padding(.horizontal, 10)
                .frame(minWidth: spacious ? 118 : 92, minHeight: spacious ? 54 : 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.12), lineWidth: highContrast ? 2 : 1.5))
            }
            .accessibilityIdentifier("settings.dayParts.\(part.rawValue).\(edge)")
            .accessibilityValue(shown)
    }

    private func boundaryText(_ hour: Int, ending: Bool) -> String {
        if ending && hour == 0 { return "24:00" }
        return String(format: "%02d:00", hour)
    }
}
