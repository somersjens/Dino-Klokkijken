# Wereld 4 — Dino Dorp verfijnd, 14 oktober 2026

## Analyse en richting

De bestaande kaart bestond uit een vlakke groene ondergrond, kleine losse huisjes en eenvoudige boom- en fonteingroepen. Het bestaande conceptbeeld laat een samenhangend, zonnig dorp zien: een herkenbare klokkentoren boven de entree, huizen met warme gevels, tuinen, marktstalletjes en stromend water tussen stenen oevers. Die ruimtelijke opbouw is vertaald naar native SwiftUI/Canvas-tekeningen.

De kaart behoudt het centrale zandpad, de bestaande bochten en de posities van levels 31–40. De grotere dorpsgroepen staan aan de buitenkant van de bochten. Kleine zijpaden verbinden het speelpad met de huisjes en pleintjes.

## Uitwerking

- Een heldere blauwe lucht met warme zonnegloed, zachte wolken en kleine vogels. Gelaagde begroeide rotsen met watervallen vormen de verte. Boven de titel is 108 punten extra ruimte vrijgemaakt voor de klokkentoren.
- Een klokkentoren met gepleisterde gevel, bladendak, vlag, ramen en stenen treden. De klok toont **10:10**, passend bij stappen van vijf minuten.
- Ronde huisjes met warme gevelschaduwen, steenaccenten, dakpannen met afzonderlijke voegen of geaderde bladendaken. De bladendaken hangen over de gevels. Houten deuren hebben planken, scharnieren en een knop; ramen hebben kruisroeden, glasreflecties en een zachte lichtgloed.
- Afwisselende dorpsgroepen met fruitkraampjes onder blauw-witte of geel-witte luifels, een stenen fontein met waterstralen en een watermolen met spaken en houten schoepen.
- Fruitbomen met gelaagde kronen, houten hekjes, bloementuinen, kleine planten, kasseien en rotsen. Beekjes hebben stenen oevers, watervallen, schuim en bruggetjes met afzonderlijke planken en leuningen. Water, bruggen en verspreide gras- en bloemgroepjes liggen achter de gebouwen, zodat ze geen daken, ramen of wijzerplaten afdekken. De grotere bruggen staan tussen de dorpsgroepen.
- Eigen levelstenen met een zandstenen rand, voegen en een groene bovenkant. Onder Dino verzacht een bleke laag de steen en verschijnt een lichte kring. Hoog contrast houdt cijfers en randen duidelijk; tikgebieden en Dino's voetpositie blijven gelijk.

`VillageWorldPainter` wordt uitsluitend gebruikt voor de kaart van wereld 4 en de wereld-4-preview op boss- en beloningskaarten. `VillageLevelStone` geldt uitsluitend voor levels 31–40. De bronvergelijking bevestigt dat de bestaande jungle-, Slaapvallei- en vulkaantekeningen gelijk zijn gebleven. Gedeelde illustraties buiten de wereld-4-preview zijn eveneens ongewijzigd.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/VillageRefinement/entrance-iphone.png) | [Screenshot](Screenshots/VillageRefinement/entrance-ipad.png) |
| Stappen van vijf minuten spelen | [Screenshot](Screenshots/VillageRefinement/five-minute-question-iphone.png) | [Screenshot](Screenshots/VillageRefinement/five-minute-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/VillageRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/VillageRefinement/occupied-stone-ipad.png) |
| Onderste dorpsdeel en boss | [Screenshot](Screenshots/VillageRefinement/lower-village-iphone.png) | [Screenshot](Screenshots/VillageRefinement/lower-village-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 4 uitgevoerd met `DINO_TEST_WORLD_IDS=4`. De hoofdstuktest opent level 31, controleert de ontgrendeling en het tikgebied, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 31 volledig en controleert de positie van Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

[Definitieve build](WorldTestLogs/VillageRefinement/verified-build.log) · [Definitieve iPhone-controle](WorldTestLogs/VillageRefinement/verified-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/VillageRefinement/verified-ipad.log) · [Bronvergelijking](WorldTestLogs/VillageRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De actuele entree, de behaalde levelsteen en het onderste dorpsdeel zijn visueel gecontroleerd. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang wordt niet gewijzigd.
