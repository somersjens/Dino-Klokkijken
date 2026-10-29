# Analyse en aanpassing van de welkomsprong

28 oktober 2026, bijgewerkt op 29 oktober 2026.

De eerder toegevoegde gegenereerde tussenbeelden zijn teruggedraaid. Alleen de hurkpose verkorten pakte het probleem in de daarna aangewezen vluchtbeelden niet aan.

## Wat in de video zichtbaar is

De oorspronkelijke opening wisselde tijdens één vlucht tussen tekeningen 03, 04, 05 en 06. Die tekeningen verschillen in hoofd- en beenhouding en lichaamscontour. Daardoor verandert de geschilderde figuur abrupt, ook als zijn buitenste afbeeldingslaag een doorlopende baan volgt. Dat verklaart de zichtbare houdingssprongen in de drie aangeleverde screenshots.

Er zijn daarnaast echte tijdgaten in het opgenomen videobestand. In een vluchtfragment van 0,54 seconde uit `/tmp/dino-opening-timing-revised.mov` staan 22 opgeslagen beelden; het grootste interval is 91,7 ms. Een extractie op vaste 60-fps-tijdstappen herhaalt daarom soms hetzelfde opgenomen beeld. Dat is iets anders dan alleen een pose die lang blijft staan.

De oude code schakelde de hele kaart pas tijdens de afzet van onzichtbaar naar zichtbaar. Daarbij werd de bovenliggende SwiftUI-kaart opnieuw bijgewerkt. Dat is onnodig tijdens de vlucht: de ondoorzichtige openingsachtergrond bedekt de kaart al volledig.

## Huidige wijziging

- De grote opening gebruikt vijf oorspronkelijke tekeningen: 01, 02, 03, 07 en 08. Beeld 03 blijft tijdens de volledige vlucht staan. Positie, schaal en kanteling blijven continu bewegen. Er zijn geen nieuwe of overlappende beelden toegevoegd.
- De kaart wordt vóór vertrek zichtbaar gemaakt onder de ondoorzichtige opening. De expliciete kaartupdate bij de afzet is verwijderd.
- Achtergrond, klok, bladeren en titel gebruiken native Core Animation-vervaging op dezelfde klok als Dino, met de bestaande afzetvertraging van 0,14 seconde. De vervaging duurt 0,38 seconde en is vóór het voetcontact afgelopen. De titel vervaagt op zijn plaats, zonder extra verplaatsing. De decorlagen dekken ook de veilige schermranden af. De klok blijft tijdens het vervagen op dezelfde schaal staan.
- De native verplaatsingsanimatie vraagt 60 fps aan. Dit is een voorkeur voor de renderer, geen garantie dat de simulator of opname ieder beeld haalt.
- De grote opening bereidt alleen de vijf werkelijk gebruikte sprites voor, in plaats van alle acht.

De totale duur blijft 0,94 seconde: afzet op 0,14 seconde, contact op 0,76 seconde en herstel tot 0,94 seconde. De hurkpose duurt 50 ms. De éénstersprong behoudt de volledige oorspronkelijke reeks; Minder beweging behoudt zijn bestaande stilstaande weergave.

## Controle en grenzen

De build slaagt. Er slagen 272.986 gerichte timing- en assetcontroles, inclusief een onveranderde vliegpose en voetregistratie tijdens de volledige vlucht. De bestaande schermtest voor landing op opgeslagen level 4 en terugkeer zonder herhaalde opening slaagt op aparte iPhone 18 Pro- en iPad (A16)-simulators, inclusief de Engelse opening in iPad-landschapstand.

De eerste aangepaste simulatoropname bevat in een vluchtfragment van dezelfde lengte 28 beelden, met een grootste interval van 63,3 ms. De houdingswissels zijn verwijderd, maar deze opname is nog niet constant 60 fps. De opnamen zijn onder verschillende simulatorbelasting gemaakt; de gemeten frequenties zijn geen benchmark van een fysiek apparaat en bewijzen niet welke wijziging welk deel van de snelheidswinst veroorzaakt.

Bij hervatting op 29 oktober is de laatste 60-fps-opname ook gecontroleerd: het gemeten fragment van 0,54 seconde bevatte 37 beelden, met een grootste interval van 30 ms. Daarin bleek de SwiftUI-decorvervaging nog tussentijds vast te lopen. Daarom is ook het decor naar native afspelen overgebracht; de vlucht is sindsdien niet meer afhankelijk van SwiftUI-opaciteitsupdates.

## Definitieve opname, 29 oktober

In `/tmp/dino-native-fade-final.mov` bevat het gemeten vluchtfragment van 7,40 tot 7,94 seconde 37 opgeslagen beelden. Het grootste interval is 20 ms en de mediaan 15 ms. In de eerdere aangewezen opname was het grootste interval 91,7 ms. Deze vergelijking betreft simulatoropnamen onder wisselende belasting. De nieuwe opname toont dezelfde vliegpose gedurende de vlucht, een titel op vaste positie en decor dat vóór de landing volledig vervaagt.

De korte gecontroleerde preview op de oorspronkelijke resolutie staat in `Screenshots/StartScreen/startscreen-steady-native-flight.mov`; de bijbehorende beelden op vaste tijdstappen staan in `Screenshots/StartScreen/steady-native-flight-frames.jpg`. De build en de iPhone-/iPad-tests voor landing en terugkeer naar de kaart zijn geslaagd.

## Vervolg: bukken en opveren

De aanvullende feedback over de hoofdpositie bij vertrek is verwerkt in [hoofdtracking bij de welkomsprong](WelcomeHeadTracking.md). De daarin beschreven timing van 1,26 seconde vervangt de eerdere 0,94 seconde voor de grote opening.
