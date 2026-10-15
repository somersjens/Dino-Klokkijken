# Zijdecoratie en wereldranden — 15 oktober 2026

De decoratie van alle tien werelden volgt de bochten van het levelpad. De gedeelde `WorldSceneryLayout` gebruikt dezelfde levelposities en kubische bochten als `WorldRouteTrail`. Grote bestemmingen houden ook boven hun voetpunt ruimte naast de weg; geneste decorstukken behouden hun vorm.

## Water via de schermzijden

De waterbanen gelden uitsluitend voor Dino Dorp (Dino Village, wereld 4) en Dino Stad (Dino City, wereld 6). Ze komen vanaf de linker- en rechterzijkant binnen, volgen het pad en buigen onderaan weer buiten beeld. Hun uiteindes liggen honderd geschaalde punten buiten de schermbreedte, ook wanneer de strokes de hoofdstukgrens passeren. Er worden geen waterstroken naar een volgende wereld doorgetrokken.

Tijdpiraten (wereld 9) behoudt de open zee aan beide kanten, met een zandrand en schuim langs de kust. Ook deze kustlijn buigt bovenaan en onderaan naar buiten. Het water blijft volledig dekkend; alpha-fades en kleurmenging van het water met de volgende wereld zijn verwijderd. De overige werelden hebben geen doorlopende waterbaan; lokale watervallen en fonteinen blijven deel van hun decoratie.

## Compacte hoofdstukken en einde

De vrije ruimte boven en onder ieder wereldbord komt uit dezelfde berekening. Die gebruikt het zichtbare midden van de titelplaat, de volledige bordhoogte, de vrije ruimte voor Dino en de verschillende diameters van de bosssteen (90 punten) en gewone steen (72 punten). Gewone levels behouden hun onderlinge stap van 175 punten. De eerdere vaste stap van boss naar bord was te kort omdat die geen rekening hield met de extra ruimte onder het bord.

Ieder wegsegment wordt op zijn eigen sectiegrens begrensd. Daardoor kunnen de verschoven schaduwen en de uiteindes van aangrenzende segmenten elkaar niet donker overlappen. Ook de landschapcanvassen worden begrensd: lichtbundels of decoratie van een volgende wereld kunnen niet meer over de voorgaande weg heen tekenen. De laatste rij werkplaatsdecoratie is teruggebracht tot een rij die volledig vóór de hoofdstukgrens past.

De kleuren en transparantie van de landstroken gaan in de laatste 180 punten over naar die van de volgende wereld. Deze menging geldt alleen voor de grondkleuren. Een aanvullende terreinstrook van 32 punten aan beide randen laat ook het omgevingslicht exact aansluiten, met behoud van dezelfde bankkleur. In deze stroken liggen de waterlijnen al volledig buiten beeld. Water blijft dekkend en verlaat het scherm via de zijkanten.

Coming soon heeft een eigen omlijst eindbord. De weg loopt achter dit bord en de kasteelondergrond gaat door onder het bord, de voltooiingsknop en de onderste veilige schermmarge. Hierdoor eindigt de kaart niet met een afgekapte weg of een los achtergrondvlak.

Implementatie: [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift) en [WorldMap.swift](../Dino/Views/WorldMap.swift).

## Verificatie

De definitieve Debug-simulatorbuild slaagt. Op 320, 393 en 834 punten breed zijn zes overgangen afzonderlijk gerenderd: 3→4, 4→5, 5→6, 6→7, 8→9 en 9→10. De zandkleur blijft bij alle achttien gecontroleerde aansluitingen exact gelijk op de twee meetstroken naast de stippellijn, over 33 pixelrijen rond de sectiegrens. De twee buitenste meetpunten per zijde verschillen bij de terreinrand maximaal één RGB-kleurstap van 255.

De gerichte schermtest `testWorldBannersHaveBalancedClearance` meet de vrije ruimte boven en onder wereldborden 2, 4, 5, 6, 9 en 10 aan de daadwerkelijke elementranden. Deze meting controleert de zichtbare marges, onafhankelijk van de layoutberekening. De zes bordcontroles en de bestaande Coming soon-test slagen op iPhone 17 en iPad Pro 11-inch (iOS 26.5): twee tests per apparaat, nul fouten. De iPhone-run duurt 129,549 seconden, de iPad-run 125,354 seconden. Na de laatste terreinverfijning slaagt de gerichte wereld-4-controle opnieuw op beide apparaten, met nul fouten.

[Definitieve build](WorldTestLogs/RouteScenery/BalancedMargins/build.log) · [iPhone-margemetingen](WorldTestLogs/RouteScenery/BalancedMargins/iphone.log) · [iPad-margemetingen](WorldTestLogs/RouteScenery/BalancedMargins/ipad.log) · [Pixelcontrole](WorldTestLogs/RouteScenery/BalancedMargins/road-seams.txt).

[Bordovergang op iPhone](Screenshots/RouteScenery/BalancedMargins/world-4-iphone.png) · [Bordovergang op iPad](Screenshots/RouteScenery/BalancedMargins/world-4-ipad.png) · [Laatste iPhone-controle](WorldTestLogs/RouteScenery/BalancedMargins/final-iphone.log) · [Laatste iPad-controle](WorldTestLogs/RouteScenery/BalancedMargins/final-ipad.log).
