# Wereld 5 — Kristalgrot verfijnd, 14 oktober 2026

## Analyse en richting

De bestaande kaart had een lichte blauwe ondergrond, losse kristallen en eenvoudige rotsgroepen. Het bestaande conceptbeeld toont juist een omsloten grot: een rotsgewelf, licht door een opening, watervallen, gelaagde stenen oevers en kristallen die hun omgeving verlichten. Dat beeld is vertaald naar native SwiftUI/Canvas-paden.

Het zandpad, de levelposities en de bestaande schermindeling blijven de basis. Het grootste detail staat langs de buitenkant van de bochten. Het midden blijft helder genoeg voor levels 41–50 en Dino.

## Uitwerking

- Een grotgewelf met ongelijke rotsvlakken, stalactieten en hangende kristallen. Het midden heeft een heldere opening, zachte transparante lichtbanen, verre rotsformaties, watervallen en kleine lichtdeeltjes. De watervallen zijn boven het titelbord geplaatst en de bovenrand van het gewelf loopt geleidelijk over uit de vorige wereld. De verre formaties vervagen in de nevel. Boven de titel is 118 punten extra ruimte toegevoegd.
- Doorlopende gelaagde rotswanden langs de randen, met steenbreuken, schaduwkanten en lichte bovenvlakken. Beekjes, watervallen en schuim verbinden de stenen terrassen; kleine stenen bruggen hebben voegen, palen en kristallen op de uiteinden.
- Kristallen in cyaan, amethist en zachtroze. De afzonderlijke vlakken hebben kleurverloop, doorsnijdende facetten, scherpe lichtranden, glasreflecties en een rustige gloed op de ondergrond. Grote groepen wisselen af met kleine scherven en hangende exemplaren.
- Geodes met een donkere binnenkant en kleine kristallen, warme lantaarns, groene planten en kleine paarse bloemen. Water en randdecoratie staan achter de grotere bestemmingen.
- Digitale klokstenen tonen **02:17** en **08:43**, passend bij exacte minuten. De schermpjes liggen voor de omringende kristalgroepen; de cijfers blijven leesbaar.
- Een rotsboog met kristallen vormt de achtergrond van de bestaande grotbaas.
- Eigen levelstenen met een koele mineraalrand, kleine kristalfacetten en een lichte mintgroene bovenkant. De steen onder Dino krijgt een bleke laag en een rustige lichtkring. Hoog contrast behoudt duidelijke cijfers en randen; tikgebieden en voetpositie blijven gelijk.

`CrystalCavePainter` geldt uitsluitend voor de kaart van wereld 5 en de wereld-5-preview op boss- en beloningskaarten. `CrystalLevelStone` geldt uitsluitend voor levels 41–50. De bronvergelijking vergelijkt de illustraties met de bestanden van vlak vóór deze opdracht. Tijdens het werk zijn in de gedeelde checkout ook onafhankelijke aanpassingen aan Dino’s vrije ruimte en de titelgrootte bij liggend gebruik binnengekomen. Die bestaande schermwerkzaamheden zijn behouden; het bronlog benoemt ze afzonderlijk. Andere landschap-painters, levelstenen en gedeelde scenecode buiten de wereld-5-preview blijven gelijk.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/CrystalCaveRefinement/entrance-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/entrance-ipad.png) |
| Exacte minuten spelen | [Screenshot](Screenshots/CrystalCaveRefinement/exact-minute-question-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/exact-minute-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/CrystalCaveRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/occupied-stone-ipad.png) |
| Onderste grotdeel en boss | [Screenshot](Screenshots/CrystalCaveRefinement/lower-cave-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/lower-cave-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 5 uitgevoerd met `DINO_TEST_WORLD_IDS=5`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 41, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 41 volledig en controleert Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

[Definitieve build](WorldTestLogs/CrystalCaveRefinement/final-build.log) · [Definitieve iPhone-controle](WorldTestLogs/CrystalCaveRefinement/final-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/CrystalCaveRefinement/final-ipad.log) · [Bronvergelijking](WorldTestLogs/CrystalCaveRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De entree, de behaalde levelsteen, de exacte-minutenvraag en het onderste grotdeel zijn visueel gecontroleerd op iPhone en iPad. De digitale klokstenen zijn leesbaar en de rotsboog bedekt de grotbaas niet. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang wordt niet gewijzigd.

## Doorlopende grot en vloeiende wereldgrenzen — 15 oktober 2026

De grotwanden beginnen in de laatste bocht van Dino Dorp, lopen door achter de Kristalgrot-banner en wijken pas voorbij de Dino Stad-banner weer naar de zijkanten. De brede luchtstroken tussen deze werelden zijn verwijderd. Elke kaart tekent zijn deel van dezelfde doorgang; positie, materiaal en raaklijn sluiten aan op de wereldgrens. Horizontale materiaalverlopen houden de rotskleur daar gelijk. De grot verdwijnt niet via een transparante laag.

De rivieroevers bij het dorp en de stad gebruiken ruime Bézierbochten. De instroom sluit aan op de verticale raaklijn bij het eerste level; de uitstroom begint bij de verticale raaklijn van het voorlaatste level. Zo schiet de oever niet voorbij zijn aansluiting om vervolgens scherp terug te draaien. Kleine stadsplateaus beginnen na de grotuitgang, zodat ze niet los boven een afgedekte rivier verschijnen.

Rotslagen, overhangende richels en vastgegroeide stalactieten omsluiten het pad. Hangende kristallen zitten met hun voet achter een rotslip. Zes grotere bestemmingen delen een richel: twee asymmetrische kristalgroepen, twee klokstenen, een geode en een waterval met aangesloten poel en boogbrug. De kristallen hebben verschillende groeirichtingen, doorschijnende facetten, reflectiebanden en kleine lichtaccenten. De klokgroepen staan bij ruimere bochten en tonen **02:17** en **08:43**.

De complete grot en de overgangen **4 → 5** en **5 → 6** zijn visueel gecontroleerd op breedtes van 320, 393, 834 en 1194 punten. De rivierbochten zijn daarnaast afzonderlijk zonder grotwanden bekeken. De simulatorbuild slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` controleren met `DINO_TEST_WORLD_IDS=5,6` de levels, speelvragen en bannerruimte op iPhone 17 en iPad Pro 11-inch: **vier geslaagde testuitvoeringen, nul fouten**. `git diff --check` is schoon.

Actuele appbeelden: [ingang iPhone](Screenshots/CrystalContinuity/entrance-iphone.png), [ingang iPad](Screenshots/CrystalContinuity/entrance-ipad.png), [uitgang iPhone](Screenshots/CrystalContinuity/exit-iphone.png) en [uitgang iPad](Screenshots/CrystalContinuity/exit-ipad.png). De eerdere afwerking van Vulkaanland en de kristalgroepen, klokken en grotbaas zijn behouden.
