# Dino Stad — nieuwe bruggen, 15 oktober 2026

De boogbruggen draaiden als geheel met de raaklijn van de rivier mee. Daardoor stonden ook hun leuningen en stenen steunpunten schuin ten opzichte van de gebouwen.

De vier oversteken hebben nu een ander ontwerp: een vlak houten wandelbrugdek, rechte turquoise leuningen, messing paalkappen en afgeronde stenen landhoofden. De brugtekening wordt niet meer gedraaid. De overspanning wordt per brug berekend over het volledige rivierprofiel onder het brugdek en de steunpunten, zodat beide landhoofden buiten de waterkant staan. Het zijpad sluit op het daadwerkelijke bruguiteinde aan.

De oversteken staan iets dichter bij de rechte delen van de kanaalbochten. De oeverdetails houden rekening met die nieuwe locaties. Het dek is dieper getekend, met afzonderlijke planken, een lichte bovenkant, een smalle draagbalk en schaduw boven het water.

Alle wijzigingen van deze correctie staan binnen `CityWorldPainter`. De rivier, gebouwen, grotovergang, levelposities en overige werelden zijn bronmatig gelijk aan de versie bij aanvang van deze correctie.

## Beelden en controle

De vier bruggen en de volledige kaart zijn visueel gecontroleerd op 320, 393, 834 en 1194 punten breed. Deze overzichtsbeelden gebruiken eenvoudige levelmarkeringen voor de compositiecontrole.

[Alle bruggen op smal scherm](Screenshots/CityBridgeRefinement/all-bridges-320.png) · [Alle bruggen op iPad-breedte](Screenshots/CityBridgeRefinement/all-bridges-834.png).

De build en de bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` zijn geslaagd op iPhone 17 en iPad Pro 11-inch: vier schermtests, nul fouten. `git diff --check` is schoon.

De bruggen zijn aanvullend in de echte app bekeken bij level 55 en level 59.

| Echte app | iPhone | iPad |
| --- | --- | --- |
| Middelste stadsdeel | [Screenshot](Screenshots/CityBridgeRefinement/middle-iphone.png) | [Screenshot](Screenshots/CityBridgeRefinement/middle-ipad.png) |
| Onderste brug en robotplein | [Screenshot](Screenshots/CityBridgeRefinement/lower-iphone.png) | [Screenshot](Screenshots/CityBridgeRefinement/lower-ipad.png) |

[Buildlog](WorldTestLogs/CityBridgeRefinement/build.log) · [iPhone-tests](WorldTestLogs/CityBridgeRefinement/iphone.log) · [iPad-tests](WorldTestLogs/CityBridgeRefinement/ipad.log).
