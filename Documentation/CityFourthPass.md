# Wereld 6 — vrije rails, extra stadswijken en een tunneltje

De vorige plaatsing beschermde de levelstraat, maar niet het grondvlak van het spoor. Daardoor konden gebouwen en terrasvloeren onderaan op de rails staan. Deze ronde controleert het volledige grondvlak tegenover de spoorbedding en de stenen rand.

## Plaatsing op echte grond

Gebouwen, trappen en cafévloeren krijgen een eigen grondcontour. Die moet vrij blijven van een spoorstrook van 29 schaalpunten aan weerszijden van de lijn. Waar nodig schuift een locatie naar vrij terrein of wordt de complete compositie kleiner. Wanneer een plek geen gebouw kan dragen, komt er een kleinere straatplek. Daken en verdiepingen mogen nog vóór de metro langs vallen; de voeten van de compositie staan naast het spoor.

De buitenwijken, binnenstraat, openbare voorgrondgebouwen en extra pleinen gebruiken deze controle. Ook de klokrobot krijgt een smaller plein op grond naast de onderste bocht. Op smallere schermen schuift dat plein iets omhoog tot de rails en beide voeten vrij blijven. De robot wordt eenmaal op zijn definitieve plek getekend.

Een ruimtelijke indeling van de spoorbedding houdt deze plaatsingscontrole snel tijdens het opbouwen van de kaart.

## Meer stad boven en onder

Er zijn extra rijen openbare gebouwen, winkels en afzonderlijke cafés bij de entree en rond de onderste lus toegevoegd. Afhankelijk van de schermbreedte passen **19 tot 27 aanvullende locaties** in deze twee stadsdelen. Zuilen, klokken, vaandels, luifels, parasols, tafeltjes en bloemen sluiten aan op de bestaande stad.

Ook deze nieuwe locaties worden als complete vormen geplaatst en houden hun vloer naast het spoor. De skyline blijft dekkend zichtbaar; de gedeelde hoofdstukondergrond wordt vóór de entreegebouwen getekend.

## Onder de levelstraat

Op het laagste deel van de lus loopt de metro door een kort stenen tunneltje onder de levelstraat. Het krijgt twee donkere boogopeningen, gemetselde portaalranden, steenlagen, kleine lampjes en rails die in de openingen verdwijnen.

De ondergrondse ruimte knipt de wagons, stroomafnemers en vonken geometrisch uit de zichtbare animatie. De metro rijdt dezelfde doorgaande lijn: de kop verdwijnt aan de ene kant, passeert onder de straat en verschijnt aan de andere kant. De vroegere dunne oversteekleuningen zijn vervangen door het tunnelgewelf.

[Drie posities van de passage](Screenshots/CityFourthPass/tunnel-sequence.jpg) · [Bewegende reeks van die posities](Screenshots/CityFourthPass/tunnel-sequence.gif).

De bestaande dertig wagons, halve kruissnelheid, twee stationsstops en in- en uitrit buiten beeld blijven behouden.

## Controle

De [native geometriecontrole](WorldTestLogs/CityFourthPass/native-render.log) slaagt op negen breedtes van **320 tot 1194 punten**:

- Alle onderzochte gebouw- en terrasfunderingen en het robotplein blijven vrij van de spoorbedding.
- De volledige gebouwcontouren laten de levelstraat vrij. De extra locaties passen ook verticaal binnen de stadssectie.
- Het tunneltje bedekt de volledige hoogte van wagons en elektrische vonken binnen de ondergrondse ruimte.
- Snelheid, twee stationsstops en herhaling buiten beeld werken nog steeds.

Native beelden leggen de tunnelpassage op drie precieze animatieposities vast, op telefoon-, smalle telefoon- en tabletbreedte. **Minder beweging** geeft identieke beelden op verschillende tijdstippen. Afmetingen, bronhashes en beeldvergelijkingen staan in de [beeldcontrole](WorldTestLogs/CityFourthPass/visual-checks.json).

De app is gebouwd en `testCityMetroRouteRemainsPlayable` slaagt op **iPhone 17 en iPad Pro 11-inch M5**: twee geslaagde uitvoeringen zonder testfouten. Level 51 opent, de route wordt langs levels 54 en 57 bekeken en de eindbaas bij level 60 opent. De test bewaart nu ook een extra beeld van de onderkant na drie seconden beweging. Zie het [apparatenlog](WorldTestLogs/CityFourthPass/devices.log).

De entree, vrije rails, extra onderste bebouwing, het robotplein en de tunnel zijn visueel bekeken in de echte app. De precieze tunnelpassage is daarnaast in de vaste native animatiebeelden gecontroleerd. `git diff --check` is schoon.

## Beelden en scope

[Overzicht van de app](Screenshots/CityFourthPass/app-overview.jpg).

| Deel | iPhone | iPad |
| --- | --- | --- |
| Entree en cafés | [Open](Screenshots/CityFourthPass/city-metro-entrance-iphone.png) | [Open](Screenshots/CityFourthPass/city-metro-entrance-ipad.png) |
| Stadsroute | [Open](Screenshots/CityFourthPass/city-metro-route-57-iphone.png) | [Open](Screenshots/CityFourthPass/city-metro-route-57-ipad.png) |
| Onderste wijk en tunneltje | [Open](Screenshots/CityFourthPass/city-metro-route-60-iphone.png) | [Open](Screenshots/CityFourthPass/city-metro-route-60-ipad.png) |
| Onderkant na beweging | [Open](Screenshots/CityFourthPass/city-metro-tunnel-motion-iphone.png) | [Open](Screenshots/CityFourthPass/city-metro-tunnel-motion-ipad.png) |

[Stadsdiff](WorldTestLogs/CityFourthPass/world-6.diff) · [Aanvulling op de bestaande schermtest](WorldTestLogs/CityFourthPass/city-ui-test.diff).

De wijziging aan de kaart omvat de stadsrenderer en het verwijderen van de dubbele robottekening in de wereld-6-tak. Gelijktijdige wijzigingen aan hoofdstukovergangen, andere werelden en andere tests zijn behouden.
