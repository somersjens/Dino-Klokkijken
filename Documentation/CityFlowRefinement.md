# Clock City — ruimere metrobocht en een natuurlijk stadshoekje

De rechter metrolijn loopt langer naar beneden en draait met een ruimere boog naar buiten. De horizontale raaklijn ligt voorbij de schermrand. Lange bochthandvatten houden de overgang geleidelijk op zowel iPhone als iPad.

De zichtbaarheid van rails en trein volgt nu de afstand langs het spoor. Daardoor kan de uitsnede van de ondergrondse lus de zichtbare retourbocht niet meer wegknippen. De linker afdaling blijft zichtbaar en de rechter klim blijft buiten beeld.

De twee gelijke winkels links zijn vervangen door een laag gevelhuis en een slanke klokkentoren. Hun schaal, hoogte en funderingslijn verschillen. De torenhoogte is begrensd op brede schermen, zodat de koepel en wijzerplaat vrij naast het slingerende speelpad blijven staan. De donkere tunnelmond blijft achter de bebouwing verborgen.

## Beelden en controle

- [iPhone: toren, afdaling en rechterbocht](Screenshots/CityFlowRefinement/metro-393-0.png)
- [iPad: metro vanuit de schermrand](Screenshots/CityFlowRefinement/metro-834-2.png)
- [Smalle iPhone](Screenshots/CityFlowRefinement/metro-320-0.png)
- [Indelingscontrole op tien breedtes](WorldTestLogs/CityFlowRefinement/geometry.log)

De native controle slaagt op tien breedtes van 320 tot 1194 punten. Hij onderzoekt een volledig bedekte tunnelmond, verschillende gebouwtypen bij de ingang, een aanwezige klokkentoren, de verborgen rechter klim en vrije open rails. Ook de latere passage van de schermrand en de positie van de robot bij level 60 worden gecontroleerd. De native afbeeldingen gebruiken eenvoudige genummerde levelcirkels.

De simulatorbuild en `testCityMetroRouteRemainsPlayable` slagen op iPhone 17 en iPad Pro 11-inch M5 met iOS 26.5: één test per apparaat, nul fouten. Level 51 opent en start, levels 54 en 57 blijven bereikbaar en eindbaas 60 opent. [iPhone-test](WorldTestLogs/CityFlowRefinement/iphone.log) · [iPad-test](WorldTestLogs/CityFlowRefinement/ipad.log).

De definitieve appbeelden tonen de [onderste wijk op iPhone](Screenshots/CityFlowRefinement/city-metro-route-60-iphone.png) en [onderste wijk op iPad](Screenshots/CityFlowRefinement/city-metro-route-60-ipad.png). De diffcontrole is schoon.
