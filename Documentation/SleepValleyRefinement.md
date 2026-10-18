# Wereld 2 — Slaapvallei verfijnd, 14 oktober 2026

## Analyse en richting

De bestaande Slaapvallei had een vrijwel vlakke lavendelkleurige ondergrond, een kleine maan en herhaalde losse bomen en paddenstoelen. Het bestaande conceptbeeld biedt een duidelijkere wereld: een maanverlichte vallei met watervallen in de verte, hangende wilgen, beekjes, nevel en kleine warme lichtbronnen. Die opbouw is vertaald naar native SwiftUI-paden, op hetzelfde detailniveau als de verfijnde jungle.

De beeldlagen bestaan nu uit een sterrenlucht met een grote warme maan, verre heuvels en rotswatervallen, een open vallei met gedempte salie- en lavendeltinten, en rijkere begroeiing aan de oevers. Het zandpad houdt zijn vaste schaal en blijft vrij voor de levelknoppen.

## Uitwerking

- De entree heeft 70 punten extra ruimte boven het titelbord, een grote maan met subtiele kraters en gloed, sterren, zachte wolken, verre heuvels, rotswatervallen en mistbanken.
- Treurwilgen hebben vertakte stammen, schorslijnen en gebogen takken met afzonderlijke hangende blaadjes. Grote bomen omlijsten de kaart; kleinere wilgen en plantgroepen wisselen af langs het pad.
- Beekjes hebben oevers, waterstrepen en waterlelies. Een houten bruggetje met planken, palen en een touwleuning verbindt een oeverplek. De verre watervallen liggen vóór de aansluiting van de beek, zodat de beek het vallende water niet afdekt.
- Paarse paddenstoelen hebben gelaagde hoeden, lichte vlekken, lamellen en een warme gloed. Klokbloemen, mosbladeren, gefacetteerde stenen en vuurvliegjes vullen de voorgrond aan.
- Kleine wekkers op rotsen tonen **03:30** of **07:30**, passend bij halve uren. Hun cijfers blijven leesbaar aan beide oevers en worden niet gespiegeld.
- De levelstenen hebben een blauwgrijze zijkant, een lichte maanrand, kleine lichtaccenten en een zachte groene bovenkant. De steen onder Dino krijgt een bleke laag en een rustige lichtkring. Hoog contrast houdt de cijfers en randen duidelijk.

`SleepValleyPainter` wordt uitsluitend gebruikt voor wereld 2 en de wereld-2-preview op belonings- en bosskaarten. `SleepValleyLevelStone` geldt uitsluitend voor levels 11–20. De landschappen en stenen van de jungle en de overige werelden behouden hun bestaande uitvoering.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/SleepValleyRefinement/entrance-iphone.png) | [Screenshot](Screenshots/SleepValleyRefinement/entrance-ipad.png) |
| Halve uren spelen | [Screenshot](Screenshots/SleepValleyRefinement/half-hour-question-iphone.png) | [Screenshot](Screenshots/SleepValleyRefinement/half-hour-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/SleepValleyRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/SleepValleyRefinement/occupied-stone-ipad.png) |

## Controle en reproduceerbaarheid

De bestaande hoofdstuktest en Dino-plaatsingstest kunnen nu gericht worden uitgevoerd met `DINO_TEST_WORLD_IDS=2` in de omgeving van de testhost. Zonder die instelling behouden ze hun oorspronkelijke bereik. De hoofdstuktest opent level 11, controleert het tikgebied en de ontgrendeling, opent de startkaart en beantwoordt een halfuurvraag. De plaatsingstest speelt het eerste level van de gekozen wereld volledig en vergelijkt Dino's voeten met het midden van de behaalde steen.

De actuele build staat in [het definitieve buildlog](WorldTestLogs/SleepValleyRefinement/final-build.log). Bij deze build zijn ook expliciete typen aan de bestaande callbacks van de analoge rekenklok gegeven, om een Swift-typecontrolefout tijdens gelijktijdige klokwijzigingen in de gedeelde map op te lossen; het gedrag is daarbij behouden.

De gerichte hoofdstukcontroles voor wereld 2 zijn geslaagd op [iPhone](WorldTestLogs/SleepValleyRefinement/iphone-focused.log) en [iPad](WorldTestLogs/SleepValleyRefinement/ipad-focused.log). Ook de controle van Dino op de behaalde steen van **level 11** slaagt op beide apparaten: [iPhone-log](WorldTestLogs/SleepValleyRefinement/stone-iphone.log) en [iPad-log](WorldTestLogs/SleepValleyRefinement/stone-ipad.log). Dit zijn vier geslaagde gerichte schermtestuitvoeringen met nul fouten. De bijbehorende screenshots zijn visueel gecontroleerd; `git diff --check` is schoon.

Ook `testDirectPerfectBoss` slaagde op iPad: de jungle voltooien ontgrendelt de Slaapvallei en de eerste halfuurvraag kan worden beantwoord. [Testlog](WorldTestLogs/SleepValleyRefinement/ipad.log).

De eerste brede hoofdstukrun werd op iPhone na de geslaagde wereld-2-stappen door een signal kill beëindigd. De brede iPad-run bereikte wereld 8, waar de bestaande aanname dat de eerste vraag meerkeuzeknoppen heeft niet klopte. Dit is geen geslaagde controle van alle werelden; de afronding van deze opdracht gebruikt daarom de gerichte wereld-2-runs. [Brede iPhone-run](WorldTestLogs/SleepValleyRefinement/iphone.log) · [Brede iPad-run](WorldTestLogs/SleepValleyRefinement/chapters-ipad.log).

Alle schermcontroles gebruiken afzonderlijke Debug-testopslag. Echte spelersvoortgang is niet gewijzigd.

## Eerste redesignronde — 18 oktober 2026

De Slaapvallei heeft een verdere verbeterslag gekregen met vollere bewegende wilgen, hangende lantaarns, doorlopende beekjes, vier kleine watervallen, rijkere oevers en subtiele lichtanimaties. [Uitwerking en verificatie](SleepValleyFirstPass.md).

## Tweede redesignronde — 18 oktober 2026

Natuurlijkere wilgen, mosoevers met waterlelies en riet, waterpoelen, afgeronde rotsen en een verre bosrand met bewegende nevel geven de vallei meer diepte. [Uitwerking, beelden en controles](SleepValleySecondPass.md).

## Klokjes verwijderd en water beter aangesloten — 18 oktober 2026

De decoratieve klokjes zijn vervangen door nachtdetails. De kleine watervallen hebben een gedeelde beeklijn voor hun toevoer en uitstroom. De rechterbeek verdwijnt eerder en de rechter lava-ingang begint al in het einde van Slaapvallei. [Aanpassingen, beelden en controles](SleepValleyWaterConnections.md).
