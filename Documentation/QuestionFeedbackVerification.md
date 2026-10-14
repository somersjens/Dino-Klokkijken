# Vraagtypen en voorbeelden — 14 oktober 2026

De nummers hieronder volgen de aangeleverde feedback. De oefenlijst bevat nu twintig vraagtypen; door het verwijderen van de activiteitvraag schuiven latere nummers op.

| Feedback | Verwerkt gedrag |
| --- | --- |
| 1 & 2 | De aanwijspijlen staan naast de wijzers. De punten, pijlhoofdjes en lijnen blijven vrij van beide wijzers, ook bij twaalf uur en bij bijna samenvallende wijzers. De nummers gebruiken de gekozen wijzerkleuren. |
| 5 | De titel bevat de tijd: ‘Welke klok laat zes uur zien?’ De tijd krijgt een blauwe tint. Het voorbeeld gebruikt dezelfde titelopbouw. |
| 6 | De dubbele activiteitvraag is verwijderd uit de oefenlijst, oplopende reeks en mix. Bestaande opgeslagen activiteitrecords blijven behouden. |
| 7 | De uitspraak staat in de titel: ‘Het is nu drie uur.’ De tijd heeft dezelfde blauwe tint. De antwoorden zijn Goed en Fout. Het voorbeeld volgt dezelfde opbouw. |
| 9 | Drie analoge klokken staan naast drie digitale tijden. Tik eerst op de ene kaart en daarna op de andere om een lijn te maken. Beide tapvolgordes werken. Een tijd kan aan één klok gekoppeld zijn. Een tik op een verbonden klok of tijd verbreekt het paar en wist de pending selectie; daarna kan een nieuw paar worden gekozen. Bevestigen kan zodra alle drie verbonden zijn. |
| 9, voorbeeld | Een handje met 1 kiest een klok, daarna kiest een handje met 2 de tijd. Vervolgens verschijnt de lijn. Dit herhaalt zich voor alle drie de paren. De speler kan de demonstratie overnemen. |
| 10 | Plus en min staan naast de digitale display en bedienen het onderstreepte cijferpaar. Tik ergens op het klokje om tussen uren en minuten te wisselen. Het voorbeeld opent met het andere paar geselecteerd dan de echte vraag. Bij een uurovergang bewegen de uren mee: 05:55 + 5 minuten = 06:00 en terug = 05:55. Analoge knoppen en het slepen van de minutenwijzer volgen dezelfde regel. |

Bij een fout meerkeuzeantwoord met meer dan twee opties blijven de andere keuzes beschikbaar. Linksonder verschijnt **Toon antwoord** of **Show answer**. Eerdere foute keuzes blijven rood; het juiste antwoord blijft verborgen tot de speler goed kiest of de knop gebruikt. Daarna verschijnt **Verder/Next**, met behoud van de verloren punt en de oorspronkelijke antwoordtijd. Oefenrecords en vragentellers veranderen slechts één keer per vraag. Twee-optievragen houden de directe feedback.

Een nieuw voorbeeld wist alleen de voorbeeldselecties. De echte vraag, koppelingen, invoertijd en records blijven behouden. Verkeerde koppelingen krijgen rode lijnen; groene stippellijnen tonen de juiste verbindingen.

## Controles

- Debug-build voor iOS Simulator: geslaagd.
- `Tools/test-dino.sh`: 444.891 controles geslaagd. De wijzercontrole gebruikt alle 720 klokstanden per wijzerdikte, met beide pijlhoofdjes. Koppelvragen worden gecontroleerd in oefenen en de levels, inclusief onvolledige en verkeerde antwoorden. Aanvullende controles bewaken alle minuutstappen en uurovergangen, herkansingen, verloren punten, antwoordtijd en oefenrecords.
- iPhone 17 en iPhone 17 Pro / iOS 26.5 en iPad Pro 11-inch (M5) / iOS 26.5: de tijdtitels, veldwisseling en koppelvraag zijn met echte taps gecontroleerd. De screenshots zijn visueel bekeken.
- `testQuestionTitlesIncludeTimeInWords`: tijden in beide titels en voorbeelden, geen dubbele tijdkaart, Goed/Fout en geen activiteitkeuze.
- `testThreePairMatchingAndTapDemonstration`: drie kaarten per kolom, beide tapvolgordes, verbreken via beide kanten van een paar, wissen van pending selecties, opnieuw verbinden, bevestigen, voorbeeldanimatie, vernieuwen, behoud van echte antwoorden en foutfeedback.
- `testDigitalClockSwitchesFieldsAndExampleUsesOtherField`: aantikken aan de rand, plus/min voor het geselecteerde paar, knoppen naast de display, beide voorbeeldvarianten en behoud van echte invoer.
- `testNumberedExamplesAdvanceWholeHours`, `testManualExamplesAndClockComparison` en `testPracticeSelectionAndEndlessDigitalMinutes`: voorbeelden bij twaalf uur, gewone levels en herhaald beantwoorden met de gewijzigde klokbediening.
- De drie interactiewijzigingen zijn gecontroleerd met vier geslaagde schermtests op iPhone 18 Pro / iOS 27.0 en vijf op iPad Air 13-inch (M4) / iOS 27.0, zonder fouten. De relevante screenshots zijn visueel bekeken.
- `testClockMinuteControlsCarryTheHourBothWays`: 05:55 → 06:00 → 05:55 via digitale knoppen, de analoge minutenwijzer en analoge knoppen; het digitale voorbeeld gaat mee over het uur en behoudt de echte invoer.
- `testMultipleChoiceRetriesKeepTheLostPoint` en `testFourChoicesAndPersistentWrongAnswer`: foute keuzes uitschakelen, andere opties beschikbaar houden, handmatig verder na correctie of tonen, en geen herstelde oefenreeks of extra vraag.
- `testShowAnswerEnglishAndTwoChoiceFeedback`: Engelse knopteksten **Show answer/Next** en directe eindfeedback bij twee opties.

## Beelden

- [Tijd in de vraagtitel](Screenshots/QuestionFeedback/question-title-spokenTime-iphone.png)
- [Goed/Fout in het voorbeeld](Screenshots/QuestionFeedback/question-title-example-trueFalse-iphone.png)
- [Drie gekoppelde klokken](Screenshots/QuestionFeedback/matching-three-pairs-ready-iphone.png)
- [Twee taps in het voorbeeld](Screenshots/QuestionFeedback/matching-example-first-line-iphone.png)
- [Digitale bediening met geselecteerde minuten](Screenshots/QuestionFeedback/digital-example-minutes-selected-iphone.png)
- [Aanwijspijlen bij twaalf uur](Screenshots/QuestionFeedback/numbered-example-12-iphone.png)
- [Koppelvoorbeeld op iPad](Screenshots/QuestionFeedback/matching-example-all-lines-ipad.png)
- [Digitale bediening op iPad](Screenshots/QuestionFeedback/digital-example-minutes-selected-ipad.png)

## Koppelvragen samengevoegd — 14 oktober 2026

Vraagtype 10 (`pairClocks`) is verwijderd uit het oefenoverzicht, Oplopend, Mix, de generator, voorbeeldweergave en vertalingen. Levels met dit type gebruiken voortaan de bestaande koppelvraag (`match`, type 7). Er zijn nu 19 vraagtypen; het oude type 11 is type 10 en de volgende typen schuiven eveneens één positie op. Bestaande oefenrecords blijven gekoppeld aan hun vaste sleutels.

Type 7 ondersteunt naast beide tikvolgordes ook indrukken en loslaten op de kaart aan de andere kant, in beide richtingen. Tijdens het slepen volgt een lijn de vinger. Een nieuwe verbinding vervangt eventuele eerdere verbindingen aan die eindpunten. Loslaten in de tussenruimte of op dezelfde kant verandert bestaande paren niet. De bestaande uitlegtekst is behouden.

`Tools/test-dino.sh` slaagt met 437.231 controles, inclusief de nieuwe nummering, alle 19 typen in Oplopend en Mix en geldige koppelvragen in alle werelden. De Debug-build slaagt. `testMatchingSupportsDragsAlongsideTaps` slaagt op iPhone 18 Pro en iPad Air 13-inch (M4), beide met iOS 27.0: heen en terug slepen, een bezette tijd overnemen, loskoppelen met een tik, ongeldige drops, combineren met losse tikken en correct bevestigen. De screenshots zijn visueel gecontroleerd.

Ook `testThreePairMatchingAndTapDemonstration` slaagt op beide apparaten, inclusief beide tikvolgordes, verbreken, het geanimeerde voorbeeld en foutfeedback. Op iPhone slaagt daarnaast `testExpandedPracticeExamplesAndBoards` met de samengevoegde koppelvraag en het sorteerbord: vijf schermtests in totaal, zonder fouten.
