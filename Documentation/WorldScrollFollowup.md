# Vervolgonderzoek naar grote vegen door werelden

2 november 2026, bijgewerkt bij de productiecontrole. De gebruiker meldt nu dat het scrollen aardig goed aanvoelt. De productiebron houdt de eerder gecontroleerde geometriecaches en de gewone beeldweergave. Alle experimentele viewportdrivers, tegelweergave en bijbehorende schakelaars zijn verwijderd. Onderstaande meetreeks is onderzoeksgeschiedenis; er is geen nieuwe gecontroleerde FPS-meting die volledige vloeiendheid op alle toestellen bewijst.

## Geldige handmatige opname

De afzonderlijke Time Profiler-opname `.build/iphone-manual-cpu-only.trace` is wel geslaagd. De gebruiker veegde zelf circa twintig seconden door meerdere werelden. Van 13.668 CPU-steekproeven van 1 ms zitten er 11.228 op de hoofdthread. Inclusief bovenliggende calls: 7.274 ms SwiftUI-renderupdates, 4.523 ms AttributeGraph-updates, 3.366 ms Core Animation-transacties. Deze aantallen overlappen. Er was geen XCTest-automatisering actief.

De eerder mislukte gecombineerde Animation Hitches/Time Profiler-opname wordt niet als meetbewijs gebruikt.

## Afgewezen centrale viewportwaarnemer

De proef met 26 native viewportaanroepplekken slaagde functioneel, maar mat 63 haperingen, 419,1 ms/s scrollhitchratio en 50,650 s CPU, tegenover 25 / 142,5 / 39,834 met alleen geometriecaches. De gehele driver en alle helpervervangingen zijn verwijderd. Details: [NativeMapViewport.md](NativeMapViewport.md).

## Lopende controles

1. Twee verder identieke appbundels vergelijken met uitsluitend `CADisableMinimumFrameDurationOnPhone` true/false. Hun uitvoerbare `__text`-sectie heeft dezelfde SHA-256: `81f5f4407a706f21aea6e5714ff338678df47c9615a3b07480d5f8dcf6eb78cc`. Broncode-Info.plist staat nog op true. De oorspronkelijke eerste testpoging stopte door een tijdelijke fout bij het starten van de teststarter; de handtekening en het profiel zijn geldig en rechtstreeks starten lukte. De herhaling loopt onder `.build/iphone-rate-retry-*.log`.
2. Een afzonderlijke proef toont de grote voorbereide terreinbeelden via CATiledLayer, dat kleine stukken asynchroon kan tekenen. De eerste testbuild is gebouwd in `/tmp/dino-phone-tiled-test`; de broncodewijziging in `DinoUI.swift` is nog experimenteel. Beeldoriëntatie, bedekking en prestaties moeten eerst op het toestel worden gecontroleerd. De jungle houdt zijn bestaande kleine afbeeldingen. Er worden geen SwiftUI-tekeningen op een achtergrondthread uitgevoerd; de tegellaag tekent alleen onveranderlijke CGImages met CGContext.

Voor de tegelproef zijn controles bij wereld 6 en 9 voorbereid in `.build/iphone-tiled-terrain-functional.xctestrun`. De eerdere beeldweergave staat lokaal in `/tmp/dino-pre-tiled-terrain.swift`, zodat de proef zonder verlies van de behouden geometriecaches kan worden teruggedraaid.

De getekende vaste grot- en kustgeometrie is eerder exact vergeleken en blijft behouden. De oorspronkelijke bron van die controles en meetwaarden staat in [IPhoneSmallScrollCorrection.md](IPhoneSmallScrollCorrection.md).

## Uitkomst verversingsvergelijking

Beide herhalingen zijn functioneel geslaagd. De huidige ProMotion-instelling mat 20 haperingen, 81,9 ms/s en 41,405 s CPU; de standaardinstelling mat 70 haperingen, 457,7 ms/s en 45,210 s CPU. De grootste callbackpauze in de gemeten iteratie was respectievelijk 230,8 en 302,0 ms. Dit is één gemeten koude iteratie per variant; de proef toont geen voordeel van de standaardinstelling. `CADisableMinimumFrameDurationOnPhone` blijft daarom true in de broncode. De twee kandidaten hebben aantoonbaar dezelfde uitvoerbare appcode; de oorspronkelijke mislukte starts bevatten geen prestatiemeting.

## Functionele tegelcontrole

De eerste tegelbuild slaagt voor `testPreparedMapArtworkStaysStableDuringScrolling` (22,950 s) en `testWorldBossSceneryRemainsPlayable` bij wereld 6 en 9 (29,215 s). De echte iPhone-screenshots zijn geëxporteerd en visueel gecontroleerd: terrein is rechtop, wegen en bazen blijven uitgelijnd en er zijn in de stilstaande beelden geen ontbrekende tegels of zichtbare naden. Log: `.build/iphone-tiled-terrain-functional.log`; de koude vergelijkingsproef loopt in `.build/iphone-tiled-terrain-cold.log`.

De tegelproef verandert het bronbeeld en de landschapcache niet. CATiledLayer tekent alleen de voorbereide CGImage, met een begrensde tegelgrootte van 512 bij 512 pixels en zonder de standaard fade-in van nieuwe tegels. UIKit/SwiftUI-tekeningen blijven op hun bestaande executor. De jungle behoudt zijn bestaande kleine afbeeldingen. Nog te beoordelen zijn de prestaties en eventuele tijdelijke lege stukken tijdens echte snelle bewegingen.

## Tegelproef afgewezen

De koude tegelproef slaagde functioneel maar mat 36 haperingen, 226,8 ms/s, 53,381 s CPU en een grootste callbackpauze van 385,1 ms. De recente herhaling met de gewone beeldweergave mat 20 / 81,9 / 41,405 / 230,8. Er is geen aangetoonde verbetering. De volledige CATiledLayer-weergave is uit de broncode verwijderd; de gewone voorbereide UIImage-weergave is teruggezet. De extra Release-bundel van de tegelproef is een afgewezen testartefact en mag niet als definitieve app worden geïnstalleerd.

## Afgeschermde proef met meetpunten per wereld

Een nieuwe proef gebruikt maximaal elf native views (één referentievlak en tien wereldmetingen), met bestaande SwiftUI-actorposities relatief aan hun eigen wereld. De vorige per-actor-native-variant voegde veel meer native views toe en is niet heringevoerd. De nieuwe variant staat uitsluitend in testbuilds aan met `DINO_TEST_CHAPTER_VIEWPORT=1`. De gewone Release-code houdt de schakelaar vooralsnog uit. De nulmeting en variant kunnen daardoor dezelfde uitvoerbare code en teststarter gebruiken.

`testColdMultiWorldFlickTrace` voegt een korte koude route toe voor gerichte SwiftUI-Instruments-opnamen zonder een tweede benchmarkiteratie af te wachten. De bestaande performanceproef logt nu ook thermische toestand en energiebesparingsmodus van het toestel. De vorige geometriecaches en de normale ProMotion-instelling blijven behouden.

De experimentele bron wordt gebouwd in `/tmp/dino-phone-chapter-test`; log `.build/iphone-chapter-viewport-build.log`. De oorspronkelijke bronnen vóór viewportproeven staan lokaal in `/tmp/dino-map-native-viewport-backup/` en bevatten de behouden grot- en kustcaches. De aangepaste testmethoden staan alleen in `Tests/DinoUITests.swift`.

## Hoofdstukproef: functioneel en meetopstelling

De hoofdstukvariant slaagt voor HUD-wereldthema, volledig rond tikvlak en wereldsprong. Tijdens de HUD-proef is kort een aanvullende SwiftUI-Instruments-opname geprobeerd; die bleef na de tijdslimiet hangen en is na normaal stoppen beëindigd. De langere duur van die functionele run is geen vergelijkbare performancemeting. De losse eerdere Time Profiler-opname blijft geldig.

De koude vergelijking loopt vervolgens zonder extra profiler, met exact dezelfde uitvoerbare appcode en `DINO_TEST_CHAPTER_VIEWPORT` alleen aan/uit. Logs: `.build/iphone-chapter-cold-control.log` en `.build/iphone-chapter-cold-native.log`. Ook de thermische toestand en energiebesparingsmodus worden bij iedere koude iteratie vastgelegd. Een productieaanpassing wordt pas overwogen na deze meting; de gewone Release-schakelaar staat nog uit.

## Thermische beperking gevonden

De nieuwe toestelstatuslogging meldt `thermal=2` (serious), met energiebesparing uit, tijdens de lange hoofdstukvergelijking. Die serie is afgebroken en de testapp is gesloten. De meetcijfers uit die warme ronde gelden niet als gecontroleerd bewijs voor of tegen de hoofdstukvariant. Eerdere reeksen zonder temperatuurregistratie kunnen hier niet achteraf voor worden gecorrigeerd.

`testDeviceThermalCooldown` houdt de app gesloten en controleert de status. Een nieuwe kortere `testColdFirstTraversalPerformance` meet alleen de eerste koude heenpassage naar het kasteel. De door XCTest verworpen opwarming bevat twee vegen in plaats van een hele heen-en-terugtocht. Iedere daadwerkelijke meting krijgt nog steeds een verse app en lege cache. Temperatuur en energiebesparing worden vastgelegd, en de app sluit direct na elke iteratie. Dit beperkt opwarming door langdurige automatische tests.

De appbron bevat nog uitsluitend de afgeschermde hoofdstukproef en de eerder behouden geometriecaches; de tegelweergave en de per-actor-native-waarnemer zijn verwijderd. De gewone Release-schakelaar voor de hoofdstukproef staat uit.

De gebruiker laat de fysieke iPhone nu met het scherm uit afkoelen. Er draaien intussen geen scrolltests op dat toestel. De temperatuurhulpfunctie is asynchroon gemaakt zodat de teststarter statusmeldingen kan blijven verwerken. De kortere eerste-passageproef controleert de temperatuur vóór het meten; logs bevatten ook de eindstatus. Een warme of mislukte ronde wordt niet gebruikt om winst te claimen.


## Afronding voor productie

De afzonderlijke Xcode-debugsessie van `monday match` op dezelfde iPhone is met toestemming van de gebruiker gestopt. Xcode bevestigde dat de debugrun was beëindigd. Dit is een mogelijke verstoring van de latere metingen; het bewijst niet dat die app de eerdere haperingen veroorzaakte. Er is geen nieuwe warme benchmarksessie gestart.

De hoofdstukvariant heeft geen geldige gecontroleerde prestatiewinst opgeleverd en is volledig uit alle vijf betrokken bronbestanden verwijderd. Er blijft ook geen ongebruikte driver in de gewone Release achter. De veilige bronbasis bevat de grot- en kustplannen waarvan de geometrische uitvoer eerder exact met de oude berekeningen is vergeleken. De oorspronkelijke `readGeometry`-aanroepen en HUD-meting zijn hersteld.

De iPad-landingsassertie van `testWorldJumpStillLandsOnNextWorld` gebruikte een vaste voetafstand van 12 punten. De kaart vergroot zowel steen als Dino op iPad. De test berekent nu diezelfde afstand uit de werkelijk weergegeven steenbreedte (72 punten met een voetafstand van 12 punten), met dezelfde nauwkeurigheid van 2 punten. Dit verandert geen appgedrag. De afzonderlijke temperatuurvoorbereiding is alleen nog op expliciet verzoek actief; een eerste-passagebenchmark markeert ook oververhitting tijdens de meting als ongeldig.

De uiteindelijke build-, kern- en schermresultaten staan in [ProductionReadiness20261102.md](ProductionReadiness20261102.md).


## Status na laatste productiecontrole (3 november)

De definitieve bron is opgeschoond en er is een gewone, ondertekende Release-archive gebouwd. Een bij de regressietest gevonden toetsenbordcrash via globale UIKit-appearance is hersteld. De actuele junglepadlayout slaagt daarnaast voor 118.784 route-/decorcontroles. Twee laatste volledige schermhercontroles en installatie van de definitieve archive op de telefoon staan nog open omdat de automatische goedkeuringscontrole de gebruikslimiet bereikte. De eerste eerder geïnstalleerde Release bevat de latere toetsenbordfix nog niet. Zie het actuele [productieverslag](ProductionReadiness20261102.md) voor de exacte stand; er is geen volledige productie-vrijgave geclaimd.


## Lokale eindcontrole afgerond (3 november)

De volledige resethercontrole en de laatste instellingencontrole zijn geslaagd. De onbetrouwbare aanraak- en rotatiegegevens van de al gebruikte simulator zijn omzeild met een afzonderlijk schoon testapparaat; de tijdelijke schakelaarmaatproef is teruggedraaid. De standaard rij blijft behouden.

De inmiddels afgeronde responsive-layoutwijzigingen zijn opgenomen in een nieuwe, geverifieerde Release-archive: `/tmp/dino-production-check-20261102/Dino-Time-production-combined.xcarchive`. De huidige bronhashes komen overeen met de vóór die bouw vastgelegde stand. De eerdere Release met scroll- en toetsenbordfix staat op de fysieke iPhone. De nieuwere gecombineerde update wacht nog op een bereikbare telefoon. Zie het definitieve [controleverslag](ProductionReadiness20261102.md) voor tests, bronversies en distributiebeperkingen.


## Definitieve telefoonupdate voltooid

Na opnieuw aansluiten is de gecombineerde Release succesvol op de fysieke iPhone geïnstalleerd en zonder debugger gestart. De archive met SHA-256 `819794540a8e7e19a765ebcc744e629935b425fc987105c21ab01753b75d713c` bevat de scrollverbeteringen, toetsenbordfix en de laatste afgeronde responsive-layoutwijzigingen. Alle lokale afrondingsstappen zijn voltooid; zie het actuele [controleverslag](ProductionReadiness20261102.md).
