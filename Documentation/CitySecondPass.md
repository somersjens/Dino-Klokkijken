# Dino Stad — langere metro en verdieping

Deze tweede ontwerpronde verwerkt de feedback op de eerste versie. De trein is ongeveer tien keer zo lang, rijdt op halve kruissnelheid en gebruikt een spoor dat links buiten beeld begint en rechts buiten beeld eindigt.

## Metro en spoor

- Het aantal wagons gaat van **3 naar 30**. De volledige trein is circa **932 tekenpunten** lang vóór de schermschaal, tegenover circa 93 punten in de eerste ronde. Elke wagon volgt afzonderlijk dezelfde spoorgeometrie.
- De kruissnelheid gaat van **265 naar 132,5 tekenpunten per seconde**. Accelereren en remmen verlopen geleidelijk. De trein stopt kort bij beide stations en rijdt daarna verder.
- De inrit begint 220 schaalpunten voorbij de linker schermrand. Het spoor slingert langs het speelpad en onderaan om de laatste levelsteen heen, en loopt daarna door tot 220 schaalpunten voorbij de rechter schermrand. De oude zichtbare stootblokken en doodlopende uiteinden zijn verwijderd.
- De herhaling van de animatie gebeurt pas nadat ook de laatste wagon buiten beeld is. Er verschijnt geen trein plotseling midden op het zichtbare spoor.
- Blauwe carrosserieën, lichte daken, warme ramen, metalen dakdetails, stroomafnemers, koplampen en messing randen sluiten sterker aan op het voorbeeld. Kleine elektrische vonken blijven bij de stroomafnemers en cabines.
- Beide stations hebben een perron dat de echte spoorbocht volgt, gele veiligheidslijnen, banken, toegangstrappen, een M-bord, glas en gebogen dakspanten. Het zijn nu doorgaande stations.

## Stad, complete vormen en laagvolgorde

De eerste versie gebruikte een gebogen masker voor zowel de straat als de architectuur. Daardoor werden gebouwen, parasols en decoraties door de bochten afgesneden. Dat masker wordt nu uitsluitend voor de bestrating gebruikt. Gebouwen en terrassen worden als complete objecten geplaatst en krijgen geen uitsnede langs een bocht.

Belangrijke openbare gebouwen en terrassen worden op hun hele omtrek ingepast. Gevelwanden lopen als een doorlopend stadspanorama achter de schermranden door. Beide gebruiken een geometrische vrije zone rond het speelpad.

De gevels hebben meer verdiepingen, mansardedaken, dakramen, schaduwkanten, gemetselde banden, balkons, metalen leuningen, blauwe luifels, hangende bloemen en warm verlichte winkelramen. Openbare gebouwen met zuilen en stadsvaandels, caféterrassen, straatbomen en kleine dinobewoners brengen variatie aan.

De achtergrondstad en terrassen staan achter het verhoogde spoor. Wagons worden op hun verticale positie getekend. Perronoverkappingen, de voetgangersoversteek en het plein met de stadsbaas hebben een afzonderlijke statische voorgrond boven de bewegende trein. De animatievlakken zijn ruim genoeg voor daken en vonken.

Bovenaan maken een gelaagde skyline, wolken, gevels en beplante entreeterrassen de stad herkenbaarder. Onderin sluiten parkterrassen, trappen en stenen brugleuningen de stadsroute af voordat deze overgaat in Slaapvallei.

## Controle

De [native geometrie- en bewegingscontrole](WorldTestLogs/CitySecondPass/native-render.log) onderzoekt negen schermbreedtes van 320 tot 1194 punten:

- Het spoor begint en eindigt aan de bedoelde buitenkanten van het scherm.
- De kruissnelheid blijft begrensd op de nieuwe waarde; beide stations krijgen een stop.
- Een sprong naar het begin van de animatie vindt alleen plaats als de volledige trein voorbij de uitrit is.
- De hoofdgebouwen en terrassen passen volledig binnen het scherm; alle onderzochte gebouwcontouren laten het speelpad vrij.
- Het spoor ligt minimaal 67 punten van de middelpunten van de levelstenen op het smalste onderzochte scherm. Op 393 punten breed is dit minimaal 84 punten.

Vaste animatierenders controleren beweging en **Minder beweging**. De animatie stopt ook buiten beeld en bij een inactieve app. De [beeldcontrole](WorldTestLogs/CitySecondPass/visual-checks.json) bewaart de resultaten.

De gerichte schermtest `testCityMetroRouteRemainsPlayable` controleert de entree, level 51, de route langs levels 54 en 57 en de eindbaas. Bij level 54 worden twee beelden met tijd ertussen vastgelegd. De definitieve controles slagen op iPhone 17 en iPad Pro 11-inch: **twee geslaagde testuitvoeringen, zonder fouten** ([apparatenlog](WorldTestLogs/CitySecondPass/devices.log)). De vastgelegde appbeelden verschillen op beide apparaten tussen de twee tijdstippen. De entree, beide stadsdelen en de onderkant zijn visueel nagekeken.

`git diff --check` is schoon.

## Beelden

[Overzicht van de vernieuwde stad](Screenshots/CitySecondPass/app-overview.jpg).

| Deel | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree | [Open](Screenshots/CitySecondPass/city-metro-entrance-iphone.png) | [Open](Screenshots/CitySecondPass/city-metro-entrance-ipad.png) |
| Bovenste wijken | [Open](Screenshots/CitySecondPass/city-metro-route-54-iphone.png) | [Open](Screenshots/CitySecondPass/city-metro-route-54-ipad.png) |
| Onderste wijken | [Open](Screenshots/CitySecondPass/city-metro-route-57-iphone.png) | [Open](Screenshots/CitySecondPass/city-metro-route-57-ipad.png) |
| Eindbaas en afgewerkte onderkant | [Open](Screenshots/CitySecondPass/city-metro-route-60-iphone.png) | [Open](Screenshots/CitySecondPass/city-metro-route-60-ipad.png) |

Native overzichtsrenders: [320](Screenshots/CitySecondPass/native-320.png), [393](Screenshots/CitySecondPass/native-393.png), [834](Screenshots/CitySecondPass/native-834.png) en [1194](Screenshots/CitySecondPass/native-1194.png) punten breed. Deze gebruiken eenvoudige genummerde routecirkels; de simulatorbeelden tonen de echte interface.

Het [afzonderlijke stadsdiff](WorldTestLogs/CitySecondPass/world-6.diff) bewaart de wijzigingen aan de stad. Gelijktijdige wijzigingen aan andere werelden en schermen zijn behouden.
