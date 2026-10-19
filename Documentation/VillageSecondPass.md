# Wereld 4 — oorspronkelijke beekjes en een levendiger dorp, 19 oktober 2026

De beekjes liggen weer op hun oorspronkelijke positie van vóór de eerste redesignronde. De bochten langs het speelpad, de instroom bovenaan en de uitstroom richting de grot komen rechtstreeks uit de bestaande `passageBankPath`. De eerste ronde verplaatste het water naar de buitenrand om ruimte voor brede dorpsgroepen te maken; die keuze is teruggedraaid. Nu zoekt elk gebouw een passende droge bouwplaats langs het vaste water.

## Dorpsleven

De vijf brede groepen zijn vervangen door afzonderlijke huizen, kramen, boomgaarden en pleintjes. De plaatsing gebruikt ruimte aan beide kanten van de beekjes. Marktkramen zijn compacter en tonen fruitkisten, brood of bloemen. Huizen langs de schermrand mogen het beeld deels verlaten, zodat het dorp buiten het scherm doorloopt. Minstens 56% van zo'n bouwplaats blijft zichtbaar; de volledige ruimte voor het huis moet nog steeds buiten het water vallen.

Kleine dino-bewoners dragen mandjes en schorten, begroeten elkaar en bewegen hun arm en hoofd zacht. Handkarren, bankjes, beplante randen en houten bruggetjes vullen de straten. De bewoners en de bestaande luifel-, molenrad-, fontein- en wateranimaties gebruiken kleine tekenvlakken die alleen in beeld draaien. **Minder beweging** houdt alle onderdelen zichtbaar in een vaste houding.

Op 393 punten breed staan **14 gebouwen, 13 marktkramen en 11 bewoners**; daarnaast zijn er boomgaarden, karren en bankjes. Het precieze aantal en de schaal passen zich aan de droge ruimte aan. [Actueel iPhone-beeld](Screenshots/VillageSecondPass/app-motion-0.png), [native iPhone-compositie](Screenshots/VillageSecondPass/native-393.png), [native iPad-compositie](Screenshots/VillageSecondPass/native-834.png).

## Verificatie

- Op tien breedtes van **320 tot 1194 punten** zijn beide waterpaden exact gelijk aan een ongewijzigde kopie van de oorspronkelijke rivierbouwer. De gebouwen worden dus aangepast aan het water.
- **380.388 punten** in de volledige bouwplaatsen zijn gecontroleerd tegen de werkelijke gestreken rivierpaden, inclusief stenen oevers, en tegen de route. Er zijn geen contacten. [Geometrische controle](WorldTestLogs/VillageSecondPass/native-render.log).
- Alle **24 animatiebeelden** verschillen. Twee beelden met Minder beweging zijn pixel voor pixel gelijk. [Animatie](Screenshots/VillageSecondPass/village-life.gif), [controle](WorldTestLogs/VillageSecondPass/animation-check.txt).
- Twee stilstaande screenshots van de draaiende iPhone-app tonen verplaatste waterreflecties. In een uitsnede met alleen water en oever veranderen **234 pixels** met meer dan achttien RGB-niveaus. [Water in beweging](Screenshots/VillageSecondPass/app-water.gif), [meetlog](WorldTestLogs/VillageSecondPass/app-motion.txt).
- De iOS-build en de tests voor level 31 en het openen van de eindbaas slagen op **iPhone én iPad**: vier geslaagde controles. Een eerste iPad-run werd door een herstart van de testrunner onderbroken; de herhaalde run slaagt volledig. [Build](WorldTestLogs/VillageSecondPass/build.log), [iPhone-tests](WorldTestLogs/VillageSecondPass/final-iphone.log), [iPad-tests](WorldTestLogs/VillageSecondPass/verified-ipad.log).

De andere wereldillustraties blijven gelijk. Het gedeelde hulpmiddel voor de stad gebruikt dezelfde berekening als voorheen; uitsluitend de dorpsvariant kiest de oorspronkelijke dorpsinstroom en -uitstroom. [Broncontrole](WorldTestLogs/VillageSecondPass/scope-check.txt).
