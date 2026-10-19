# Wereld 4 — eerste redesignronde, 18 oktober 2026

Dino Dorp heeft een nieuwe ruimtelijke indeling: vijf dorpsbuurten aan doorlopende wandelkades, met extra huisjes en boomgaardtuinen tussen de pleinen. De markt bestaat uit meerdere houten fruitkramen met gestreepte luifels, afzonderlijke fruitkisten, tonnen en kleine uithangborden. Een fonteinplein en een molenbuurt geven de route herkenbare bestemmingen.

## Gebouwen en landschap

De huizen staan op gemetselde funderingen en droge bestrating aan de binnenkant van de beekjes. `VillagePlan` bepaalt zowel het water als de ruimte voor complete gebouwen. Bij smalle schermen zoekt de plaatsing een kleinere of iets verschoven bouwplaats. Daarbij blijft de volledige ruimte voor daken, gevels en funderingen vrij van water en het speelpad. Ook de extra huisjes en boomgaarden gebruiken deze controle.

De gevels hebben pleisterdetails, lichtaccenten, houten luiken, bloembakken, klimranken, een zolderraampje, lantaarns en traptreden. De bestaande dakconcepten zijn behouden en verder afgewerkt. Fruitbomen dragen negentien afzonderlijk getekende vruchten, met steeltjes, blaadjes en lichtaccenten. De markt en de huizen staan op kleine pleinen van afzonderlijke straatstenen. De oevers hebben stenen dekplaten, voegen, mos, planten en een doorlopend wandelpad. Beide beekjes komen vanaf de zijkant het dorp in en verlaten de kaart weer vóór de grot.

## Kleine bewegingen

Luifelranden bewegen zacht in de wind, het molenrad draait langzaam, de fontein krijgt bewegende druppels en rimpels, vlinders bewegen bij de planten en kleine reflecties schuiven over het water. De statische dorpsillustratie blijft gecachet; uitsluitend kleine tekenvlakken voor deze details worden bijgewerkt, met maximaal vijftien beelden per seconde. Buiten het scherm en bij een inactieve app pauzeren ze. **Minder beweging** toont een vaste versie waarin alle onderdelen zichtbaar blijven.

## Beelden en controles

- Native composities zijn bekeken op **320, 393, 834 en 1194 punten**: [iPhone](Screenshots/VillageFirstPass/native-393.png), [iPad](Screenshots/VillageFirstPass/native-834.png).
- De vijf dorpsbuurten en aanvullende huisjes/boomgaarden zijn gecontroleerd op **tien breedtes van 320 tot 1194 punten**, inclusief de volledige ruimte voor gebouwen, de afstand tot het water en de afstand tot het pad. Alle controles slagen. [Plaatsingslog](WorldTestLogs/VillageFirstPass/native-render.log).
- **24 verschillende animatiebeelden**; twee beelden met Minder beweging zijn pixel voor pixel gelijk. [Animatie](Screenshots/VillageFirstPass/village-life.gif), [controle](WorldTestLogs/VillageFirstPass/animation-check.txt).
- De draaiende iPhone-app is bekeken met afzonderlijke testvoortgang. Twee beelden zonder scrollen of aanraken tonen de beweging: in alleen de luifeluitsnede verschillen **3.201 pixels** met meer dan achttien RGB-niveaus. [Actueel appbeeld](Screenshots/VillageFirstPass/app-motion-0.png), [bewegingscontrole](WorldTestLogs/VillageFirstPass/app-motion.txt).
- De iOS-build slaagt. De bestaande kaarttest opent de eindbaas van wereld 4 op zowel iPhone als iPad. [iPhone](WorldTestLogs/VillageFirstPass/final-iphone.log), [iPad](WorldTestLogs/VillageFirstPass/final-ipad.log).
- De bestaande hoofdstuktest slaagt afzonderlijk op zowel iPhone als iPad: level 31 openen, starten, de eerste vraag beantwoorden en doorgaan naar de tweede vraag. [iPhone](WorldTestLogs/VillageFirstPass/level31-iphone.log), [iPad](WorldTestLogs/VillageFirstPass/level31-ipad.log). De vier geslaagde spelcontroles bestaan uit deze twee uitvoeringen en de twee eindbaascontroles; de afzonderlijke titelafstandtest blijft rood.
- De bestaande test voor gelijke afstand boven en onder de titel faalt: het verschil is **6,42 punten op iPhone** en **6,90 punten op iPad**, bij een tolerantie van vier punten. De titelgeometrie, levelposities en het hoofdpad zijn in deze ronde niet aangepast. Deze afstandsafwijking is daarmee geen geslaagde controle en blijft een aandachtspunt voor de volgende ronde.

De codewijzigingen zijn beperkt tot de dorpsplanner, de dorpsillustratie en de nieuwe wereld-4-animatielaag in `JungleLandscape.swift`. De tekeningen van andere werelden zijn vergeleken met de toestand bij aanvang en zijn gelijk gebleven. Er zijn geen bitmapachtergronden toegevoegd.
