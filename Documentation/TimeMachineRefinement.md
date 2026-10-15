# Wereld 8 — Tijdmachine verfijnd, 15 oktober 2026

## Analyse en richting

De bestaande kaart bestond uit een lichte ondergrond, losse tandwielen, kleine portalen en werkbanken. Het bestaande [conceptbeeld](WorldConcepts/world-8-map.png) geeft de tijdmachine een samenhangende omgeving: zwevende terrassen, messing bogen, glazen energieleidingen, watervallen en begroeiing. Die richting is uitgewerkt met native SwiftUI/Canvas-tekeningen, passend bij de eerder verfijnde werelden.

Wereld 8 draait om analoge en digitale klokken combineren. Daarom krijgen de klokplekken telkens een analoge wijzerplaat en een digitaal scherm met dezelfde tijd. De centrale route, levelposities en bediening blijven de basis.

## Uitwerking

- Een entree met zachte wolken, verre zwevende eilanden, torens en watervallen. De eilanden vervagen in de nevel. Een grote messing boog omlijst een helder portaal en een astronomische machine boven de titel. De titel heeft 118 punten extra bovenruimte.
- Portalen met een metalen omranding, klinknagels, glazen lichtstroken, concentrische lichtbanen, een heldere kern en kleine lichtdeeltjes.
- Zwevende werkterrassen met gelaagde stenen gevels, voegen, gouden randen en afzonderlijke klinknagels. Glazen energiezuilen hebben vloeistof, bellen, reflecties en metalen verbindingsringen.
- Energieleidingen met bochten, tandwielen en kleine watervallen. Een brug heeft afzonderlijke dekdelen, palen en messing leuningen. De leidingen en brug liggen achter de grotere werkplaatsen.
- Afwisselende werkplekken met een portaal, klokconsole, tekentafel of astronomische machine. Werkbanken hebben een blauwdruk, boeken, een klein energievat en tandwielen. De astronomische machines hebben drie gekantelde ringen, kleine planeten en een analoge klok.
- Klokconsoles met de tijden **06:25** en **14:40**, elk met bijpassende analoge wijzers. De astronomische klokken wijzen **09:10** aan. De digitale schermen worden zonder spiegeling getekend.
- Beplante terrassen met afzonderlijke bladeren, bladnerven, roze bloemen en warme lantaarns. Kleine blauwe lichtdeeltjes verbinden de machines visueel met de glazen leidingen.
- Eigen levelstenen voor levels 71–80: messing randen met klinknagels en uurmarkeringen rond een zacht groen glazen midden. De eindbaassteen heeft een donkerblauwgroene bovenkant. Onder Dino verzacht een bleke laag het midden en verschijnt een lichtblauwe kring. Hoog contrast behoudt duidelijke randen en cijfers; tikgebieden en voetpositie blijven gelijk.

`TimeMachinePainter` geldt alleen voor de kaart en de wereld-8-preview op boss- en beloningskaarten. `TimeMachineLevelStone` geldt alleen voor levels 71–80. De nieuwe entree-opmaak is begrensd tot wereld 8. Andere werelden behouden hun bestaande tekeningen en levelstenen.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/TimeMachineRefinement/entrance-iphone.png) | [Screenshot](Screenshots/TimeMachineRefinement/entrance-ipad.png) |
| Analoge en digitale klokken koppelen | [Screenshot](Screenshots/TimeMachineRefinement/matching-question-iphone.png) | [Screenshot](Screenshots/TimeMachineRefinement/matching-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/TimeMachineRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/TimeMachineRefinement/occupied-stone-ipad.png) |
| Laatste machines en Professor Pendel | [Screenshot](Screenshots/TimeMachineRefinement/lower-machine-iphone.png) | [Screenshot](Screenshots/TimeMachineRefinement/lower-machine-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 8 uitgevoerd met `DINO_TEST_WORLD_IDS=8`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 71, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 71 volledig en controleert Dino’s voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

De hoofdstuktest ondersteunt nu ook de bestaande koppelvragen: de test wacht op de klokknop en gebruikt de al aanwezige koppelhelper. Dit is nodig omdat wereld 8 begint met koppelvragen. De spelvragen en antwoordcontrole van de app blijven gelijk.

[Definitieve build](WorldTestLogs/TimeMachineRefinement/verified-build.log) · [iPhone-controle](WorldTestLogs/TimeMachineRefinement/verified-iphone.log) · [iPad-controle](WorldTestLogs/TimeMachineRefinement/verified-ipad.log) · [Bronvergelijking](WorldTestLogs/TimeMachineRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De entree, koppelvraag, behaalde levelsteen en eindzone zijn visueel gecontroleerd op iPhone en iPad. Bij de laatste entreecontrole is het hoofdportaal naar links verplaatst, zodat het pad de opening vrijlaat. De boog is volledig binnen het entreevlak getekend en eindigt op de terrassen. De eerste controle was eveneens succesvol; de [eerste build](WorldTestLogs/TimeMachineRefinement/build.log), [iPhone-log](WorldTestLogs/TimeMachineRefinement/iphone.log) en [iPad-log](WorldTestLogs/TimeMachineRefinement/ipad.log) zijn bewaard.

De bronvergelijking controleert tegen de bestanden van vlak vóór deze opdracht, inclusief de eerder gemaakte verfijningen van wereld 6 en 7. De volledige landschapsbron en kaartbron zijn buiten de expliciete wereld-8-aanpassingen gelijk gebleven. Ook alle andere tests zijn gelijk gebleven. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd; de simulatorcontroles gebruiken afzonderlijke testopslag.
