# Hoofdtracking bij de welkomsprong

29 oktober 2026.

De aangeleverde opeenvolgende beelden tonen een andere schok dan de eerder aangepakte vlucht: de rustachtige tekening 01 wordt eerst verwisseld met de diepe bukpose 02 en vrijwel meteen met vliegpose 03. In de bronbeelden verplaatst het midden tussen de ogen zich daarbij van circa (703, 332) naar (833, 548) en vervolgens (685, 304). Een korte afspeelduur lost die grote verplaatsing niet op.

De opening begint nu met precies dezelfde `dino-idle`-afbeelding als de stilstaande compositie. Tekening 01 vervalt uit de opening. Daarna volgt een doorlopende neerwaartse beweging van 0,28 seconde, gevolgd door het opveren en de vlucht. Er is geen stilstand op de laagste positie en er zijn geen extra beelden toegevoegd.

De irissen en de twee neusgaten zijn in de oorspronkelijke beelden gemeten. Een affiene registratie brengt beide ogen en het midden tussen de neusgaten in hetzelfde referentiestelsel. De native afbeeldingslaag houdt een gemeten oogmiddelpunt als anker; een tweede laag beweegt het doelgezicht langs een vloeiend pad. Wanneer de tekening verandert, veranderen het lokale anker en de correctiematrix op exact hetzelfde tijdstip. Daardoor blijven de drie gevolgde gezichtspunten op hun pad.

De bukbeweging helt licht voorover, met veel minder zijwaartse verplaatsing dan in de ruwe bronbeelden. Het laagste oogmiddelpunt ligt op bronhoogte 550, vrijwel gelijk aan de oorspronkelijke diepe buktekening (548). Daarmee zakt de kin weer tot de bovenrand van het bord. De eerste trackingversie stopte op hoogte 470 en verloor daardoor een deel van de buk. Omhoog versnelt Dino naar de houding die hij tijdens de vlucht vasthoudt.

De daaropvolgende hapering bij het opveren had ook een snelheidscomponent. De kwadratische lokale hoofdbeweging eindigde bij de afzet, terwijl de bovenliggende vlieglaag daar ineens begon te verplaatsen, verkleinen en draaien. De beeldpositie was continu, maar de zichtbare snelheid niet. De beweging wordt nu in schermcoördinaten berekend: een kubische Hermite-curve vertrekt vanuit de diepe buk met snelheid nul en sluit 0,10 seconde na de afzet aan op zowel de positie als de snelheid van beide ogen en de neus in de werkelijke vlucht. Tot dat moment compenseert de lokale registratie de bewegende vlieglaag. Daarna heffen registratie en correctie elkaar weer volledig op. De rest van de vlucht en de landing blijven ongewijzigd. Na goedkeuring van de vloeiendheid is de afzet subtiel aangescherpt: het opveren vóór vertrek duurt 0,28 in plaats van 0,34 seconde (circa 18% korter). De neerwaartse buk en de diepte blijven gelijk; de curve sluit nog steeds op de werkelijke vluchtsnelheid aan.

| Fase | Tijd |
| --- | ---: |
| Rust naar laagste bukpositie | 0,00–0,28 s |
| Terugveren naar de vliegpositie | 0,28–0,56 s |
| Vlucht naar de steen | 0,56–1,18 s |
| Aansluiting hoofdbeweging op vlucht, overlappend | 0,56–0,66 s |
| Contact en herstel | 1,18–1,36 s |

De afbeelding wisselt halverwege het bukken op 0,14 seconde naar de buktekening en halverwege het opveren op 0,42 seconde naar de vliegpose. Die wissels sturen niet langer de hoofdpositie. Er is geen overgang via twee overlappende dino's. De native decorvervaging, vooraf voorbereide kaart en volledige bronresolutie blijven behouden. De éénstersprong behoudt zijn eigen oorspronkelijke timing en reeks.

In de simulatoropname bleek bij het begin van de decorvervaging bovendien een langer frame-interval te zitten. De achterste decorlaag gebruikt tijdens de rustfase daarom één transparantiestap (`254/255`) in plaats van volledige ondoorzichtigheid. Zo wordt de kaart alvast mee gecomposeerd in plaats van pas wanneer de vervaging start. De maximale afwijking ten opzichte van de volledig ondoorzichtige versie is één 8-bits kleurstap per kanaal. Alle native keyframe- en bewegingsgroepen van de sprong vragen 60 fps aan.

De gerichte controles bewaken de gevolgde ogen en neus, de continuïteit rond beide beeldwissels, de oorspronkelijke bukdiepte, het wegvallen van tekening 01, de volgorde bij 30 en 60 fps en de oorspronkelijke voetregistratie bij het contact en de uiteindelijke rustpose. Extra controles meten de zichtbare snelheid van alle drie gezichtspunten aan beide kanten van de diepste buk, afzet en aansluiting op de vlucht, in telefoon- en tabletgeometrie en beide schermoriëntaties. De volledige opvering heeft één stijging en geen tweede dip; bij een lage landschapsboog mag het hoogste punt vóór het einde van de aansluiting liggen.

## Verificatie

De build met de iets fellere afzet is geslaagd. De gerichte timing- en assettest bevat 274.366 geslaagde controles, inclusief de snelheidsaansluiting en de bukdiepte. De voorgaande versie met dezelfde vlieg- en landingsgeometrie doorliep de bestaande schermtest voor de opening, landing op opgeslagen level 4 en terugkeer zonder herhaalde opening op een aparte iPhone 18 Pro en iPad (A16), inclusief iPad-landschapstand.

De eerder goedgekeurde native iPhone-opname met de doorlopende afzet is ook rond de afzet op frame-intervallen gecontroleerd. Het langste interval in het gecontroleerde venster is 18,3 ms (5,85–6,85 s in `/tmp/dino-launch-handoff-final-native.mov`), tegenover 65 ms in de voorgaande diepe-bukopname (9,90–10,70 s in `/tmp/dino-deeper-crouch-native.mov`). Dit meet de simulatoropname en vormt geen framerategarantie voor ieder toestel; de positie- en snelheidscontroles staan los van de opnamecadans.

De nieuwe opname met de iets fellere afzet behoudt een regelmatige cadans: maximaal 20 ms in het gecontroleerde afzetvenster (5,50–6,50 s in `/tmp/dino-snappier-takeoff-warm-native.mov`). Ook de opeenvolgende beelden zijn visueel gecontroleerd.

De normale preview staat in `Screenshots/StartScreen/startscreen-snappier-takeoff.mov`. De drie keer vertraagde afzet staat in `Screenshots/StartScreen/startscreen-snappier-takeoff-slow.mov`; deze verandert uitsluitend de afspeeltijd van de originele opname en verzint geen extra frames. De vaste tijdstappen van de voorbereiding staan in `Screenshots/StartScreen/snappier-takeoff-preparation.jpg`. De eerdere trackingpreviews blijven apart beschikbaar voor vergelijking.
