# Dino Stad — eerste redesignronde

Wereld 6 is uitgewerkt als een levendige stad op basis van het aangeleverde voorbeeld. De bestaande waterlopen zijn vervangen door een doorlopende, slingerende metrolijn. De kaart blijft volledig getekend met SwiftUI en Canvas.

## Stad en metro

- Eén lijn loopt vanaf de linkerhalte langs de bochten van het speelpad, keert onderaan terug en eindigt bij de rechterhalte. De twee haltes staan bewust op verschillende hoogtes. Perrons, glazen overkappingen, M-borden, toegangstrappen en stootblokken maken de haltes herkenbaar.
- Drie blauwe wagons volgen elk afzonderlijk het spoor. De metro rijdt snel, remt af bij de eindhaltes en wacht daar kort voor de terugrit. Kleine elektrische vonken en snelheidsstrepen bewegen met de trein mee.
- Het spoor heeft een verhoogde stenen bedding, dwarsliggers, twee stalen rails en lage balustrades. Het speelpad loopt bij de onderste keerbocht boven het spoor langs.
- Doorlopende geplaveide stadsflanken vervangen de losse eilandjes. Verhoogde terrassen, trappen en balustrades verbinden de gevels met de straat.
- Terrassen hebben blauwe en gele parasols, ronde tafels, stoelen, kopjes en menubordjes. Straatbomen, plantenbakken, bloemen, lantaarns en luifels geven de stad meer sfeer.
- Grotere openbare gebouwen hebben zuilen, geveldriehoeken, stadszegels en blauwe vaandels. Een stadhuisvariant heeft een klokkentoren. Gewone gevels en openbare gebouwen wisselen elkaar af; brede iPads krijgen extra bouwblokken en terrassen.
- Warmere ramen en zachtere overgangen naar de omliggende werelden verbinden de nieuwe onderdelen met de bestaande tekenstijl.

De stadsarchitectuur gebruikt de bestaande cache voor kaartkunst. De drie kleine bewegende tekenvlakken tekenen alleen de wagons die nabij het scherm liggen. De animatie stopt buiten beeld en bij een inactieve app; **Minder beweging** toont een stilstaande trein zonder vonken.

## Beelden

De simulatorbeelden tonen de echte interface; native overzichtsrenders gebruiken eenvoudige genummerde cirkels als routeaanduiding.

| Kaartdeel | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste halte | [Open](Screenshots/CityFirstPass/city-metro-entrance-iphone.png) | [Open](Screenshots/CityFirstPass/city-metro-entrance-ipad.png) |
| Bovenste stadswijken | [Open](Screenshots/CityFirstPass/city-metro-route-54-iphone.png) | [Open](Screenshots/CityFirstPass/city-metro-route-54-ipad.png) |
| Onderste stadswijken | [Open](Screenshots/CityFirstPass/city-metro-route-57-iphone.png) | [Open](Screenshots/CityFirstPass/city-metro-route-57-ipad.png) |
| Eindbaas en keerbocht | [Open](Screenshots/CityFirstPass/city-metro-route-60-iphone.png) | [Open](Screenshots/CityFirstPass/city-metro-route-60-ipad.png) |

Volledige native kaarten: [320](Screenshots/CityFirstPass/native-320.png), [393](Screenshots/CityFirstPass/native-393.png), [834](Screenshots/CityFirstPass/native-834.png) en [1194](Screenshots/CityFirstPass/native-1194.png) punten breed.

## Verificatie

De [geometriecontrole](WorldTestLogs/CityFirstPass/native-render.log) onderzoekt negen breedtes van 320 tot 1194 punten. Het spoor blijft minimaal 82 punten van de middelpunten van de levelstenen; de treinposities blijven ook bij stoppen en omkeren binnen de spoorlengte. De stadsbaas en zijn plein staan in een afzonderlijke voorgrondlaag vóór de bewegende trein. Het gecentreerde speelpad wordt vrijgehouden door de contouren van de stadsflanken.

Vier vaste animatietijdstippen geven verschillende beelden. Twee renders met **Minder beweging** zijn identiek ([controlebestand](WorldTestLogs/CityFirstPass/visual-checks.json)).

De gerichte simulatortest `testCityMetroRouteRemainsPlayable` opent level 51, controleert dat de vraag verschijnt, scrolt langs levels 54, 57 en 60 en opent de eindbaas. De definitieve controle slaagt op iPhone 17 en iPad Pro 11-inch: **twee geslaagde testuitvoeringen, zonder fouten** ([apparatenlog](WorldTestLogs/CityFirstPass/devices.log)). De entree, de stadswijken en de eindbaas zijn op beide schermformaten visueel gecontroleerd ([overzicht](Screenshots/CityFirstPass/app-overview.jpg)).

`git diff --check` is schoon.

Het [afzonderlijke stadsdiff](WorldTestLogs/CityFirstPass/world-6.diff) bewaart de wijziging aan de stad. Gelijktijdige aanpassingen aan andere werelden in dezelfde bronfile zijn behouden.
