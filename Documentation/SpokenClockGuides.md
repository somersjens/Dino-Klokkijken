# Klokhulp per vraagtype — 29 oktober 2026

De hulp wordt per vraagtype gekozen en alleen na een fout op de huidige vraag geactiveerd. Een nieuwe vraag begint zonder hulp. De voorbeeldkaarten van de betreffende leesvragen tonen de uitleg meteen.

| Vraagtypen | Klokhulp |
| --- | --- |
| 1, 2, 7, 8 | Bestaande genummerde uur- en minutenpijlen |
| 3, 4, 5 | Uitspraakschaal met één blauwe boogpijl zonder (1) of (2) |
| Overige typen | Geen van deze klokhelpers |

De klokhulp heeft geen extra tijdzin onder de wijzerplaat. Elk schaalgetal of ankerwoord staat als gewone tekst net buiten een kort streepje aan de klokrand. De plaatsing gebruikt de gemeten tekstafmetingen, zodat ook twee cijfers en woorden vrij van het streepje blijven. De blauwe boog volgt de rand. De cirkel met een kort verbindingsstukje markeert de minutenstand van de vraag: bij over/past en over half het eindpunt, bij voor/to en voor half het beginpunt. Bij de kleine antwoordklokken van type 5 vervalt de cirkel. De verticale ruimte volgt de schaal, de boog en de korte richtingswoorden, met een kleine veiligheidsmarge.

Bij type 4 verschijnt na een fout direct de eenvoudige hulplijn. De antwoordstenen blijven in beeld. Bij twee keuzes is de juiste steen meteen groen omlijnd; Verder gaat direct naar de volgende vraag. Er is geen tweede uitlegfase. De volledige ring met alle tijdomschrijvingen staat uitsluitend in Voorbeeld. De aansluitingen bestaan daar uit een kort streepje, een gewone Nederlandse of Engelse schaalwaarde en een langere lijn naar de uitspraak. De langere lijn blijft buiten de schaaltekst en de tekstballon. De gekleurde buitenband en het omcirkelde vertrekpunt zijn verwijderd; de tekstballonnen behouden hun taalspecifieke kleurgroepen.

Bij type 5 krijgt na een fout elke antwoordklok een hulplijn voor zijn eigen tijd, zonder omcirkeling. Kleinere buitencijfers en kleinere marges geven de wijzerplaat meer ruimte. De speler kan ook bij twee antwoordklokken de juiste keuze nog maken. Een goed antwoord gaat na de gewone antwoordanimatie automatisch door; de eerste fout blijft de score bepalen. Het afzonderlijke uitlegscherm en de losse tijdzin onder een fout gekozen klok zijn verwijderd.

| Minutenpositie | Nederlands | Engels |
| --- | --- | --- |
| :00 | uur | o’clock |
| :05 | 5 | 5 |
| :10 | 10 | 10 |
| :15 | kwart | 15 |
| :20 | 10 | 20 |
| :25 | 5 | 25 |
| :30 | half | half |
| :35 | 5 | 25 |
| :40 | 10 | 20 |
| :45 | kwart | 15 |
| :50 | 10 | 10 |
| :55 | 5 | 5 |

Bij :50 staat in het Engels 10: de uitspraak is ten to. De 20 uit de opgegeven reeks is als typefout geïnterpreteerd.

De Nederlandse boog loopt bij ‘over’ vanaf het hele uur naar de minutenpositie, bij ‘voor half’ vanaf de minutenpositie naar half, bij ‘over half’ vanaf half naar de minutenpositie en bij ‘voor’ vanaf de minutenpositie naar het volgende hele uur. De Engelse boog loopt tot en met half vanaf het hele uur naar de minutenpositie (‘past’) en daarna vanaf de minutenpositie naar het volgende hele uur (‘to’).

Voor :20 betekent dit Nederlands 20 → 30 met ‘voor half’, tegenover Engels 0 → 20 met ‘past’. Bij exacte hele uren en het Nederlandse halve uur staat het schaalwoord bij zijn streepje, zonder een afstandsboog te suggereren. De grote helper markeert dit woord met een cirkel; de compacte antwoordhelper laat de cirkel weg. Bij losse minuten vervangt het exacte aantal de dichtstbijzijnde schaalwaarde, bijvoorbeeld 13 bij :17 in het Nederlands. Het verbindingswoord staat apart met een eigen aansluitstreepje. De aansluiting komt tussen twee schaalwaarden door en sluit vlak naast de tekst aan.

De schaal volgt ronde, vierkante en achthoekige klokken. De boog gebruikt steeds de gewone blauwe appkleur en neemt geen persoonlijke wijzerkleur over. De uur- en minutenwijzers zelf behouden hun gekozen kleuren.

## Controles

De gerichte kerncontroles bewaken alle twintig vraagtypen, de volledige schalen in beide talen, alle zestig minuutstanden, de referentiepunten, de boogrichtingen, activatie na een fout en herstel bij de volgende vraag. De bestaande herkansingscontrole bewaakt het leesmoment van type 5 en behoud van de eerste score en antwoordtijd.

Geslaagd: de iOS-simulatorbuild, **51.634 klokhulpcontroles**, **17.601 controles van leesvragen en herkansingen**, de bestaande schermtest voor hulp op alleen de huidige vraag en de Nederlandse en Engelse schermtests op iPhone 17 Pro / iOS 26.5. De laatste Nederlandse schermtest is opnieuw uitgevoerd na het vergroten van het tekengebied voor de pijlpunt op de complete uitlegklok. De schermtests doorlopen typen 3, 4 en 5 na een fout en in Voorbeeld en controleren het wegblijven van handpijlen bij typen 9 en 10. De verdeling over alle twintig typen wordt rechtstreeks door de kerncontrole bewaakt.

Visueel gecontroleerd: [Nederlands tien voor half](Screenshots/SpokenClockGuides/spoken-guide-nl-spokenTime-twenty.png), [Engels twenty past](Screenshots/SpokenClockGuides/spoken-guide-en-spokenTime-twenty.png), [complete Nederlandse uitlegklok](Screenshots/SpokenClockGuides/spoken-guide-nl-readDigital-twenty.png), [Nederlandse hulp na een fout](Screenshots/SpokenClockGuides/spoken-guide-nl-readDigital-after-miss.png) en [afzonderlijke hulp bij type 5](Screenshots/SpokenClockGuides/spoken-guide-nl-spokenTime-after-miss.png).

## Verfijning van de directe hulp — 29 oktober 2026

De nieuwe controles bewaken de direct groene juiste keuze na een tweekeuzefout bij type 4, doorgaan met één tik, normale doorgang na een juist antwoord en hulp op alle antwoordklokken van type 5. De hoogte wordt over alle zestig minuutstanden, beide talen, drie klokvormen en meerdere klokomvangen gecontroleerd op behoud van de wijzerplaat en een kleinere marge dan de eerdere vierkante tekenruimte.

Geslaagd na deze verfijning: simulatorbuild, **53.794 klokhulpcontroles**, **17.494 controles van leesvragen en herkansingen**, de Nederlandse en Engelse schermtest van typen 3/4/5 en de aanvullende Nederlandse leesvraagtest met twee en vier keuzes. De laatste Nederlandse helpertest is opnieuw uitgevoerd met de verbeterde leesbaarheid van kwart op kleine antwoordklokken. De schermbeelden zijn visueel gecontroleerd op cirkels, verbindingsstukjes, compacte marges, genummerde aansluitpunten in Voorbeeld 4 en hulp op alle antwoordklokken van type 5.

Nieuwe beelden: [type 5 na een fout](Screenshots/SpokenClockGuides/compact-spoken-nl-spokenTime-after-miss.png), [Voorbeeld 4 met schaalwaarden](Screenshots/SpokenClockGuides/compact-spoken-nl-readDigital-twenty.png), [type 4 direct na een fout](Screenshots/SpokenClockGuides/compact-spoken-nl-readDigital-after-miss.png), [compact Nederlands voorbeeld](Screenshots/SpokenClockGuides/compact-spoken-nl-trueFalse-twenty.png) en [Engelse helper](Screenshots/SpokenClockGuides/compact-spoken-en-spokenTime-twenty.png).

## Schaaluitlijning — 29 oktober 2026

Alle schaalwaarden krijgen dezelfde plaatsingslogica: een kort radiaal streepje, een kleine vrije ruimte en het gemeten tekstvlak. Dit geldt voor zowel 0–55 bij de genummerde helpers als de Nederlandse en Engelse uitspraakschaal. De uitspraakhulp heeft geen cirkel meer om het vertrekpunt; de enkele blauwe pijl volgt de klokrand.

Voorbeeld 4 toont een iets kleinere klok, zonder gekleurde buitenband of losse boog. Na het korte streepje en de schaalwaarde loopt een langere lijn naar de uitspraak. Beide lijnen blijven buiten de tekst. Ook naast kwart is er ruimte voor een zichtbare verbinding. De uitspraakvakjes behouden hun taalspecifieke kleuren.

Geslaagd: **53.794 bestaande klokhulpcontroles**, simulatorbuild en de drie bestaande schermtests voor de gewone minutenschaal en Nederlandse/Engelse uitspraakhulp. Na het verkleinen van de voorbeeldklok zijn beide taaltests opnieuw geslaagd op iPhone 17 Pro / iOS 26.5. De nieuwe Nederlandse en Engelse voorbeeldkaarten, kleine antwoordklokken en gewone minutenschaal zijn visueel gecontroleerd.

Nieuwe beelden: [Nederlands voorbeeld](Screenshots/SpokenClockGuides/rim-scale-nl-example.png), [Engels voorbeeld](Screenshots/SpokenClockGuides/rim-scale-en-example.png), [antwoordklokken na een fout](Screenshots/SpokenClockGuides/rim-scale-nl-answer-clocks.png) en [gewone minutenschaal](Screenshots/SpokenClockGuides/rim-minute-scale.png).

## Aansluitingen en compacte antwoordklokken — 29 oktober 2026

De cirkel volgt nu de echte minutenstand. Bij tien over of ten past zit hij bij het pijleinde; bij tien voor half zit hij bij het begin. Het verbindingswoord krijgt een eigen dunne lijn met een kort horizontaal stukje vlak naast de tekst. De lijn loopt tussen de schaalwaarden door. De schaaltekst is kleiner en sluit daardoor beter aan bij de uurcijfers. Bij losse minuten blijft het exacte aantal zichtbaar op de schaal.

Type 5 gebruikt na een fout voor elke antwoordklok een compacte helper zonder cirkel. De kleinere buitenmarges en kaartpadding geven de wijzerplaat meer ruimte. Het grotere Voorbeeld van type 5 behoudt de cirkel. De volledige uitlegklok van Voorbeeld 4 houdt de gewone schaalwaarden en lijnen naar alle uitspraakvakjes.

Geslaagd: **5.066 gerichte uitspraakhulpcontroles**, **108.154 brede klokhulpcontroles** op de actuele gedeelde broncode, simulatorbuild en de Nederlandse en Engelse schermtests voor typen 3/4/5. De beelden zijn visueel gecontroleerd op cirkelplaatsing aan begin én einde, tekstverbindingen, kleinere schaaltekst en grotere antwoordklokken zonder cirkel.

Beelden: [tien over aan het pijleinde](Screenshots/SpokenClockGuides/connected-count-nl-ten-past.png), [ten past met tekstverbinding](Screenshots/SpokenClockGuides/connected-count-en-ten-past.png), [voor half aan het begin](Screenshots/SpokenClockGuides/connected-count-nl-before-half.png), [compacte antwoordklokken zonder cirkel](Screenshots/SpokenClockGuides/compact-unringed-answer-clocks.png) en [Engels groter Voorbeeld](Screenshots/SpokenClockGuides/connected-count-en-twenty-past.png).
