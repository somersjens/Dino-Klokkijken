# Clock City — gevelklokken, stadsentree en metro

Alle gebouwtypen hebben een analoge gevelklok. Winkels, herenhuizen, serres, galerijen en grotere gevelhuizen gebruiken een lichte wijzerplaat met donkere wijzers en uurmarkeringen. De bestaande klokken van de klokkentorens blijven behouden. Ook de openbare gebouwen hebben een klok in hun fronton.

De overgang vanaf Crystal Cave ligt ongeveer 125 punten hoger, achter het wereldembleem. Een aaneengesloten rij gevelhuizen loopt over de volledige schermbreedte, met verschillende dakhoogten en warme en blauwe daken. De centrale gevels staan achter het wereldbord. De laatste grotstenen worden binnen deze gevelrij afgewerkt, zodat geen blauwe uitloper over de stadsbestrating ligt.

Linksonder blijft de metro geleidelijk afdalen. Een laag gevelhuis en een slanke klokkentoren staan op verspringende funderingen vóór de tunnelmond. De metro verdwijnt achter deze gebouwen en rijdt onder de wijk door. De rechter tunnelmond en de volledige klim liggen buiten beeld. De rechter stadsroute loopt langer door en maakt een ruimere boog tot voorbij de schermrand. De laatste verfijning, beelden en controles staan in [CityFlowRefinement.md](CityFlowRefinement.md).

De retourbocht gebruikt de werkelijke schermbreedte. Daardoor ligt de verborgen klim ook op een brede iPad buiten beeld, terwijl de speelroute haar bestaande breedte behoudt. Dezelfde geometrie stuurt de rails, wagonrotatie, helling, ondergrondse uitsnede en plaatsing van de bebouwing.

## Controle en beelden

De native controle onderzoekt tien breedtes: 320, 375, 393, 402, 430, 600, 744, 834, 1024 en 1194 punten. Hij controleert de doorlopende gevelrij, volledige bedekking van de donkere tunnelopening, de rechter klim buiten beeld, vrije open rails en de zichtbare afdaling. De gebouwen vóór de tunnel zijn de bedoelde uitzondering op de normale vrijhouding van spoorfunderingen. De native beelden gebruiken eenvoudige genummerde levelcirkels.

- [Geometriecontrole](WorldTestLogs/CityRedesign/geometry.log)
- [Stadsentree op iPhone](Screenshots/CityRedesign/join-5-393.png)
- [Stadsentree op iPad](Screenshots/CityRedesign/join-5-834.png)
- [Afdalende metro op iPhone](Screenshots/CityRedesign/metro-393-0.png)
- [Metro vanuit de rechter schermrand op iPad](Screenshots/CityRedesign/metro-834-2.png)

De simulatorbuild en de bestaande schermtest `testCityMetroRouteRemainsPlayable` slagen op iPhone 17 en iPad Pro 11-inch M5 met iOS 26.5: één test per apparaat, nul fouten. Level 51 opent en start, de route langs levels 54 en 57 blijft bereikbaar en eindbaas 60 opent. [iPhone-resultaat](WorldTestLogs/CityRedesign/iphone-verified.log) · [iPad-resultaat](WorldTestLogs/CityRedesign/ipad-verified.log). Een eerdere herhaling kon de iPad-testrunner niet starten; na het opstarten van de tijdelijke simulator slaagt de volledige definitieve controle.

De definitieve appbeelden zijn visueel bekeken: [entree iPhone](Screenshots/CityRedesign/city-metro-entrance-iphone.png), [entree iPad](Screenshots/CityRedesign/city-metro-entrance-ipad.png), [onderste wijk iPhone](Screenshots/CityRedesign/city-metro-route-60-iphone.png) en [onderste wijk iPad](Screenshots/CityRedesign/city-metro-route-60-ipad.png). De tijdelijke testsimulators zijn na de controle opgeruimd. De diffcontrole van de stadswijzigingen is schoon.

De native controle is opnieuw uit te voeren vanuit de projectmap:

```sh
set -e
python3 Documentation/WorldTestLogs/CityRedesign/prepare-native.py /private/tmp/clock-city-redesign
xcrun swiftc -parse-as-library -module-cache-path /private/tmp/clock-city-redesign/modules /private/tmp/clock-city-redesign/native.swift -o /private/tmp/clock-city-redesign/render
/private/tmp/clock-city-redesign/render "$PWD/Documentation/Screenshots/CityRedesign"
```

Voeg `--geometry-only` toe aan de laatste opdracht om alleen de indeling te controleren.
