# Scrollen krijgt voorrang op decoranimatie

**Deels teruggedraaid na iPhone-feedback.** De snelheidsafhankelijke 10Hz-modus en bijbehorende gebaarwaarnemer zijn verwijderd. Het onderscheid tussen voorbereiding en zichtbaarheid blijft behouden. Hieronder staat de historische proef, niet het huidige scrollgedrag. Zie [het vervolgonderzoek op iPhone](IPhoneSmallScrollCorrection.md).

1 november 2026. Vervolg op de geometrie- en cacheverbeteringen uit de eerdere performanceanalyse.

De eenvoudige uitstraling van de kaart betekent niet dat de uitvoering weinig werk doet. De kaart heeft veel losse water-, dier-, klok-, trein- en lichtlagen met eigen tekenupdates. Deze verfijning beperkt hun terugkerende werk tijdens het bewegen van de kaart.

## Aangepast gedrag

- Bij afzonderlijke water-, dier-, licht- en eindbaaskloklagen is de tickzone verkleind tot het zichtbare scherm. De bestaande voorbereidingszone blijft bestaan: de laag kan vóór de schermrand worden opgebouwd, terwijl de animatieklok pas voor zichtbare lagen terugkerende updates aanvraagt.
- Bij een veegsnelheid van minstens 700 schermpunten per seconde krijgen de decoratieve timelines tijdelijk maximaal tien updates per seconde. Hun gebruikelijke frequenties van 15, 20, 24, 30 en 60 blijven gelden wanneer de kaart rustig is.
- Onder 250 punten per seconde keert de normale frequentie na 0,2 seconde terug. Zodra slepen en uitrollen helemaal stoppen, wordt die meteen hersteld. De verschillende grenzen voorkomen heen-en-weer schakelen tijdens vertragen.
- Water, treinen en klokwijzers blijven bewegen. Hun tijd volgt nog steeds de gedeelde epoch; alleen de bemonstering is tijdens snel scrollen grover. Er is geen blijvende verlaging van snelheid, resolutie of detailniveau.
- De openingsanimatie, Dino's wereldsprong en de spelinteractie gebruiken deze decoratieve begrenzing niet.

Een gewone laag met twintig updates per seconde vraagt in de snelle modus maximaal tien updates aan; voor de metro gaat het van zestig naar tien. Dit beschrijft de ingestelde bovengrens van de updates, niet een gemeten winst in framerate of totale CPU-belasting.

## Implementatie

`DinoMapScrollBudget` bewaakt de drempels en het herstel. Een kleine native probe observeert de bestaande panherkenner zonder de delegate van SwiftUI te vervangen. Alleen tijdens een gebaar en het uitrollen controleert een displaylink op vijftien Hz de snelheid. Hij stopt zodra de kaart stilstaat.

Scrolloffsets blijven lokaal in de probe. Alleen omschakelingen tussen de normale en beperkte modus worden aan SwiftUI doorgegeven. De twintig decoratieve timelines lezen deze modus via de environment. Een gedeelde zichtbaarheidscontrole scheidt voorbereiding van doorlopende animatieupdates. De vaste landschapafbeeldingen, levelankers en scrollposities behouden hun bestaande gedrag.

## Controle

`zsh Tools/test-dino.sh --map-viewport` slaagt met **115 controles**. De nieuwe gevallen dekken beide scrollrichtingen, snelheidsdrempels, hysterese, einde van een gebaar, herstel van alle oorspronkelijke frequenties en het onderscheid tussen voorbereiding en zichtbaarheid.

De Debug-testbuild en de Release-simulatorbuild voor arm64 slagen.

De vergelijkende proef `testCityScrollRenderingBudgetPerformance` gebruikt dezelfde iOS 27-simulator, hetzelfde startprofiel bij wereld 6 en dezelfde gebaren. Na de XCTest-opwarming volgen drie gemeten herhalingen met twee snelle vegen omlaag door de kaart en twee terug. CPU-tijd, piekgeheugen en scrollinterval worden afzonderlijk gemeten. De oorspronkelijke variant is vóór de broncodewijziging gebouwd en uitgevoerd; de aangepaste variant wordt na het afronden van beide builds gemeten.

De afzonderlijke UI-controle `testMapScrollBudgetRestoresAfterFastGesture` controleert dat een echte snelle veeg de modus activeert en dat de normale frequentie na het uitrollen terugkomt. Een alleen in testbuilds toegankelijke teller bewaart de activatie, zodat XCTest die ook kan zien nadat zijn eigen wachttijd op een stilstaande app voorbij is.

Deze wijziging vermindert terugkerend tekenwerk tijdens scrollen. Een eerste, koude landschaprasterisatie op de hoofdthread kan nog steeds een onderbreking veroorzaken. Een constante 60/120 fps op een fysiek toestel wordt hiermee niet zonder toestelmeting geclaimd.

## Resultaten

Alle drie de geselecteerde UI-tests slagen: de stadsroute, de vergelijkende scrollproef en het activeren en herstellen van de decorfrequentie na een echte snelle veeg.

| Gemiddelde, drie gemeten herhalingen | Voor | Na |
| --- | ---: | ---: |
| CPU-tijd app | 4,808 s | 4,868 s |
| Absoluut fysiek appgeheugen | 213,8 MB | 188,0 MB |
| Piek fysiek appgeheugen | 215,5 MB | 190,2 MB |
| Scroll-/uitloopinterval | 2,668 s | 2,630 s |

Het gemiddelde appgeheugen is in deze proef ongeveer 12,1% lager, het piekgeheugen 11,7%. De totale CPU-tijd is ongeveer gelijk (+1,2%, binnen de spreiding van deze korte proef). Er wordt geen CPU-winst of bepaalde FPS geclaimd. De kortere intervalduur is evenmin een FPS-meting.

De vaste tekeningen en de stadsroute zijn na het herstellen van de animatiefrequentie visueel gecontroleerd. De ruwe meetreeksen staan in [ScrollAnimationBudgetMeasurements.json](ScrollAnimationBudgetMeasurements.json); de lokale logs zijn `.build/scroll-budget-baseline.log` en `.build/scroll-budget-verified.log`.
