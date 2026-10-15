# Wereld 3 — Vulkaanland verfijnd, 14 oktober 2026

## Analyse en richting

De bestaande kaart had een vrijwel egale oranje ondergrond, kleine losse vulkanen en enkele rotsgroepen. In het bestaande conceptbeeld ontstaat de wereld juist uit een warme avondlucht, een grote vulkaan in de verte, gelaagde basaltwanden en lavavallen langs het pad. Die ruimtelijke opbouw is uitgewerkt met native SwiftUI/Canvas-paden.

De entree heeft een duidelijk herkenbare vulkaantop boven het titelbord. Verderop wisselen basaltterrassen, lavapoelen, klokrotsen, palmen en kleine planten elkaar af. Het centrale zandpad behoudt zijn bestaande schaal, doorlopende route en levelposities.

## Uitwerking

- Een lucht met warme zonnegloed, zachte wolken, mauve avondtinten, verre rotsformaties en lichte stoom. Boven het titelbord is 88 punten extra ruimte vrijgemaakt voor de vulkaantop.
- Een grote samengestelde vulkaan met meerdere rotsvlakken, breuklijnen, een verlichte krater, vertakkende lavastromen en een zachte pluim. De berg heeft een doorlopende voet; de lichtere steenlagen sluiten daarop aan.
- De vulkaanvoet loopt met een zachte transparantie over in de nevel. Verre basaltformaties blijven links en in het midden, zodat ze niet als losse poten onder de berg uitsteken.
- Vier grotere lavaterrassen langs het speelpad. Ze hebben ongelijke basaltzuilen, warme bovenvlakken, donkere schaduwkanten, een aanvoer over de bovenste richel, gelaagde lavavallen, poelen en kleine stoomwolken.
- Gefacetteerde rotsen, amberkleurige mineralen, palmen met stamringen en geaderde bladeren, plus kleine groepen groene en koperkleurige planten. Een stenen oeverbrug heeft afzonderlijke voegen, palen en een leuning.
- Klokjes in stenen behuizingen tonen **04:15** en **04:45**, passend bij kwartieren. De klokgroepen staan vóór de palmen, zodat bladeren de cijfers niet afdekken.
- De levelstenen hebben een gelaagde basaltzijkant, warme randaccenten en een lichte groene bovenkant. De steen onder Dino krijgt een zachte bleke laag en een rustige lichtkring. Hoog contrast houdt de cijfers en randen duidelijk. Tikgebieden, sterren en ontgrendeling zijn behouden.

`VolcanoWorldPainter` wordt uitsluitend gebruikt voor de kaart van wereld 3 en de wereld-3-preview op boss- en beloningskaarten. `VolcanoLevelStone` geldt uitsluitend voor levels 21–30. De landschapstekening van wereld 1 en 2 is bij vergelijking met de bron van vóór deze opdracht gelijk gebleven. Wereld 4–10 gebruiken hun bestaande uitvoering.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/VolcanoRefinement/entrance-iphone.png) | [Screenshot](Screenshots/VolcanoRefinement/entrance-ipad.png) |
| Kwartieren spelen | [Screenshot](Screenshots/VolcanoRefinement/quarter-hour-question-iphone.png) | [Screenshot](Screenshots/VolcanoRefinement/quarter-hour-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/VolcanoRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/VolcanoRefinement/occupied-stone-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 3 uitgevoerd met `DINO_TEST_WORLD_IDS=3`. De hoofdstuktest opent level 21, controleert de ontgrendeling en het tikgebied, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 21 volledig en controleert de positie van Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

De eerste vier testuitvoeringen op iPhone en iPad zijn geslaagd. Tijdens de visuele controle zijn vervolgens de doorlopende vulkaanvoet, de verbinding van de verre rotsen met het landschap en de laagvolgorde van de klokjes afgewerkt.

[Definitieve build](WorldTestLogs/VolcanoRefinement/final-build.log) · [Definitieve iPhone-controle](WorldTestLogs/VolcanoRefinement/final-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/VolcanoRefinement/final-ipad.log).

Ook de definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De screenshots tonen de actuele build en zijn visueel gecontroleerd. Een vergelijking van de bestaande jungle- en Slaapvallei-painters en de gedeelde scenecode buiten de wereld-3-preview bevestigt dat die inhoud gelijk is gebleven. `git diff --check` is schoon.

Bij een eerdere herhaling stopte de iPhone-testomgeving vóór de testverbinding met een signal kill en een timeout bij het verzamelen van diagnostiek. Die omgevingsfout is bewaard in [het opstartlog](WorldTestLogs/VolcanoRefinement/iphone-startup-timeout.log). De hercontrole op een aparte tijdelijke iPhone 17-simulator met iOS 26.5 slaagt met twee tests en nul fouten. De actuele iPhone-beelden zijn daarna bijgewerkt en de tijdelijke simulator is opgeruimd. De [bronvergelijking](WorldTestLogs/VolcanoRefinement/scope-check.log) bevestigt de afbakening tot wereld 3.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang is niet gewijzigd.

## Verdere afwerking — 15 oktober 2026

De basaltzuilen en losse rotsen hebben afgeronde contouren en gedeelde, onregelmatige voeten. De rotsfacetten worden binnen het silhouet getekend. Ook de basaltornamenten van het wereldbord hebben zachtere hoeken en gebogen lavanaden die achter de voet doorlopen.

De vier lavavallen beginnen in een bron op de hoogste rots en waaieren onderaan uit in een aangesloten poel. De poelen hebben golvende oevers, een stenen rand, warme reflecties en zachte grondschaduwen. De zijstromen op de grote vulkaan lopen spits uit in de rots; de hoofdgeul eindigt in een poel. De afgeronde vulkaan staat zichtbaar naast de eerste bocht en verdwijnt aan de voet geleidelijk in de nevel. De verre, losstaande zuilen zijn vervangen door lage verbonden rotsruggen.

De grotere scènes staan verder uit elkaar. Losse decorrotsjes en verspreide grassprietjes die voor een lavabron konden vallen zijn verwijderd. De kwartierklokken zijn in stenen behuizingen geplaatst; de planten en palmen hebben contactschaduwen. De zijbrug heeft een echte boog met een doorlopende lavageul en kleine poelen aan beide oevers.

De hele landschapstekening is visueel gecontroleerd op breedtes van 320, 393, 834 en 1194 punten. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` zijn met `DINO_TEST_WORLD_IDS=3` uitgevoerd op iPhone 17 en iPad Pro 11-inch: vier geslaagde testuitvoeringen en nul fouten. De definitieve simulatorbuild en `git diff --check` slagen.

Actuele appbeelden: [iPhone](Screenshots/VolcanoPolish/entrance-iphone.png) · [iPad](Screenshots/VolcanoPolish/entrance-ipad.png). De native kaart- en spelcode buiten de wereld-3-tekening en zijn basaltornamenten is gelijk gebleven.
