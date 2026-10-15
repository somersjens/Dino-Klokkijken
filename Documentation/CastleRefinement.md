# Wereld 10 — Dinokasteel verfijnd, 15 oktober 2026

## Analyse en richting

De bestaande kaart had een zachte beige ondergrond en losse, eenvoudige kloktorens. Het bestaande [conceptbeeld](WorldConcepts/world-10-map.png) toont een koninklijke omgeving met blauwe daken, gouden accenten, begroeide kasteelmuren, waterlopen, bruggen en bloementuinen. Die richting is uitgewerkt met native SwiftUI/Canvas-tekeningen, passend bij de eerder verfijnde werelden.

Het Dinokasteel combineert alle vaardigheden en eindigt bij Koning Chronos. Daarom krijgen de kloktorens analoge én digitale tijden, terwijl een zandloperpaviljoen, kristallen, fonteinen en een grote poort de laatste etappe afwisselend maken. De centrale route, levelposities en bediening blijven de basis.

## Uitwerking

- Een entree met zonlicht, zachte wolken, verre kastelen op rotsplateaus, watervallen en cipressen. De verre gebouwen vervagen in de nevel. Een groter kasteel naast het pad, een kloktoren, een waterval en bloembakken omlijsten de titel. De titel heeft 138 punten extra bovenruimte.
- Torens met gelaagd metselwerk, lichte voegen, gewelfde vensters, een blauwe deur en klimop. Blauwe puntdaken hebben afzonderlijke dakpannen, gouden dakranden, kleine sierbollen en windvanen.
- Blauwe vaandels met gouden randen en kroontjes. Kloktorens tonen **10:25** en **16:40**, met passende analoge wijzers en digitale schermen. De klok boven de grote poort wijst **12:00** aan.
- Waterlopen met zachte overgangen bij de entree en het einde, kleurverloop, lichte oevers en reflecties. Watervallen hebben afzonderlijke waterbanen en schuim onderaan.
- Stenen bruggen met een open boogdoorgang, bestrating, palen, gouden sierbollen en bloembakken. De brugopening is binnen het buitenvlak uitgesneden, zodat alleen de echte brugmassa zichtbaar is.
- Tuinplekken met cipressen, klimop, afzonderlijke bladeren, kleine witte en roze bloemen en stenen plantenbakken. Blauwe kristallen en warme vuurkommen geven extra kleur aan de randen.
- Fonteinen met meerdere schalen, waterbogen en rimpelingen in het bassin. Het paviljoen heeft een blauwe koepel met gouden ribben, vier zuilen en een glazen zandloper met zand en reflecties.
- Een koninklijke poort vlak voor Koning Chronos, met twee torens, een gouden dubbele deur, treden, bloemen, vuurkommen en een klok boven de ingang. Deze scène staat verder naar binnen en iets hoger om de koning en het laatste level ruimte te geven.
- Eigen levelstenen voor levels 91–100 met lichte stenen randen, gouden banden en blauwe sierstenen. Onder Dino verzacht een bleke laag het midden en verschijnt een lichte kring. Hoog contrast behoudt duidelijke randen en cijfers; tikgebieden en voetpositie blijven gelijk.

`CastleWorldPainter` geldt alleen voor de kaart en de wereld-10-preview op boss- en beloningskaarten. `CastleLevelStone` geldt alleen voor levels 91–100. De extra entreeruimte geldt alleen voor wereld 10. De bestaande tekeningen en levelstenen van wereld 1–9 blijven gelijk.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/CastleRefinement/entrance-iphone.png) | [Screenshot](Screenshots/CastleRefinement/entrance-ipad.png) |
| Alle vaardigheden spelen | [Screenshot](Screenshots/CastleRefinement/question-iphone.png) | [Screenshot](Screenshots/CastleRefinement/question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/CastleRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/CastleRefinement/occupied-stone-ipad.png) |
| Poort en Koning Chronos | [Screenshot](Screenshots/CastleRefinement/royal-gate-iphone.png) | [Screenshot](Screenshots/CastleRefinement/royal-gate-ipad.png) |
| Afsluiting na level 100 | [Screenshot](Screenshots/CastleRefinement/after-hundred-iphone.png) | [Screenshot](Screenshots/CastleRefinement/after-hundred-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions`, `testDinoStandsOnCompletedLevel` en `testComingSoonOnlyAfterLevelHundred` zijn gericht op wereld 10 uitgevoerd met `DINO_TEST_WORLD_IDS=10`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 91, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 91 volledig en controleert Dino’s voeten op de behaalde steen. De afsluitingstest controleert dat na level 100 geen level 101 verschijnt en dat het bestaande “Coming soon”-blok onder het laatste level staat. Alle controles gebruiken afzonderlijke Debug-testopslag. De bestaande tests, spelvragen en antwoordcontrole zijn niet aangepast voor deze verfijning.

[Definitieve build](WorldTestLogs/CastleRefinement/verified-build.log) · [iPhone-controle](WorldTestLogs/CastleRefinement/verified-iphone.log) · [iPad-controle](WorldTestLogs/CastleRefinement/verified-ipad.log) · [Bronvergelijking](WorldTestLogs/CastleRefinement/scope-check.log).

De definitieve versie slaagt met drie tests per apparaat: **zes geslaagde schermtestuitvoeringen, nul fouten**. De entree, eerste vraag, behaalde levelsteen, koninklijke poort en afsluiting na level 100 zijn visueel gecontroleerd op iPhone en iPad. De toren en waterval links bij de entree staan verder uit elkaar, zodat het digitale bord volledig **10:25** toont.

De eerste controles waren eveneens succesvol. De [eerste build](WorldTestLogs/CastleRefinement/build.log), [build met uitgesneden brugdoorgang](WorldTestLogs/CastleRefinement/bridge-build.log), [eerste iPhone-controle](WorldTestLogs/CastleRefinement/iphone.log) en [eerste iPad-controle](WorldTestLogs/CastleRefinement/ipad.log) zijn bewaard.

De bronvergelijking controleert tegen de bestanden van vlak vóór deze opdracht, inclusief de eerder gemaakte verfijningen van wereld 6–9. De volledige landschapsbron en kaartbron zijn buiten de expliciete wereld-10-aanpassingen gelijk gebleven. Alle bestaande tests zijn gelijk gebleven. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd; de simulatorcontroles gebruiken afzonderlijke testopslag.
