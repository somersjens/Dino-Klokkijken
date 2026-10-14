# Wereld 1 — jungle verfijnd, 14 oktober 2026

## Analyse van het voorbeeld

Het aangeleverde beeld gebruikt drie duidelijke dieptelagen: een heldere lucht met wolken en verre rotswatervallen, een zonnige open plek rond het speelpad, en grote bomen en planten aan de voorrand. De bladeren hebben licht, schaduw, vouwen en nerven. De stammen hebben schors en verbonden takken; lianen maken de omlijsting organisch. De ronde levelstenen hebben een dikke rand, een lichte bovenkant en een grondschaduw. Onder Dino wordt de steen zachter en bleker.

In de bestaande eerste wereld waren de kruinen vooral grote vlakke vormen. De entree had weinig zichtbare wolken en de verre watervallen vielen weg door hun lage dekking. De ronde knoppen misten materiaalverschil tussen rand, zijkant en bovenkant. Vooral die punten zijn uitgewerkt. HUD, titelbord en spelregels vallen buiten deze verfijning.

## Uitwerking

- Een blauwere lucht met meerdere zachte wolkenbanken, warme zonnegloed, lichtbundels, verre heuvels en kleine vogels. De entree heeft 32 punten extra ruimte voor het uitzicht.
- Een hoge, zichtbare waterval rechts achter het titelbord, met een tweede verder gelegen waterval links. Beide hebben rotsvlakken, begroeiing op richels, waterstrepen, schuim, spatwater en rimpels in een poel. Ook de waterval langs het levelpad is vervangen.
- Samengestelde boomkruinen van losse gebogen bladeren, met kleurverlopen, vouwen, nerven en slagschaduw. Vertakte stammen hebben schorslijnen en lianen die om de boom hangen. Palmen, struiken, rotsen en lage oeverplanten volgen dezelfde afwerking.
- De junglestenen hebben een dikkere zijkant, een lichte buitenrand, een verdiepte binnenrand, kleine materiaalaccenten en een grondschaduw. Een bleke laag verzacht alleen de steen waarop Dino staat. Dino zelf blijft ondoorzichtig. Tikgebieden, levelposities, sterren en ontgrendeling blijven behouden.

De extra landschapstekening staat in `JungleWorldPainter`, die uitsluitend door `WorldMapLandscape` van wereld 1 wordt gebruikt. De bestaande gedeelde `JunglePainter`, de achtergrond van vragen, de HUD en de landschappen en levelstenen van wereld 2–10 zijn niet aangepast voor deze opdracht. Alle nieuwe illustraties zijn native SwiftUI/Canvas-paden; er zijn geen nieuwe bitmap-assets nodig.

## Gecontroleerde beelden

| Weergave | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree | [Screenshot](Screenshots/JungleRefinement/entrance-iphone.png) | [Screenshot](Screenshots/JungleRefinement/entrance-ipad.png) |
| Dino op vervaagde steen | [Screenshot](Screenshots/JungleRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/JungleRefinement/occupied-stone-ipad.png) |
| Middendeel met boom, palm en levelstenen | [Screenshot](Screenshots/JungleRefinement/middle-iphone.png) | — |

## Verificatie

De definitieve simulatorbuild is geslaagd: [buildlog](WorldTestLogs/JungleRefinement/build.log). De bestaande schermtests `testStartPointCleanCardAndExitCancel` en `testDinoStandsOnCompletedLevel` slagen op iPhone 17 en iPad Pro 11-inch met iOS 26.5: vier geslaagde uitvoeringen, nul fouten. Ze controleren onder meer het beginpunt, openen en spelen van een level, verlaten/hervatten en de positie van Dino op een behaalde levelsteen.

[iPhone-testlog](WorldTestLogs/JungleRefinement/iphone.log) · [iPad-testlog](WorldTestLogs/JungleRefinement/ipad.log).

Na de eerste iPhone-test zijn de bovenste waterval en de verre begroeiing beter geplaatst en de palmen verder uitgewerkt. De definitieve versie is op iPad getest en op iPhone opnieuw geopend met afzonderlijke Debug-testopslag; entree, bezette steen en middendeel zijn visueel gecontroleerd. Er is geen echte spelersvoortgang gewijzigd. `git diff --check` is schoon.
