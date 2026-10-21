# Tijdpiraten — eerste verbeterslag

21 oktober 2026. Wereld 9 is verder uitgewerkt in de bestaande native SwiftUI-stijl, met het aangeleverde piratenconcept als richting en de detaillering van wereld 3, 5 en 7 als uitgangspunt.

## Kust en begroeiing

De palmen hebben gebogen bladstelen met afzonderlijke bladveren, overlappende groene lagen, geribbelde stammen, wortels en uitgewerkte kokosnoten. Lagere planten hebben een tweede bladlaag en meer contrast in hun bloemen. De stenen hebben afgeronde silhouetten, breukvlakken, korrel, mos en contactschaduwen.

Rotsriffen liggen in de turquoise inhammen, met schuim rond hun voet. Onder het oppervlak liggen zachtere stenen, koraal en verspreide lichtlijntjes. De waterdetails worden gemaskeerd met exact dezelfde inhamcontour als het bestaande water. Die contour verlaat de wereld aan de zijkanten, waardoor beide hoofdstukovergangen droog blijven.

Verspreide waaierschelpen, spiraalschelpen, zeesterren en kiezeltjes vullen het strand. Hun plaatsing houdt ruimte vrij rond het werkelijke slingerpad en controleert het water over hun hele kleine tekenvlak. De zandbanken onder de piratenscènes hebben onregelmatige contouren en zandkorrel.

## Boten en schatten

De boten hebben bolle, brede zeilen met een herkenbaar doodshoofd met gekruiste botten, een donkere piratenvlag, een tweede mast, voorzeil, tuigage, een touwladder en meer hout- en metaalwerk. Het kamp heeft gestreept rood/crème doek, een afgewerkte rand en een kleine schatkist.

De schatkisten staan open: een gevoerde binnenkant, verhoogd deksel, beslag en losse munten vullen de opening. Goudstapels, uitgestrooide munten, edelstenen en parels liggen rond de kisten. De bestaande wereldpreviews delen deze nieuwe piratenscènes.

## Meeuwen en overgangen

Zeven meeuwen vliegen op verschillende hoogtes in beide richtingen, met vleugelslagen en een zachte op-en-neerbeweging. Alleen kleine tekenvlakken rond zichtbare vogels verversen, maximaal twintig keer per seconde. De animatie pauzeert buiten beeld, bij een inactieve app en bij **Minder beweging**. In die laatste stand blijven de vogels in vaste poses staan.

De zon en wolken boven de oorspronkelijke entree zijn vervangen door kustgrond en begroeiing. De bestaande overgangsstroken verbinden deze grond met wereld 8 en 10. Pad, levelposities, titelbord, HUD en eindbaas behouden hun bestaande opbouw.

De implementatie staat in [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift), bij de gedeelde kustcontour, `PirateCoastPainter`, `PirateCoastFlights` en `PirateGullPainter`. [WorldMap.swift](../Dino/Views/WorldMap.swift) plaatst de vliegende vogels boven de getekende weg en onder de levelinterface.

## Beelden

[Voor en na](Screenshots/PirateFirstPass/before-after.jpg) · [iPhone-entree](Screenshots/PirateFirstPass/entrance-iphone.png) · [iPhone-eindbaas en overgang naar wereld 10](Screenshots/PirateFirstPass/boss-iphone.png) · [iPad-entree](Screenshots/PirateFirstPass/entrance-ipad.png) · [kustscènes op iPad](Screenshots/PirateFirstPass/route-87-ipad.png).

Native composities op [320](Screenshots/PirateFirstPass/native-320.png), [393](Screenshots/PirateFirstPass/native-393.png), [834](Screenshots/PirateFirstPass/native-834.png) en [1194](Screenshots/PirateFirstPass/native-1194.png) punten. De genummerde cirkels in deze composities zijn controlemarkeringen; de echte interface staat in de simulatorbeelden.

## Verificatie

De [iOS-build](WorldTestLogs/PirateFirstPass/build.log) en [native renderbuild](WorldTestLogs/PirateFirstPass/native-build.log) slagen. De vier native composities zijn visueel gecontroleerd. Vier animatiemomenten verschillen in pixels; twee beelden met Minder beweging zijn pixel voor pixel identiek. [Pixelcontrole](WorldTestLogs/PirateFirstPass/visual-checks.json).

De bestaande eindbaascontrole slaagt op iPhone en iPad. De oorspronkelijke hoofdstuktest opent level 81, maar verwacht daarna een meerkeuzeantwoord. De huidige leerlijn begint daar met **Zet de klok vooruit**, met een bedienbare analoge klok en een controleerknop. Een afzonderlijke kopie van de schermtest controleert daarom die klok, de bereikbare controleerknop, het voorbeeld, terugkeer naar de kaart en scrollen naar levels 84 en 87. De tests in de werkmap zijn hiervoor niet aangepast.

Deze definitieve controlekopie slaagt op [iPhone](WorldTestLogs/PirateFirstPass/iphone-verified.log) en [iPad](WorldTestLogs/PirateFirstPass/ipad-verified.log): **vier testuitvoeringen, nul fouten**. De [verificatiebuild](WorldTestLogs/PirateFirstPass/verification-build.log) gebruikt dezelfde piratenbroncode als de werkmap. Deze aangepaste kaartcontrole beantwoordt de klokvraag niet; zij controleert de bereikbaarheid en bediening van de vraag en het voorbeeld.

`Tools/test-dino.sh` slaagt met **819.303 controles** voor onder meer spelregels, opslag, voortgang en synchronisatie. [Testlog](WorldTestLogs/PirateFirstPass/core-tests.log). `git diff --check` is schoon.
