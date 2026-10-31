# Klokhulp per vraagtype — 29 oktober 2026

De hulp wordt per vraagtype gekozen en alleen na een fout op de huidige vraag geactiveerd. Een nieuwe vraag begint zonder hulp. De voorbeeldkaarten van de betreffende leesvragen tonen de uitleg meteen.

| Vraagtypen | Klokhulp |
| --- | --- |
| 1, 2, 7, 8 | Bestaande genummerde uur- en minutenpijlen |
| 3, 4, 5 | Uitspraakschaal met één blauwe boogpijl zonder (1) of (2) |
| Overige typen | Geen van deze klokhelpers |

De klokhulp heeft geen extra tijdzin onder de wijzerplaat. Elk schaalgetal of ankerwoord staat als gewone tekst net buiten een kort streepje aan de klokrand. De plaatsing gebruikt de gemeten tekstafmetingen, zodat ook twee cijfers en woorden vrij van het streepje blijven. De blauwe boog volgt de rand. De cirkel met een kort verbindingsstukje markeert de minutenstand van de vraag: bij over/past en over half het eindpunt, bij voor/to en voor half het beginpunt. Ook de antwoordklokken van type 5 tonen beide cirkels: de minutenafwijking en het uitgesproken uur. De verticale ruimte volgt de schaal, de boog en de korte richtingswoorden, met een kleine veiligheidsmarge.

Bij type 4 verschijnt na een fout direct de eenvoudige hulplijn. De antwoordstenen blijven in beeld. Bij twee keuzes is de juiste steen meteen groen omlijnd; Verder gaat direct naar de volgende vraag. Er is geen tweede uitlegfase. De volledige ring met alle tijdomschrijvingen staat uitsluitend in Voorbeeld. De aansluitingen bestaan daar uit een kort streepje, een gewone Nederlandse of Engelse schaalwaarde en een langere lijn naar de uitspraak. De langere lijn blijft buiten de schaaltekst en de tekstballon. De gekleurde buitenband en het omcirkelde vertrekpunt zijn verwijderd; de tekstballonnen behouden hun taalspecifieke kleurgroepen.

Bij type 5 krijgt na een fout elke antwoordklok een hulplijn voor zijn eigen tijd, met omcirkeling van de minutenafwijking en het uitgesproken uur. Kleinere buitencijfers en kleinere marges geven de wijzerplaat meer ruimte. De speler kan ook bij twee antwoordklokken de juiste keuze nog maken. Een goed antwoord gaat na de gewone antwoordanimatie automatisch door; de eerste fout blijft de score bepalen. Het afzonderlijke uitlegscherm en de losse tijdzin onder een fout gekozen klok zijn verwijderd.

| Minutenpositie | Nederlands | Engels |
| --- | --- | --- |
| :00 | uur | o’clock |
| :05 | 5 | 5 |
| :10 | 10 | 10 |
| :15 | kwart | quarter |
| :20 | 10 | 20 |
| :25 | 5 | 25 |
| :30 | half | half |
| :35 | 5 | 25 |
| :40 | 10 | 20 |
| :45 | kwart | quarter |
| :50 | 10 | 10 |
| :55 | 5 | 5 |

Bij :50 staat in het Engels 10: de uitspraak is ten to. De 20 uit de opgegeven reeks is als typefout geïnterpreteerd.

De Nederlandse boog loopt bij ‘over’ vanaf het hele uur naar de minutenpositie, bij ‘voor half’ vanaf de minutenpositie naar half, bij ‘over half’ vanaf half naar de minutenpositie en bij ‘voor’ vanaf de minutenpositie naar het volgende hele uur. De Engelse boog loopt tot en met half vanaf het hele uur naar de minutenpositie (‘past’) en daarna vanaf de minutenpositie naar het volgende hele uur (‘to’).

Voor :20 betekent dit Nederlands 20 → 30 met ‘voor half’, tegenover Engels 0 → 20 met ‘past’. Bij exacte hele uren en het Nederlandse halve uur staat het schaalwoord bij zijn streepje, zonder een afstandsboog te suggereren. De grote helper markeert dit woord met een cirkel; de compacte antwoordhelper laat de cirkel weg. Bij losse minuten vervangt het exacte aantal de dichtstbijzijnde schaalwaarde, bijvoorbeeld 13 bij :17 in het Nederlands. Het verbindingswoord staat apart met een eigen aansluitstreepje. De aansluiting begint precies op het midden van de boog en sluit vlak naast de tekst aan.

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

## Uurcirkel en vrijstaande boog — 31 oktober 2026

De boog staat weer op de eerdere afstand buiten de klokrand (0,26 maal de diameter). Het aansluitstreepje naar het verbindingswoord is korter. Het uitgesproken uur krijgt een cirkel met dezelfde hoogte als die bij de minutenafwijking, achter beide wijzers. Nederlands half zeven markeert 7; kwart over zes markeert 6. Engels half past six markeert 6 en quarter to seven markeert 7. De uurcirkel staat ook in de volledige voorbeeldklok.

Type 5 toont de minuten- en uurcirkel weer in alle antwoordklokken na een fout. De Engelse buitenste schaal gebruikt quarter op beide kwartierposities. Dit langere woord staat buiten de boog, zodat de lijn vrij van de letters blijft.

De 5.070 gerichte kerncontroles en beide taaltests slagen op iPhone 17 Pro / iOS 26.5. De Engelse schermtest is aanvullend uitgevoerd na het verbinden van de quarter-schaalwoorden met hun streepje. Visueel gecontroleerd: [boog en uurcirkel](Screenshots/SpokenClockGuides/outer-arc-hour-circle-nl.png), [beide cirkels in type 5](Screenshots/SpokenClockGuides/outer-arc-two-circles-type5.png) en [Engelse quarter-schaal](Screenshots/SpokenClockGuides/outer-arc-quarter-en.png).

## Aansluiting op de cirkel — 31 oktober 2026

De boog gaat met een korte vloeiende bocht naar de relevante cirkel. De pijlpunt stopt net voor de cirkelrand, zodat de witte badge geen deel van de pijl verbergt. Bij een cirkel aan het begin loopt de verbinding op dezelfde manier vloeiend de boog in. De eerdere losse radiale verbinding is verwijderd.

Het streepje naar voor, over, past, to en de half-varianten begint op het exacte tijdmidden tussen de twee boogeinden. De afronding naar een plek tussen schaalstreepjes is verwijderd.

Geslaagd: 5.070 gerichte kerncontroles, simulatorbuild en de Nederlandse en Engelse schermtests voor typen 3/4/5. Visueel gecontroleerd: [pijleinde bij over](Screenshots/SpokenClockGuides/docked-arrow-nl-over.png), [begin bij voor half](Screenshots/SpokenClockGuides/docked-arrow-nl-voor-half.png) en [kleine antwoordklokken](Screenshots/SpokenClockGuides/docked-arrow-type5.png).

## Binnenliggende boog met uitgelijnde cirkel — 31 oktober 2026

De boog staat dichter bij de schaalwaarden: de afstand buiten de klokrand is 0,13 maal de wijzerplaatdiameter. De geselecteerde cirkel staat iets verder buiten de schaal, in het verlengde van de raaklijn aan het boogeinde. De gewone pijlpunt en het midden van de cirkel liggen daardoor op één lijn, met een kleine vrije ruimte vóór de cirkelrand. De gebogen aansluiting uit de vorige iteratie is vervangen door de normale boog met pijlpunt. Bij voor/to begint de boog op dezelfde manier na de cirkel. De verbinding voor de richtingswoorden blijft op het exacte midden van de boog staan.

Geslaagd: 5.070 gerichte kerncontroles en de Nederlandse en Engelse schermtests. Visueel gecontroleerd: [over](Screenshots/SpokenClockGuides/inner-arc-aligned-circle-over.png), [voor half](Screenshots/SpokenClockGuides/inner-arc-aligned-circle-voor-half.png) en [type 5](Screenshots/SpokenClockGuides/inner-arc-aligned-circle-type5.png).

## Schaalvaste cirkel — 31 oktober 2026

De gemarkeerde schaalwaarde staat weer op haar eigen radiale streepje. De verschuiving langs de raaklijn vervalt. De boog blijft naar binnen geplaatst en wordt bij de cirkelrand ingekort, met een kleine vrije ruimte rond de normale pijlpunt. Het verbindingswoord sluit aan op het midden van de ingekorte, zichtbare boog.

De Nederlandse en Engelse schermtests slagen. Visueel gecontroleerd: [cirkel bij het schaalstreepje met ingekorte pijl](Screenshots/SpokenClockGuides/scale-aligned-circle-short-arrow.png) en [type 5](Screenshots/SpokenClockGuides/scale-aligned-circle-type5.png).

## Aansluiting midden op de cirkelzijde — 31 oktober 2026

De boog krijgt meer afstand tot de normale schaaltekst. De gemeten tekstvlakken bepalen de benodigde vrije ruimte langs het actieve boogdeel, ook bij langere woorden in het Engels. De geselecteerde cirkel blijft bij zijn eigen streepje staan. De verbinding komt exact op het midden van de boven-, onder-, linker- of rechterzijde uit, volgens de leesrichting van de taal. Quarter to vertrekt bijvoorbeeld bovenaan de kwartiercirkel; bij twintig minuten gebruikt Nederlands voor half de onderzijde en Engels past de bovenzijde. De aansluiting loopt vloeiend over in de boog en de pijlpunt blijft zichtbaar.

Quarter heeft dezelfde korte schaalstreep en tekstafstand als alle andere waarden. De eerdere speciale buitenpositie en verlengde streep zijn verwijderd. Het verbindingswoord blijft op het midden van de boog aansluiten.

Geslaagd: 5.073 gerichte kerncontroles, beide bestaande taaltests en de nieuwe schermtest voor quarter past/to. De aansluitingen en de korte quarter-streepjes zijn visueel gecontroleerd: [quarter to](Screenshots/SpokenClockGuides/centered-side-quarter-to.png), [quarter past](Screenshots/SpokenClockGuides/centered-side-quarter-past.png) en [tien over](Screenshots/SpokenClockGuides/centered-side-ten-past.png).

De korte aansluitcurves begrenzen hun controlepunten tot de eerste en laatste derde van de verbinding. Daardoor ontstaat geen S-knik wanneer de cirkel dicht bij de boog staat. De gerichte schermtest voor quarter past/to slaagt opnieuw; [het vertrekpunt is visueel gecontroleerd](Screenshots/SpokenClockGuides/smooth-quarter-to.png).
