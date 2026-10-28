# Voorbeeldkaarten

De analoge voorbeeldklok toont buiten de rand **0, 5, 10 … 55**, elk met een kort streepje. Deze schaal volgt de gekozen ronde, vierkante of achthoekige klokvorm. **2** wijst met tussenruimte naar de minutenschaal, in de exacte richting van de lange wijzer. **1** wijst naar het cijfer van het verstreken uur: bij **04:45** naar **4**, terwijl de echte korte wijzer gewoon tussen vier en vijf blijft staan. Een kleine boog wijst vanaf de stand van de korte wijzer terug naar dat uur. De boog gebruikt bij voorkeur een lichtere tint van de urenwijzer; de kleur houdt minimaal 3:1 contrast met de wijzerplaat, ook bij zwarte en witte wijzers of een zwarte klok.

De rechte, genummerde pijlen gebruiken de gekozen wijzerkleuren. De uurpijl loopt tussen de buitenste minutencijfers door; als de hulpbolletjes dicht bij elkaar komen, schuiven ze opzij. De cijfers **1** en **2** blijven zwart op wit. Bolletje en pijl delen hun zwarte rand en witte buitenrand. De digitale klok behoudt dezelfde koppeling: **1** boven de uren en **2** boven de minuten.

Onder **Ik ben er klaar voor** staat **Een ander voorbeeld laten zien**, met een blauwe omlijning en een witte vulling. De kaart blijft open en krijgt een nieuwe doeltijd binnen de gekozen tijdsoort.

Vraagtype **9 – Zet de analoge wijzers** gebruikt voor iedere tijdsoort **Zet beide klokken op dezelfde tijd**. De uren/minutenkeuze en de twee draaiknoppen delen dezelfde afgeronde vormen, groene vulling, blauwe tekst en diepteschaduw als de overige spelknoppen. De actieve keuze is groen; de draaiknoppen tonen hun richting en stapgrootte. Bij hele uren ontbreekt de minutenkeuze.

Het voorbeeld van vraagtype 9 toont de vaste digitale doeltijd bovenaan, daaronder de analoge klok en dezelfde bediening als de echte vraag. De te oefenen wijzers starten precies 180 graden tegenover hun doelpositie. Bij hele uren blijft de minutenwijzer op twaalf staan. Een handje toont elke tik op de wijzerkeuze, de draaiknoppen en ten slotte de bevestiging. De wijzers bewegen per stap in de gekozen draairichting, ook langs twaalf. Daarna blijft het juiste antwoord zichtbaar. **Een ander voorbeeld laten zien** start een verse animatie met een nieuwe doeltijd; zelf tikken of slepen stopt de animatie en laat de speler verder oefenen. Sluiten en vernieuwen bewaren de echte vraag, invoer en voortgang.

Meerkeuzevoorbeelden tonen één opgave en alleen het juiste antwoord. Zo staat onder **half vier** één analoge klok op **03:30**, zonder de drie andere antwoordklokken of het groene uitlegblok. Digitale leesvragen, dagdelen, waar/niet waar, tijdreeksen en alle rekenvragen tonen op dezelfde manier hun ene juiste antwoord. De uitlegkaart heeft geen meerkeuzeknoppen. De echte vraag houdt alle gewone antwoordopties.

| Gekozen tijdsoort | Voorbeelden |
| --- | --- |
| Hele uren | 03:00 → 04:00 → 05:00; na 12:00 volgt 01:00 |
| Halve uren | 03:30 → 04:30 → 05:30 |
| Kwartieren | 03:15 → 03:45 → 04:15 |
| Tien minuten | 03:10 → 03:20 → … → 03:50 → 04:10 |
| Vijf minuten | 03:05 → 03:10 → … → 03:55 → 04:05 |
| Gemengd | 03:00 → 03:05 → 03:10 |
| Wereld met exacte minuten | 03:00 → 03:01 → 03:02 |

Wereldvoorbeelden volgen de toegestane minuten van die wereld. Oefenvoorbeelden volgen de gekozen tijdsoort en het huidige vraagtype, ook in gemengde oefenreeksen en bosslevels. Activiteiten wisselen tussen echte activiteiten met hun bijbehorende uur. Leesvragen schuiven door binnen hun 12- of 24-uursbereik. Rekenvragen, tijdzones, tijdreeksen, sorteren en koppelen gebruiken dezelfde vraaggenerator als de echte vragen, met een andere doeltijd dan het vorige voorbeeld. Het uitgewerkte antwoord wordt tegelijk vernieuwd.

Een nieuw uitgebreid voorbeeld krijgt een eigen, verse sessie. Vorige antwoorden, sorteervolgordes, koppelingen en wijzerkeuzes blijven daardoor niet hangen. De echte vraag, voortgang, oefenrecords en aantallen beantwoorde vragen worden niet gewijzigd.

## Verificatie

De leesuitleg is op 28 oktober 2026 aangepast. `testHandHintClearance` controleert voor alle 720 klokstanden en alle drie de klokvormen het verstreken uur, de exacte minuutrichting, vrije ruimte rond wijzers en minutencijfers en gescheiden hulpnummers. De laatste geometrie- en kleurcontrole slaagt met **116.761 controles**. De volledige kernsuite slaagt met **1.251.868 controles**; na de laatste kleine afstandsaanpassing is de gerichte klokcontrole opnieuw uitgevoerd. Native SwiftUI-beelden zijn gecontroleerd voor 04:45 met een lichte klok, een zwarte klok met witte wijzers en een vierkante klok, plus 12:00, 03:15 en 11:59. De gerichte schermtest `testExampleReadingScaleAndCompletedHour` slaagt op **iPhone 17 Pro** en **iPad Pro 11-inch (M5)** met iOS 26.5: doorlopen tot 04:45, dezelfde tijd op beide klokken, gecentreerde uitlijning en behoud van vraag 1 na sluiten. De zwarte uitvoering met witte wijzers is daarnaast visueel gecontroleerd op iPhone. De bredere bestaande voorbeeldtests veronderstellen nog de oude tijdsoortreeksen en de kleurkiezerhelpers zijn niet betrouwbaar op alle simulatorversies; die instellingenstromen vallen buiten deze gerichte klokcontrole.

De twee nieuwe UI-tests voor vraagtype 9 slagen op **iPhone 17 Pro** en **iPad Pro 11-inch (M5)** met iOS 26.5. Hele uren en minuten worden automatisch ingesteld en bevestigd; vernieuwen begint tegenover een nieuwe doeltijd en zelf bedienen onderbreekt de animatie. Ook de bestaande iPhone-tests voor slepen en voor het meenemen van uren bij minuutovergangen slagen. De vernieuwde kaarten en de volledig zichtbare bevestigingsknop zijn visueel gecontroleerd.

De Debug-build en `Tools/test-dino.sh` slagen. De kernsuite bevat **805.872 controles**, waaronder de nieuwe voorbeeldreeksen en alle bestaande spel-, opslag- en sociale controles. De pijlen zijn bij alle 720 wijzerstanden gecontroleerd op uitlijning, richting, afstand tot de wijzers en afzonderlijke nummerposities, voor beide geteste wijzerdiktes. De bestaande voorbeeldtests voor hele uren en oefentijdsoorten slagen op iPhone 17 Pro / iOS 26.5; de beelden van 03:00, 03:15 en 12:00 zijn opnieuw visueel gecontroleerd.

De vereenvoudigde kaarten zijn gecontroleerd op **iPhone 17 Pro / iOS 26.5**: alle twaalf uitgebreide meerkeuzevraagtypen tonen één juist antwoord en de hele-urenreeks loopt door van 03:00 tot 12:00 en terug naar 01:00. De hele-urenreeks en het vernieuwen van 24-uurs- en tijdzonevoorbeelden slagen ook op **iPad Pro 11-inch (M5) / iOS 26.5**. De beelden zijn visueel gecontroleerd, inclusief de twee wijzers op twaalf uur en de blauwe knopomlijning.

- `testDemonstrationExamples`: alle oefentijdsoorten en wereldminuten, doorlopen en teruglopen van de klok, alle uitgebreide vraagtypen, geldige reken- en tijdzoneantwoorden en behoud van opgeslagen voortgang.
- `testNumberedExamplesAdvanceWholeHours`: de nieuwe knop onder de klaar-knop, uitlijning, overeenkomst tussen beide klokken, 03:00 tot 12:00 en terug naar 01:00, behoud van de echte vraag.
- `testExamplesRetainPracticeTimeFamily`: halve uren, kwartieren, tien minuten, vijf minuten en gemengd, met twee vervolgstappen per tijdsoort.
- `testExpandedExamplesRefreshTheirQuestionAndAnswer`: opeenvolgende kwartieren bij 24-uursvragen, een tijdzonevoorbeeld met het ene juiste antwoord vervangen en behoud van de oefenteller.
- `testExpandedMultipleChoiceExamplesShowOneAnswer`: alle twaalf uitgebreide meerkeuzevraagtypen tonen precies één antwoord, zonder afleidende opties of uitlegblok; de echte vraag behoudt meerdere antwoordopties.
- `testPracticeAnalogHandsAndManualExample`: openen en sluiten van de interactieve voorbeeldkaart en daarna de gewone wijzerbediening gebruiken.
- `testAnalogSettingExamples`: alle uren en toegestane minuutstappen, beide draairichtingen, tegenovergestelde beginstanden, kleine draaistappen langs twaalf en bevestigen op de juiste doeltijd.
- `testAnalogSettingExampleShowsTapsAndRestartsAtOppositeTime`: automatisch instellen van hele uren, een vaste digitale doeltijd bovenaan, opnieuw beginnen tegenover een nieuwe doeltijd, zelf bedienen en behoud van de echte invoer.
- `testAnalogSettingMinuteExampleUsesSharedControlsAndFixedTarget`: dezelfde switch in vraag en voorbeeld, de bevestigingsknop volledig in beeld, automatisch instellen en bevestigen van minuten en behoud van de echte wijzerkeuze.

De controle met witte wijzers en vaste zwarte hulpnummers is op iPhone 17 (iOS 26.5) en iPad (A16, iOS 27) geslaagd. Ook de oorspronkelijke wijzerkleuren zijn opnieuw visueel gecontroleerd.

## Beelden

- [Nieuwe minutenschaal en uurverwijzing bij 04:45 — iPhone](Screenshots/Examples/example-reading-four-forty-five-iphone.png)
- [Dezelfde uitleg met een zwarte klok en witte wijzers — iPhone](Screenshots/Examples/example-reading-four-forty-five-black-iphone.png)
- [Nieuwe minutenschaal en uurverwijzing bij 04:45 — iPad](Screenshots/Examples/example-reading-four-forty-five-ipad.png)

- [Vraagtype 9 met de vernieuwde bediening — iPhone](Screenshots/Examples/analog-setting-question-iphone.png)
- [Vraagtype 9 met het ingestelde voorbeeld — iPhone](Screenshots/Examples/analog-setting-example-iphone.png)
- [Vraagtype 9 met het ingestelde voorbeeld — iPad](Screenshots/Examples/analog-setting-example-ipad.png)

- [Verbonden aanwijzers bij witte wijzers — iPhone](Screenshots/Examples/example-connected-white-hand-hints-iphone.png)
- [Verbonden aanwijzers bij witte wijzers — iPad](Screenshots/Examples/example-connected-white-hand-hints-ipad.png)

- [Drie uur op iPhone](Screenshots/Examples/numbered-example-three-iphone.png)
- [Eén klok bij ‘half vier’ op iPhone](Screenshots/Examples/simple-spoken-time-example-iphone.png)
- [Eén tijdsduur als antwoord op iPhone](Screenshots/Examples/simple-duration-example-iphone.png)
- [Samenvallende wijzers om twaalf uur op iPhone](Screenshots/Examples/numbered-example-12-iphone.png)
- [Halve uren op iPhone](Screenshots/Examples/numbered-example-half-iphone.png)
- [Kwartieren op iPhone](Screenshots/Examples/numbered-example-quarter-iphone.png)
- [Kwartieren op iPad](Screenshots/Examples/numbered-example-quarter-ipad.png)
- [Vernieuwd tijdzonevoorbeeld op iPad](Screenshots/Examples/refreshed-time-zone-example-ipad.png)
