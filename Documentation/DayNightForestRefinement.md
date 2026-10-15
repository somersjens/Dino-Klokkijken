# Wereld 7 — Dag-en-nachtbos verfijnd, 15 oktober 2026

## Analyse en richting

De bestaande kaart had een zachte kleurwisseling, kleine losse bomen en enkele klokjes. Het bestaande conceptbeeld laat een vol bos zien dat langs het pad van zonnige middag naar schemering en maanlicht overgaat. Bomen, watervallen, holle stammen, paddenstoelen en lantaarns geven die overgang vorm. Dat is vertaald naar native SwiftUI/Canvas-tekeningen.

De kleurwisseling volgt de positie op de kaart. Het bovenste deel heeft warme groene bladeren en zonlicht; verderop worden de stammen, bladeren, oevers en stenen koeler. De digitale tijden bij de analoge klokken ondersteunen de 12- en 24-uursklok. Het centrale zandpad en de bestaande levelposities blijven de basis.

## Uitwerking

- Een zonnige entree met zachte wolken, begroeide rotsplateaus, watervallen en grote bomen aan de randen. De verre formaties vervagen in de nevel. Boven de titel is 108 punten extra ruimte toegevoegd.
- Brede bomen met vertakte stammen, wortels, houtnerven, knoesten en meerdere lagen gebladerte. Afzonderlijke bladeren hebben kleurverloop, lichte middennerven en zijnerfjes. De kleuren veranderen geleidelijk van warm groen naar blauwgroen en maanlichtblauw.
- Een schemerzone met een warme gloed en verre bossilhouetten. Verderop verschijnen een maansikkel, kleine sterren, vuurvliegjes, hangende sterretjes en lantaarns met warme gloed.
- Holle boomstammen met schorslijnen en zichtbare binnenkant, rotsen met mos, varens, kleine bloemen en paddenstoelen met stippen en lichte stelen. In het nachtdeel krijgen de paddenstoelen meer gloed en koelere kleuren.
- Beekjes met kleurovergang en reflecties, watervallen met schuim en houten bruggen met afzonderlijke planken, palen en leuningen. Water en kruisingen liggen achter de grotere bosgroepen.
- Klokplekken met analoge wijzerplaten en digitale tijden **15:00**, **18:00** en **20:00**. De bijbehorende analoge klokken wijzen drie, zes en acht uur aan. Bomen staan achter de klokplekken, zodat de wijzerplaten en cijfers leesbaar blijven. De laatste klokplek staat verder naar binnen naast de bosuil. Lantaarns staan bij de klokplekken naast de digitale borden.
- Eigen levelstenen met een mossige rand en een lichte groene bovenkant. Verderop krijgen de stenen een koelere tint. Onder Dino verzacht een bleke laag de steen en verschijnt een lichte kring. Hoog contrast behoudt duidelijke cijfers en randen; tikgebieden en voetpositie blijven gelijk.

`DayNightForestPainter` geldt uitsluitend voor de kaart van wereld 7 en de wereld-7-preview op boss- en beloningskaarten. `DayNightLevelStone` geldt uitsluitend voor levels 61–70. De bronvergelijking controleert tegen de bestanden van vlak vóór deze opdracht, inclusief de eerder gemaakte stadsverfijning. Andere werelden en gedeelde illustratiecode buiten de wereld-7-preview blijven gelijk.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Zonnige entree en eerste level | [Screenshot](Screenshots/DayNightForestRefinement/entrance-iphone.png) | [Screenshot](Screenshots/DayNightForestRefinement/entrance-ipad.png) |
| Dagdelen spelen | [Screenshot](Screenshots/DayNightForestRefinement/day-part-question-iphone.png) | [Screenshot](Screenshots/DayNightForestRefinement/day-part-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/DayNightForestRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/DayNightForestRefinement/occupied-stone-ipad.png) |
| Schemerovergang | [Screenshot](Screenshots/DayNightForestRefinement/twilight-iphone.png) | [Screenshot](Screenshots/DayNightForestRefinement/twilight-ipad.png) |
| Maanlicht en bosuil | [Screenshot](Screenshots/DayNightForestRefinement/night-forest-iphone.png) | [Screenshot](Screenshots/DayNightForestRefinement/night-forest-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 7 uitgevoerd met `DINO_TEST_WORLD_IDS=7`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 61, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 61 volledig en controleert Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

[Definitieve build](WorldTestLogs/DayNightForestRefinement/verified-build.log) · [Definitieve iPhone-controle](WorldTestLogs/DayNightForestRefinement/verified-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/DayNightForestRefinement/verified-ipad.log) · [Bronvergelijking](WorldTestLogs/DayNightForestRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De zonnige entree, de behaalde levelsteen, de dagdeelvraag, de schemerovergang en het nachtelijke bos zijn visueel gecontroleerd op iPhone en iPad. De tijd 20:00 is volledig zichtbaar naast de bosuil. `git diff --check` is schoon.

De eerste plaatsingstest stopte in de bestaande testhelper, die uitsluitend naar tijdantwoorden in `options` zocht. Dagdeelvragen gebruiken andere antwoordkeuzes. De helper kiest nu uit `responses` op basis van `expectedAnswer`, net als de hoofdstuktest, en meldt een ontbrekend antwoord met een testfout in plaats van een crash. De spelvragen en antwoordcontrole van de app zijn gelijk gebleven. De eerste logs zijn bewaard: [iPhone](WorldTestLogs/DayNightForestRefinement/iphone.log) en [iPad](WorldTestLogs/DayNightForestRefinement/ipad.log).

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang wordt niet gewijzigd.
