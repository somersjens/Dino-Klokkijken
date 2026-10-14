# Levels oefenen — uitbreiding van 12 oktober 2026

Via **Instellingen → Levels oefenen** kiest de speler een tijdsoort in een raster van **drie kolommen en twee rijen**. Elke kaart heeft een klok: hele uren, halve uren, kwartieren, 10 minuten, 5 minuten en mix. De klokken volgen het gekozen klokontwerp van de speler.

Het overzicht bevat **21 unieke vraagtypen**, van makkelijk naar moeilijk. De twee- en vierkeuzeversies van analoog en digitaal aflezen zijn samengevoegd. Het spel gebruikt beide aantallen nog als variatie binnen deze typen.

Een gekozen type geeft onbeperkt nieuwe vragen. **Oplopend** doorloopt alle 21 typen op volgorde en begint opnieuw. **Mix** bevat per reeks van 21 vragen ieder type één keer in een willekeurige volgorde. Alleen de huidige vraag blijft in het geheugen. Oefenen bewaart geen levelvoortgang en verstuurt geen Game Center-resultaten. Sinds de update van 13 oktober worden eigen oefenrecords en vragentellers lokaal bewaard; zie hieronder. De reguliere wereld heeft de bestaande tien levels; deze uitbreiding is beschikbaar in het oefenoverzicht.

Alle nieuwe typen hebben een handmatig te openen voorbeeld achter het vraagteken, met een uitleg en een uitgewerkt antwoord. De interactieve voorbeeldvraag heeft een eigen sessie, zodat oefenen in de voorbeeldkaart de echte vraag en score niet beïnvloedt. Voorbeelden bevatten geen dino en openen nooit automatisch.

## Vraagtypen uit de aangeleverde tekst

| Nummer in uitwerking | Vraagtype in het oefenoverzicht |
| --- | --- |
| 1 | Lees de analoge klok af — bestaand |
| 2 | Bereken een latere tijd — nieuw |
| 3 | Bereken hoeveel tijd is verstreken — nieuw |
| 4 en 9 | Zet tijden op volgorde — één nieuw type |
| 5 | Woorden naar een analoge klok — nieuw |
| 6 | Draai de klok vooruit — nieuw |
| 7 | Maak de tijdreeks af — nieuw |
| 8 | Goed of fout? — nieuw |
| 10 | Digitale tijd in woorden — nieuw |
| 11 | Kies de analoge klok — bestaand |
| 12 | Verbind de klokken — nieuw, vier koppelingen met dagdeel en 24-uursnotatie |
| 13 | Lees de 24-uursklok af — nieuw |
| 14 | Kies het dagdeel — nieuw |
| 15 | Bereken een eerdere tijd — nieuw |
| 16 | Wanneer is de les afgelopen? — nieuw |
| 17 | Wanneer komt de vlucht aan? — nieuw |
| 18 | Bereken de tijd in een andere tijdzone — nieuw |
| 19 | Samenvatting van optellen, aftrekken en verstreken tijd — geen dubbel type |

De bestaande typen **Activiteit**, **Aangewezen klok**, **Digitale klok instellen** en **Analoge klok instellen** blijven beschikbaar.

## Bediening en antwoorden

- Bij sorteren tikt de speler vier kaarten in volgorde aan. Nogmaals tikken verwijdert de kaart uit de gekozen reeks. Na een fout antwoord staan de eigen en correcte reeks onder elkaar met rood en groen.
- Bij koppelen kiest de speler per analoge klok een digitale tijd. Elke tijd kan één keer worden gebruikt; een dagdeellabel maakt de 24-uursnotatie duidelijk. Na bevestigen wordt elke koppeling afzonderlijk beoordeeld.
- Bij de klok vooruitdraaien begint de bediening op de gegeven begintijd. Uur- en minutenwijzers zijn afzonderlijk te bedienen. Een fout antwoord toont de eigen en correcte klok naast elkaar.
- Tijdrekenen en reeksen gebruiken 24-uursnotatie en kunnen middernacht passeren. De berekening werkt met minuten binnen een dag, onafhankelijk van apparaatdatum of tijdzone.
- Vluchtvragen vermelden expliciet dat vertrek en aankomst dezelfde tijdzone gebruiken. Tijdzonevragen geven het verschil tussen stad A en B expliciet, inclusief een verschil van nul uur. Zo bevat de vraag alle benodigde informatie.
- Nacht is 00:00–05:59, ochtend 06:00–11:59, middag 12:00–17:59 en avond 18:00–23:59; de voorbeeldkaart vermeldt deze grenzen.

## Kerncontrole

`Tools/test-dino.sh` slaagt met **313.492 controles**. Dekking: alle 21 typen in iedere tijdsoort en selectiemodus, reproduceerbare vragen, unieke antwoordmogelijkheden, volledige gemengde reeksen, 24-uursnotatie, Nederlandse en Engelse tijdwoorden, middernacht, tijdzoneverschillen, sorteren, koppelen, voorbeelden en 1.000 achtereenvolgende antwoorden zonder opgeslagen voortgang of groeiende vragenlijst. De bestaande gameplay-, opslag-, synchronisatie- en sociale tests slagen eveneens.

Elke vraag wordt bij het eerste antwoord beoordeeld; dubbel tikken telt niet opnieuw. Antwoordtijd blijft begrensd tot 1–60 seconden per vraag. Een analoge klok vooruitzetten wordt op de wijzerstand beoordeeld, omdat een analoge wijzerplaat 01:00 en 13:00 gelijk toont.

## Schermcontrole

De Debug-build slaagt. Op **iPhone 17 / iOS 26.5** slagen het raster, twaalf opeenvolgende digitale oefenantwoorden, correct beantwoorden van koppelen en sorteren, alle 21 typen in oplopende en gemengde volgorde en het openen van alle vijftien nieuwe voorbeelden. Op **iPhone SE (3e generatie) / iOS 26.5** slagen het raster, beide nieuwe borden, handmatige voorbeelden, de digitale minutenbediening en twaalf opeenvolgende digitale oefenantwoorden. De vijf simulatorcontroles eindigen met **TEST SUCCEEDED**.

De eerste volledige reeks vond een crash bij het verlaten van een nieuwe vraagkaart: SwiftUI evalueerde de uitgaande kaart met de gegevens van een volgende, bestaande vraag. De renderer behandelt die overgang nu expliciet. De hercontrole doorloopt ook de overgang terug naar het eerste type en alle gemengde vraagwissels.

De [3×2 tijdkeuzes op iPhone SE](Screenshots/Practice/practice-grid-and-types-iphone-se.png), [koppelingen](Screenshots/Practice/practice-expanded-pairs-ready-iphone.png), [sorteerbord](Screenshots/Practice/practice-expanded-sorting-ready-iphone.png), [wijzervergelijking](Screenshots/Practice/practice-expanded-advanceAnalog-iphone.png), [tijdreeks](Screenshots/Practice/practice-expanded-timeSequence-iphone.png) en [tijdzonevraag](Screenshots/Practice/practice-expanded-timeZone-iphone.png) zijn opgeslagen en visueel gecontroleerd.

## Oefenscherm en records — 13 oktober 2026

De koppen **Soort tijd oefenen** en **Type vraag** staan gecentreerd, zonder pictogrammen. De toelichting ‘Van makkelijk naar moeilijk’ is verwijderd. **Oplopend** selecteren of het informatieknopje ernaast openen toont de uitleg als pop-up. Iedere vraagoptie heeft een zachte eigen achtergrondkleur en een trofee met het record voor de geselecteerde tijdsoort.

De opbouw van het oorspronkelijke scherm bevatte zes GeometryReaders, zes interactieve klokbomen met ieder zestig losse maatstreepjes en een direct opgebouwde lijst van 21 opties. Bovendien kreeg de volledige lange vraagkaart een vervaagde schaduw. De oefenklokken gebruiken nu elk één statische Canvas zonder gebaren of losse layout voor maatstreepjes. De lijst gebruikt een LazyVStack; de grote kaartoppervlakken hebben een eenvoudige achtergrond zonder de grote schaduwrendering. De klokken blijven het gekozen klokontwerp volgen. De achterliggende wereldkaart is tijdens het oefenscherm uitgesloten van bediening en toegankelijkheid; daardoor bevat het scherm geen verborgen kaartacties.

Oefenen gebruikt dezelfde `AdventureHeader` als een normaal level: **Reeks · Vraag · Voorbeeld · Pauze**, met hetzelfde dinoportret. Onder Reeks staat klein een trofee met het persoonlijke record. Een nieuw record groeit direct mee na elk goed antwoord. Een fout antwoord zet de huidige reeks voor dit vraagtype op nul. De actieve reeks blijft sinds de vervolgaanpassing lokaal bewaard bij pauzeren, opnieuw oefenen en herstarten van de app. Alleen een fout antwoord in die combinatie of het resetten van voortgang breekt die reeks. In Oplopend en Mix wordt de reeks per vraagtype bijgehouden.

De recordhoogte en het aantal beantwoorde vragen worden per combinatie van tijdsoort en vraagtype lokaal opgeslagen, los van levelvoortgang en iCloud-/Game Center-scores. Nieuwe typen beginnen bij vraag 1. Tijdens antwoordfeedback blijft hetzelfde vraagnummer staan; bij de volgende vraag stijgt de teller. Na opnieuw openen gaat die teller verder. Voorbeeldvragen, onbeantwoorde vragen en dubbele tikken tellen niet extra mee. Het resetten van voortgang of alle appgegevens verwijdert ook de oefenrecords.

De grote vraagcijfers tonen 0–999. Vraag 1000 verschijnt als **0**, met daaronder **1k**; vraag 1999 is **999** met **1k**. De kleine teller loopt tot **999k**. Na één miljoen begint uitsluitend de zichtbare teller opnieuw; het opgeslagen totaal blijft oplopen. De grote waarden Reeks en Vraag blijven dezelfde HUD-lettergrootte delen.

### Verificatie van deze update

De actuele Debug-build slaagt. `Tools/test-dino.sh` slaagt met **394.693 controles**, inclusief opslag, onafhankelijke combinaties, reeksbreuk, dubbele antwoorden, voorbeelden, opnieuw openen, alle drie de oefenmodi, resetten en de grenzen 999, 1000, 1999 en 999k.

Op aparte **iPhone 17**, **iPhone SE (3e generatie)** en **iPad (A16)** met iOS 26.5 slaagt `testPracticeHUDRecordsAndPersistentCounter`: twee goede antwoorden maken direct record 2; een fout zet de reeks op nul; een andere tijdsoort toont een eigen record; opnieuw starten hervat vraag 4 met record 2 en reeks 0. De pop-up en overgang van 999 naar 0 met 1k slagen op alle drie de formaten. Twaalf opeenvolgende digitale oefenvragen en de normale game-HUD zijn eveneens gecontroleerd.

De geautomatiseerde open-/scrolltest (openen, drie keer omhoog en drie keer omlaag, sluiten; drie herhalingen) meet **22,779 seconden** bij de nulmeting en **18,051 seconden** na de wijzigingen, ongeveer 21% korter. Dit is de totale duur van het UI-testscenario, inclusief gebaren en XCTest-wachttijden; het is geen FPS-meting of garantie voor de snelheid op fysieke apparaten.

De schermcontrole vond en verholp extra lege ruimte rond de klokvoorbeelden op iPad en een dubbel voorleeslabel voor de trofee. De tests scrollen nu met kleine bewegingen naar langzaam geladen opties, zodat ze ook op kleine schermen de juiste rij selecteren.

- [Overzicht op iPhone](Screenshots/PracticeUpdate/overview-iphone.png)
- [Reeks 2 en record 2 op iPhone](Screenshots/PracticeUpdate/hud-record-iphone.png)
- [Hervat na herstart op iPhone](Screenshots/PracticeUpdate/hud-resumed-iphone.png)
- [Overzicht op iPhone SE](Screenshots/PracticeUpdate/overview-iphone-se.png)
- [1k-teller op iPhone SE](Screenshots/PracticeUpdate/hud-thousand-iphone-se.png)
- [Overzicht op iPad](Screenshots/PracticeUpdate/overview-ipad.png)
- [1k-teller op iPad](Screenshots/PracticeUpdate/hud-thousand-ipad.png)
- [Build- en recordtestlogs](PracticeUpdateTestLogs)

## HUD en pauzeren — vervolgaanpassing van 13 oktober 2026

De **actieve reeks** wordt nu bij elk antwoord samen met het record en het aantal antwoorden opgeslagen. Pauzeren, opnieuw starten vanuit het oefenoverzicht, wisselen van oefenmodus en een volledige appherstart behouden de reeks per tijdsoort en vraagtype. Een volgend goed antwoord verlengt de bewaarde reeks; een fout antwoord breekt die reeks. Bestaande opslag zonder het nieuwe veld behoudt het record en de teller. Voorbeeldvragen blijven buiten deze opslag.

Pauze in oefenen gaat direct naar het oefenoverzicht, zonder bevestigingskaart. Gewone levels behouden hun bestaande bevestiging na de eerste vraag. De HUD toont nu **Vraag** / **Question** in beide spelvormen.

Het record staat in een kleine medaillebadge met een gouden trofee, lichte vulling en groene rand uit het HUD-palet. De k-teller gebruikt dezelfde badgevorm. Onder de HUD zit een aangehecht hoofdstukplaatje: het gekozen vraagtypenummer, de oplopende pijl of het mix-symbool, gevolgd door de tijdsoort. De losse regel met tijdsoort en volledige vraagtypenaam in het speelveld is verwijderd. De voorbeeldknop verandert tijdens antwoordfeedback niet meer van helderheid.

`Tools/test-dino.sh` slaagt met **394.699 controles**. De Debug-build slaagt. Op aparte iPhone 17- en iPhone SE-simulatoren met iOS 26.5 slagen de bewaarde reeks na pauze en appherstart, hervatten van de teller, direct verlaten zonder waarschuwing, alle drie de ondertitels en de indeling in liggende stand. De normale game-HUD met het enkelvoudige vraaglabel slaagt op iPhone 17. De 999→0/1k-overgang met de nieuwe badge slaagt op iPhone SE. De feedback-HUD is visueel gecontroleerd op een onveranderde voorbeeldknop.

- [Nieuwe badge en aangehechte ondertitel](Screenshots/PracticeHUDFollowup/record-iphone.png)
- [Dezelfde reeks na pauzeren](Screenshots/PracticeHUDFollowup/paused-and-resumed-iphone.png)
- [Reeks na volledige appherstart](Screenshots/PracticeHUDFollowup/after-relaunch-iphone-se.png)
- [Oplopend](Screenshots/PracticeHUDFollowup/ascending-iphone.png)
- [Mix](Screenshots/PracticeHUDFollowup/mix-iphone.png)
- [Kleine iPhone in liggende stand](Screenshots/PracticeHUDFollowup/landscape-iphone-se.png)
- [Heldere voorbeeldknop tijdens feedback](Screenshots/PracticeHUDFollowup/feedback-iphone.png)
- [Normale game met Vraag](Screenshots/PracticeHUDFollowup/normal-game-iphone.png)

## Grotere ondertitel en bovenste badges — 14 oktober 2026

Tekst, symbool en typecirkel van de aangehechte HUD-ondertitel zijn 20% vergroot. De ovaal heeft daarnaast meer binnenruimte links en boven/onder de cirkel. Extra ruimte onder de HUD voorkomt overlap met de vraag.

De recordbadge staat boven **Reeks**. De k-badge staat, vanaf vraag 1000, op dezelfde hoogte boven de vraagkolom. De grote cijfers staan weer op dezelfde hoogte als de actie-iconen. In liggende stand reserveert de HUD ook bovenruimte voor de badges.

De Debug-build en de bestaande controles voor Oplopend/Mix, liggende indeling en de overgang 999→0/1k slagen op iPhone SE / iOS 26.5. Het [controlebeeld met beide bovenste badges](Screenshots/PracticeHUDFollowup/larger-subtitle-top-badges-iphone-se.png) toont het grotere plaatje en de extra ruimte rond de typecirkel.

## Grotere recordbadge en gelijktijdige tellers — 14 oktober 2026

De gouden trofee en het recordgetal zijn vergroot (14 pt op iPhone, 18 pt op iPad en 11 pt in de compacte HUD). Meer binnenruimte en een duidelijkere rand verbinden de capsule met de HUD. De grotere badge valt verder over de bovenrand, zonder de titel Reeks te bedekken.

Reeks, record en Vraag worden nu samen bijgewerkt wanneer de volgende vraag verschijnt. Tijdens de antwoordfeedback blijven de getoonde waarden bij de huidige vraag. Na een fout antwoord veranderen de reeks en het vraagnummer samen bij Verder. Het antwoord wordt direct opgeslagen; pauzeren of herstarten tijdens feedback verliest geen voortgang. De HUD-waarden worden in één gepubliceerde toestand bijgehouden, zodat tussenstanden niet zichtbaar kunnen worden.

`Tools/test-dino.sh`: **394.890 controles geslaagd**, inclusief één gezamenlijke tellerupdate, goed/fout antwoord, dubbele inzending en direct opslaan. Op iPhone 18 Pro / iOS 27 slagen de drie gerichte HUD-tests voor tellers/opslag, alle ondertitels/liggende weergave en de 999→0/1k-overgang. Op iPad A16 / iOS 27 slagen tellers/opslag en ondertitels/liggende weergave. De grotere badge is visueel beoordeeld op beide apparaten. De Debug-build en `git diff --check` slagen.

- [Grotere badge op iPhone](Screenshots/PracticeHUDCounters/record-iphone.png)
- [Grotere badge op iPad](Screenshots/PracticeHUDCounters/record-ipad.png)
- [Beide tellers blijven staan tijdens feedback](Screenshots/PracticeHUDCounters/feedback-iphone.png)
- [Beide tellers veranderen bij de volgende vraag](Screenshots/PracticeHUDCounters/next-question-iphone.png)
- [Controlelogs](PracticeHUDCounterTestLogs)
