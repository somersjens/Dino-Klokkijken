# Dino Stad — rivier en oevers, 15 oktober 2026

De stadsdecoratie volgde de afstand tot het levelpad. Daardoor stonden grote pleinen, haltes en kleine tegelvlakken gedeeltelijk op de kanalen. Zijpaden liepen bovendien zonder herkenbare brug door het water.

De rivier bepaalt nu de compositie. Vijf compactere stadsplekken staan achter de buitenkades. Hun volledige grondvlak wordt langs de bocht gecontroleerd. De oude losse tegelvlakken en losse watervallen midden in het kanaal zijn uit de stadsroute gehaald. De stadsvoorbeelden op de beloningskaarten behouden hun eigen compositie.

Beide oevers van beide kanalen hebben doorlopende, gebogen promenades met tegelvoegen en lichte dekstenen. Kleinere bankjes, plantenbakken, bloemen, lantaarns en aanlegpaaltjes staan op land naast de kades. Op bredere schermen komen er extra palmentuintjes bij. Een klein roeibootje ligt in het kanaal.

Het brugontwerp is daarna herzien naar vier vlakke houten wandelbruggen met rechte turquoise leuningen, messing paalkappen en stenen landhoofden. De bruggen blijven horizontaal en hun overspanning past zich aan de waterkant aan. Gebogen zijpaden verbinden de binnenkant met het centrale levelpad. Zie de [laatste brugverfijning](CityBridgeRefinement.md) voor de actuele beelden en controles. Losse oeverdetails houden afstand tot de oversteken. Grote gebouwen worden na de kleine oeverdetails getekend, zodat die details niet over daken heen verschijnen.

Het kanaal buigt vóór het robotplein vloeiend naar de zijkanten af. De klokrobot staat op een betegeld plein met een eigen toegangspad, plantenbak en bloemen. De turquoise ondergrond onder de robot is vervangen door zichtbaar steen.

## Controle

- `build-for-testing`: geslaagd.
- `testNativeWorldChaptersAndMinuteQuestions`: geslaagd op iPhone 17 en iPad Pro 11-inch.
- `testWorldBannersHaveBalancedClearance`: geslaagd op beide apparaten.
- Totaal vier schermtests, nul fouten. De bestaande tests controleren het openen van level 51, het beantwoorden van een klokvraag en de ruimte rond de wereldtitel.
- De volledige native Canvas-kaart is visueel gecontroleerd op 320, 393, 834 en 1194 punten breed. Deze kaartbeelden gebruiken eenvoudige levelmarkeringen voor de compositiecontrole.
- Aanvullende screenshots van de echte app tonen het midden bij level 55 en de onderste stad bij level 59, met afzonderlijke Debug-testopslag.
- De bestaande vulkaan- en grotpainters zijn bronmatig gelijk aan de versie bij aanvang van deze stadsverfijning. De laatste 390 punten van de grot boven de stadsgrens zijn op 393 punten breed ook pixelgelijk.
- `git diff --check`: schoon.

## Beelden

| Onderdeel | iPhone | iPad |
| --- | --- | --- |
| Middelste stadsdeel, echte app | [Screenshot](Screenshots/CityRiverPolish/middle-iphone.png) | [Screenshot](Screenshots/CityRiverPolish/middle-ipad.png) |
| Onderste stad en robotplein, echte app | [Screenshot](Screenshots/CityRiverPolish/lower-iphone.png) | [Screenshot](Screenshots/CityRiverPolish/lower-ipad.png) |
| Volledige kaart, compositiecontrole | [393 punten](Screenshots/CityRiverPolish/whole-map-393.png) | [834 punten](Screenshots/CityRiverPolish/whole-map-834.png) |
| Grot naar stad | [Kaartbeeld](Screenshots/CityRiverPolish/transition-5-6-393.png) | [Kaartbeeld](Screenshots/CityRiverPolish/transition-5-6-834.png) |
| Stad naar bos | [Kaartbeeld](Screenshots/CityRiverPolish/transition-6-7-393.png) | [Kaartbeeld](Screenshots/CityRiverPolish/transition-6-7-834.png) |

[Buildlog](WorldTestLogs/CityRiverPolish/build.log) · [iPhone-tests](WorldTestLogs/CityRiverPolish/iphone.log) · [iPad-tests](WorldTestLogs/CityRiverPolish/ipad.log).
