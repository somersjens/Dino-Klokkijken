import SwiftUI

/// Both endpoints stay visible while the unknown interval becomes the worked answer.
struct DinoMinutesBetweenCard: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let start: ClockTime
    let end: ClockTime
    let minutes: Int
    let theme: ClockTheme
    let width: CGFloat
    let showsAnswer: Bool
    let isDemonstration: Bool
    let language: String
    var compact = false

    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var clockFont: CGFloat { min(compact ? 31 : 48, (width - 52) / 7.8) }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }

    var body: some View {
        VStack(spacing: compact ? 10 : 18) {
            HStack(spacing: 16) {
                endpoint(start, title: "dino.minutesBetween.from", identifier: "start")
                endpoint(end, title: "dino.minutesBetween.until", identifier: "end")
            }

            ZStack {
                HStack(spacing: 0) {
                    Circle().fill(DinoStyle.green)
                        .overlay(Circle().strokeBorder(DinoStyle.deepGreen, lineWidth: 2))
                        .frame(width: 12, height: 12)
                    Rectangle().fill(DinoStyle.deepGreen.opacity(highContrast ? 1 : 0.35))
                        .frame(height: 2)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(DinoStyle.deepGreen)
                }.accessibilityHidden(true)

                HStack(spacing: 9) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 19, weight: .semibold)).accessibilityHidden(true)
                    Text(verbatim: showsAnswer ? DinoTimeWords.minutes(minutes, language: language) : "? min")
                        .font(.system(size: compact ? 20 : 22, weight: .heavy, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                }
                .foregroundStyle(DinoStyle.deepGreen)
                .padding(.horizontal, 18).padding(.vertical, compact ? 10 : 13)
                .background {
                    Capsule().fill(DinoStyle.paper)
                        .overlay {
                            if showsAnswer { Capsule().fill(DinoStyle.green.opacity(0.32)) }
                        }
                }
                .overlay(Capsule().strokeBorder(DinoStyle.deepGreen.opacity(highContrast ? 1 : 0.5),
                                               style: StrokeStyle(lineWidth: highContrast ? 2.5 : 1.5,
                                                                  dash: showsAnswer ? [] : [5, 4])))
                .padding(.horizontal, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: showsAnswer ? DinoTimeWords.minutes(minutes, language: language)
                                         : L(key: "dino.question.minutesBetween")))
                .accessibilityIdentifier(isDemonstration ? "demo.answer" : "question.minutesBetween.\(showsAnswer ? "answer" : "unknown")")
            }

        }
        .padding(compact ? 14 : 18).frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [.white, DinoStyle.paper], startPoint: .top, endPoint: .bottom))
        }
        .overlay(RoundedRectangle(cornerRadius: 28)
            .strokeBorder(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.16),
                          lineWidth: highContrast ? 2.5 : 1.5))
        .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 14, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).minutesBetween.card")
    }

    private func endpoint(_ time: ClockTime, title: String, identifier: String) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(secondaryInk)
            DigitalClock(time: time, theme: theme, fontSize: clockFont)
                .accessibilityIdentifier("\(prefix).minutesBetween.\(identifier)")
        }.frame(maxWidth: .infinity)
    }
}

struct DinoMinutesBetweenExplanation: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let difference: DinoMinuteDifference
    let language: String

    private var hourUnit: String { language == "nl" ? "uur" : "h" }

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: "\(difference.later.digitalText) − \(difference.earlier.digitalText)")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .accessibilityIdentifier("demo.minutesBetween.subtraction")
            if difference.borrowsHour {
                Text(verbatim: String(format: L(key: "dino.minutesBetween.borrow.format"),
                                      difference.later.hour, difference.later.minute,
                                      difference.later.hour - 1, difference.later.minute + 60))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                    .accessibilityIdentifier("demo.minutesBetween.borrow")
            }
            Text(verbatim: "= \(difference.hours) \(hourUnit) \(difference.minutes) min")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .accessibilityIdentifier("demo.minutesBetween.remainder")
            Text(verbatim: "\(difference.hours) × 60 + \(difference.minutes) = \(DinoTimeWords.minutes(difference.totalMinutes, language: language))")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(DinoStyle.deepGreen)
                .accessibilityIdentifier("demo.minutesBetween.conversion")
        }
        .monospacedDigit().multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12).frame(maxWidth: .infinity)
        .background(DinoStyle.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("demo.minutesBetween.calculation")
    }
}
