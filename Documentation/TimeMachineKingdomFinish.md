# Wereld 8 — bronnen, afvoer en op hol geslagen uurwerken

21 oktober 2026. Vervolg op de [wateraansluitingen en laagvolgorde](TimeMachineWaterConnections.md).

De kraanuitlaten beginnen nu met een lichtere, iets groenere aquakleur. Die verloopt naar hetzelfde blauw als de rivier bij het raakpunt. De vallende waterdraden en het schuim blijven over deze overgang bewegen.

## Een complete entree en uitgang

De bovenste gevelrij begint met hele daken en bevestigde dakmasten. Beide rivieren ontspringen aan een stenen bronhuis met een boograam en messing uitlaat. De bovenste aanloop van iedere rivier verbindt deze uitlaat met de bestaande rivierbochten. De vroegere vervaging van afgesneden architectuur is verwijderd.

De laatste terrasrij wordt vanuit de onderste kade geplaatst. Daardoor eindigen de trappen op een volledig bordes, ook aan de rechterkant. De kade krijgt een afdeksteen, metselwerk en een gesloten onderrand. Beide rivieren lopen door naar ronde afvoerputten, met bewegende spiraalstromen en een donkere opening. De voorste putrand blijft voor het water staan. Daaronder gaat de bestrating over in de zandkleur van de volgende wereld.

[Entree, midden en uitgang op iPhone en iPad](Screenshots/TimeMachineKingdomFinish/app-overview.png) · [Volledige kaart](Screenshots/TimeMachineKingdomFinish/native-393.png) · [Afvoeranimatie](Screenshots/TimeMachineKingdomFinish/drain-flow.gif)

## Bevestiging en bewegende onderdelen

Vaandels hebben een zichtbare montageplaat, bouten en draagstang. Dakvaandels zijn aan een mast bevestigd; terrasvaandels zijn op de stenen muur geplaatst. Stadslantaarns staan op droge bordessen of brughoeken. Een verplaatste lantaarn heeft een ondersteunde messing draagarm met een bevestigingspunt in het metselwerk. De silhouetten blijven in dezelfde dieptevolgorde als de terrassen, machines en bruggen. Het zandpad en de levelstenen blijven vrij.

De decoratieve klokwijzers draaien tegen de klok in: de minutenwijzer maakt twee omwentelingen per seconde, de uurwijzer één per zes seconden. Ook de gevelklokken, kleine meters, klokken op Pendels hoed en het wereldbord bewegen. De speelklokken voor vragen houden hun gewone bediening.

Alle tandwielen bewegen. Bij een paar volgen de diameter en snelheid uit het aantal tanden: de tandwielen grijpen in elkaar, draaien tegengesteld en behouden dezelfde snelheid langs hun steekcirkel. Ook de drie gekoppelde tandwielen van het wereldbord gebruiken die verhouding.

Het zand van de grote zandlopers wordt op de werkelijke glasvorm begrensd. De vulhoogtes volgen de doorsnede van de gebogen kolven. Na iedere keerbeweging blijven de glasstand en de zandverdeling doorlopen; ze springen niet terug naar een andere beginstand.

[Simulatoropname](Screenshots/TimeMachineKingdomFinish/kingdom-motion-iphone.mp4) · [Stroming en klokwijzers in detail](Screenshots/TimeMachineKingdomFinish/flow-and-clocks-detail.gif) · [Keerbeweging zandloper](Screenshots/TimeMachineKingdomFinish/hourglass-turn.gif)

## Controle

De [definitieve testbuild](WorldTestLogs/TimeMachineKingdomFinish/build.log) slaagt. De bestaande `testTimeMachineWorkshopRouteRemainsPlayable` slaagt op [iPhone 17](WorldTestLogs/TimeMachineKingdomFinish/iphone.log) en [iPad Pro 11-inch](WorldTestLogs/TimeMachineKingdomFinish/ipad.log): twee tests, nul fouten. Deze controle opent level 71, bedient de instelbare klok, scrolt langs levels 74 en 77 en opent de eindbaas bij level 80.

De [native geometriecontrole](WorldTestLogs/TimeMachineKingdomFinish/native-render.log) doorloopt negen breedtes van 320 tot 1194 punten. De 81 kraanuitmondingen liggen exact op hun riviermiddellijn. De onderzochte lantaarnsilhouetten en gebouwkernen houden de speelroute vrij; de geplaatste bruggen raken geen klokvlak. De bovenste daken vallen binnen de stadsgrens en de onderste trapbordessen eindigen op de kade. De tandverhouding van een gekoppeld paar blijft behouden. Overzichtsrenders op 320, 393, 834 en 1194 punten vullen de geometrische steekproeven aan.

De waterlaag is apart gerenderd met de werkelijke voorgrondmaskers. Na 0,35 seconde veranderen 6.463 waterpixels op 393 punten breed en 7.797 op 834 punten breed, boven een kanaalverschil van 10 op 255. Direct vóór en na de zandlopergrenzen op 16 en 32 seconden verandert in de onderzochte glasuitsnede geen pixel meer dan 6 op 255. Dit meet de aansluiting; de langere animatiepreview toont het hele keren. Twee renders met bevroren kaartanimaties zijn identiek ([meetbestand](WorldTestLogs/TimeMachineKingdomFinish/visual-checks.json)). De animaties blijven pauzeren buiten beeld, bij een inactieve app en bij **Minder beweging**.

`git diff --check` is schoon. Het [afgebakende diff](WorldTestLogs/TimeMachineKingdomFinish/world-8.diff) bevat de Tijdmachine-laag en de voor wereld 8 bewegende bordversieringen. Gelijktijdige wijzigingen aan andere functies zijn behouden.
