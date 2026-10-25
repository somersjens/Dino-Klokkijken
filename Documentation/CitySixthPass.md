# Wereld 6 — nieuwe stadsindeling

De stadsbebouwing gebruikt nu één gezamenlijke indeling. De oude, over elkaar geplaatste reeksen gevels en losse huizen langs de binnenrand zijn vervangen door buitenwijken met verschillende bouwhoogtes, gevelhuizen, galerijen, serres, openbare gebouwen en klokkentorens. Extra torens vullen de bovenste skyline op buiten de looproute.

Gebouwen, treinwagons, stationskappen en het eindbaasplein delen hun tekenvolgorde op basis van het grondcontact. Gedetailleerde gevels blijven in afzonderlijke, stabiele canvassen staan tijdens de treinanimatie.

Terrasvloeren sluiten aan op de buitenrand van het spoor. De stations hebben bredere perrons, een doorlopende gebogen kap, duidelijke entrees, klokken, informatiepanelen, zitbanken en plantenbakken. De grotbodem blijft over de volle breedte zichtbaar achter en boven het stadslabel; de stadsbestrating begint onder het bord. De overgang naar de volgende wereld behoudt zijn natuurlijke grondrand.

## Controle

De native indelingscontrole slaagt op negen breedtes, van 320 tot 1194 punten. De controle onderzoekt unieke gebouwidentiteiten, verschillende gebouwtypen, vrije spoorfunderingen, afstand van volledige gevels tot de centrale promenade en ruimte rond het eindbaasplein. [Geometrieresultaten](WorldTestLogs/CitySixthPass/geometry.log).

De bestaande schermtest `testCityMetroRouteRemainsPlayable` slaagt op iPhone 17 en iPad Pro 11-inch M5. Level 51 opent, de route wordt langs levels 54 en 57 bekeken en de eindbaas bij level 60 opent. De test legt ook beelden na beweging vast. [iPhone-test](WorldTestLogs/CitySixthPass/iphone.log) · [iPad-test](WorldTestLogs/CitySixthPass/ipad.log).

De laatste kleine verschuiving van de bovenste skyline is meegenomen in de definitieve iPhone-test en de indelingscontrole op alle negen breedtes. De iPad-beelden tonen de voorafgaande skylinepositie; de stations en verdere stadsroute zijn daarin gelijk.

`git diff --check` is schoon. Gelijktijdige wijzigingen aan de wereldborden en resultaatschermen zijn behouden.

## Appbeelden

- [Grotverbinding en bovenste skyline, iPhone](Screenshots/CitySixthPass/city-metro-entrance-iphone.png)
- [Stations en stadsroute, iPhone](Screenshots/CitySixthPass/city-metro-route-54-iphone.png)
- [Onderste wijk en eindbaas, iPhone](Screenshots/CitySixthPass/city-metro-route-60-iphone.png)
- [Stations en stadsroute, iPad](Screenshots/CitySixthPass/city-metro-route-54-ipad.png)
- [Onderste wijk en eindbaas, iPad](Screenshots/CitySixthPass/city-metro-route-60-ipad.png)
