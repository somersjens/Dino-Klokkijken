# Clock City — futuristische gebouwen en objecten

De bestaande stadsindeling heeft een nieuwe materiaal- en vormtaal gekregen, gebaseerd op de blauwgroene metalen, blauwe koepels en cyaanaccenten van het stadsbord. Alle acht gebouwtypen gebruiken nu afgeschuinde gevelpanelen, glazen entrees, koel glas, metalen draagribben en dunne lichtlijnen. Winkelluifels en balkonranden zijn opnieuw getekend; de klokken behouden lichte wijzerplaten en donkere wijzers.

Stationskappen, perrons, metrostellen, spoorverlichting, tunnelranden, banken, straatlampen, plantenbakken en terrassen delen die materialen. De kleinere stadsvignetten gebruiken hetzelfde palet. Groen en bloemen houden hun natuurlijke kleuren. Alle extra details zijn statisch; de bestaande afzonderlijke gevelcanvassen en treinanimatie blijven behouden.

Gebouwposities, maten van de kavels, spoorgeometrie, stationsposities, eindbaasplein en tekenvolgorde zijn ongewijzigd ten opzichte van de werkmap bij aanvang. De eerder aanwezige aanpassingen aan de metrobocht en tunnel zijn behouden.

[Gebouwtypen](Screenshots/CityFuturistic/buildings.png) · [Stad op telefoonformaat](Screenshots/CityFuturistic/world-6-393.png) · [Stad op tabletformaat](Screenshots/CityFuturistic/world-6-834.png).

## Controle

De native rendercontrole slaagt op tien breedtes, van 320 tot 1194 punten. Alle gebouwfunderingen blijven vrij van het open spoor. Een vergelijking van alle gebouwposities, hun begrenzingen, de bemonsterde spoorpunten en het eindbaasplein met de oorspronkelijke werkmap geeft exact dezelfde gegevens. [Native controle](WorldTestLogs/CityFuturistic/native.log) · [Vergelijking van de indeling](WorldTestLogs/CityFuturistic/placement-comparison.log).

De simulatorbuild en de build van de bestaande stadstest slagen. [Build](WorldTestLogs/CityFuturistic/build.log) · [Definitieve testbuild](WorldTestLogs/CityFuturistic/build-for-testing.log).

De bestaande schermtest `testCityMetroRouteRemainsPlayable` slaagt op iPhone 17 en iPad Pro 11-inch M5 met iOS 26.5: één test per apparaat, nul fouten. Level 51 opent en start, de route langs levels 54 en 57 blijft bereikbaar en eindbaas 60 opent. [iPhone-test](WorldTestLogs/CityFuturistic/iphone.log) · [iPad-test](WorldTestLogs/CityFuturistic/ipad.log).

De appbeelden zijn ook visueel gecontroleerd: [entree op iPhone](Screenshots/CityFuturistic/city-metro-entrance-iphone.png), [entree op iPad](Screenshots/CityFuturistic/city-metro-entrance-ipad.png), [stadsroute op iPhone](Screenshots/CityFuturistic/city-metro-route-54-iphone.png) en [onderste wijk op iPad](Screenshots/CityFuturistic/city-metro-route-60-ipad.png).

De native beelden kunnen opnieuw worden gemaakt vanuit de projectmap:

```sh
python3 Documentation/WorldTestLogs/CityFuturistic/prepare-native.py /private/tmp/clock-city-futuristic
xcrun swiftc -parse-as-library -module-cache-path /private/tmp/clock-city-futuristic/modules /private/tmp/clock-city-futuristic/native.swift -o /private/tmp/clock-city-futuristic/render
/private/tmp/clock-city-futuristic/render "$PWD/Documentation/Screenshots/CityFuturistic"
```
