# Mos en verbonden bladwerk — 25 oktober 2026

Het mos op de resultaatstenen is opnieuw getekend. De gladde, dikke kappen zijn vervangen door dunnere begroeiing langs de steenrand, met onregelmatig verdeelde moskussentjes, fijne scheutjes en subtiele lichtverschillen. Links en rechts verschillen in omvang. De jungle gebruikt warmer groen, het dorp lagere mosplekjes en de Slaapvallei koelere, lagere begroeiing.

De hangende junglebladeren groeien nu aan korte gebogen ranken die in het mos beginnen. Iedere bladsteel wordt berekend vanaf dezelfde curve als de hoofdrank; er zijn geen apart geplaatste blaadjes meer. De bladeren hebben dezelfde contour, nerven, vouw en belichting als het grotere junglebladwerk. De lagere planten in dorp en vallei gebruiken ook die gedeelde bladvormen. De dubbele, eenvoudigere bladgroep aan de voet van de junglesteen is verwijderd.

Alle wijzigingen zijn native SwiftUI/Canvas-tekeningen in `Dino/Views/ResultWorldPodium.swift` en `Dino/Views/LevelResult.swift`. De sterren blijven rechtstreeks op het doorlopende wereldmateriaal staan. De bestaande podiumproporties en extra tekenruimte rondom het object blijven behouden.

## Controle van de werelden

Alle tien werelden zijn op eigen iPhone 17- en iPad Pro 11-inch (M5)-simulators met iOS 26.5 bekeken, zowel als complete scène als in een uitsnede van de steen.

| Wereld | Visueel gecontroleerd |
| --- | --- |
| 1 · Jungle | Fijne mosstructuur, aansluiting op de rand, verbonden bladstelen, voorgrondplanten |
| 2 · Woestijn | Droge steenlagen, fossielen en aansluiting op zand, zonder junglebeplanting |
| 3 · Vulkaanland | Basaltzuilen, breuken en vrije sterpunten |
| 4 · Klokdorp | Lager mos op de kroonlijst, gedetailleerde bladeren en bloembakken |
| 5 · Kristalgrot | Volledige kristalpunten, facetten en aansluiting op de grotbodem |
| 6 · Klokstad | Metalen randen, ventilatieroosters, lampen en sterruimte |
| 7 · Slaapvallei | Koel mos, bladnerven, voorgrondplanten en paddenstoelen |
| 8 · Tijdmachine | Leidingen, meters, tandwielen en volledige onderrand |
| 9 · Tijdpiraten | Aanhechting van het touw, plankoppervlak, palen en schelpen |
| 10 · Tijdkasteel | Banieren, metselwerk, voetlijst en vrije sterpunten |

- Debug-testbuild: geslaagd.
- `testAllWorldResultScenery`: geslaagd op iPhone en iPad, twintig wereldbeelden en bereikbare bediening.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart en eindbaasresultaten.
- Drie UI-testuitvoeringen, nul fouten. Ook de vier beloningsstaten zijn visueel bekeken.
- Aanvullend visueel gecontroleerd op een eigen iPhone SE (3e generatie, iOS 26.1): wereld 1, 4, 7, 6, 9 en het resultaat van level 100 met extra uitleg. Begroeiing en sterren blijven volledig zichtbaar en de bediening past op het scherm.
- `git diff --check`: schoon.

[Build](WorldTestLogs/ResultBotanicalFinish/build.log) · [iPhone](WorldTestLogs/ResultBotanicalFinish/iphone.log) · [iPad](WorldTestLogs/ResultBotanicalFinish/ipad.log) · [Kleine iPhone](WorldTestLogs/ResultBotanicalFinish/compact.log).

## Beelden

[Mos en bladwerk voor en na](Screenshots/ResultBotanicalFinish/mos-en-bladwerk-voor-na.jpg) · [Alle podiums op iPhone](Screenshots/ResultBotanicalFinish/podiums-iphone.jpg) · [Alle podiums op iPad](Screenshots/ResultBotanicalFinish/podiums-ipad.jpg).

[Complete wereldscènes op iPhone](Screenshots/ResultBotanicalFinish/werelden-iphone.jpg) · [Complete wereldscènes op iPad](Screenshots/ResultBotanicalFinish/werelden-ipad.jpg).

[Nul tot drie sterren](Screenshots/ResultBotanicalFinish/beloningsstaten.jpg) · [Kleine iPhone](Screenshots/ResultBotanicalFinish/compact/overzicht.jpg).

De vergelijking gebruikt twee echte appopnames. De beelden zijn alleen uitgesneden en met behoud van hun verhouding verkleind.
