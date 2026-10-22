# Wereld 8 — stroming, aansluitingen en laagvolgorde

21 oktober 2026. Vervolg op de [eerste stadsronde](TimeMachineKingdomFirstPass.md), naar aanleiding van de drie aangeleverde detailbeelden.

## Water dat in de rivier uitkomt

De losse opvangbakjes onder de uitlaten zijn verwijderd. Iedere uitvinding heeft nu een messing leiding die naar de nabijgelegen rivier loopt. De monding en de onderkant van de waterval worden vanuit dezelfde rivierbocht berekend. Ook de uitvindingen aan de rechterkant lozen daardoor naar de rivier, in plaats van naar de buitenrand van het scherm.

Rivier en watervallen delen één blauw palet. Meerdere stroomdraden, schuimstrepen en lichtere waterbanen bewegen met verschillende snelheden door de rivier. Bij de uitmondingen lopen bewegende draden door tot aan het rivieroppervlak en ontstaan kleine schuimkringen. De grote rechthoekige animatiemaskers zijn vervangen door de daadwerkelijke silhouetten van machines, balustrades, bruggen en lantaarns. Een smalle paal verbergt daardoor alleen het water direct achter de paal.

[Opname uit de iPhone-simulator](Screenshots/TimeMachineWaterConnections/water-flow-iphone.mp4) · [Animatiepreview](Screenshots/TimeMachineWaterConnections/water-flow-detail.gif)

## Diepte en volledige lantaarns

De bovenste balkons en de onderste terrasranden krijgen elk hun eigen grondhoogte. Hun balustrades, vaandels en begroeiing worden samen met machines, losse apparaten en bruggen op die hoogte gesorteerd. De animatiemaskers gebruiken dezelfde onderdelen en dezelfde volgorde. Gevelklokken hebben een eigen bevestigingslaag en blijven achter de uitvinding die vóór hun gevel staat.

Bruggen worden geplaatst buiten de wijzerplaten en buiten de wateruitlaten. Zo loopt een brugdek niet meer dwars door een klok of waterval. De uiteinden van balustrades volgen het bordes waarop ze staan.

Alleen het metselwerk en de funderingen worden nog op de stadsrand afgeknipt. Uitstekende lantaarns, tandwielen, vaandels en begroeiing mogen over de paarse bestrating heen hangen. Het echte zandpad en de levelstenen blijven vrij. Iedere stadslantaarn wordt over zijn volledige hoogte geplaatst, inclusief het dakje en het glas; indien nodig krijgt de bevestiging een korte messing steunarm.

## Beelden en controle

De [testbuild](WorldTestLogs/TimeMachineWaterConnections/build.log) en de bestaande `testTimeMachineWorkshopRouteRemainsPlayable` slagen op [iPhone 17](WorldTestLogs/TimeMachineWaterConnections/iphone.log) en [iPad Pro 11-inch](WorldTestLogs/TimeMachineWaterConnections/ipad.log): **twee geslaagde testuitvoeringen**. De tests controleren level 71 met de instelbare klok, scrollen langs levels 74 en 77 en openen de eindbaas bij level 80.

De entree, het middendeel en de uitgang zijn op beide apparaten visueel nagekeken ([beeldoverzicht](Screenshots/TimeMachineWaterConnections/app-overview.png)). Native overzichtsrenders zijn gemaakt op [320](Screenshots/TimeMachineWaterConnections/native-320.png), [393](Screenshots/TimeMachineWaterConnections/native-393.png), [834](Screenshots/TimeMachineWaterConnections/native-834.png) en [1194](Screenshots/TimeMachineWaterConnections/native-1194.png) punten breed.

De [geometriecontrole](WorldTestLogs/TimeMachineWaterConnections/native-render.log) onderzoekt negen breedtes van 320 tot 1194 punten. Alle **81 onderzochte uitmondingen** sluiten exact op hun riviermiddellijn aan. Alle **11.496 onderzochte punten** van de lantaarnsilhouetten liggen buiten het speelpad en de levelstenen. De geplaatste bruggen raken geen onderzochte klokvlakken. Dit zijn geometrische steekproeven, aangevuld met de appbeelden.

De rivieranimatie is ook afzonderlijk mét de echte voorgrondmaskers gerenderd. Na 0,35 seconde veranderen op 393 punten breed 5.943 waterpixels en op 834 punten breed 8.816 waterpixels. Deze meting bevat geen bewegende portalen of tandwielen. Twee volledige renders met **Minder beweging** zijn identiek ([meetbestand](WorldTestLogs/TimeMachineWaterConnections/visual-checks.json)). De bestaande zichtbaarheidspauze en pauze bij een inactieve app zijn behouden. `git diff --check` is schoon.

Het [diff voor deze ronde](WorldTestLogs/TimeMachineWaterConnections/world-8.diff) is beperkt tot het Tijdmachine-gedeelte van het gedeelde tekenbestand. Onafhankelijke wijzigingen aan de piratenwereld zijn behouden.

Vervolg: [Bronhuizen, afvoerputten, bevestigde versieringen en bewegende uurwerken](TimeMachineKingdomFinish.md).
