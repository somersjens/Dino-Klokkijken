# Wereld 10 — groot kasteel bij de koning, 27 oktober 2026

Het grote kasteel staat nu aan het einde van de wereld, boven Koning Chronos. Het behoudt op alle schermbreedtes zijn schaal van 0,94 ten opzichte van de wereld. Op telefoons loopt de rechtervleugel buiten beeld door. Het voorplein ligt op de droge oever; de brug eindigt aan de ingang van dat plein. De gevel, het plein en de onderzijde van de brug houden afstand tot de koning. Het kleinere paleisje staat op het hof halverwege. De laatste decoratieve galerij rechts op tablets vervalt, zodat haar standbeeld de nieuwe kasteelgevel niet bedekt.

Alle zes trapvluchten delen de bestaande eindpunten met hun negen bordessen. Eerst worden de vloeren getekend, daarna de treden en ten slotte de leuningen. De laatste trede sluit vlak op het volgende bordes aan. De vloerrand is onderbroken bij de volgende trap. De leuningen lopen met passende raaklijnen over de tussenbordessen door en sluiten bij de boven- en onderbrug aan; de tuintoegang blijft open.

De dinostandbeelden hebben een nieuw gebeeldhouwd silhouet met een brede snuit, korte armen, stevige achterpoten, een oplopende staart en rugstekels. Een zachte kalksteengradiënt, buik- en kniereliëf, fijne steenkorrels, een gouden kroon en een blauw met gouden plakkaat vervangen de eerdere blokvoegen door het lichaam.

## Beelden

- [Kasteel op telefoon](Screenshots/CastlePlacementAndStatue/palace-393.png) en [tablet](Screenshots/CastlePlacementAndStatue/palace-834.png).
- [Standbeeld en trappen](Screenshots/CastlePlacementAndStatue/district-0-834.png).
- [Klein paleisje halverwege](Screenshots/CastlePlacementAndStatue/district-1-393.png).
- [Volledige wereld op 320 punten](Screenshots/CastlePlacementAndStatue/full-320.png) en [834 punten](Screenshots/CastlePlacementAndStatue/full-834.png).

## Controle

De native Canvas-tekeningen zijn gerenderd op 320, 393, 834 en 1194 punten breed en visueel gecontroleerd. De [geometriecontrole](WorldTestLogs/CastlePlacementAndStatue/geometry.log) controleert tien breedtes van 320 tot 1194 punten: 169.070 meetpunten van de trap-, bordes- en voorpleinvloeren blijven vrij van rivier en speelroute. Alle gedeelde trapuiteinden sluiten aan. Het paleis behoudt zijn schaal, de brug komt in het voorplein uit en ook de onderzijde van de brug blijft boven de ruimte voor de koning. Alle 320 gecontroleerde pixels op de rivier onder de acht werkelijk gerenderde brugbogen blijven transparant.

De eindtest wacht nu, net als de bestaande eindbaastest, eerst tot de kaartopening klaar is voordat hij de bediening van level 100 controleert. Daarmee controleert hij de normale interactieve kaart na de openingsanimatie.

De echte appbeelden van [iPhone](Screenshots/CastlePlacementAndStatue/scenery-depth-world-10-iphone.png) en [iPad](Screenshots/CastlePlacementAndStatue/scenery-depth-world-10-ipad.png) tonen het grote kasteel boven de koning, de bereikbare laatste levels en het vernieuwde standbeeld.

De definitieve simulatorbuild slaagt. De hoofdstuktest controleert level 91 en een vraag; de eindbaastest controleert de bereikbaarheid en bediening van level 100. Beide slagen op iPhone 18 Pro en iPad Pro 13-inch (M5), met iOS 27. De afzonderlijke herhaling van de eindtest na de synchronisatiecorrectie slaagt op beide apparaten. Daarmee zijn de drie gerichte controles per apparaat geslaagd. [Resultaten](WorldTestLogs/CastlePlacementAndStatue/verification.log) · [Afsluiting op iPhone](Screenshots/CastlePlacementAndStatue/ending-iphone.png) · [Afsluiting op iPad](Screenshots/CastlePlacementAndStatue/ending-ipad.png).

De eerste iPhone-eindtest controleerde de bediening tijdens de openingsanimatie; een eerdere iPad-run had een onderbroken testrunner. De eindtest gebruikt nu dezelfde bestaande openingscontrole als de eindbaastest. Spelvragen, voortgang en antwoordcontrole zijn voor deze wijziging niet aangepast. Alle illustraties blijven native Canvas; er zijn geen bitmap-assets aan het spel toegevoegd. `git diff --check` is schoon.
