# Wereld 6 — Dino Stad verfijnd, 15 oktober 2026

Laatste uitwerking: [rivier en oevers](CityRiverRefinement.md) en [nieuw horizontaal brugontwerp](CityBridgeRefinement.md).

## Analyse en richting

De bestaande kaart had een vrijwel egale blauwe ondergrond, kleine losse gebouwen en enkele straatobjecten. Het bestaande conceptbeeld toont een zonnige stad met crème gevels, turquoise koepels, kanalen, palmentuinen en een gele tram. Die samenhang is uitgewerkt met native SwiftUI/Canvas-paden.

Het centrale zandpad, de levelposities en de bestaande schermindeling blijven de basis. De grote gebouwen en tramhaltes staan aan de buitenkant van de bochten. Bestrate zijpaden verbinden de route met de pleinen; langs de tegenoverliggende rand staan kleinere tuinen, bankjes en lantaarns.

## Uitwerking

- Een zonnige entree met zachte wolken, verre stadsgebouwen op rotsplateaus, een brug en watervallen. De verre skyline vervaagt in de nevel. Een koepeltoren boven de titel vormt een herkenningspunt. Boven het titelbord is 108 punten extra ruimte toegevoegd.
- Crèmekleurige gevels met lichte bovenvlakken, schaduwkanten, steenvoegen en brede koepeldaken. De koepels hebben gebogen naden, kleurverloop, glans en een warme metalen rand. De ramen hebben kruisroeden, gekleurd glas, reflecties en stenen dorpels.
- Balkons met leuningen, planten en bloemen, turquoise deuren met koperen knoppen, traptreden en kleine cafés met gestreepte luifels.
- Tramhaltes met een gebogen turquoise overkapping en digitale klok **08:05**. De gele tram heeft ramen, deuren, wielen, koplamp, bovenbeugel en rails. De haltes staan iets naar binnen ten opzichte van de overige randdecoratie, zodat de voorkant van de tram zichtbaar blijft. Kloktorens tonen **10:30** op een analoge en digitale klok; bij fonteinen staat **12:45** op een eigen bord.
- Kanalen met lichte kades, waterreflecties, watervallen en schuim. Stenen boogbruggen hebben een open doorgang, voegen, palen en leuningen.
- Pleinen met afzonderlijke tegels, palmen met stamringen en geaderde bladeren, gemetselde plantenbakken, bloemperken, houten bankjes en straatlantaarns met warme gloed en vaandels. Water, bestrating en bruggen liggen achter de gebouwen en klokborden.
- Eigen levelstenen met een turquoise metalen rand, messing klinknagels en een lichte groene bovenkant. De steen onder Dino krijgt een bleke laag en een rustige lichtkring. Hoog contrast houdt de cijfers en randen duidelijk; tikgebieden en voetpositie blijven gelijk.

`CityWorldPainter` geldt uitsluitend voor de kaart van wereld 6 en de wereld-6-preview op boss- en beloningskaarten. `CityLevelStone` geldt uitsluitend voor levels 51–60. De bronvergelijking controleert de bestaande illustraties en schermcode tegenover de bestanden van vlak vóór deze opdracht. Andere werelden en gedeelde illustratiecode buiten de wereld-6-preview blijven gelijk.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/CityRefinement/entrance-iphone.png) | [Screenshot](Screenshots/CityRefinement/entrance-ipad.png) |
| Digitale klok spelen | [Screenshot](Screenshots/CityRefinement/digital-question-iphone.png) | [Screenshot](Screenshots/CityRefinement/digital-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/CityRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/CityRefinement/occupied-stone-ipad.png) |
| Onderste stadsdeel en boss | [Screenshot](Screenshots/CityRefinement/lower-city-iphone.png) | [Screenshot](Screenshots/CityRefinement/lower-city-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 6 uitgevoerd met `DINO_TEST_WORLD_IDS=6`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 51, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 51 volledig en controleert Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

[Definitieve build](WorldTestLogs/CityRefinement/final-build.log) · [Definitieve iPhone-controle](WorldTestLogs/CityRefinement/final-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/CityRefinement/final-ipad.log) · [Bronvergelijking](WorldTestLogs/CityRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De entree, de behaalde levelsteen, de digitale-klokvraag en het onderste stadsdeel zijn visueel gecontroleerd op iPhone en iPad. De voorkant van de tram en de digitale klokken blijven zichtbaar. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang wordt niet gewijzigd.
