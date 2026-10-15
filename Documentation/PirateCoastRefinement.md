# Wereld 9 — Tijdpiraten verfijnd, 15 oktober 2026

## Analyse en richting

De bestaande kaart had een zandkleurige ondergrond, rustige waterstroken en losse palmen, schatkisten en bootjes. Het bestaande [conceptbeeld](WorldConcepts/world-9-map.png) laat een tropische kust zien met begroeide rotseilanden, watervallen, aanlegsteigers en piratenkampjes. Dat is vertaald naar native SwiftUI/Canvas-tekeningen, aansluitend op de eerder verfijnde werelden.

De wereld draait om tijdsduur. Klokbordjes langs de route tonen **09:00**, **09:30** en **10:00**; zandlopers ondersteunen het thema. De route en levelposities blijven de bestaande basis. De grootste voorwerpen staan aan de buitenzijde van de bochten.

## Uitwerking

- Een entree met zonlicht, zachte wolken, kleine vogels, verre begroeide eilanden en een baai. Een grote rotsboog met een open doorkijk, waterval en schuim staat naast het pad. Een zeilboot en grote palmen omlijsten de titel. De titel heeft 128 punten extra bovenruimte.
- Turquoise kuststroken met bochtige ondieptes, zandkleurige oevers, lichte schuimranden, korte golfjes en waterreflecties. Rotsen, koraaltakken, schelpen en kleine planten geven de oever meer detail.
- Palmen met gebogen stammen, schorsringen, kokosnoten en afzonderlijke bladeren met kleurverloop, middennerven en zijnerfjes. Onder de palmen staan tropische planten en bloemen.
- Steigers met afzonderlijke planken, houtnerven, spijkers, palen en doorhangende touwen. Kleine watervallen, steigers en branding liggen achter de grotere kustscènes.
- Zeilboten met een gevormde romp, houten huidgangen, patrijspoorten, mast, touwen, twee zeilen, een wimpel en een klein anker. Vaten hebben losse duigen en metalen banden.
- Kampjes met een gestreept doek, palen, lantaarns en duidelijke digitale klokbordjes. Schatkisten hebben houtnerven, messing banden, klinknagels, een slot en losse muntjes.
- Een grote zandloper bij Kapitein Zandloper, met glazen rondingen, zand in beide helften, een dunne zandstraal, reflecties en houten staanders. De laatste scène staat verder naar binnen om de kapitein ruimte te geven.
- Eigen levelstenen voor levels 81–90 met een zandstenen rand, een gevlochten touwring en een zacht groen midden. De eindbaassteen heeft een donkerblauwgroene bovenkant. Onder Dino verzacht een bleke laag het midden en verschijnt een lichte kring. Hoog contrast behoudt duidelijke randen en cijfers; tikgebieden en voetpositie blijven gelijk.

`PirateCoastPainter` geldt alleen voor de kaart en de wereld-9-preview op boss- en beloningskaarten. `PirateLevelStone` geldt alleen voor levels 81–90. De extra entreeruimte geldt alleen voor wereld 9. Andere werelden behouden hun bestaande tekeningen en levelstenen.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/PirateCoastRefinement/entrance-iphone.png) | [Screenshot](Screenshots/PirateCoastRefinement/entrance-ipad.png) |
| Tijdsduur spelen | [Screenshot](Screenshots/PirateCoastRefinement/duration-question-iphone.png) | [Screenshot](Screenshots/PirateCoastRefinement/duration-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/PirateCoastRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/PirateCoastRefinement/occupied-stone-ipad.png) |
| Kust en Kapitein Zandloper | [Screenshot](Screenshots/PirateCoastRefinement/lower-coast-iphone.png) | [Screenshot](Screenshots/PirateCoastRefinement/lower-coast-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 9 uitgevoerd met `DINO_TEST_WORLD_IDS=9`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 81, opent de startkaart en beantwoordt een tijdsduurvraag. De plaatsingstest speelt level 81 volledig en controleert Dino’s voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag. De bestaande tests, spelvragen en antwoordcontrole zijn niet aangepast voor deze verfijning.

[Definitieve build](WorldTestLogs/PirateCoastRefinement/verified-build.log) · [iPhone-controle](WorldTestLogs/PirateCoastRefinement/verified-iphone.log) · [iPad-controle](WorldTestLogs/PirateCoastRefinement/verified-ipad.log) · [Bronvergelijking](WorldTestLogs/PirateCoastRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De entree, tijdsduurvraag, behaalde levelsteen en eindzone zijn visueel gecontroleerd op iPhone en iPad. Het kustwater vervaagt bij de entree en bij de overgang naar de volgende wereld. De grote zandloper staat iets hoger en verder naar binnen naast de kapitein. Lantaarns op de vaten sluiten aan op de bovenkant van het hout.

De eerste controles waren eveneens succesvol. De [eerste build](WorldTestLogs/PirateCoastRefinement/build.log), [eerste iPhone-controle](WorldTestLogs/PirateCoastRefinement/iphone.log) en [eerste iPad-controle](WorldTestLogs/PirateCoastRefinement/ipad.log) zijn bewaard.

De bronvergelijking controleert tegen de bestanden van vlak vóór deze opdracht, inclusief de eerder gemaakte verfijningen van wereld 6, 7 en 8. De volledige landschapsbron en kaartbron zijn buiten de expliciete wereld-9-aanpassingen gelijk gebleven. Alle bestaande tests zijn gelijk gebleven. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd; de simulatorcontroles gebruiken afzonderlijke testopslag.
