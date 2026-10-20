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
| 10 (nu vraagtype 8) | De volledige gekozen digitale klok blijft behouden, met losse pijltjes boven en onder de uren en minuten. De compacte controleknop heeft vaste donkerblauwe en witte kleuren. Alle vier pijltjes zijn direct beschikbaar, in de vraag en in het voorbeeld. Digitale minuten worden apart ingesteld: 05:55 → 05:00 → 05:55. Bij de analoge klok blijven de uren bij een uurovergang meebewegen. |

Bij een fout meerkeuzeantwoord met meer dan twee opties blijven de andere keuzes beschikbaar. Linksonder verschijnt **Toon antwoord** of **Show answer**. Eerdere foute keuzes blijven rood; het juiste antwoord blijft verborgen tot de speler goed kiest of de knop gebruikt. Daarna verschijnt **Verder/Next**, met behoud van de verloren punt en de oorspronkelijke antwoordtijd. Oefenrecords en vragentellers veranderen slechts één keer per vraag. Twee-optievragen houden de directe feedback.

Een nieuw voorbeeld wist alleen de voorbeeldselecties. De echte vraag, koppelingen, invoertijd en records blijven behouden. Verkeerde koppelingen krijgen rode lijnen; groene stippellijnen tonen de juiste verbindingen.

## Controles

- Debug-build voor iOS Simulator: geslaagd.
- `Tools/test-dino.sh`: 444.891 controles geslaagd. De wijzercontrole gebruikt alle 720 klokstanden per wijzerdikte, met beide pijlhoofdjes. Koppelvragen worden gecontroleerd in oefenen en de levels, inclusief onvolledige en verkeerde antwoorden. Aanvullende controles bewaken alle minuutstappen en uurovergangen, herkansingen, verloren punten, antwoordtijd en oefenrecords.
- iPhone 17 en iPhone 17 Pro / iOS 26.5 en iPad Pro 11-inch (M5) / iOS 26.5: de tijdtitels, veldwisseling en koppelvraag zijn met echte taps gecontroleerd. De screenshots zijn visueel bekeken.
- `testQuestionTitlesIncludeTimeInWords`: tijden in beide titels en voorbeelden, geen dubbele tijdkaart, Goed/Fout en geen activiteitkeuze.
- `testThreePairMatchingAndTapDemonstration`: drie kaarten per kolom, beide tapvolgordes, verbreken via beide kanten van een paar, wissen van pending selecties, opnieuw verbinden, bevestigen, voorbeeldanimatie, vernieuwen, behoud van echte antwoorden en foutfeedback.
- `testDigitalClockHasIndependentHourAndMinuteArrows`: vier direct beschikbare knoppen van minstens 44 × 44 punten, pijltjes boven en onder het bijbehorende cijferpaar, afwisselend uren en minuten aanpassen, een volgend voorbeeld en behoud van de echte invoer.
- `testNumberedExamplesAdvanceWholeHours`, `testManualExamplesAndClockComparison` en `testPracticeSelectionAndEndlessDigitalMinutes`: voorbeelden bij twaalf uur, gewone levels en herhaald beantwoorden met de gewijzigde klokbediening.
- De drie interactiewijzigingen zijn gecontroleerd met vier geslaagde schermtests op iPhone 18 Pro / iOS 27.0 en vijf op iPad Air 13-inch (M4) / iOS 27.0, zonder fouten. De relevante screenshots zijn visueel bekeken.
- `testDigitalMinutesWrapAndAnalogMinutesCarry`: digitale minuten gaan van 55 naar 00 en terug zonder het uur te wijzigen; analoge minuten blijven het uur meenemen. Het digitale voorbeeld behoudt de echte invoer.
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

## Vraagtypen en voorbeelden — 15 oktober 2026

- **Dagdeel kiezen:** vragen gebruiken geen 06:00–06:59 of 22:00–23:59. De voorbeelden blijven de volledige dag doorlopen, inclusief deze tijden. De vier dagdelen blijven beschikbaar.
- **Verbind de klokken:** tijdens het spelen staat alleen de titel boven het bord. Het voorbeeld bevat de volledige beschrijving van de twee tikvolgordes. De genummerde handjes en het opbouwen van de verbindingen blijven zichtbaar; de beschrijving wisselt niet meer tussendoor.
- **Stel de juiste tijd in (vraagtype 8):** sinds 18 oktober hebben uren en minuten eigen pijltjes boven en onder de cijfers. Spel en voorbeeld gebruiken dezelfde component. De veldselectie, onderstreping en verbindingslijnen zijn vervangen door de directe bediening.
- **Draai de korte wijzer:** bij een fout antwoord blijft de invoerklok dezelfde view en schuift hij verkleind naar links. De juiste klok verschijnt rechts op zijn uiteindelijke schaal. Dezelfde vergelijking wordt gebruikt bij het vooruitzetten van de analoge klok.
- **Lees de tijd en het dagdeel af:** het voorbeeld reserveert een vaste hoogte voor het antwoord. Een langer antwoord of een extra tekstregel verschuift de onderknoppen niet. Een nieuw voorbeeld vervangt de inhoud zonder overgangsanimatie.
- **Van vroeg naar laat:** 00:00 komt niet voor op het sorteerbord. De extra instructie staat alleen in het voorbeeld. Daar zijn alle vier klokken al geselecteerd en genummerd van vroeg naar laat, met de uitgewerkte volgorde eronder en zonder bevestigingsknop voor het antwoord.
- **Welke tijd komt hierna:** de extra uitleg staat alleen in het voorbeeld. Tussen elke twee tijden staat een pijl, ook van de laatste tijd naar het vraagteken. In het voorbeeld staat bij iedere pijl de werkelijke stap, bijvoorbeeld +2 uur of +30 min; de pijlen en digitale klokken passen zich aan de beschikbare breedte aan.

De filters zitten in de gedeelde vraaggenerator en gelden dus voor losse oefentypen, Oplopend, Mix en de betreffende levels. Voorbeelden gebruiken eigen invoer en veranderen de echte vraag of oefenrecords niet.

De kerncontroles omvatten alle minuutsoorten, de vier dagdelen, verboden tijden als voorkeursdoel, vier unieke sorteerkeuzes en voorbeelden op de grensminuten 00 en 59. `Tools/test-dino.sh`: **555.334 controles geslaagd**. De definitieve Debug-build voor iOS Simulator slaagt.

De digitale verbindingslijnen zijn in het spel en het voorbeeld visueel gecontroleerd op iPhone 17 en iPad Pro 11-inch met iOS 26.5. De analoge vergelijking is met een simulatoropname en beelden om de 50 milliseconden gecontroleerd: de invoerklok blijft zichtbaar, schuift en verkleint zonder extra klokbeeld. De VoiceOver-acties gebruiken een eigen toegankelijkheidsrepresentatie, zodat het uitschakelen van de bediening de zichtbare klok niet vervangt. `testManualExamplesAndClockComparison` en `testPracticeAnalogHandsAndManualExample` slagen, inclusief klokwaarden, slepen, minutenbediening en behoud van de echte invoer na een voorbeeld.

Op iPhone 18 Pro en iPad Air 13-inch met iOS 27.0 slagen `testDayPartExampleActionsStayInPlace` en `testQuestionInstructionsAndWorkedBoards`: 22 opeenvolgende voorbeeldwissels zonder verschuiving van de onderknoppen, uitleg uitsluitend in voorbeelden, vier vooraf geselecteerde en chronologisch genummerde sorteerklokken zonder bevestigingsknop, en drie pijlen met de werkelijke tijdstap. De screenshots van de voorbeelden zijn visueel gecontroleerd.

Ook `testThreePairMatchingAndTapDemonstration` slaagt op iPhone: verbinden in beide tikvolgordes, verbreken, opnieuw verbinden, geanimeerde voorbeeldverbindingen, behoud van echte selecties en foutfeedback. In totaal zijn twaalf gerichte schermtestuitvoeringen geslaagd, zonder fouten.

## Tijdenreeksen en tijdrekenen — 16 oktober 2026

- **Welke tijd komt hierna:** de digitale tijden staan groter onder elkaar, met neerwaartse pijlen tussen de stappen. De vraag eindigt met een vraagteken en behoudt de vier antwoordopties. Het voorbeeld toont het antwoord als laatste klok in dezelfde reeks. De 24-uursuitleg staat direct onder de vraagtitel. Rechts verbinden boogjes de opeenvolgende klokken; iedere tijdsprong staat naast het boogje, vrij van de pijl tussen de klokken. De boogjes volgen de werkelijke klokafmetingen, ook bij een andere cijferstijl.
- **Hoe laat is het straks** en **Bereken een eerdere tijd:** de vraag toont alleen de titel, een grotere digitale begintijd, het tijdsverschil en de antwoordopties. De labels **Het spelen begint om** en **Begintijd** en de extra uitleg zijn verwijderd. Het voorbeeld gebruikt dezelfde compacte opbouw met de 24-uursuitleg onder de titel en één uitgewerkt antwoord.

Deze weergaven worden gedeeld door oefenen en de levels, in Nederlands en Engels.

De Debug-build voor iOS Simulator slaagt. `testExpandedMultipleChoiceExamplesShowOneAnswer` slaagt op iPhone 17 / iOS 26.5: alle uitgebreide meerkeuzevoorbeelden tonen precies één uitgewerkt antwoord, behouden de vier opties in de echte vraag en veranderen de oefenteller niet. Ook `testQuestionInstructionsAndWorkedBoards` slaagt op dit apparaat, inclusief de drie tijdsprongen in de reeks. De screenshots van de drie aangepaste vraagtypen en hun voorbeelden zijn visueel gecontroleerd.

De iPad-schermcontrole kon niet worden afgerond: de testrunner op iPad Pro 11-inch / iOS 26.5 werd beëindigd met `signal kill`. Een afzonderlijke herhaling brak eveneens af. De iPad-weergave is hiermee niet bevestigd.

Beelden: [tijdenreeks in het voorbeeld](Screenshots/QuestionFeedback/sequence-example-vertical-iphone.png), [vooruitrekenen](Screenshots/QuestionFeedback/add-time-question-clean-iphone.png), [voorbeeld vooruitrekenen](Screenshots/QuestionFeedback/add-time-example-clean-iphone.png), [terugrekenen](Screenshots/QuestionFeedback/subtract-time-question-clean-iphone.png) en [voorbeeld terugrekenen](Screenshots/QuestionFeedback/subtract-time-example-clean-iphone.png).

## Directe digitale bediening — 18 oktober 2026

Vraagtype **8 – Digitale klok instellen** behoudt de volledige `DigitalClock` van de speler, inclusief achtergrond, vorm, cijfers en dubbele punt. Vier losse pijltjes staan erboven en eronder, gecentreerd op de werkelijke posities van de uren en minuten. De pijltjes hebben een aanraakvlak van 44 × 44 punten en eigen VoiceOver-labels en waarden. Ze zijn ook zichtbaar bij witte digitale cijfers, doordat hun kleur onafhankelijk van het display is.

**Controleer mijn klok** staat compact direct onder de bediening en behoudt de vaste donkerblauwe achtergrond met witte tekst, onafhankelijk van de gekozen klokkleuren. De vraag en het voorbeeld delen dezelfde digitale bediening. Het voorbeeld licht de pijltjes toe in Nederlands en Engels; sluiten behoudt de echte invoertijd.

De digitale instelvelden werken onafhankelijk: 05:55 → 05:00 → 05:55 via de minuutknoppen laat het uur op vijf staan. De stapgrootte blijft de gekozen tijdsoort volgen. Voor analoge wijzers blijft de bestaande uurovergang behouden.

De actuele projectbuild voor iOS Simulator slaagt. `testDigitalClockHasIndependentHourAndMinuteArrows` slaagt op iPhone 17 en iPad Pro 11-inch (M5), beide met iOS 26.5. De test controleert de vier losse pijltjes, de compacte gecentreerde controleknop, het voorbeeld, behoud van de invoer en live omschakelen naar een gele klok met digitale cijfers en donkerblauwe tekst. De controleknop behoudt daarbij zijn standaardkleuren. De schermbeelden zijn visueel gecontroleerd.

`testDigitalMinutesWrapAndAnalogMinutesCarry` slaagt op iPhone 17 / iOS 26.5: 05:55 → 05:00 → 05:55 bij digitaal instellen, ook in het voorbeeld, met behoud van de bestaande analoge uurovergang.

Beelden: [standaardklok op iPhone](Screenshots/QuestionFeedback/digital-preserved-display-iphone.png), [gekozen klok en bijpassende knop](Screenshots/QuestionFeedback/digital-preserved-display-custom-iphone.png), [gekozen klok op iPad](Screenshots/QuestionFeedback/digital-preserved-display-custom-ipad.png) en [het voorbeeld op iPad](Screenshots/QuestionFeedback/digital-preserved-display-example-ipad.png).


## Vaste knopstijl en automatische wijzerselectie — 18 oktober 2026

Vraagtypen **8** en **9** gebruiken één compacte knopstijl met donkerblauw en wit. De controleknop verandert niet mee met een ander klokontwerp. Dezelfde stijl geldt voor vooruit/achteruit en de uren/minutenswitch: de geselecteerde stand is donkerblauw met witte tekst, de andere stand wit met donkerblauwe tekst en een rand.

Bij het vastpakken van een wijzer selecteert de analoge klok automatisch die wijzer en werkt de switch direct mee. De keuze blijft tijdens dezelfde sleepbeweging vast, ook wanneer de wijzers elkaar kruisen. Bij overlappende wijzers behoudt het gedeelde deel de bestaande selectie; de uitstekende punt van de minutenwijzer is afzonderlijk te kiezen. Tikken op een leeg deel van de wijzerplaat blijft de handmatig gekozen stand volgen. De middenknop kiest geen andere wijzer. Dit geldt ook voor de handmatig bediende voorbeelden en vooruitdraai-vragen.

De analoge klok biedt voor toegankelijkheid één tijdwaarde; de switch geeft ook aan welke wijzer is geselecteerd.

De iOS Simulator-build slaagt. `Tools/test-dino.sh` slaagt met **796.994 controles**, inclusief aanraken van beide wijzers, een leeg deel van de wijzerplaat, de middenknop, overlappende wijzers en de minutenpunt bij alle 720 klokstanden.

`testAnalogClockSelectsTheTouchedHandAndUpdatesControls` slaagt op iPhone 17 en iPad Pro 11-inch (M5), beide met iOS 26.5. De test sleept eerst de minutenwijzer terwijl Uren geselecteerd is, daarna de uurwijzer terwijl Minuten geselecteerd is. Hij controleert de tijd, geselecteerde knop, stapgrootte van vooruit/achteruit en het vasthouden van de selectie bij het kruisen van de andere wijzer. Ook het voorbeeld schakelt automatisch mee.

`testDigitalClockHasIndependentHourAndMinuteArrows` slaagt op iPhone 17 / iOS 26.5, met een gele digitale klok en een controleknop die donkerblauw blijft. De schermbeelden zijn visueel gecontroleerd.

Beelden: [vaste knopkleur bij een andere digitale klok](Screenshots/QuestionFeedback/clock-controls-fixed-color-iphone.png), [analoge bediening op iPhone](Screenshots/QuestionFeedback/analog-controls-auto-hand-iphone.png) en [automatische wijzerselectie in het voorbeeld op iPad](Screenshots/QuestionFeedback/analog-controls-auto-hand-example-ipad.png).

## Aaneengesloten switch en afstand tot bevestigen — 18 oktober 2026

Uren en Minuten vormen één aaneengesloten switch in een gezamenlijke rand, met twee even brede aanraakvlakken en een schuivende donkerblauwe selectie. De totale breedte blijft gelijk aan die van de rij met draaiknoppen. De geselecteerde helft heeft witte tekst, de andere helft donkerblauwe tekst. Automatische wijzerselectie werkt ook de switch bij.

Bij vraagtype **9** staat **Controleer mijn klok** 24 punten onder de draaiknoppen. Bij vraagtype **8** is de afstand tot de onderste digitale pijltjes eveneens 24 punten. Het analoge voorbeeld gebruikt dezelfde afstand. De tussenruimte houdt de aanraakvlakken van instellen en bevestigen uit elkaar.

De iPhone-controle voor de aaneengesloten switch en bevestigingsafstand slaagt. De actuele iOS Simulator-build en beide gerichte schermtests eindigen met **TEST SUCCEEDED** op iPhone 17 / iOS 26.5:

- `testAnalogClockSelectsTheTouchedHandAndUpdatesControls`: twee even brede switchhelften zonder tussenruimte, voldoende afstand tot bevestigen, behoud van de automatische wijzerselectie en dezelfde indeling in het voorbeeld.
- `testDigitalClockHasIndependentHourAndMinuteArrows`: voldoende afstand tussen de onderste pijltjes en bevestigen bij type 8, ook met een ander klokontwerp.

De schermbeelden zijn visueel gecontroleerd: [switch bij vraagtype 9](Screenshots/QuestionFeedback/clock-hand-segmented-switch-iphone.png), [de switch in het voorbeeld](Screenshots/QuestionFeedback/clock-hand-segmented-switch-example-iphone.png) en [afstand bij vraagtype 8](Screenshots/QuestionFeedback/digital-confirm-spacing-iphone.png).

## Rustige antwoordtransities en vaste ruimte — 20 oktober 2026

- Analoge en digitale instelvragen behouden de ingevulde klok als dezelfde view op dezelfde hoogte. Hij maakt in 0,3 seconde ruimte; het goede antwoord verschijnt op zijn uiteindelijke plek, met een korte vertraging zodat de klokken elkaar niet overlappen. De vergelijkingsruimte is vooraf gereserveerd.
- Bij **Zet de wijzers vooruit** behoudt de beginklok zijn plaats en grootte. De ingevulde klok verkleint binnen een vaste rechterkolom; het goede antwoord verschijnt daaronder. De vraag wordt tijdens feedback niet hoger of lager.
- Instel- en bevestigingsknoppen trekken in 0,18 seconde in hun eigen ruimte terug. De langzame fade en het verwijderen van bevestigingsknoppen uit de layout zijn vervallen. Antwoordopties blijven volledig leesbaar.
- **Van vroeg naar laat** reserveert vanaf het begin ruimte voor de hele gekozen reeks en de correctie, inclusief eventuele regelafbreking. De eerste selectie duwt de bevestigingsknop niet omlaag.
- De zelf samengestelde tijdzin reserveert twee regels. Tijdzones, treinreizen en vluchten reserveren hun extra uitleg vooraf. Het aankomstveld van de trein houdt dezelfde afmetingen bij het vervangen van het vraagteken door de tijd.
- Automatisch scrollen gebeurt alleen als het antwoordgedeelte buiten het zicht valt. Een volledig zichtbaar antwoord blijft op zijn plek. **Minder beweging** schakelt de nieuwe bewegingen en vertragingen uit. Digitale vraag- en antwoordklokken bieden één volledige tijd voor VoiceOver.

De analoge, digitale en vooruitzet-overgangen zijn in een simulatoropname per 50 milliseconden visueel gecontroleerd. Beelden: [analoge vergelijking](Screenshots/AnswerTransitions/feedback-setAnalog-after.png), [vooruitzetten](Screenshots/AnswerTransitions/feedback-advanceAnalog-after.png) en [eerste sorteerkeuze](Screenshots/AnswerTransitions/feedback-sorting-first-selection.png).

De Debug-build voor iOS Simulator slaagt. Op iPhone 17 en iPad Pro 11-inch (M5), beide met iOS 26.5, slagen alle vier gerichte schermtests: acht geslaagde uitvoeringen in totaal.

- `testClockAnswerFeedbackKeepsItsStageAndTargetInPlace`: vaste titel, onveranderde vraagklok, behoud van de ingediende waarde, één toegankelijke invoer- en antwoordklok en handmatig verdergaan bij analoog instellen, digitaal instellen en vooruitzetten.
- `testSortingReservesDraftAndCorrectionBeforeTheFirstTap`: dezelfde knoppositie na iedere selectie en dezelfde klokcentra na het tonen van de correctie.
- `testWorkedAnswersKeepTheOptionsInPlace`: vaste antwoordposities tijdens uitleg en rekenen bij de treinreis, tijdzones en vluchten, ook na afloop van de animatie.
- `testMultipleChoiceRetriesKeepTheLostPoint`: herkansingen, Toon antwoord, Verder, behoud van de verloren punt en één doorlopende vragenteller.

`Tools/test-dino.sh`: **805.838 controles geslaagd**. De schermbeelden op iPhone en iPad zijn visueel gecontroleerd. `git diff --check` meldt geen fouten.
