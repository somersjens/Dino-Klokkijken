# Zwevende wereld-HUD

Het leveloverzicht en de game delen de SwiftUI-balk in `Dino/Views/AdventureHeader.swift`. De achtergrond buiten de balk is transparant. In het leveloverzicht loopt het junglelandschap door achter het menu; de HUD blijft zichtbaar tijdens het scrollen.

| Scherm | Onderdelen na het portret |
| --- | --- |
| Leveloverzicht | Level · Sterren · Oefenen · Instellingen |
| Game | Level · Vraag · Voorbeeld · Pauze |
| Oefenen | Reeks · Vraag · Voorbeeld · Pauze; onderaan een aangehechte oefenondertitel |

De kroon en ster naast de koppen zijn verwijderd. Alle tekstkoppen staan gecentreerd en delen één lettergrootte, bepaald door het langste vertaalde woord. Als bijvoorbeeld ‘Instellingen’ minder ruimte heeft, worden alle vier de koppen evenveel verkleind. Tekst, cijfers, oefentegels, tandwiel, voorbeeld en pauze volgen hetzelfde wereldpalet als de bladeren en omlijning. De tekstkleur is een donkere variant van de wereldrand; hoog contrast maakt deze kleur donkerder zonder de wereldtint kwijt te raken. De berekende tekst-/papiercontrastverhouding is in alle tien werelden minimaal 4,5:1. Het oefenraster heeft vier afgeronde tegels met circa 1,4 punt tussenruimte, op de schermpixels afgeronde afmetingen en een donkere rand van één pixel. De zachte schaduw en dunne witte rand zijn verwijderd. Oefentegels en tandwiel zijn beide 10% kleiner; hun buitenste layoutvak en tikvlak behouden dezelfde maat.

De cijfers in het leveloverzicht zijn kleiner dan de iconen: hun zichtbare caphoogte is maximaal 80% van de icoonhoogte. Beide getallen delen dezelfde lettergrootte, gebaseerd op de breedste waarde. In de game delen het levelnummer en de vraagcounter eveneens één maat; een brede waarde zoals `8/10` verkleint dus ook het levelnummer. De caphoogte van het afgeronde lettertype bepaalt de maat en verticale of individuele tekstschaling is uitgeschakeld.

Het portret toont hoofd, nek en bovenlichaam uit de oorspronkelijke, gepersonaliseerde dinoafbeelding. De twee bandana-uiteinden en de twee bovenste stekels liggen voor de cirkel en de witte rand. De bandanacijfers blijven wit, behalve bij zeer lichte kleuren (relatieve sRGB-luminantie vanaf 0,70); dan wordt de opdruk zwart, ook in de andere dinoweergaven en animatieposes. De bladeren hebben verschillende maten en hoeken, een lichte vouw, gebogen nerven en schaduw. De eerste teller staat dichter bij het portret en bladeren worden achter de balk gemaskeerd, zodat ze geen cijfers bedekken. De linkermarge op telefoons is 4 punten.

Voorbeeld en pauze hebben een omlijning in de wereldkleur en een transparante binnenkant. De bestaande acties en toegankelijkheidslabels zijn behouden; voorbeeld blijft uitgeschakeld tijdens antwoordfeedback, met dezelfde helderheid tussen vragen.

De bladkleuren, portretcirkel, rand en scheidingslijnen komen uit hetzelfde wereldpalet als het landschap. Het leveloverzicht volgt de bovenkant van elk hoofdstuk onder de HUD, onafhankelijk van de voortgang van de speler. Bij een speler op level 90 krijgt terugscrollen naar wereld 1 dus het junglepalet; omlaag scrollen naar wereld 2 geeft het palet van wereld 2. De overgang duurt 0,25 seconde. In de game wordt de wereld van het actieve level gebruikt. Het vaste `session.level.worldID` bepaalt het volledige palet, ook bij een volgende vraag, antwoordfeedback of een voorbeeldkaart.

De balk is maximaal 780 punten breed. De HUD reserveert 128 punten op telefoons en 160 op tablets, met 12 punten boven en 16 onder het portret inclusief bladeren. De extra ruimte onderaan vangt de schaduw op. In telefoonlandschap gebruikt de HUD een kleiner portret en 82 punten hoogte, met 6 punten boven en 8 onder. Hoog contrast versterkt de randen; Minder beweging schakelt de druk- en kleurovergangsanimatie uit.

## Beelden

- [Leveloverzicht op iPhone](Screenshots/HUD/map-iphone.png)
- [Game op iPhone](Screenshots/HUD/game-iphone.png)
- [Speler op level 90, kaart bij wereld 1](Screenshots/HUD/world-1-level-90.png)
- [Dezelfde speler, kaart bij wereld 2](Screenshots/HUD/world-2-level-90.png)
- [Dezelfde speler, kaart bij wereld 9](Screenshots/HUD/world-9-level-90.png)

## Controles — 13 oktober 2026

De laatste Debug-app en UI-testbundle bouwen succesvol met Xcode 27. Op een geïsoleerde iPhone 17 / iOS 26.5 slagen beide gerichte tests zonder fouten:

- `testContextualHUDAndFirstQuestionExit`: gelijke celhoogtes, uitlijning, minimaal 44 punten brede cellen, oefenen, instellingen, vraagcounter, voorbeeld en verlaten vóór en na de eerste vraag.
- `testHUDThemeFollowsScrollInsteadOfPlayerLevel`: voortgang op level 90, herstellen naar wereld 9, terugscrollen naar wereld 1, omlaag naar wereld 2 en weer terug. Het wereldlabel verandert telkens en de levelcounter blijft 90.

De vijf actuele iPhone-beelden hierboven zijn visueel gecontroleerd op cijfergrootte, gelijke koppen, bladplaatsing, transparante knoppen en wereldkleuren. [De geslaagde build- en testlog](HUDTestLogs/world-theme-iphone.log) is bewaard. `git diff --check` geeft geen fouten.

De brede kaarttest heeft daarnaast een bestaande fout in de verwachting voor de voeten van de kaartdino: de code plaatst die op het midden van de levelknop plus 12 punten, terwijl de test midden min 24 verwacht. Beide waarden stonden al in `HEAD`; deze HUD-aanpassing wijzigt ze niet.

De eerdere portret- en knopvariant is ook gecontroleerd op iPhone 18 Pro / iOS 27, iPhone SE (3e generatie) / iOS 26.1 en iPad (A16) / iPadOS 26.5. Op iPhone 18 Pro slaagden toen ook `testLayoutAndLanguage` en `testPersonalizeHeaderColors`, inclusief opgeslagen kleuren, koude herstart, personaliseren tijdens een level en landschap. Die eerdere [loguitkomsten](HUDTestLogs) en beelden blijven bewaard; de laatste kleur- en schaalcorrecties zijn met de iPhone 17-controles hierboven gevalideerd.

## Wereldkleur en scherpte — 13 oktober 2026

De kaarticonen zijn met 10% verkleind, met behoud van de labeluitlijning en oorspronkelijke tikvlakken. Het oefenraster gebruikt scherpe, donker omlijnde vectorvormen zonder zachte schaduw. Het volledige HUD-palet, inclusief tekst, cijfers, oefentegels en actieknoppen, volgt de zichtbare wereld op de kaart en de vaste wereld van het actieve level.

De app en UI-testbundle bouwen succesvol met Xcode 27. `testContextualHUDAndFirstQuestionExit` slaagt op een geïsoleerde iPhone 17 en iPad (A16), beide met iOS 26.5. `testHUDThemeFollowsScrollInsteadOfPlayerLevel` slaagt op de iPhone. `testNativeWorldChaptersAndMinuteQuestions` slaagt op de iPad voor alle negen latere werelden; de test controleert nu expliciet de HUD-wereld direct na levelstart en na het eerste antwoord. Wereld 1 is gecontroleerd in de gewone HUD-test.

De eerste brede wereldrun op iPhone miste de kaarttap op level 61 voordat de startkaart opende. De HUD-controles voor wereld 2 t/m 6 waren toen al geslaagd. Xcode bleef daarna hangen bij het afronden van de diagnostiek; die run is na afloop van alle testcases beëindigd. De afzonderlijke herhaling van de volledige wereldtest op iPad slaagde zonder fouten. De uitkomsten staan in [iPhone-log](HUDTestLogs/palette-iphone.log), [iPad-HUD-log](HUDTestLogs/palette-ipad.log) en [volledige iPad-wereldcontrole](HUDTestLogs/palette-worlds-ipad.log).

Visueel gecontroleerde beelden:

- [Kaart in wereld 9 op iPhone](Screenshots/HUDPalette/map-world-9-iphone.png)
- [Kleinere kaarticonen op iPad](Screenshots/HUDPalette/map-ipad.png)
- [Groene jungle-HUD tijdens een level](Screenshots/HUDPalette/game-ipad.png)
- [Vulkaanland tijdens de tweede vraag](Screenshots/HUDPalette/game-world-3-ipad.png)
- [Tijdpiraten tijdens de tweede vraag](Screenshots/HUDPalette/game-world-9-ipad.png)
- [Dinokasteel tijdens de tweede vraag](Screenshots/HUDPalette/game-world-10-ipad.png)

## Optische cijferuitlijning — 14 oktober 2026

Het afgeronde lettertype reserveert voor de smalle 1 dezelfde breedte als voor andere cijfers. Het zichtbare gewicht ligt daardoor bij bijvoorbeeld `1`, `10` en `1/5` iets rechts van het middelpunt. De HUD berekent nu per waarde een subtiele horizontale correctie op basis van de zichtbare cijfermassa, met maximaal 6% van de lettergrootte. Een 1 achteraan kan juist een verschuiving naar rechts nodig hebben. De vaste cijferbreedtes, gedeelde lettergrootte, celmaten en bestaande acties blijven behouden. De correctie wordt ook toegepast op oefencijfers, recordbadges en het vraagtypenummer. De meting wordt per waarde bewaard; het zichtbare resultaat blijft gewone SwiftUI-tekst.

Met het echte iOS-lettertype is de afwijking gecontroleerd voor losse, dubbele en driedubbele cijfers en vraagtellers, waaronder `1`, `10`, `11`, `21`, `100`, `111`, `1/5`, `1/10` en `8/10`. Bij 40 punten is de correctie voor de losse 1 ongeveer 1,13 punt naar links; voor `10` en `1/5` 2,4 punten naar links. [De metingen](HUDTestLogs/number-alignment-font-measurements.txt) zijn bewaard.

De Debug-app en UI-testbundle bouwen succesvol. Op een geïsoleerde iPhone 17 met iOS 26.5 slagen `testContextualHUDAndFirstQuestionExit` en `testPracticeHUDSubtitleModes`, inclusief de oefen-HUD in liggende stand, met nul fouten. [Testlog](HUDTestLogs/number-alignment-iphone.log). `git diff --check` geeft geen fouten.

- [Leveloverzicht met gecentreerde 1](Screenshots/HUDNumberAlignment/map-iphone.png)
- [Game met level 1 en vraag 1/5](Screenshots/HUDNumberAlignment/game-iphone.png)
- [Oefen-HUD](Screenshots/HUDNumberAlignment/practice-iphone.png)
- [Oefen-HUD in liggende stand](Screenshots/HUDNumberAlignment/landscape-iphone.png)
