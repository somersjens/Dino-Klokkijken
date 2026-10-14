# Voorbeeldkaarten

De analoge klok reserveert ruimte rondom de wijzerplaat voor twee genummerde aanwijspijlen. **1** wijst naar de korte urenwijzer en **2** naar de lange minutenwijzer. De pijlen gebruiken de actuele wijzerkleur uit de gekozen klokstijl. De cijfers **1** en **2** in de hulpbolletjes blijven zwart op wit, onafhankelijk van de klok- en wijzerkleuren. Bolletje en pijl vormen één aansluitend geheel met dezelfde zwarte rand en witte buitenrand voor contrast op donkere wijzerplaten. De pijlen en nummers staan in het verlengde van hun wijzer en draaien mee met de kloktijd. Alleen als de wijzers minder dan 22 graden uit elkaar staan, behouden ze de schuine plaatsing naast de wijzers zodat de nummers elkaar niet overlappen. De aanwijslijnen zijn recht, zonder bocht of knik. Dezelfde zwarte nummers en verbonden pijlen staan boven de digitale klok: **1** boven de eerste twee cijfers en **2** boven de laatste twee cijfers. De extra legenda en uitlegtekst onder de klokken zijn verwijderd.

Onder **Ik ben er klaar voor** staat **Een ander voorbeeld laten zien**, met een blauwe omlijning en een witte vulling. De kaart blijft open en beide klokken veranderen samen. Er is geen automatische tijdsprong meer bij het openen van een instelvoorbeeld.

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

De Debug-build en `Tools/test-dino.sh` slagen. De kernsuite bevat **418.761 controles**, waaronder de nieuwe voorbeeldreeksen en alle bestaande spel-, opslag- en sociale controles. De pijlen zijn bij alle 720 wijzerstanden gecontroleerd op uitlijning, richting, afstand tot de wijzers en afzonderlijke nummerposities, voor beide geteste wijzerdiktes. De bestaande voorbeeldtests voor hele uren en oefentijdsoorten slagen op iPhone 17 Pro / iOS 26.5; de beelden van 03:00, 03:15 en 12:00 zijn opnieuw visueel gecontroleerd.

De vereenvoudigde kaarten zijn gecontroleerd op **iPhone 17 Pro / iOS 26.5**: alle twaalf uitgebreide meerkeuzevraagtypen tonen één juist antwoord en de hele-urenreeks loopt door van 03:00 tot 12:00 en terug naar 01:00. De hele-urenreeks en het vernieuwen van 24-uurs- en tijdzonevoorbeelden slagen ook op **iPad Pro 11-inch (M5) / iOS 26.5**. De beelden zijn visueel gecontroleerd, inclusief de twee wijzers op twaalf uur en de blauwe knopomlijning.

- `testDemonstrationExamples`: alle oefentijdsoorten en wereldminuten, doorlopen en teruglopen van de klok, alle uitgebreide vraagtypen, geldige reken- en tijdzoneantwoorden en behoud van opgeslagen voortgang.
- `testNumberedExamplesAdvanceWholeHours`: de nieuwe knop onder de klaar-knop, uitlijning, overeenkomst tussen beide klokken, 03:00 tot 12:00 en terug naar 01:00, behoud van de echte vraag.
- `testExamplesRetainPracticeTimeFamily`: halve uren, kwartieren, tien minuten, vijf minuten en gemengd, met twee vervolgstappen per tijdsoort.
- `testExpandedExamplesRefreshTheirQuestionAndAnswer`: opeenvolgende kwartieren bij 24-uursvragen, een tijdzonevoorbeeld met het ene juiste antwoord vervangen en behoud van de oefenteller.
- `testExpandedMultipleChoiceExamplesShowOneAnswer`: alle twaalf uitgebreide meerkeuzevraagtypen tonen precies één antwoord, zonder afleidende opties of uitlegblok; de echte vraag behoudt meerdere antwoordopties.
- `testPracticeAnalogHandsAndManualExample`: openen en sluiten van de interactieve voorbeeldkaart en daarna de gewone wijzerbediening gebruiken.

De controle met witte wijzers en vaste zwarte hulpnummers is op iPhone 17 (iOS 26.5) en iPad (A16, iOS 27) geslaagd. Ook de oorspronkelijke wijzerkleuren zijn opnieuw visueel gecontroleerd.

## Beelden

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
