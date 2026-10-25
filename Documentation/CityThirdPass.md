# Wereld 6 — nieuwe metro en drukkere stad

Deze derde ontwerpronde verwerkt de feedback op de trein, de lege binnenrand en de transparante objecten bij de entree.

## Nieuwe metro

De platte, gedraaide wagon is vervangen door een rechtopstaand volume. De richting van het spoor bepaalt het onderstel en het dak, terwijl de hoogte van de carrosserie verticaal op het scherm blijft. Daardoor zijn zijwanden, deuren en passagiersramen zichtbaar wanneer de trein door een bocht rijdt.

De cabine heeft een groot gebogen voorraam, een bestemmingsbord met een gouden dinovoet, twee koplampen en een blauwe neus. De wagons hebben lichte raamomlijstingen, warme ramen, metalen dakribben, ventilatie, wielen en stroomafnemers met kleine vonken. De tekenvlakken zijn vergroot om de hoge carrosserie en stroomafnemers volledig te kunnen tonen. De perronoverkappingen staan hoger om bij de nieuwe trein te passen.

De eerdere lengte en beweging blijven behouden: **30 wagons, circa 932 tekenpunten lang en 132,5 tekenpunten per seconde**. De trein remt bij beide stations, stopt kort en vertrekt weer. De rails beginnen links buiten beeld en eindigen rechts buiten beeld.

Cabinedetails: [frontaal](Screenshots/CityThirdPass/cab-0.png), [schuin](Screenshots/CityThirdPass/cab-1.png) en [zijaanzicht](Screenshots/CityThirdPass/cab-2.png).

## Bewoonde binnenrand en laagvolgorde

Langs beide kanten van de levelstraat liggen nu **56 straatlocaties**. Ze wisselen woongevels met balkons, winkels met gestreepte luifels, een bloemenwinkel, caféterrassen, parasols, bomen en zitplekken af. Een doorlopende geplaveide binnenstraat verbindt deze locaties. Kleinere pleinen vullen daarnaast open hoeken buiten het spoor.

Grotere openbare gebouwen met zuilen, klokken, vlaggen en terrassen staan op de voorgrond waar de bocht daar ruimte voor geeft. Deze gebouwen en een deel van de binnengevels bedekken daadwerkelijk stukken van de rails en de bewegende trein. Voorgrondgevels worden na de stationsdaken getekend, zodat een overkapping niet door een voorgelegen gevel heen verschijnt. Binnen deze voorgrond bepaalt de positie op straat de tekenvolgorde.

De volledige contour van een gebouw wordt op afstand van de speelstraat geplaatst. Alleen bestrating gebruikt een gebogen straatmasker; gevels, daken en parasols blijven complete vormen. De levelstenen en bediening blijven bereikbaar.

## Entree zonder vervaging

De transparantie en uitfademaskers van de skyline, de zijgebouwen en de entree zijn verwijderd. Ook de wolken zijn volledig dekkend. De gebouwen bovenaan hebben nu een vaste, zichtbare onderkant en worden niet met de grond vermengd. Materiaalschaduw en lichtgloed blijven onderdeel van de illustratie.

## Verificatie

De [native geometriecontrole](WorldTestLogs/CityThirdPass/native-render.log) slaagt op negen breedtes van **320 tot 1194 punten**. Deze controle onderzoekt de speelstraat bij de binnenrand, de openbare voorgrondgebouwen en de extra pleintjes. Ook de bestaande controles op afstand tussen spoor en levels, snelheid, twee stationsstops en herhaling buiten beeld slagen.

Vaste animatiebeelden verschillen tussen de onderzochte tijdstippen. De beelden bij **Minder beweging** zijn identiek. De [beeldcontrole](WorldTestLogs/CityThirdPass/visual-checks.json) bevat afmetingen, bronhashes en de uitkomsten.

De definitieve app is gebouwd en `testCityMetroRouteRemainsPlayable` slaagt op **iPhone 17 en iPad Pro 11-inch M5**: twee geslaagde uitvoeringen zonder testfouten. De test opent level 51, controleert de route langs levels 54 en 57 en opent de eindbaas bij level 60. Bij level 54 zijn twee beelden met 2,5 seconden ertussen vastgelegd. Zie het [apparatenlog](WorldTestLogs/CityThirdPass/devices.log).

Entree, stadsroute, beweging, voorgrondlagen en onderkant zijn visueel bekeken in de echte appbeelden. `git diff --check` is schoon. Het [afzonderlijke stadsdiff](WorldTestLogs/CityThirdPass/world-6.diff) bevat alleen deze ontwerpronde; gelijktijdige wijzigingen aan andere werelden en schermen zijn behouden.

## Beelden

[Overzicht van de definitieve appbeelden](Screenshots/CityThirdPass/app-overview.jpg).

| Deel | iPhone | iPad |
| --- | --- | --- |
| Entree | [Open](Screenshots/CityThirdPass/city-metro-entrance-iphone.png) | [Open](Screenshots/CityThirdPass/city-metro-entrance-ipad.png) |
| Bovenste stadsdeel | [Open](Screenshots/CityThirdPass/city-metro-route-54-iphone.png) | [Open](Screenshots/CityThirdPass/city-metro-route-54-ipad.png) |
| Metro en onderste stadsdeel | [Open](Screenshots/CityThirdPass/city-metro-route-57-iphone.png) | [Open](Screenshots/CityThirdPass/city-metro-route-57-ipad.png) |
| Eindbaas en onderkant | [Open](Screenshots/CityThirdPass/city-metro-route-60-iphone.png) | [Open](Screenshots/CityThirdPass/city-metro-route-60-ipad.png) |

Native overzichtsrenders zijn beschikbaar op [320](Screenshots/CityThirdPass/native-320.png), [393](Screenshots/CityThirdPass/native-393.png), [834](Screenshots/CityThirdPass/native-834.png) en [1194](Screenshots/CityThirdPass/native-1194.png) punten breed. Die gebruiken eenvoudige genummerde routecirkels; de simulatorbeelden tonen de echte interface.
