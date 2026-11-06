# Performance van scrollen door de werelden

Nieuwste vervolg: [kleine scrollbewegingen op iPhone](IPhoneSmallScrollCorrection.md). De proeven met adaptieve decorfrequentie en gedeelde levelstenen zijn teruggedraaid na toestelervaringen; hun eerdere simulatorcijfers gelden niet als bewijs voor vloeiender scrollen op iPhone.

1 november 2026. Onderzoek gericht op de wereldkaart, inclusief de eerste passage met lege landschapcache en terugscrollen.

Er zijn concrete verbeteringen aangebracht aan gedeelde metro-, tunnel- en watervalgeometrie, statisch tekenwerk, gelijktijdige landschapaanvragen en behoud van geladen hoofdstukken bij korte omkeringen. **Het scrollprobleem is nog niet volledig opgelost.** De behouden versie mat in de gerichte koude proef 503,0 ms tegenover 866,9 ms in de oorspronkelijke run; de bestaande grens van 500 ms faalt dus nog. De brede passage registreerde maximaal 733,8 ms. Dit zijn simulatorcallbackpauzes, geen bewezen 60/120 fps of algemene procentuele snelheidswinst.

| Controle | Resultaat |
| --- | --- |
| Debug-testbuild en Release-build, arm64 simulator | Geslaagd |
| Gerichte viewportcontroles | 93 geslaagd |
| Stadsroute, HUD-thema bij terugscrollen, landschapcachehergebruik | Geslaagd |
| Alle tien werelden en level 100 bereiken en terugscrollen | Functioneel geslaagd; maximaal 733,8 ms gemeten |
| Bestaande koude regressiegrens van 500 ms | Nog niet gehaald: 503,0 ms |

De twee aanvullende renderexperimenten zijn teruggedraaid. De definitieve code is teruggebracht naar de eerder gebouwde en geteste versie met gedeelde watervalgeometrie. De ruwe waarden en verwijzingen naar lokale logs staan in [WorldScrollMeasurements.json](WorldScrollMeasurements.json).

## Vastgestelde knelpunten

1. **Stadsanimatie berekende vaste tunnelgeometrie ieder frame.** `CityMetroForeground` draait tot 60 keer per seconde. Zowel `tunnel.buriedVolume` als `tunnel.bounds` construeerden dezelfde convexe omhulling opnieuw: punten langs het ondergrondse spoor bemonsteren, sorteren en een hull berekenen. `bounds` vroeg `buriedVolume` nogmaals op. Ook de plaatsingszoektocht voor het eindbaasplein werd herhaald. Dit werk concurreerde rechtstreeks met scrollen op de hoofdthread, ook in de voorbereidingsstrook naast het zichtbare scherm.
2. **Dezelfde metrolijn werd op verschillende plekken opnieuw gemaakt.** De constructor maakt Béziermeetpunten, uniforme afstandsmetingen, een filter met 41 gewichten, tangenten, stationsafstanden en een ruimtelijke index voor funderingen. Terreintekenen, gebouwen, stations, tunnels en eindbaasplein gebruikten afzonderlijke instanties. Dit gebeurde bij nieuwe viewevaluaties en voorheen ook via de eindbaastekening op de animatieklok.
3. **Een stilstaand eindbaasplein stond in de bewegende tekenboom.** De nieuwe tijdwaarde maakte een nieuwe Canvas-closure voor het plein, de schaduw en het eindbaaslichaam. De klokwijzers hebben al hun eigen laag; het lichaam hoeft niet mee te tekenen.
4. **Gelijktijdige landschapaanvragen deelden niet de volledige voorbereiding.** Alleen de rasterstroken van het kasteel werden samengevoegd. Verzoeken voor dezelfde sleutel konden vooraf elk hun eigen geometrievoorbereiding en PNG-decodering starten.
5. **Watervallen herbouwden hun vaste stroompaden tijdens de animatie.** In de steekproef waren `Cascade.filament`, `Cascade.ribbon`, `centerX` en lengtemetingen zichtbaar in de tekenroute van de slaapvallei. Acht paden met elk 65 meetpunten, het masker en de lengtes zijn onafhankelijk van de animatietijd.
6. **Alle stadsgevels kregen tegelijk een tekensurface.** De treinen en wijzers waren op de viewport begrensd, maar de vaste gevels, stations, tunnel en het eindbaasplein werden over het hele hoofdstuk opgebouwd zodra de stadsanimatie naderde. Die piek was ook bij terugscrollen relevant.
7. **De laad- en vrijgavegrens van een landschap was identiek.** Bij heen-en-weer bewegen rond die grens kon een compleet hoofdstuk herhaald verdwijnen en terugkomen, met nieuwe taken, afbeeldingsreferenties en decoratieve subviews.

## Aangebrachte verbeteringen

- Een begrensde cache van maximaal acht onveranderlijke metrolijnen, met breedte, hoogte en routeoffset als sleutel. Alle bestaande gebruikers delen dezelfde rekenuitkomst. De oorspronkelijke constructieberekeningen zijn behouden.
- Een afzonderlijke, eveneens begrensde cache voor tunnelmasker, tunnelgrenzen en eindbaaspositie. De animatie leest deze vaste waarden; alleen de treinposities en de kloktijd veranderen per frame.
- Stadsgeometrie en gebouwenplaatsing worden nu meegenomen in de bestaande achtergrondvoorbereiding van landschapafbeeldingen, ook bij een afbeelding uit de schijfcache. De nabijgelegen animatielagen kunnen die voorbereide geometrie hergebruiken.
- Het eindbaasplein heeft een afzonderlijke `Equatable` tekenview. De animatieklok kan ongewijzigde tekeningen overslaan. De trein en klokwijzers behouden hun bestaande frequentie en snelheid.
- De watervallen delen nu hun exacte maskers, acht stroompaden en lengtemetingen via een cache van maximaal 32 cascadeplannen. Wereld 2 en 7 bereiden die geometrie op de achtergrond voor. De bestaande punten, stroomrichting en animatieformules blijven gelijk.
- De landschapcache combineert nu de volledige aanvraag per sleutel: geometrie, schijfdecode en rasterisatie. Een verdwenen aanvrager publiceert geen laat resultaat in zijn view; gedeeld cachewerk kan door een andere aanvrager worden gebruikt. Wanneer de laatste aanvrager verdwijnt, wordt de gedeelde taak geannuleerd zodat een achterhaalde schermmaat geen nieuwe rasterisatie meer start.
- Een geladen hoofdstuk blijft één extra schermhoogte (minimaal 512 punten) behouden buiten de bestaande voorbereidingsgrens van drie schermen/minimaal 1.800 punten. Deze hysterese voorkomt opbouw bij korte omkeringen. Verre hoofdstukken worden nog steeds vrijgegeven. Dit kan bij een grens tijdelijk meer geheugen vasthouden.

De wijzigingen wijzigen geen levelposities, scrollankers, beeldresolutie, illustratiedetails, animatiesnelheid of spelregels. Alle honderd levelankers blijven aanwezig; een eenvoudige omzetting naar `LazyVStack` zou herstel naar verre levels en toegankelijkheidsnavigatie veranderen en is hier niet toegepast.

## Metingen en controle

De bestaande koude test op de oorspronkelijke build, `testColdSleepValleyScrollKeepsMainThreadResponsive`, reproduceerde een maximale hoofdthreadcallbackpauze van **866,9 ms**. De test faalde op de bestaande grens van 500 ms. De meetroute gaat door levels 57, 61, 65, 68, 71, 75, 81 en 85. Dit meet een lange pauze tussen displaylinkcallbacks, geen exacte GPU-framerate. De oorspronkelijke log staat lokaal in `.build/scroll-baseline.log` en de resultaatbundel in `.build/scroll-baseline.xcresult`.

De nieuwe `testColdScrollAcrossEveryWorld` begint zonder opwarming met een unieke lege cache, bezoekt de eerste steen van alle tien werelden en level 100, en scrolt daarna snel terug. Zo worden de vroege werelden ook meegenomen; een warme XCTest-performanceherhaling kan hun eerste opbouw anders verbergen.

De corecontroles testen de voorbereidingsgrens, behoud bij een korte omkering en uiteindelijke vrijgave bij meerdere schermhoogten. Bestaande tests controleren kaartpositie, HUD-thema, stabiele landschapafbeeldingen en speelbaarheid van de metroroute.

## Resterende aandachtspunten

- Buiten het kasteel rendert een koude landschapafbeelding nog als één `ImageRenderer`-bewerking op de hoofdthread. Meer werelden in stroken renderen is een mogelijke vervolgstap, maar moet samen met geometrische uitsluiting van objecten buiten iedere strook gebeuren. Alleen dezelfde volledige tekening vele keren clippen kan de totale CPU-belasting juist sterk vergroten. De [Apple-documentatie voor ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) markeert de renderer als `MainActor`; deze zomaar naar een achtergrondtaak verplaatsen is geen geldige oplossing.
- Water, begroeiing, dieren, treinen en klokwijzers delen tijdens scrollen de beschikbare CPU/GPU-tijd. Ze worden al buiten hun zichtbare/voorbereide gebied gepauzeerd. Deze wijziging verlaagt hun frequentie niet en zet zichtbaar water niet stil.
- De viewport gebruikt diverse geometrieobservaties. Die publiceren grotendeels booleans of afgeronde banden, zodat niet iedere scrollpixel de hele kaart bijwerkt. Een centrale viewportwaarnemer kan het aantal observaties verder verminderen, maar vraagt een bredere aanpassing en metingen van layout en toegankelijkheid.
- Cachelimieten zijn geen harde limieten voor het totale procesgeheugen: zichtbare views houden eigen afbeeldingen vast. Controleer bij apparaatmetingen ook herhaald scrollen en rotatie, naast de eerste passage.
- Voor een uitspraak over een constante 60/120 fps is een Release-build op een fysiek toestel met Animation Hitches en Time Profiler nodig. Simulatorcallbackpauzes, CPU-tijd, geheugen en de duur van scrollgebaren zijn afzonderlijke meetwaarden.

De bestaande `testSleepValleyToTimeMachineScrollPerformance` brak in de oorspronkelijke build af: na de zes vaste snelle vegen stond level 71 op y=1.337,3 bij een schermhoogte van 874 punten. De vereiste wereld was dus nog niet bereikt. Deze run levert geen geldige CPU-/geheugenvergelijking op en wordt daarvoor niet gebruikt (`.build/scroll-baseline-metrics.log`).

De gerichte coreproef (`zsh Tools/test-dino.sh --map-viewport`) slaagt met **93 controles**. De volledige coreproef faalde tijdens deze sessie op een losstaande assetinventariscontrole: `AppIcon-for-promo` staat in de assetcatalogus maar niet in de verzameling gebruikte spelillustraties. Die catalogus is voor dit onderzoek niet aangepast.

De tussenversie met uitsluitend de cacheverbeteringen slaagde voor `testCityMetroRouteRemainsPlayable`, maar de nieuwe brede proef registreerde nog 650,2 ms bij de dorp/grotpassage en later 1.226,6 ms. Daarom is die versie niet als oplossing voor de volledige kaart beoordeeld en is asynchrone presentatie als afzonderlijk experiment onderzocht. De tussenrun is na de brede passage gestopt om de definitieve versie te bouwen. Tijdens deze sessie was ook een tweede app op een andere iPhone-simulator actief; beide delen de CPU/GPU van de Mac. De twee seconden stacksteekproef bevat onder meer wachten op Metal en tekenen van slaapvalleieffecten. Dat bewijst geen afzonderlijke oorzaak voor de eerder gemeten dorp/grotpauze. De steekproef staat lokaal in `.build/scroll-main.sample.txt`.

**Niet behouden experiment:** Apples [Canvas-optie `rendersAsynchronously`](https://developer.apple.com/documentation/swiftui/canvas/rendersasynchronously) is op de bewegende kaartlagen geprobeerd. De brede proef bleef lange pauzes melden, onder meer 865,5 ms bij wereld 4 en 1.011,5 ms bij wereld 6. Er is in deze sessie geen verbetering mee aangetoond. De optie is teruggedraaid; de definitieve wijziging bevat de gedeelde vaste geometrie, statische tekenisolatie, samengevoegde aanvragen en hysterese. Later is ook de in de steekproef gevonden watervalgeometrie gedeeld. De experimentlog staat lokaal in `.build/scroll-final.log`. Er wordt geen CPU-, GPU- of frameratewinst voor deze afgewezen variant geclaimd.

De nieuwe brede proef controleert bereikbaarheid van alle werelden en registreert de maximale callbackpauze als diagnose. Zij claimt geen reeds behaalde limiet van 500 ms voor alle werelden. De bestaande gerichte koude test houdt zijn oorspronkelijke 500 ms-assertie; die is niet verruimd.

## Functionele tussencontrole van de behouden wijzigingen

- `testCityMetroRouteRemainsPlayable`: geslaagd; level 51 openen, de route naar 54/57/60 en het eindbaasplein.
- `testHUDThemeFollowsScrollInsteadOfPlayerLevel`: geslaagd; vanuit level 90 terug door de werelden, met behoud van spelersniveau en het juiste gescrollde HUD-thema.
- De gerichte koude route mat met de metro-/aanvraagcache en hysterese **505,7 ms**, tegenover **866,9 ms** in de oorspronkelijke Debug-run. De bestaande 500 ms-assertie faalde dus nog. Dit is een afzonderlijke simulatorrun, geen bewezen algemene procentuele frameratewinst. De watervalcache is daarna toegevoegd en wordt afzonderlijk gecontroleerd.

- `testPreparedMapArtworkStaysStableDuringScrolling`: geslaagd; de landschapafbeeldingen worden bij herhaalde kleine scrollbewegingen hergebruikt.
- De definitieve Debug-testbuild en Release-simulatorbuild voor arm64 slagen, inclusief de watervalcache. Ook `zsh Tools/test-dino.sh --map-viewport` slaagt met 93 controles.

## Controle met de gedeelde watervalgeometrie

De brede diagnoseproef door alle tien werelden en level 100, inclusief snel terugscrollen, slaagt functioneel. De grootste callbackpauze was **733,8 ms**; tijdens de neerwaartse passage was dat **672,6 ms**. Deze proef controleert bereikbaarheid en registreert pauzes; slagen betekent hier geen garantie dat alle pauzes onder 500 ms vallen. De gerichte koude proef mat **503,0 ms** en faalde nog op de ongewijzigde grens van 500 ms. De waterval is ook visueel gecontroleerd bij de slaapvallei-entree. Dit is vastgelegd in `.build/scroll-water-verified.log` en `.build/scroll-water-verified.xcresult`.

Een tweede experiment begrensde de verre stadsgevels, stations, tunnel en het eindbaasplein tot de voorbereidingsstrook. De stadsroute slaagde, maar de daaropvolgende koude proef registreerde 2.543,7 ms en eindigde met een timeout van de simulatorautomatisering. Die run is geen betrouwbare vergelijkende performanceproef. De begrenzing is teruggedraaid; zij zit niet in de definitieve code. De log staat in `.build/scroll-city-verified.log`. Ook voor dit afgewezen experiment wordt geen verbetering geclaimd.

## Praktische vervolgstap voor de resterende haperingen

Meet een Release-build op het toestel waarop de vertraging wordt ervaren met Animation Hitches en Time Profiler, met speciale aandacht voor de dorp/grotpassage en terugscrollen door de stad. De simulatorsteekproef toont renderwachttijd, maar is onvoldoende om die volledig aan een specifieke decorlaag toe te schrijven. De huidige 500 ms-guard bewaakt alleen zeer lange onderbrekingen; ook slagen voor die guard zou nog geen vloeiend framebudget van 16,7 ms aantonen. Begin een vervolg dus met een toesteltrace voordat tekendetails, animatiefrequenties of de complete renderer worden veranderd.
