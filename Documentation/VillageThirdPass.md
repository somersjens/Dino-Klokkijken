# Wereld 4 — grotere gebouwen en werkende ophaalbruggen, 19 oktober 2026

De klokkentoren is een herkenbaar hoog gebouw geworden, met een ronde, volledig zichtbare wijzerplaat. Huizen, marktkramen en fruitbomen staan op de buitenoevers van de oorspronkelijke rivieren. De binnenoevers hebben bankjes en beplante wandelkades. De plaatsing geeft grotere gebouwen voorrang en reserveert daarna fruitbomen en marktkramen, zodat ook een smalle iPhone een dorp met een markt toont.

Op 393 punten breed zijn er drie grote woonhuizen, een molen, de klokkentoren, vier marktkramen, twee volwassen fruitbomen, een handkar en tien bankjes. Boomkruinen zijn veel hoger dan de bloemen. De hoge gevels en boomkruinen mogen in het verhoogde kaartperspectief boven water en achter andere decorstukken uitsteken; hun funderingen staan op droge grond. Huizen aan de schermrand lopen deels buiten beeld door. De complete klok blijft zichtbaar.

## Varen en bruggen

Er varen precies twee dino's: één bootje per rivier. De romp volgt de bochten van het bestaande water; roeispanen en een kleine boeggolf bewegen mee. De vijf bruggen hebben ieder één dino-brugwachter op de binnenkade. Bij een naderend bootje draait deze aan de lier, gaat het houten brugdek omhoog en blijft het open totdat het bootje veilig voorbij is. Daarna draaien lier en brug terug. Er zijn geen losse, zwaaiende bewoners meer langs de route.

Bootpositie, brugdek, kabel en hand aan de lier gebruiken dezelfde tijdlijn en afgelegde afstand. De brug is al volledig open voordat de boeg aankomt en begint pas na de passage te sluiten. Kleine tekenvlakken beperken de bewegende laag tot zichtbare bootjes en bruggen. De bestaande water-, luifel-, fontein- en molenanimaties blijven aanwezig. **Minder beweging** zet het geheel in een vaste houding.

[Bewegend voorbeeld van een volledige passage](Screenshots/VillageThirdPass/bridge-passage.gif) · [Volledig iPhone-ontwerp](Screenshots/VillageThirdPass/native-393.png) · [iPad-ontwerp](Screenshots/VillageThirdPass/native-834.png).

## Controles

- Beide rivierpaden zijn op tien breedtes van 320 tot 1194 punten exact gelijk aan een ongewijzigde referentie van de oorspronkelijke rivierbouwer. Het water is niet voor de huizen verplaatst.
- Alle huizen, kramen en bomen staan buiten de rivieren; alle bankjes staan binnen. Er zijn 473.484 punten langs de funderingen en de volledige ruimte rond het speelpad gecontroleerd. Elke breedte heeft een grote toren, minstens twee fruitbomen, minstens drie kramen en minstens vijf bankjes. Zie [geometrie- en doorvaartcontrole](WorldTestLogs/VillageThirdPass/native-render.log).
- De zichtbare romp van beide bootjes blijft tijdens de volledige route binnen het echte wateroppervlak. Alle vijf bruggen zijn gecontroleerd vóór, tijdens en na de passage, inclusief de lierbeweging.
- De 64 beelden van de passage verschillen allemaal. Met Minder beweging zijn alle dorps- en verkeerspixels onder het vaste titelbord identiek op twee verschillende tijdstippen. Zie [animatiecontrole](WorldTestLogs/VillageThirdPass/animation-check.txt).
- Twee screenshots van de draaiende app zonder scrollen tonen beweging in water en brugwachters; de uitsnede van alleen de middelste brugwachter verschilt op 481 pixels met meer dan 18 RGB-niveaus. [Livebeeld](Screenshots/VillageThirdPass/app-motion-0.png) · [Meetlog](WorldTestLogs/VillageThirdPass/app-motion.txt).
- De iOS-build en de bestaande tests voor level 31 en het openen van de eindbaas slagen op iPhone en iPad. Zie [iPhone](WorldTestLogs/VillageThirdPass/verified-iphone.log) en [iPad](WorldTestLogs/VillageThirdPass/verified-ipad.log). Deze tests gebruiken afzonderlijke testvoortgang.

De native tekencontrole isoleert wereld 4; voor het gelijktijdig bewerkte kasteel gebruikt dit tijdelijke tekenprogramma de eerdere kasteeltekening. De iOS-build en speltests compileren wel de volledige actuele app.
