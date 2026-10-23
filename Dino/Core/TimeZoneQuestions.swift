import Foundation
import CoreGraphics

struct DinoCapital: Equatable, Sendable {
    let id: String
    let dutchName: String
    let englishName: String
    let countryCode: String
    let timeZoneID: String
    let latitude: Double
    let longitude: Double

    func name(language: String) -> String { language == "nl" ? dutchName : englishName }
    var utcHours: Int { gmtHours(on: DinoTimeZoneJourney.referenceDate) }
    /// Offset baked into the simplified winter zone bands.
    var atlasUTCHours: Int { gmtHours(on: DinoTimeZoneJourney.atlasDate) }

    private func gmtHours(on date: Date) -> Int {
        TimeZone(identifier: timeZoneID)!.secondsFromGMT(for: date) / 3_600
    }
}

/// One hour of the worked example, counted from the reference until the new time.
struct DinoTimeZoneHourStep: Equatable, Sendable {
    let addedHours: Int
    let time: ClockTime

    var caption: String { "\(addedHours > 0 ? "+" : "−")\(abs(addedHours))" }
}

enum DinoTimeZoneDifficulty: CaseIterable {
    case nearby, regional, worldwide

    init(minuteStep: Int) {
        self = minuteStep >= 30 ? .nearby : minuteStep >= 10 ? .regional : .worldwide
    }
}

struct DinoTimeZoneJourney: Equatable, Sendable {
    let origin: DinoCapital
    let destination: DinoCapital
    var offsetHours: Int { destination.utcHours - origin.utcHours }

    /// Noon UTC on the player's current calendar day. The header and the city
    /// difference both use this instant, so the shown date matches the answer.
    static var referenceDate: Date {
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        return utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12))!
    }

    /// The bundled zone shapes were simplified for this winter afternoon.
    static let atlasDate = Date(timeIntervalSince1970: 1_768_478_400) // 15 January 2026, 12:00 UTC

    static func displayedDate(language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == "nl" ? "nl_NL" : "en_GB")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: referenceDate)
    }

    /// +1, then +2, through the destination. A westward journey counts −1, −2.
    func hourSteps(from reference: ClockTime) -> [DinoTimeZoneHourStep] {
        let count = abs(offsetHours)
        guard count > 0 else { return [] }
        let direction = offsetHours > 0 ? 1 : -1
        return (1...count).map { step in
            let added = direction * step
            return DinoTimeZoneHourStep(addedHours: added, time: reference.adding(minutes: added * 60))
        }
    }

    static func generate<R: RandomNumberGenerator>(language: String, difficulty: DinoTimeZoneDifficulty,
                                                   using rng: inout R) -> Self {
        let origin = capitals.first { $0.id == (language == "nl" ? "amsterdam" : "london") }!
        let candidates = capitals.filter { capital in
            let difference = abs(capital.utcHours - origin.utcHours)
            let distance = hypot(capital.longitude - origin.longitude, capital.latitude - origin.latitude)
            guard capital.id != origin.id, difference != 0 else { return false }
            switch difficulty {
            case .nearby: return difference == 1 && distance < 40
            case .regional: return (1...3).contains(difference) && distance < 70
            case .worldwide: return difference >= 4
            }
        }
        return Self(origin: origin, destination: candidates.randomElement(using: &rng)!)
    }

    // Familiar countries, whole-hour zones and actual capitals; Istanbul is
    // deliberately excluded because Ankara is Turkey's capital.
    static let capitals: [DinoCapital] = [
        .init(id: "amsterdam", dutchName: "Amsterdam", englishName: "Amsterdam", countryCode: "NLD", timeZoneID: "Europe/Amsterdam", latitude: 52.37, longitude: 4.90),
        .init(id: "london", dutchName: "Londen", englishName: "London", countryCode: "GBR", timeZoneID: "Europe/London", latitude: 51.51, longitude: -0.13),
        .init(id: "paris", dutchName: "Parijs", englishName: "Paris", countryCode: "FRA", timeZoneID: "Europe/Paris", latitude: 48.86, longitude: 2.35),
        .init(id: "berlin", dutchName: "Berlijn", englishName: "Berlin", countryCode: "DEU", timeZoneID: "Europe/Berlin", latitude: 52.52, longitude: 13.41),
        .init(id: "brussels", dutchName: "Brussel", englishName: "Brussels", countryCode: "BEL", timeZoneID: "Europe/Brussels", latitude: 50.85, longitude: 4.35),
        .init(id: "madrid", dutchName: "Madrid", englishName: "Madrid", countryCode: "ESP", timeZoneID: "Europe/Madrid", latitude: 40.42, longitude: -3.70),
        .init(id: "rome", dutchName: "Rome", englishName: "Rome", countryCode: "ITA", timeZoneID: "Europe/Rome", latitude: 41.90, longitude: 12.50),
        .init(id: "dublin", dutchName: "Dublin", englishName: "Dublin", countryCode: "IRL", timeZoneID: "Europe/Dublin", latitude: 53.35, longitude: -6.26),
        .init(id: "lisbon", dutchName: "Lissabon", englishName: "Lisbon", countryCode: "PRT", timeZoneID: "Europe/Lisbon", latitude: 38.72, longitude: -9.14),
        .init(id: "athens", dutchName: "Athene", englishName: "Athens", countryCode: "GRC", timeZoneID: "Europe/Athens", latitude: 37.98, longitude: 23.73),
        .init(id: "helsinki", dutchName: "Helsinki", englishName: "Helsinki", countryCode: "FIN", timeZoneID: "Europe/Helsinki", latitude: 60.17, longitude: 24.94),
        .init(id: "ankara", dutchName: "Ankara", englishName: "Ankara", countryCode: "TUR", timeZoneID: "Europe/Istanbul", latitude: 39.93, longitude: 32.86),
        .init(id: "cairo", dutchName: "Caïro", englishName: "Cairo", countryCode: "EGY", timeZoneID: "Africa/Cairo", latitude: 30.04, longitude: 31.24),
        .init(id: "moscow", dutchName: "Moskou", englishName: "Moscow", countryCode: "RUS", timeZoneID: "Europe/Moscow", latitude: 55.76, longitude: 37.62),
        .init(id: "washington", dutchName: "Washington", englishName: "Washington", countryCode: "USA", timeZoneID: "America/New_York", latitude: 38.91, longitude: -77.04),
        .init(id: "ottawa", dutchName: "Ottawa", englishName: "Ottawa", countryCode: "CAN", timeZoneID: "America/Toronto", latitude: 45.42, longitude: -75.70),
        .init(id: "brasilia", dutchName: "Brasília", englishName: "Brasília", countryCode: "BRA", timeZoneID: "America/Sao_Paulo", latitude: -15.79, longitude: -47.88),
        .init(id: "beijing", dutchName: "Peking", englishName: "Beijing", countryCode: "CHN", timeZoneID: "Asia/Shanghai", latitude: 39.90, longitude: 116.41),
        .init(id: "tokyo", dutchName: "Tokio", englishName: "Tokyo", countryCode: "JPN", timeZoneID: "Asia/Tokyo", latitude: 35.68, longitude: 139.69),
        .init(id: "seoul", dutchName: "Seoul", englishName: "Seoul", countryCode: "KOR", timeZoneID: "Asia/Seoul", latitude: 37.57, longitude: 126.98),
        .init(id: "canberra", dutchName: "Canberra", englishName: "Canberra", countryCode: "AUS", timeZoneID: "Australia/Sydney", latitude: -35.28, longitude: 149.13)
    ]
}

/// Highest simplified coastline in each 10° longitude bin of the bundled atlas.
enum DinoTimeZoneLand {
    static let northernLatitude: [Double] = [
        71.5, 68.9, 71.4, 70.9, 70.2, 71.9, 77.6, 79.3, 80.9,
        82.7, 83.1, 83.2, 82.9, 82.6, 83.6, 83.5, 82.7, 81.7,
        62.0, 80.0, 80.7, 80.4, 80.6, 80.9, 76.3, 76.9, 73.6,
        81.0, 81.2, 78.7, 73.8, 73.6, 76.1, 75.6, 71.0, 70.1
    ]

    /// Northern land across the middle of a crop, ignoring a corner spike.
    static func northernEdge(longitude: Double, span: Double) -> Double {
        var best = -90.0
        for step in 0...40 {
            let t = (Double(step) / 40 - 0.5) * 0.9
            var lon = longitude + span * t
            while lon > 180 { lon -= 360 }
            while lon < -180 { lon += 360 }
            let bin = Int((lon / 10).rounded())
            let index = (bin == 18 ? -18 : bin) + 18
            if northernLatitude.indices.contains(index) { best = max(best, northernLatitude[index]) }
        }
        return best
    }
}

/// A flat, locally scaled projection with enough room for the two city labels.
/// It expands naturally from Europe to an intercontinental view.
struct DinoTimeZoneViewport {
    let longitude: Double
    let latitude: Double
    let longitudeSpan: Double
    let latitudeSpan: Double

    init(journey: DinoTimeZoneJourney, size: CGSize) {
        let a = journey.origin, b = journey.destination
        let centerLongitude = (a.longitude + b.longitude) / 2
        var centerLatitude = (a.latitude + b.latitude) / 2
        let aspect = Double(max(1, size.width) / max(1, size.height))
        let latitudeScale = max(0.55, cos(centerLatitude * .pi / 180))
        let width = max(25, abs(a.longitude - b.longitude) * 1.55 + 12)
        let height = max(18, abs(a.latitude - b.latitude) * 1.65 + 10)
        longitudeSpan = max(width, height * aspect / latitudeScale)
        latitudeSpan = longitudeSpan * latitudeScale / aspect
        // Keep the same scale and frame shape, but drop a crop that would
        // otherwise run past the land and leave an empty band at the top.
        let north = centerLatitude + latitudeSpan / 2
        let land = DinoTimeZoneLand.northernEdge(longitude: centerLongitude, span: longitudeSpan)
        let margin = latitudeSpan * (8 / Double(max(size.height, 1)))
        if north > land + margin { centerLatitude -= north - (land + margin) }
        longitude = centerLongitude
        latitude = centerLatitude
    }

    func point(latitude lat: Double, longitude lon: Double, size: CGSize) -> CGPoint {
        CGPoint(x: (0.5 + (lon - longitude) / longitudeSpan) * size.width,
                y: (0.5 - (lat - latitude) / latitudeSpan) * size.height)
    }

    func point(_ capital: DinoCapital, size: CGSize) -> CGPoint {
        point(latitude: capital.latitude, longitude: capital.longitude, size: size)
    }
}

struct DinoTimeZoneLabelLayout {
    let origin: CGPoint
    let destination: CGPoint
    let width: CGFloat

    init(origin: CGPoint, destination: CGPoint, size: CGSize, offsetHours: Int) {
        let width = min(132, (size.width - 20) / 2)
        self.width = width
        func clamp(_ point: CGPoint) -> CGPoint {
            CGPoint(x: min(size.width - width / 2 - 7, max(width / 2 + 7, point.x)),
                    y: min(size.height - 43, max(43, point.y)))
        }
        func rect(_ point: CGPoint) -> CGRect {
            CGRect(x: point.x - width / 2, y: point.y - 38, width: width, height: 76)
        }
        func candidates(_ point: CGPoint, below: Bool) -> [CGPoint] {
            let direction: CGFloat = below ? 1 : -1
            var points = [CGPoint(x: point.x, y: point.y + 55 * direction),
                          CGPoint(x: point.x - width / 2 - 20, y: point.y),
                          CGPoint(x: point.x + width / 2 + 20, y: point.y),
                          CGPoint(x: point.x, y: point.y - 55 * direction)]
            for x in [width / 2 + 7, size.width / 2, size.width - width / 2 - 7] {
                for y in [CGFloat(43), size.height / 2, size.height - 43] {
                    points.append(CGPoint(x: x, y: y))
                }
            }
            return points.map(clamp)
        }
        func markerPenalty(_ label: CGPoint) -> CGFloat {
            let bounds = rect(label).insetBy(dx: -12, dy: -12)
            return [origin, destination].reduce(0) { $0 + (bounds.contains($1) ? 10_000 : 0) }
        }
        /// A later city sits to the right of the reference card; an earlier city sits to the left.
        func orderPenalty(_ reference: CGPoint, _ other: CGPoint) -> CGFloat {
            guard offsetHours != 0 else { return 0 }
            let later = offsetHours > 0
            let ordered = later ? other.x - reference.x : reference.x - other.x
            if ordered <= 1 { return 50_000 }
            let leading = later ? rect(reference) : rect(other)
            let trailing = later ? rect(other) : rect(reference)
            let overlap = leading.maxX - trailing.minX
            return overlap > 0 ? 8_000 + overlap : 0
        }
        let originChoices = candidates(origin, below: true)
        let destinationChoices = candidates(destination, below: false)
        var best = (originChoices[0], destinationChoices[0])
        var bestScore = CGFloat.infinity
        for (i, a) in originChoices.enumerated() {
            for (j, b) in destinationChoices.enumerated() {
                let overlap = rect(a).insetBy(dx: -4, dy: -4).intersects(rect(b)) ? CGFloat(10_000) : 0
                let distance = hypot(a.x - origin.x, a.y - origin.y) + hypot(b.x - destination.x, b.y - destination.y)
                let score = markerPenalty(a) + markerPenalty(b) + overlap + orderPenalty(a, b) + distance + CGFloat(i + j) * 2
                if score < bestScore { bestScore = score; best = (a, b) }
            }
        }
        self.origin = best.0
        self.destination = best.1
    }
}
