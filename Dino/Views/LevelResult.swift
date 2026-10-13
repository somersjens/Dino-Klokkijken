import SwiftUI

struct DinoResultView: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    let result: DinoLevelResult
    let retry: () -> Void
    let next: () -> Void
    let map: () -> Void
    var sharedCompanion = false
    private var succeeded: Bool { result.level.isBoss ? result.victory != .none : result.stars > 0 }
    private var nextAvailable: Bool { result.level.isBoss ? succeeded : player.profile.isUnlocked(result.level.id + 1) }
    var body: some View {
        ZStack {
            JungleBackground()
            ScrollView {
                VStack(spacing: 24) {
                    Text("dino.levelNumber \(result.level.id)").font(.system(size: 13, weight: .heavy, design: .rounded)).tracking(1).padding(.top, 24)
                    Text(LocalizedStringKey(succeeded ? (result.level.isBoss ? "dino.bossWon" : "dino.wellDone") : "dino.keepPracticing"))
                        .font(.system(size: 34, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                    ZStack(alignment: .bottomTrailing) {
                        if sharedCompanion {
                            DinoCompanionAnchor(placement: .result, size: 210)
                        } else {
                            DinoCharacter(state: succeeded ? .celebrating : .thinking, size: 210,
                                          performsBackflip: result.correct == result.level.questionCount)
                        }
                        if result.level.isBoss && succeeded {
                            Image(systemName: "trophy.fill").font(.system(size: 75))
                                .foregroundStyle(DinoStyle.green)
                                .shadow(color: DinoStyle.ink.opacity(0.2), radius: 4, y: 4).offset(x: 18, y: 8)
                        }
                    }.frame(height: result.correct == result.level.questionCount ? 300 : 210, alignment: .bottom)
                    if result.level.isBoss {
                        if result.victory == .perfect { Label("dino.perfectBoss", systemImage: "sparkles").font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.deepGreen) }
                    } else { DinoStars(count: result.stars, size: 48) }
                    Text(verbatim: "\(result.correct)/\(result.level.questionCount)")
                        .font(.system(size: 42, weight: .heavy, design: .rounded)).monospacedDigit()
                    Text("dino.correctAnswers").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                    if !succeeded {
                        Text(LocalizedStringKey(result.level.isBoss ? (player.profile.normalLevelsComplete(in: result.level.worldID) ? "dino.needFive" : "dino.needPerfectOrRoute") : "dino.needThree"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                    }
                    VStack(spacing: 14) {
                        if nextAvailable {
                            Button(action: next) {
                                Label { Text(LocalizedStringKey(result.level.isBoss ? "dino.worldComplete" : "dino.next")) }
                                    icon: { Image(systemName: "arrow.right") }
                            }
                                .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("result.next")
                        }
                        Button(action: retry) { Label("dino.retry", systemImage: "arrow.clockwise") }
                            .buttonStyle(DinoButtonStyle(color: succeeded ? DinoStyle.ink : DinoStyle.green)).accessibilityIdentifier("result.retry")
                        Button("dino.map", action: map).buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("result.map")
                    }
                }.padding(26).frame(maxWidth: 460).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(DinoStyle.ink)
    }
}

struct WorldCompleteView: View {
    @EnvironmentObject private var player: DinoPlayer
    var worldID = 1
    var nextWorld: (() -> Void)? = nil
    var map: () -> Void
    var body: some View {
        ZStack {
            JungleBackground()
            ScrollView {
                VStack(spacing: 26) {
                    Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(DinoStyle.green).padding(.top, 30)
                    Text("dino.worldComplete").font(.system(size: 36, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                    DinoCharacter(state: .celebrating, size: 215)
                    Image(systemName: "trophy.fill").font(.system(size: 74)).foregroundStyle(DinoStyle.green)
                    Text(LocalizedStringKey(DinoWorldCatalog.world(worldID)!.titleKey))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    if player.profile.perfectVictory(in: worldID) { Text("dino.perfectBoss").font(.system(size: 18, weight: .bold, design: .rounded)) }
                    VStack(spacing: 16) {
                        if let next = DinoWorldCatalog.world(worldID + 1) {
                            WorldThemePreview(world: next)
                                .frame(height: 150).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
                                .accessibilityHidden(true)
                            Text(LocalizedStringKey(next.titleKey)).font(.system(size: 24, weight: .heavy, design: .rounded))
                            if let nextWorld {
                                Button("dino.nextWorld", action: nextWorld).buttonStyle(DinoButtonStyle())
                                    .accessibilityIdentifier("completion.nextWorld")
                            }
                        } else {
                            Image(systemName: "sparkles").font(.system(size: 54)).foregroundStyle(DinoStyle.green)
                            Text("dino.comingSoon").font(.system(size: 24, weight: .heavy, design: .rounded))
                            Text("dino.afterHundred").font(.system(size: 14, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                    }.frame(maxWidth: .infinity).dinoCard()
                    Button("dino.map", action: map).buttonStyle(DinoButtonStyle())
                }.padding(26).frame(maxWidth: 460).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(DinoStyle.ink)
    }
}
