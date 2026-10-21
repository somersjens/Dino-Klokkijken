# Tijdpiraten — droge steigerinstap

21 oktober 2026. De steigers schilderden een eigen ovaal water- en schuimvlak onder het volledige dek. Daardoor verscheen ook aan de zandkant water boven de echte strandgrond.

De waterlaag van beide kuststeigers wordt nu begrensd door de definitieve zeecontour, vóór de plaatselijke verplaatsing en spiegeling van het houtwerk. Aan de landkant blijft zand zichtbaar. De korte instap is verlengd met aangesloten planken, houtnerf, spijkerkoppen en een ondersteunende balk. De rechter steiger is gespiegeld, zodat zijn instap naar het vasteland wijst.

Ook de schuimlaag onder de piratenschepen gebruikt voortaan de echte watercontour. Zo kan dit wateraccent niet alsnog over een nabije strandrand heen tekenen. De ondergrond van de kleine waterval blijft een afzonderlijke bronpoel.

`PirateCoastLayout.jetties` deelt de posities en de richting van de steigers. `PirateCoastPainter.seaWash` begrenst de zee-effecten. De houtlagen blijven los van deze begrenzing, zodat het dek vanaf zee doorloopt op het zand. Implementatie: [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift).

## Beelden

[Vergelijking op telefoonbreedte](Screenshots/PirateThirdPass/before-after.jpg) · [rechter steiger op tabletbreedte](Screenshots/PirateThirdPass/right-jetty-before-after.jpg).

Native composities op [320](Screenshots/PirateThirdPass/native-320.png), [393](Screenshots/PirateThirdPass/native-393.png), [834](Screenshots/PirateThirdPass/native-834.png) en [1194](Screenshots/PirateThirdPass/native-1194.png) punten zijn visueel gecontroleerd. De cirkels in deze native composities zijn controlemarkeringen.

## Controles

De [iOS-build](WorldTestLogs/PirateThirdPass/build.log) en [native renderbuild](WorldTestLogs/PirateThirdPass/native-build.log) slagen. De bestaande plaatsingscontrole bevestigt op tien breedtes dat de scheepsrompen in het water liggen en de schatplekken doorlopend op droog land liggen. [Plaatsings- en renderlog](WorldTestLogs/PirateThirdPass/native-render.log).

Vier bewegingsbeelden verschillen; twee beelden met **Minder beweging** zijn pixelgelijk. [Pixelcontrole](WorldTestLogs/PirateThirdPass/visual-checks.json).

Een aanvullende controle test 32 punten op de twee instappen per schermbreedte: op alle tien breedtes liggen deze **320 punten op droog land**. Samen met de eerdere romp- en strandcontroles slagen 25.520 plaatsingscontroles. [Geometriecontrole](WorldTestLogs/PirateThirdPass/geometry-checks.log).

De gerichte controles van de kaart, de bediening van level 81 en de eindbaas slagen op [iPhone](WorldTestLogs/PirateThirdPass/iphone-verified.log) en [iPad](WorldTestLogs/PirateThirdPass/ipad-verified.log): vier testuitvoeringen, nul fouten. Hiervoor is dezelfde afzonderlijke controlekopie gebruikt als in de tweede ronde; de tests in de werkmap zijn niet aangepast. De gecontroleerde piratenbroncode komt overeen met de werkmap. [Actueel appbeeld met de droge instap](Screenshots/PirateThirdPass/pirate-route-83-iphone.png). `git diff --check` is schoon.
