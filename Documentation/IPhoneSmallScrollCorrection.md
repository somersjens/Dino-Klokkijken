# Kleine scrollbewegingen op iPhone

**Huidige uitkomst:** op de aangesloten iPhone zijn vaste grot-, kust-, rots- en scheepsberekeningen gedeeld en naar de bestaande achtergrondvoorbereiding verplaatst. In de koude vergelijkingsproef met twaalf snelle vegen per richting daalde de native scrollteller van **63 naar 25 haperingen** en de hitchratio van **402,6 naar 142,5 ms/s**. De langste callbackpauze bleef circa **261 ms**. Dit is één gemeten koude iteratie per variant en geen bewijs dat alle scrollhaperingen weg zijn. De decoruitstelproef is wegens slechtere resultaten verwijderd. De gewone Release-app is gebouwd en op de telefoon geïnstalleerd.

Onderzoek van 1–2 november 2026. De gebruiker meldt haperingen bij iedere kleine beweging. Het probleem is nog niet als opgelost aangetoond. De eerdere warme simulatorproef met minder CPU-tijd was onvoldoende om deze ervaring te beoordelen.

## Teruggedraaide proeven

Gedeelde steenafbeeldingen en de centrale rasterplanner zijn verwijderd na de iPhone-feedback. Levelstenen gebruiken weer hun oorspronkelijke SwiftUI-tekening; de volledige cirkel blijft aanklikbaar. Ook de snelheidsafhankelijke decorfrequentie en de gebaarwaarnemer zijn verwijderd. Animaties gebruiken weer hun gewone frequentie en tijd.

Twee aanvullende vergelijkingen met korte, langzame heen-en-weerbewegingen leverden geen verbetering op:

| Simulatorproef, drie gemeten herhalingen | Oorspronkelijk | Experiment |
| --- | ---: | ---: |
| Decor pauzeren: CPU-tijd app | 8,325 s | 8,230 s |
| Decor pauzeren: grootste scrollcallbackpauze | 252,0 ms | 316,4 ms |
| Layoutcache en minder Dino-ankers: CPU-tijd app | 8,240 s | 9,725 s |
| Layoutcache en minder Dino-ankers: grootste scrollcallbackpauze | 236,2 ms | 280,2 ms |

Beide experimenten zijn teruggedraaid. De gewone layoutmeting en Dino-ankers zijn hersteld. De lokale logs zijn `.build/gentle-scroll-verified.log` en `.build/map-layout-verified.log`. De maximale callbackpauze is een diagnose van de hoofdthread, geen GPU-framerate. Een warm CPU-gemiddelde kan korte, voelbare haperingen verbergen.

De eerder aangebrachte geometriecaches, samengevoegde landschapaanvragen en behoud van voorbereide hoofdstukken bij korte scrollomkeringen blijven aanwezig. Voorbereiding buiten beeld en daadwerkelijk zichtbare animatie zijn nog steeds afzonderlijk begrensd.

## Toestel en build

De aangesloten fysieke iPhone is een iPhone 17 Pro met iOS 26.6.1. In de eerdere Time Profiler-opname stond `Dino Time.debug.dylib` in de appstack. Dit past bij de Debug-uitvoerindeling die [Apple beschrijft](https://developer.apple.com/documentation/xcode/understanding-build-product-layout-changes); de projectinstelling voor Debug is `-Onone`.

Die opname duurde ongeveer 21,7 seconden en bevatte slechts tien CPU-steekproeven, samen circa 10 ms. Dit was vrijwel inactiviteit, geen gemeten scrollroute. Er wordt daarom geen scrollhotspot of bewezen oorzaak uit afgeleid.

Het extra schema **Dino Klokkijken Performance** start Release zonder debugger; het normale schema blijft beschikbaar voor ontwikkeling. TestAction blijft Debug zodat bestaande testfixtures hun eigen opslag gebruiken. Een apart geoptimaliseerd toesteltestproces moet dezelfde fixtures gebruiken om het buildverschil eerlijk te vergelijken.

`CADisableMinimumFrameDurationOnPhone` staat op `true`. Volgens [Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/cadisableminimumframedurationonphone) maakt dat hogere verversingsfrequenties op ondersteunde iPhones mogelijk; het garandeert geen 120 fps. Het daadwerkelijke teken- en scrollbudget moet op het toestel worden gemeten.

## Controle vóór de nieuwe toestelmeting

- Gerichte coreproef `zsh Tools/test-dino.sh --map-viewport`: 97 controles geslaagd in de vorige sessie.
- Herstelde kaart: UI-test voor het volledige raakvlak en UI-test voor de wereldsprong naar level 61 geslaagd. Log: `.build/map-rollback-verified.log`.
- De UI-performanceproef `testGentleMapScrollPerformance` voert kleine, langzame bewegingen uit en registreert CPU/geheugen afzonderlijk. De optionele callbackprobe meet alleen tijdens slepen/uitrollen, zodat de openingsanimatie en stilstand de scrollwaarde niet bepalen.

De huidige vervolgstap is die vaste route op de aangesloten iPhone uitvoeren en vervolgens een geoptimaliseerde variant vergelijken. Resultaten worden hieronder toegevoegd zodra de toestelruns werkelijk voltooid zijn. Geen toestelwinst wordt vooruitlopend daarop geclaimd.

## Eerste actieve toestelmeting op 2 november

Na het toestaan van UI-automatisering slaagde de vaste kleine-scrolltest op de iPhone. De Debug-run registreerde 56,5 ms als grootste scrollcallbackpauze. De drie CPU-metingen waren 8,461 / 9,230 / 6,446 seconden. Deze run overlapte met Time Profiler en dient als diagnose, niet als zuivere procentuele vergelijking.

De actieve Time Profiler-opname bevatte 28.067 CPU-steekproeven van 1 ms, waarvan 27.407 op de hoofdthread. Ongeveer 12.456 steekproeven zaten in XCTest-toegankelijkheidssnapshots: automatisering veroorzaakt zelf aanzienlijk werk. Die kosten mogen niet als normale gebruikersbelasting worden gepresenteerd.

Daarnaast zaten 10.505 steekproeven in de Canvas-tekening van de mijnwerkermaskers (`CrystalCaveLife`), waarvan 9.495 in `timberClearances`. Per frame werden voor tientallen mineraalbedden dezelfde vaste houtconstructies en klokgrenzen opnieuw geplaatst. Dit was zichtbaar bij de grot/stadovergang, terwijl de proef bij wereld 6 begon. De inclusieve stackaantallen overlappen; ze worden niet bij elkaar opgeteld.

De nieuwe aanpassing deelt deze exacte hout- en klokgrenzen via een begrensde cache van acht scene-afmetingen. De sleutel bevat breedte, hoogte, routeoffset en junglemodus. De oorspronkelijke plaatsingsformules blijven aanwezig. Wereld 5 bereidt het plan mee voor op de bestaande achtergrondroute. De cache bevat uitsluitend onveranderlijke rechthoeken; de bewegende mijnwerkers en hun dieptevolgorde blijven onafhankelijk tekenen.

Logs: `.build/iphone-gentle-debug-retry.log` en `.build/iphone-gentle-active-debug.trace`. Een eerste testpoging stopte vóór de test door het niet starten van UI-automatisering. De geoptimaliseerde vervolgmeting wachtte vervolgens op een opnieuw ontgrendelde telefoon. Voor de cacheaanpassing is nog geen toestelwinst geclaimd zolang de vergelijkende meting niet is afgerond.

## Verduidelijking van de gebruiker

De belangrijkste klacht betreft flinke vegen door meerdere werelden; heen-en-weer bewegen binnen een al geladen gebied lijkt goed te gaan. Daarom richt het vervolg zich op de eerste passage door alle tien werelden, niet op verdere verfijning van de warme kleine-bewegingentest.

De afgeronde geoptimaliseerde kleine-bewegingenproeven registreerden 5,685 s CPU vóór en 5,139 s na de grotcache; de maximale scrollcallbackpauze was respectievelijk 26,8 en 25,3 ms. Beide runs gebruikten dezelfde geoptimaliseerde appinstellingen met uitsluitend voor de test `DEBUG` ingeschakeld, een afzonderlijk profiel en drie gemeten herhalingen. Er draaide hierbij geen profiler op de telefoon. Dit is een beperkte warme route bij de grot/stadovergang en bewijst geen oplossing voor grote vegen.

Een aanvullende exacte uitvoervergelijking van de oorspronkelijke en aangepaste grotformules omvat 32 sceneconfiguraties (acht breedtes, twee hoogtes, twee routeoffsets). Alle 2.272 regels met houtgrenzen, mineraalposities en lampen zijn identiek; SHA-256 van beide: `2ef7edcf5abc0e92ddf552a307113ec145bda01b9022567ca38e1fe13764f04f`.

## Eerste koude passage door alle werelden

De geoptimaliseerde oorspronkelijke app slaagde voor `testColdScrollAcrossEveryWorld` op de fysieke iPhone. Deze proef start met een unieke lege landschapcache, bezoekt alle tien werelden en level 100 en veegt terug. De grootste callbackpauze was 219,1 ms, met eerste grotere waarden van 184,6 / 185,2 ms en later 191,3 ms. De probe in deze historische proef omvat ook stilstand en toegankelijkheidsmetingen; dit is geen zuivere telling van gemiste scrollframes.

De 90-secondenopname bevat 44.945 ms aan hoofdthreadsteekproeven. Daarvan liepen 21.523 ms via XCTest/toegankelijkheid. Buiten die stacks zijn SwiftUI-graphupdates, laagopbouw en rendertransacties prominent; onder meer 843 bladsteekproeven zaten in `CA::Layer::insert_sublayer`. De laatst gerapporteerde losse landschapcaptures bij de grootste pauzes duurden 12,4 / 8,8 / 14,1 ms. Die waarden meten alleen de afzonderlijke capture en schrijven de hele pauze niet aan die capture toe.

De volgende gerichte proef stelt het **voor het eerst opbouwen** van bewegende decor- en maskerbomen uit tot de scroll stilstaat. Bestaande bomen blijven tijdens het gebaar behouden. De vaste wereldafbeeldingen blijven vooruit laden. Op iOS 18 en nieuwer gebruikt dit alleen de native scrollfasewisselingen via [onScrollPhaseChange](https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:)); er komt geen per-frame snelheidswaarnemer bij. Eerdere iOS-versies behouden hun bestaande voorbereiding.

`testColdMultiWorldFlickPerformance` voert twaalf snelle vegen door meerdere werelden uit en twaalf terug. Iedere XCTest-iteratie herstart de app met een eigen leeg cachepad, ook de verworpen opwarmiteratie. Handmatig starten/stoppen van de meting sluit de openingsanimatie uit. Naast CPU/geheugen worden de native scroll/deceleratiemetriek en op iOS 26 [XCTHitchMetric](https://developer.apple.com/documentation/xctest/xcthitchmetric) vastgelegd. De callbackprobe registreert bij deze proef uitsluitend tijdens slepen/uitrollen.

De eerste versie van deze nieuwe proef had acht vegen: beide varianten bereikten het kasteel daarmee niet en faalden op de bereikbaarheidseis. Er zijn geen performanceconclusies aan die twee afgebroken runs verbonden. De route is verlengd tot twaalf vegen per richting.

## Resultaat van de koude vergelijking

| Meting op dezelfde iPhone, twaalf snelle vegen per richting | Oorspronkelijke geoptimaliseerde app | Grot- en kustcaches |
| --- | ---: | ---: |
| Native scrollhaperingen | 63 | 25 |
| Native scrollhitchratio | 402,6 ms/s | 142,5 ms/s |
| CPU-tijd binnen de meetperiode | 42,300 s | 39,834 s |
| Grootste scrollcallbackpauze in de gemeten iteratie | 261,7 ms | 260,5 ms |
| Grootste scrollcallbackpauze in de verworpen, eveneens koude opwarmiteratie | 217,8 ms | 236,6 ms |

Beide routes bereiken het kasteel en slagen functioneel. Dit is één gemeten iteratie met een aparte koude opwarmiteratie per variant; de percentages uit deze vergelijking zijn geen verwachting voor alle apparaten of veegbewegingen. Er draaide tijdens deze vergelijking geen Instruments-profiler op de telefoon. XCTest veroorzaakt wel extra toegankelijkheidswerk.

De aanvullende applicatiebrede `XCTHitchMetric` rapporteerde nul terwijl de native scrollsignposts wel haperingen detecteerden. Die nul wordt niet als bewijs van vloeiendheid gebruikt. Ook de frame-countcounter rapporteerde nul; de apart gerapporteerde FPS-waarde wordt daarom niet als framerategarantie gepresenteerd. De ruwe metriekwaarden staan in [IPhoneWorldFlickMeasurements.json](IPhoneWorldFlickMeasurements.json).

De afgewezen decoruitstelvariant mat 67 scrollhaperingen, 458,9 ms/s, 44,596 s CPU en 271,4 ms grootste callbackpauze in de gemeten iteratie. De fasewaarnemer, environmentwaarde en bijbehorende zichtbaarheidsschakeling zijn volledig verwijderd. Er is geen verlaging van de decorfrequentie, stilzetten van water of gewijzigde veegbesturing behouden.

De kustverbetering deelt vaste bouwwerken, steigers, rotsposities, kustpunten, waterpaden en scheepsplaatsingen. De meeuwensimulatie en waterlagen lezen hetzelfde onveranderlijke zeeplan. Wereld 9 bereidt dat plan mee op de bestaande achtergrondroute voor. Drie begrensde planverzamelingen (grotgrenzen, kustobjecten, zeegeometrie) bevatten ieder maximaal acht schermconfiguraties. Dit zijn geometrieplannen, geen extra volledige wereldafbeeldingen.

De exacte kustcontrole omvat dezelfde 32 schermconfiguraties en vergelijkt ook alle punten van de waterpaden. Alle **172.809 uitvoerregels** zijn gelijk; SHA-256 vóór en na: `824fff0003779a495e531c482e49b60fb6d7397743d506701449e8326cc995cc`. De statische tekeningen, botsingsgrenzen, routes en scheepsplaatsen volgen dezelfde formules.

## Gewone Release-app en handmatige opname

De gewone Release-build zonder testfixtures of debugger is gebouwd, ondertekend en met `devicectl` geïnstalleerd en geopend op de fysieke iPhone. Er is geen app verwijderd en de normale profielopslag is niet gereset. De gebruiker maakte daarna circa twintig seconden echte, grote vegen voor een gecombineerde Animation Hitches/Time Profiler-opname.

Bij deze opname bleef Instruments na de tijdslimiet hangen bij het afsluiten; een eerste export meldde dat de template nog ontbrak. Zolang het afsluiten niet voltooid is, worden deze handmatige gegevens niet als geldige meting gepresenteerd. De eerder afgeronde koude XCTest-vergelijking is afzonderlijk en blijft beschikbaar.
