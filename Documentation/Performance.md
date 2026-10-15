# Performanceanalyse en optimalisaties

Datum: 15 oktober 2026.

Doel: minder werk tijdens scrollen, menu-overgangen, starten, pauzeren en antwoordanimaties, met behoud van de bestaande interface, tekeningen, kleuren, spelregels en animatieduur.

## Bevindingen en uitgevoerde wijzigingen

| Onderdeel | Oorspronkelijke kosten | Uitgevoerde verbetering |
| --- | --- | --- |
| Wereldkaart | De gewone `VStack` bevatte alle tien grote landschapcanvassen, ook ver buiten beeld. | Alleen landschappen binnen twee schermhoogten van het zichtbare scherm worden opgebouwd, met minimaal 1.200 punten voorbereiding aan beide kanten. Verre canvassen worden vrijgegeven. |
| Overgangen boven de kaart | Nieuwe viewwaarden en closures konden ook statische tekeningen opnieuw laten evalueren. | Landschappen, wereldborden en routepaden hebben expliciete waarde-equivalentie. Ongewijzigde tekeningen kunnen blijven staan tijdens profiel- en menu-updates. |
| Kaartindeling | Elk hoofdstuk mat een al vaststaande bordhoogte en wijzigde daarna de landschapoffset. Dat kon een tweede tekenronde veroorzaken. | Dezelfde offset wordt direct berekend uit de bestaande vaste hoogte en marges. Dino's huidige level en de wereldvoltooiing worden eenmaal per hoofdstuk berekend. Een routepad wordt eenmaal opgebouwd voor zijn vier penseelstreken. |
| Analoge klokken | Iedere klok had zestig losse SwiftUI-markeringen die deelnamen aan layout en updates. | Dezelfde markeringen worden samen in één Canvas getekend. Hun tekenview is onafhankelijk van de wijzers en wordt alleen bij andere maten, markeerkleuren of contrast bijgewerkt. Cijfers, wijzers, interacties en toegankelijkheid blijven bestaan. |
| Slepen aan wijzers | Meerdere aanrakingen binnen dezelfde afgeronde minuut of hetzelfde uur konden dezelfde waarden opnieuw publiceren. | Identieke afgeronde waarden worden bij het gebaar afgevangen. De sessie publiceert alleen werkelijk gewijzigde invoervelden. |
| Dino inkleuren | Per ingekleurde pixel ontstonden tijdelijke arrays voor RGB-kanalen en werd opnieuw door de lijst lichaamsdelen gezocht. | Vaste tuples vervangen de arrays. Een directe enumselectie en vooraf berekende kleurvergelijkingen vervangen herhaald zoekwerk. Het kleurrekenwerk en de afbeeldingsresolutie zijn gelijk gebleven. |
| Dino voorbereiden | Kaart, startkaart en game konden ieder dezelfde reeks poses laden en inkleuren. Een alleen op `NSCache` steunende animatie kon na verdringing opnieuw werk krijgen. | Eén gedeelde loader combineert verzoeken voor dezelfde kleuren. Een nieuwe kleurselectie annuleert de oude voorbereiding. De actuele spriteverzameling blijft beschikbaar en elk zichtbaar personage houdt zijn voorbereide beelden vast. Tijdens de animatie verandert alleen pose en transformatie. |
| Avatars | Ook een al gerenderde avatar deed eerst een globale cachelookup. | De lokale afbeelding met precies dezelfde sleutel wordt direct hergebruikt. De bestaande eerste-renderfallback blijft behouden om verkeerd gekleurde flitsen te voorkomen. |
| Klokvoorbeelden in menu's | Analoge/digitale voorbeelden en de vier lettertypevoorbeelden werden elke seconde bijgewerkt, hoewel ze uitsluitend uren en minuten tonen. | Updates volgen nu exact de minuutgrens. Dat vermindert de geplande updates per voorbeeld van zestig naar één per minuut. |
| Voorbeelden afsluiten | Een reeds bekend voorbeeld kon opnieuw een identiek profiel opslaan, publiceren en vervolgwerk veroorzaken. | De profielmutatie vergelijkt het resultaat voordat er wordt gepubliceerd of opgeslagen. |
| iCloud tijdens personalisatie | Iedere profielwijziging, inclusief uitsluitend lokale Dino- en klokkleuren, startte de synchronisatieroutine met cloudreads. | De subscription vergelijkt het daadwerkelijke voortgangspayload. Alleen gewijzigde gedeelde voortgang start deze route. Expliciete sync, instellingen, voorgrond/achtergrond en externe cloudmeldingen blijven werken. |
| Antwoordgeluid | Bij ieder antwoord werden de audiocategorie en een nieuwe `AVAudioPlayer` voorbereid. | De twee korte tonen hebben herbruikbare spelers, worden bij het openen van de game voorbereid en starten opnieuw vanaf nul. De bestaande volume-instelling, stille modus en het afbreken van een vorige toon blijven behouden. Haptiek wordt eveneens voorbereid. |
| Niet-actieve app | Een nog lopende sprite-timeline kon updates aanvragen terwijl de app niet actief was. | De timeline pauzeert bij een niet-actieve scene. De bestaande limiet van zestig updates per seconde en de ondersteuning voor Minder beweging blijven behouden. |

### Waarom de kaart geen LazyVStack heeft gekregen

De game gebruikt echte, geneste levelankers om direct naar Dino te scrollen, ook bij een opgeslagen level in wereld 9 of 10. Alle levelrijen behouden daarom hun bestaande layout en toegankelijkheid. Alleen de decoratieve achtergrond wordt begrensd. Dit voorkomt dat een snelheidsverbetering het herstellen van de kaartpositie, het HUD-thema of levelbediening verstoort.

De zichtbaarheid wordt als een boolean gemeten in de bestaande viewportcoördinaten. Daardoor verandert de lokale toestand alleen bij het binnenkomen of verlaten van de ruime voorbereidingszone. Er wordt geen scrolloffset naar de volledige schermboom gepubliceerd en er is geen extra timer. De verborgen landschappen blijven hun bestaande effen grondkleur als achtergrond houden; hun afmetingen veranderen niet.

### Wat behouden is

- Alle bestaande wereldillustraties, levelposities, klokmaten, kleuren en teksten.
- De overgangen van 0,24 seconde bij levelstart en resultaat en de pauzekaartanimatie.
- De juiste-antwoordvertraging van 0,72 seconde, handmatige vervolgknoppen en herkansingsregels.
- De doorgaande Dino tussen game en resultaat, inclusief salto, schaduw en eindpose.
- Direct lokaal bewaren van personalisatie en oefenresultaten. Opslag is niet vertraagd of afhankelijk gemaakt van het sluiten van een menu.
- De bestaande ondersteuning voor hoog contrast, Minder beweging, talen en iPad-oriëntaties.

## Gemeten spriteverwerking

De oorspronkelijke en aangepaste `DinoSpriteColorRenderer` zijn apart gecompileerd met `swiftc -O` en gevoed met dezelfde zeven PNG-bronnen op hun bestaande renderresolutie. Elke variant is drie keer uitgevoerd met standaardkleuren en met blauw/paars/roze/oranje. Onderstaande waarden zijn de medianen van de totale verwerkingstijd voor zeven beelden; afbeelding lezen en SHA-256 berekenen vallen buiten het gemeten deel.

| Kleurset | Oorspronkelijk | Aangepast | Minder verwerkingstijd |
| --- | ---: | ---: | ---: |
| Standaard | 256,5 ms | 172,3 ms | 32,8% |
| Gepersonaliseerd | 252,2 ms | 168,4 ms | 33,2% |

De SHA-256-hashes van alle veertien gerenderde pixelbuffers zijn gelijk tussen de oude en nieuwe renderer. Deze optimalisatie verandert dus geen pixels. Dit is een geoptimaliseerde macOS-meting van de gedeelde rendercode, geen FPS-meting op een iPhone.

Herhalen vanuit de projectmap:

```sh
zsh Tools/benchmark-dino-rendering.sh
```

De uitvoer bevat per pose en kleurset de verwerkingstijd en de pixelhash. De totaaltijden kunnen per machine, belasting en temperatuur verschillen.

## Vergelijkende scrollmeting

Dezelfde `testMapScrollPerformance` is uitgevoerd tegen een aparte kopie van de oorspronkelijke code en tegen de aangepaste app, op dezelfde iPhone 18 Pro-simulator met iOS 27 en een Debug-build. Elke meting heeft drie gemeten herhalingen van vier snelle vegen omhoog en vier omlaag, na de opwarming van XCTest. Het startprofiel, de random seed en de gebaren zijn gelijk.

| Metriek, gemiddelde over drie herhalingen | Oorspronkelijk | Aangepast | Verschil |
| --- | ---: | ---: | ---: |
| CPU-tijd van de app | 6,741 s | 6,511 s | −3,4% |
| Absoluut fysiek appgeheugen | 156,0 MB | 150,2 MB | −3,7% |
| Piek fysiek appgeheugen | 160,9 MB | 152,2 MB | −5,4% |
| Totale testbewerking inclusief UI-automatisering | 25,027 s | 24,430 s | −2,4% |
| Gemeten scrollanimatie-interval | 2,706 s | 2,733 s | +1,0% |

De appkosten zijn in deze proef lager. De totale testduur bevat wachttijd en automatisering; het animatie-interval is de duur van dezelfde gebaren en uitloop. Geen van beide is een FPS-meting. De kleine verschillen in scrollduur zijn geen bewijs voor een gewijzigde animatiesnelheid. Er is geen kunstmatige vertraging verkort om een betere score te krijgen. De geheugenwaarden meten het appproces, niet alle geheugenallocaties van de simulator en compositor.

De ruwe reeksen, pixelhashes en referentiecommit staan in [PerformanceMeasurements.json](PerformanceMeasurements.json). Dit is één vergelijkende simulatorsessie met drie herhalingen per variant; vooral kleine verschillen moeten als indicatie worden gelezen.

De bestaande oefenmenutest, die het menu opent, drie keer omhoog en omlaag scrolt en weer sluit, meet gemiddeld 17,309 s vóór en 16,940 s na de wijziging (drie herhalingen). Dit is circa 2,1% korter voor de hele geautomatiseerde handeling, inclusief wachttijden. Het is geen afzonderlijke meting van de openingsanimatie.

## Functionele en schermcontroles

`Tools/test-dino.sh` slaagt met **437.244 controles**. De vijf extra controles dekken dubbele invoerpublicaties, ongewijzigde profielpublicaties en het ontbreken van cloudreads/sync/writes bij alleen lokale personalisatie. De bestaande regressiecontroles blijven de klokberekeningen, uurovergangen, vragen, scoring, opslag, oefenrecords en cloudmerge/reset controleren.

De oorspronkelijke simulatorbuild is geslaagd. De vijf geselecteerde bestaande iPhone-schermtests zijn vóór de wijzigingen geslaagd: personalisatie met live klokpagina's, HUD-thema tijdens scrollen vanuit level 90, doorgaande Dino bij levelstart/resultaat, oefenen openen/scrollen en pauzeren/hervatten/verlaten.

De aangepaste Debug-simulatorbuild en de Release-simulatorbuild zijn geslaagd. Op iPad (A16), iOS 27, slagen de drie geselecteerde schermtests: live personalisatie, proportionele HUD en schermoriëntaties, en starten/pauzeren/hervatten/verlaten. Xcode bleef bij deze iPad-run na de geslaagde tests hangen in het afronden van de resultaatbundel; dat proces is gestopt. Voor deze drie uitslagen is de volledige testuitvoer gebruikt, niet de onafgeronde `.xcresult`-bundel.

Op iPhone 17 met iOS 26.5 slaagt `testContextualHUDAndFirstQuestionExit`, inclusief oefenen en instellingen openen/sluiten, voorbeeld tonen/sluiten, een eerste vraag verlaten, en een latere vraag pauzeren/hervatten/verlaten.

Op iPhone 18 Pro met iOS 27 slagen **alle zes geselecteerde schermtests, zonder fouten**:

- `testHeaderPersonalizerHasLiveClockPages`: kleuren en klokstijlen, tabwissels, sluiten/heropenen en live aanpassen tijdens een vraag.
- `testHUDThemeFollowsScrollInsteadOfPlayerLevel`: herstel bij level 90 en terugscrollen door wereldgrenzen met behoud van het juiste HUD-thema.
- `testMapScrollPerformance`: herhaalde snelle scrollbewegingen met CPU-, geheugen- en animatie-intervalmetingen.
- `testPlayCardAndContinuousResultDino`: gepersonaliseerde Dino, startkaart naar game, antwoorden en één doorgaande salto op het resultaat.
- `testPracticeOpenAndScrollPerformance`: herhaald openen, scrollen en sluiten van het oefenmenu.
- `testStartPointCleanCardAndExitCancel`: gecentreerde klok/Dino, pauzekaart, hervatten met dezelfde vraag en definitief verlaten.

Samen zijn dit tien geslaagde schermtestgevallen voor de aangepaste app, verdeeld over iPhone en iPad en iOS 26.5/27. Voor de oorspronkelijke code zijn daarnaast de vijf bestaande iPhone-tests en de nieuwe vergelijkende scrolltest uitgevoerd.

De kaart is daarnaast vóór en na de wijziging vastgelegd op dezelfde iPhone 17-simulator met iOS 26.5. Het spelgedeelte bij het herstelde level 90 is pixelidentiek, inclusief de overgang naar wereld 10. Op de beginpagina is de achtergrond identiek en zit het resterende verschil in de HUD-rendering: maximaal vier van 255 kleurstappen, met gemiddeld 0,019 kleurstap per kanaal over het spelgedeelte. Beide beelden zijn ook visueel gecontroleerd. De statusbalk met systeemtijd is buiten deze pixelvergelijking gehouden. De vier beelden staan lokaal in de genegeerde map `Documentation/Screenshots/Performance`.

### Interpretatie van framerate

Een animatie op zestig frames per seconde heeft ongeveer 16,7 ms per frame beschikbaar. De wijzigingen verminderen vooral werk dat tijdens een overgang op diezelfde tijd concurreert: inkleuren, dubbele audiovoorbereiding, achtergrondcanvassen en overbodige viewpublicaties. De bestaande animatiesnelheden zijn niet verhoogd.

Simulatorresultaten tonen regressies en relatieve kosten. Ze bewijzen geen constante framerate op ieder toestel. Voor een harde beoordeling op een fysiek toestel moet dezelfde Release-build met Instruments Animation Hitches en Time Profiler worden gecontroleerd bij koud starten, snel kaartscrollen, personalisatie, starten/pauzeren/hervatten en een volledige bossuitslag. Meet daarbij ook na meerdere minuten spelen, met het daadwerkelijke verversingstempo van het toestel. De huidige spriteanimatie blijft bewust begrensd op zestig updates per seconde.

## Git en testbeelden

De **459 eerder gevolgde screenshots** in `Documentation/Screenshots` vertegenwoordigen **720.962.325 bytes**, ongeveer **687,6 MiB** aan bronbestanden. Ze zijn met `git rm --cached` uit de index gehaald. De bestanden en submappen blijven lokaal aanwezig.

`.gitignore` sluit screenshotmappen en `test-screenshots` op iedere mapdiepte uit, evenals lokale buildmappen, `.xcresult`-bundels en `.DS_Store`. Nieuwe testbeelden worden daardoor niet opnieuw toegevoegd bij normale `git add`/sync. Ontwerpconcepten in `Documentation/WorldConcepts`, de game-assets en de geschreven verificatieverslagen blijven gevolgd.

Dit maakt toekomstige commits en synchronisaties lichter. De bestaande Git-geschiedenis behoudt haar oude afbeeldingen en de huidige `.git`-map krimpt hierdoor niet onmiddellijk. Er is geen geschiedenis herschreven. Historische screenshotlinks verwijzen voortaan naar lokaal bewaarde beelden; een nieuwe checkout heeft deze beelden niet automatisch.
