# Klokstad — gebouwen op stadsgrond

De drie bovenste gevelrijen staan met hun volledige fundering op de bestrating van wereld 6. Hun daken en bovenste geveldelen overlappen de grotgrond bij de stadsentree. De kristalgrot tekent geen complete stadsgebouwen meer boven de hoofdstukgrens.

De plaatsingscontrole gebruikt dezelfde grondcontour als de getekende straat. Lage winkels vullen de linkerkant voor de metro-inrit. Hun hoogte volgt de grens naar de grot en blijft boven de vrije ruimte rond de eerste levelsteen; op brede schermen loopt deze gevelrij verder door naar het midden.

De native geometriecontrole slaagt met **317.844 controles** op negen breedtes van 320 tot 1194 punten. De controle onderzoekt volledige funderingen op stadsgrond, vrije rails en stationsperrons, ruimte rond het eindbaasplein, complete gevels naast de speelroute, de eerste levelsteen en unieke gebouwidentiteiten. [Geometrieresultaten](WorldTestLogs/CityEntrancePlacement/geometry.log).

De overgang is visueel gecontroleerd op vier breedtes. De native beelden gebruiken genummerde levelcirkels; het appbeeld toont de echte interface.

- [320 punten](Screenshots/CityEntrancePlacement/join-5-320.png)
- [393 punten](Screenshots/CityEntrancePlacement/join-5-393.png)
- [834 punten](Screenshots/CityEntrancePlacement/join-5-834.png)
- [1194 punten](Screenshots/CityEntrancePlacement/join-5-1194.png)

De iOS-build en `testCityMetroRouteRemainsPlayable` slagen op iPhone 17 met iOS 26.5. Level 51 opent en start, de route langs levels 54 en 57 blijft bereikbaar en de eindbaas bij 60 opent. [Testresultaat](WorldTestLogs/CityEntrancePlacement/iphone.log) · [Stadsentree in de app](Screenshots/CityEntrancePlacement/city-metro-entrance-iphone.png). `git diff --check` is schoon.
