# Wereld 6 — verdiept spoor en vloeiende metrobochten

Het vorige tunneltje was een gewelf over de bestaande spoorhoogte. Het spoor daalt nu af in uitgegraven aanlopen en loopt onder het stadsplateau door. De rijtuigen volgen tegelijk een doorlopende, vloeiende spoorgeometrie.

[Bewegende voorvertoning](Screenshots/CityFifthPass/metro-underground-motion.gif) · [Vijf posities van de passage](Screenshots/CityFifthPass/underground-sequence.jpg) · [Definitieve appbeelden](Screenshots/CityFifthPass/app-overview.jpg).

## Ondergronds

De inrit en uitrit hebben een lagere spoorvloer, verticale keerwanden, donkere ballast en dekstenen op de hoogte van de straat. De vloer zakt geleidelijk tot 58 schaalpunten onder het maaiveld. De rijtuigen en hun wielstellen dalen mee; in de verdiepte bak krijgen ze ook minder daglicht.

De twee tunnelmonden zijn ingebouwd in keerwanden aan de zijkanten van het plateau. Het vroegere zichtbare dak over de onderste lus is verwijderd. De lus loopt onder de ononderbroken levelstraat door, met gewone grond erboven. Rijtuigen, koppelingen, rails en vonken worden in het ondergrondse deel verborgen. Aan de andere kant komt de trein uit de tunnel en klimt hij terug naar straatniveau.

De reservering voor gebouwen en terrasvloeren houdt ook rekening met de lagere spoorvloer en de uitgraving. De bestaande bebouwing en het robotplein blijven naast het spoor geplaatst.

## Vloeiende rijtuigen

De oorspronkelijke route had op enkele aansluitingen een plotselinge verandering van richting. Bovendien gebruikte elk rijtuig de richting van één kort recht spoorsegment.

De nieuwe route wordt op afstand bemonsterd en afgerond. Doorlopende kubische curves verbinden de punten met dezelfde raaklijn aan beide kanten van elke aansluiting. De richting van een rijtuig komt uit de positie van zijn voorste en achterste wielstel. Daardoor draait het geleidelijk en volgt het ook de helling van de verdiepte aanloop.

Balgen verbinden de uiteinden van aangrenzende rijtuigen en vullen de openingen bij de bochten. De animatie gebruikt een richtfrequentie van 60 beelden per seconde, tegenover 24. De bestaande pauze buiten beeld, bij een inactieve app en bij **Minder beweging** blijft gelden.

De trein houdt dertig wagons, circa 932 tekenpunten lengte en een kruissnelheid van 132,5 schaalpunten per seconde. De twee stationsstops en de in- en uitrit buiten beeld blijven werken.

## Verificatie

De [native controle](WorldTestLogs/CityFifthPass/native-render.log) slaagt op negen schermbreedtes van 320 tot 1194 punten. De oude route toont richtingknikken van circa 21–37 graden op sommige segmentovergangen. Bij de nieuwe wagonrichting blijft de gemeten verandering over een interval van 0,02 schaalpunt overal kleiner dan 0,022 graden. De nieuwe raaklijnen lopen door; er is geen sprong naar de richting van het volgende rechte segment.

Dezelfde controle onderzoekt de afdalingshoogte, het volledig verbergen van de rijtuigen en vonken onder de grond, de funderingen naast het spoor, de afstand tot de levels, de snelheid, beide stops en de herhaling buiten beeld. De vaste beelden bij **Minder beweging** zijn pixelgelijk op twee tijdstippen.

De bewegende voorvertoning bevat 121 opeenvolgende beelden op 30 beelden per seconde, getekend met dezelfde rijtuigposities, koppelingen, schaduw en ondergrondse uitsnede als de app. Die native compositie gebruikt eenvoudige genummerde routecirkels. De afzonderlijke simulatorbeelden tonen de echte interface. [Bronhashes en beeldcontrole](WorldTestLogs/CityFifthPass/visual-checks.json).

De definitieve app is gebouwd. `testCityMetroRouteRemainsPlayable` slaagt op **iPhone 17 en iPad Pro 11-inch M5**: twee geslaagde uitvoeringen zonder testfouten. Level 51 en de eindbaas openen, de route wordt langs levels 54 en 57 gecontroleerd en de onderkant krijgt een extra bewegingsopname. De verdiepte doorgang, tunnelmonden en bebouwing zijn in de echte app visueel bekeken. [Apparatenlog](WorldTestLogs/CityFifthPass/devices.log).

`git diff --check` is schoon. Het [stadsdiff](WorldTestLogs/CityFifthPass/world-6.diff) bevat de wijzigingen in de stadsregio. Gelijktijdige wijzigingen aan andere schermen zijn behouden.
