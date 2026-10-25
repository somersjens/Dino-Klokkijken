# Minder voorbereiding tijdens het scrollen

23 oktober 2026.

**Vervolg na de gemelde vastloper:** deze eerste optimalisatie verlaagde het geheugengebruik, maar loste de meersecondenpauze niet op. De [afzonderlijke koude meting en de verplaatste meeuwensimulatie](ColdSleepValleyFreeze.md) beschrijven de vervolgcorrectie. De geheugenvergelijking hieronder hoort bij de eerste optimalisatie.

De ruime voorbereidingszone van de kaart maakte ook alle bewegende decorlagen van een volgende wereld aan. Een gepauzeerde `TimelineView` tekent nog steeds een eerste frame, inclusief zijn statische maskers. Daardoor werden onder meer de vele uurwerken, tandwielen en voorgrondmaskers van de tijdmachinewereld opgebouwd terwijl de speler nog in een eerdere wereld scrolde.

De kaart gebruikt nu twee afzonderlijke voorbereidingsafstanden. Het bestaande landschap blijft ruim vooruit geladen en behoudt zijn vaste afbeelding. De bewegende decoratie wordt pas binnen 256 punten van het scherm opgebouwd, inclusief de bijbehorende maskers. In de slaapvallei, vulkaan, tijdmachinewereld, piratenkust en kasteelwereld gebeurt dat bovendien per kleine effectlaag. Een eenmaal opgebouwde laag blijft tot 512 punten buiten beeld bestaan om herhaald opbouwen bij korte bewegingen heen en weer te voorkomen. De eigen timelines blijven buiten beeld pauzeren.

De animatieklok blijft doorlopen tijdens scrollen en bij het opnieuw verschijnen van een laag. De bestaande snelheden, frequenties, vormen, kleuren, schaal en resolutie zijn behouden. Water krijgt dezelfde voorbereiding vóór de schermrand als andere bewegende decoratie en wordt tijdens een scrollgebaar niet stilgezet. Volledige vaste renders en previews blijven alle lagen kunnen tekenen.

De slaapvallei deelt voortaan dezelfde voorbereide riviermiddellijnen, oevers en schouders tussen het landschap en de bewegende waterstroken. Deze geometrie, en het water- en uurwerkplan van de tijdmachinewereld, wordt op een achtergrondtaak voorbereid. Dat gebeurt ook wanneer de landschapafbeelding al uit de geheugen- of schijfcache komt; een cachetreffer mag de voorbereiding van de bewegende wereld niet overslaan.

De levelindeling, scrollankers, bediening en de bestaande opslag van landschapafbeeldingen blijven behouden. De optimalisatie verlaagt geen detailniveau.

## Controle

- `Tools/test-dino.sh`: 819.645 geslaagde controles. De nieuwe controles dekken voorbereiding vóór de schermrand, behoud bij kleine omgekeerde bewegingen, vrijgeven van verre lagen, zichtbare waterlagen en verschillende viewportmaten.
- `testPreparedMapArtworkStaysStableDuringScrolling`: herhaald scrollen door het dorp hergebruikt de landschapafbeeldingen.
- `testTimeMachineWorkshopRouteRemainsPlayable`: de entree blijft bewegen; level 71 is speelbaar en de route langs 74, 77 en eindbaas 80 blijft bereikbaar.
- `testSleepValleyToTimeMachineScrollPerformance`: vaste snelle vegen door de slaapvallei en tijdmachinewereld, met CPU-, geheugen- en scrollintervalmetingen. De test controleert dat de gebaren wereld 8 daadwerkelijk bereiken.
- De volledige vaste landschappen van wereld 7 en 8 zijn vergeleken op 804 × 4.192 pixels: beide hebben nul gewijzigde pixels en nul kanaalverschil.

De simulatoropname van de overgang is in afzonderlijke frames visueel gecontroleerd. De achtergrond blijft volledig aanwezig, inclusief water, begroeiing en machinerie. Simulatorcijfers zijn vergelijkende metingen; het scrollinterval is geen FPS-meting op een fysiek toestel.

De controles voor de tijdmachinewereld slagen op iPhone 18 Pro en iPad (A16), beide met iOS 27. De Debug-testbuild en de Release-simulatorbuild (arm64 en x86_64) slagen eveneens. `git diff --check` is schoon.

## Vergelijkende scrollmeting

De oorspronkelijke en aangepaste versie zijn achtereenvolgens op dezelfde aparte iPhone 18 Pro-simulator met iOS 27 gemeten, in Debug. Iedere gemeten herhaling bevat zes snelle vegen omlaag door de kaart vanaf level 51 en zes terug. Er zijn drie gemeten herhalingen per versie; een positiecontrole bevestigt dat wereld 8 wordt bereikt.

| Metriek | Oorspronkelijk | Aangepast |
| --- | ---: | ---: |
| Gemiddeld fysiek appgeheugen | 259,7 MB | 171,7 MB |
| Piek fysiek appgeheugen | 262,3 MB | 174,5 MB |
| CPU-tijd | 14,548 s | 14,815 s |
| Scroll-/uitloopinterval | 2,572 s | 2,561 s |

Het gemiddelde appgeheugen is in deze proef 33,9% lager, de piek 33,5%. De CPU-tijd is ongeveer gelijk (+1,8%, binnen de spreiding van deze korte proef); er wordt geen CPU- of FPS-winst geclaimd. Het doel van de wijziging is de grote opbouw van verre decorlagen te spreiden en minder maskers tegelijk vast te houden. `XCTHitchMetric` wordt op iOS 26 en hoger aangevraagd, maar deze simulator retourneert daarvoor geen meetwaarden. Er is dus geen afzonderlijke gemeten hitch- of FPS-score.

De [ruwe meetreeksen en pixelcontrole](MapScrollMeasurements.json) leggen beide versies en de begrenzing van deze vergelijking vast.
