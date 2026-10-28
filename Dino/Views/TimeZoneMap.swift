import SwiftUI

/// Earlier stays the destination red; later uses the same light green as a positive difference.
enum DinoTimeDirection {
    static let earlier = Color(dinoHex: 0xA34A26)
    static func color(later: Bool, highContrast: Bool) -> Color {
        later ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : earlier
    }
}

/// Offline atlas: Natural Earth country outlines and simplified time-zone
/// geometry. The task's two offsets always come from Foundation's IANA zones.
struct DinoTimeZoneMap: View {
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    @Environment(\.dinoHighContrast) private var highContrast
    let journey: DinoTimeZoneJourney
    let referenceTime: ClockTime
    let answer: ClockTime
    let showsAnswer: Bool
    var isDemonstration = false
    var compactLayout = false
    var theme = ClockTheme.standard

    private let originColor = Color(dinoHex: 0x25674C)
    private var destinationColor: Color {
        DinoTimeDirection.color(later: journey.offsetMinutes > 0, highContrast: highContrast)
    }
    private var code: String { language.effective.code }
    private var prefix: String { isDemonstration ? "demo" : "question" }

    var body: some View {
        let _ = deviceHourFormat.notation
        GeometryReader { geometry in
                let size = geometry.size
                let viewport = DinoTimeZoneViewport(journey: journey, size: size)
                let origin = viewport.point(journey.origin, size: size)
                let destination = viewport.point(journey.destination, size: size)
                let labels = DinoTimeZoneLabelLayout(origin: origin, destination: destination, size: size,
                                                      offsetMinutes: journey.offsetMinutes)
                let labelWidth = labels.width
                let originLabel = labels.origin
                let destinationLabel = labels.destination
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: [Color(dinoHex: 0xD6EBEF), Color(dinoHex: 0xEEF7F5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Canvas { context, canvasSize in
                        drawAtlas(context: &context, size: canvasSize, viewport: viewport)
                        drawLeader(context: &context, from: origin, to: originLabel, labelWidth: labelWidth, color: originColor)
                        drawLeader(context: &context, from: destination, to: destinationLabel, labelWidth: labelWidth, color: destinationColor)
                    }.accessibilityHidden(true)

                    cityLabel(journey.origin, time: theme.digitalReading(referenceTime, languageCode: code), isOrigin: true, width: labelWidth)
                        .position(originLabel)
                        .accessibilityIdentifier("\(prefix).timeZone.origin")
                    cityLabel(journey.destination, time: showsAnswer ? theme.digitalReading(answer, languageCode: code) : "?", isOrigin: false, width: labelWidth)
                        .position(destinationLabel)
                        .accessibilityIdentifier("\(prefix).timeZone.destination")
                    marker(color: originColor, target: false).position(origin)
                    marker(color: destinationColor, target: true).position(destination)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(highContrast ? DinoStyle.ink : Color(dinoHex: 0x83ADB4).opacity(0.65), lineWidth: highContrast ? 2 : 1))
            }
            .frame(height: isDemonstration ? 224 : compactLayout ? 184 : 252)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("\(prefix).timeZone.map")
    }

    private func marker(color: Color, target: Bool) -> some View {
        ZStack {
            Circle().fill(.white.opacity(0.8)).frame(width: 23, height: 23)
            Circle().fill(color).frame(width: 12, height: 12)
            if target { Circle().stroke(color, lineWidth: 1.5).frame(width: 22, height: 22) }
            Circle().fill(.white).frame(width: 3, height: 3)
        }.accessibilityHidden(true)
    }

    private func cityLabel(_ capital: DinoCapital, time: String, isOrigin: Bool, width: CGFloat) -> some View {
        let color = isOrigin ? originColor : destinationColor
        let later = journey.offsetMinutes > 0
        let direction = DinoTimeDirection.color(later: later, highContrast: highContrast)
        let difference = isOrigin ? 0 : journey.offsetMinutes
        let offset = difference == 0 ? L(key: "dino.timeZone.reference") : differenceText(difference)
        return VStack(spacing: 2) {
            Text(verbatim: capital.name(language: code))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(isOrigin ? color : direction)
            Text(verbatim: time)
                .font(.system(size: 23, weight: .heavy, design: .rounded)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.55)
                .foregroundStyle(isOrigin ? color : direction)
                .numericTextTransition()
                .accessibilityIdentifier("\(prefix).timeZone.\(isOrigin ? "referenceTime" : "targetTime")")
            Text(verbatim: offset)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.75)
                .foregroundStyle(isOrigin ? color : direction)
        }
        .padding(.vertical, 7).frame(width: width)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func differenceText(_ difference: Int) -> String {
        String(format: L(key: difference > 0 ? "dino.timeZone.later" : "dino.timeZone.earlier"), DinoTimeWords.zoneHours(difference))
    }

    private func drawLeader(context: inout GraphicsContext, from point: CGPoint, to label: CGPoint, labelWidth: CGFloat, color: Color) {
        var path = Path()
        path.move(to: point)
        let bounds = CGRect(x: label.x - labelWidth / 2, y: label.y - 38, width: labelWidth, height: 76)
        path.addLine(to: CGPoint(x: min(bounds.maxX, max(bounds.minX, point.x)),
                                y: min(bounds.maxY, max(bounds.minY, point.y))))
        context.stroke(path, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    }

    private func drawAtlas(context: inout GraphicsContext, size: CGSize, viewport: DinoTimeZoneViewport) {
        let atlas = DinoTimeZoneAtlas.shared
        let transform = CGAffineTransform(a: size.width / viewport.longitudeSpan, b: 0,
                                         c: 0, d: -size.height / viewport.latitudeSpan,
                                         tx: size.width * (0.5 - viewport.longitude / viewport.longitudeSpan),
                                         ty: size.height * (0.5 + viewport.latitude / viewport.latitudeSpan))
        // Repeat the atlas across the date line so wide Pacific crops remain filled.
        for shift in [-360.0, 0, 360] {
            let translated = CGAffineTransform(translationX: shift, y: 0).concatenating(transform)
            for country in atlas.countries {
                let path = country.path.applying(translated)
                context.fill(path, with: .color(Color(dinoHex: 0xEDF0CD)))
            }
            for zone in atlas.zones {
                let path = zone.path.applying(translated)
                let opacity = Int(zone.offset.rounded()).isMultiple(of: 2) ? 0.035 : 0.095
                context.fill(path, with: .color(Color(dinoHex: 0x367684).opacity(opacity)))
                context.stroke(path, with: .color(Color(dinoHex: 0x447887).opacity(highContrast ? 0.9 : 0.58)),
                               style: StrokeStyle(lineWidth: highContrast ? 1.4 : 1, dash: [4, 4]))
            }
            for country in atlas.countries {
                let path = country.path.applying(translated)
                context.stroke(path, with: .color(Color(dinoHex: 0x8DAB8A).opacity(0.8)), lineWidth: 0.65)
                let isOrigin = country.id == journey.origin.countryCode
                let isDestination = country.id == journey.destination.countryCode
                if isOrigin || isDestination {
                    let color = isOrigin ? originColor : destinationColor
                    context.fill(path, with: .color(color.opacity(0.15)))
                    context.stroke(path, with: .color(color.opacity(0.65)), lineWidth: 1)
                }
            }
        }
        drawZoneLabels(context: &context, size: size, transform: transform)
    }

    private func drawZoneLabels(context: inout GraphicsContext, size: CGSize, transform: CGAffineTransform) {
        let atlas = DinoTimeZoneAtlas.shared
        let inverse = transform.inverted()
        let y = size.height - 13
        var runs: [(offset: Int, start: CGFloat, end: CGFloat)] = []
        for x in stride(from: CGFloat(0), through: size.width, by: 4) {
            let coordinate = CGPoint(x: x, y: y).applying(inverse)
            guard let zone = atlas.zones.first(where: { $0.path.contains(coordinate) }) else { continue }
            let offset = Int((zone.offset * 60).rounded()) - journey.origin.atlasUTCMinutes
            guard offset.isMultiple(of: 30) else { continue }
            if let last = runs.last, last.offset == offset, x - last.end <= 8 {
                runs[runs.count - 1].end = x
            } else { runs.append((offset, x, x)) }
        }
        for run in runs where run.end - run.start >= 42 {
            let sign = run.offset < 0 ? "−" : run.offset > 0 ? "+" : ""
            let unit = code == "nl" ? "u" : "h"
            let text = Text(verbatim: "\(sign)\(DinoTimeWords.zoneHours(run.offset)) \(unit)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .canvasInk(Color(dinoHex: 0x315F6B))
            let x = (run.start + run.end) / 2
            context.fill(Path(roundedRect: CGRect(x: x - 21, y: y - 9, width: 42, height: 18), cornerRadius: 6),
                         with: .color(.white.opacity(0.88)))
            context.draw(text, at: CGPoint(x: x, y: y))
        }
    }
}

/// Worked example: two clocks start equal, with one difference chip between them.
struct DinoTimeZoneLesson: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let journey: DinoTimeZoneJourney
    let referenceTime: ClockTime
    let answer: ClockTime
    let showsAnswer: Bool
    let isDemonstration: Bool
    var compactLayout = false
    let theme: ClockTheme
    let width: CGFloat
    var explainsLive = false
    @State private var applied = 0

    private var total: Int { abs(journey.offsetMinutes) }
    private var clockFont: CGFloat { min(28, max(18, (width - 120) / 8)) }
    private var signedMinutes: Int { journey.offsetMinutes >= 0 ? applied : -applied }
    private var resultTime: ClockTime { referenceTime.adding(minutes: signedMinutes) }
    /// Spoken form keeps the sign. The chip shows only the number; the icon carries + or −.
    private var differenceCaption: String {
        if applied == 0 { return "+0" }
        return "\(signedMinutes > 0 ? "+" : "−")\(differenceNumber)"
    }
    private var differenceNumber: String { DinoTimeWords.zoneHours(applied) }

    var body: some View {
        VStack(spacing: 10) {
            DinoTimeZoneMap(journey: journey, referenceTime: referenceTime,
                            answer: answer, showsAnswer: mapShowsAnswer,
                            isDemonstration: isDemonstration, compactLayout: compactLayout, theme: theme)
            if playsWalk {
                walk
                .scaleEffect(playsWalk || reduceMotion ? 1 : 0.96)
                .opacity(playsWalk ? 1 : 0)
                .accessibilityHidden(!playsWalk)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: playsWalk)
            }
        }
        .task(id: stepIdentity) { await play() }
    }

    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var playsWalk: Bool { isDemonstration || explainsLive }

    private var stepIdentity: String {
        "\(journey.origin.id)-\(journey.destination.id)-\(referenceTime.digitalText)-\(playsWalk)"
    }

    /// The city keeps its question mark until the chip has reached the real difference.
    private var mapShowsAnswer: Bool {
        isDemonstration ? (applied == total && total > 0) : showsAnswer
    }

    private var walk: some View {
        HStack(alignment: .center, spacing: 10) {
            DigitalClock(time: referenceTime, theme: theme, fontSize: clockFont)
                .accessibilityIdentifier("\(prefix).timeZone.step.0")
            difference
            DigitalClock(time: resultTime, theme: theme, fontSize: clockFont)
                .accessibilityIdentifier(isDemonstration ? "demo.answer" : "question.timeZone.result")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeZone.steps")
    }

    private var difference: some View {
        let resting = applied == 0
        let negative = signedMinutes < 0
        let ink = resting ? DinoStyle.muted : negative ? DinoTimeDirection.earlier : DinoStyle.deepGreen
        let fill = resting ? DinoStyle.muted : negative ? DinoTimeDirection.earlier : DinoStyle.green
        return HStack(spacing: 4) {
            Image(systemName: signedMinutes < 0 ? "minus.circle.fill" : "plus.circle.fill")
                .font(.system(size: 15, weight: .bold))
            Text(verbatim: differenceNumber)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .numericTextTransition()
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minWidth: 64)
        .background(fill.opacity(resting ? 0.14 : 0.28), in: Capsule())
        .overlay(Capsule().strokeBorder(ink.opacity(resting ? 0.28 : 0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: differenceCaption))
        .accessibilityIdentifier("\(prefix).timeZone.difference")
    }

    @MainActor private func play() async {
        guard playsWalk else {
            applied = 0
            return
        }
        if reduceMotion || total == 0 {
            applied = total
            return
        }
        applied = 0
        do {
            try await Task.sleep(for: .milliseconds(900))
            for step in stride(from: 0, to: total, by: 60) {
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: 0.35)) { applied = min(step + 60, total) }
                if applied < total { try await Task.sleep(for: .milliseconds(700)) }
            }
        } catch { /* Closing the example or loading another one cancels the walk. */ }
    }
}

private struct DinoTimeZoneAtlas {
    struct Country { let id: String; let path: Path }
    struct Zone { let offset: Double; let path: Path }
    let countries: [Country]
    let zones: [Zone]

    private struct DataSet: Decodable {
        struct Country: Decodable { let id: String; let rings: [[[Double]]] }
        struct Zone: Decodable { let offset: Double; let rings: [[[Double]]] }
        let countries: [Country]
        let zones: [Zone]
    }

    static let shared: Self = {
        guard let url = Bundle.main.url(forResource: "TimeZoneMap", withExtension: "json"),
              let data = try? Data(contentsOf: url), let decoded = try? JSONDecoder().decode(DataSet.self, from: data) else {
            assertionFailure("Missing bundled time-zone atlas")
            return Self(countries: [], zones: [])
        }
        return Self(countries: decoded.countries.map { Country(id: $0.id, path: path($0.rings)) },
                    zones: decoded.zones.map { Zone(offset: $0.offset, path: path($0.rings)) })
    }()

    private static func path(_ rings: [[[Double]]]) -> Path {
        Path { path in
            for ring in rings {
                var previous: Double?
                for (index, coordinate) in ring.enumerated() {
                    var longitude = coordinate[0]
                    if let previous {
                        while longitude - previous > 180 { longitude -= 360 }
                        while longitude - previous < -180 { longitude += 360 }
                    }
                    let point = CGPoint(x: longitude, y: coordinate[1])
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    previous = longitude
                }
                path.closeSubpath()
            }
        }
    }
}
