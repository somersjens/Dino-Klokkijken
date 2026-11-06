# Kleinere download zonder ander uiterlijk

Onderzoek en metingen op 4 november 2026, met Xcode 27.0 (27A266a).

## Aanpassingen

- Alleen het app-target in **Release** gebruikt nu `SWIFT_OPTIMIZATION_LEVEL = -Osize`. Whole-module-compilatie blijft aan. Debug behoudt zijn bestaande instellingen.
- Alleen Release gebruikt `ASSETCATALOG_COMPILER_OPTIMIZATION = space`. Xcode kiest daarmee compactere opslag voor de catalogus. Alle 63 gamebeelden hebben in de gecompileerde catalogus dezelfde metadata, resolutie en pixelhash als voorheen; alleen de opslagcompressie van de zes icoonvarianten verandert van LZFSE naar ZIP. De oorspronkelijke PNG-bestanden blijven ongewijzigd.
- `TimeZoneMap.json` gebruikt kortere, equivalente getalnotatie. Dezelfde Swift `JSONDecoder` als in de app levert voor alle **30.687 getallen exact dezelfde 64-bits Double-waarden** op. Landcodes, volgorde, aantallen en kaartgeometrie blijven gelijk. Het bestand gaat van 539.189 naar 255.828 bytes.

Er zijn geen schermen, teksten, functies, animatieframes, kleuren of beeldresoluties aangepast. De bestaande offline werking blijft behouden.

## Meting

De vergelijking gebruikt twee lokale, ongesigneerde Release-builds voor **fysieke iOS-apparaten, arm64**, met dezelfde SDK en deployment target iOS 16. De oorspronkelijke app is vóór het opnieuw bouwen apart bewaard. MB betekent 1.000.000 bytes.

| Onderdeel | Voor | Na | Besparing |
| --- | ---: | ---: | ---: |
| Appbundel na verwijderen van symbolen | 39,238 MB | 38,008 MB | **1,230 MB (3,13%)** |
| Executable na verwijderen van symbolen | 7,096 MB | 6,299 MB | 0,797 MB (11,23%) |
| Gecompileerde assetcatalogus | 31,461 MB | 31,312 MB | 0,150 MB |
| Kaartgegevens | 0,539 MB | 0,256 MB | 0,283 MB |
| Lokale ZIP na verwijderen van symbolen | 34,499 MB | 34,028 MB | **0,470 MB (1,36%)** |

Voor deze vergelijking zijn beide executables op aparte kopieën gestript met `xcrun strip -D`, dezelfde opdracht als in het bestaande Xcode-archiveringslog. Daarmee tellen ontwikkelsymbolen niet mee als downloadwinst. De oorspronkelijke ongestripte builds zijn respectievelijk 52.686.664 en 52.052.479 bytes; hun lokale ZIP's zijn 36.029.574 en 35.647.238 bytes. De gestript vergeleken bundles zijn exact **39.237.760 → 38.007.991 bytes**, met ZIP's van **34.498.629 → 34.028.269 bytes**.

`Tools/report-app-size.py` rapporteert de totale bestandsgrootte, executable, assetcatalogus, kaartgegevens en een reproduceerbare lokale ZIP-vergelijking:

```sh
python3 Tools/report-app-size.py \
  '.build/size-before/Dino Time.app' \
  '.build/size-audit/Build/Products/Release-iphoneos/Dino Time.app'
```

De ZIP gebruikt vaste timestamps, bestandsvolgorde en compressieniveau 9. Het script schrijft geen IPA en publiceert niets.

De metingen, de gecompileerde catalogusinventarissen en de oorspronkelijke appkopie staan lokaal onder `.build/size-*`. Deze gegenereerde bestanden worden niet aan de app toegevoegd.

**Dit is geen exacte App Store-downloadmeting.** Apple past onder andere app thinning en distributieverwerking toe. Gebruik voor de definitieve downloadgrootte per toestel App Store Connect, of exporteer een gesigneerd archief met `thinning = <thin-for-all-variants>` en lees `App Thinning Size Report.txt`. De lokale ZIP is uitsluitend een vergelijkingsmaat.

## Controles

- Release voor fysieke iOS-apparaten bouwt succesvol met de nieuwe instellingen.
- De volledige bestaande core-suite slaagt: **1.648.086 controles** voor onder meer spelregels, opslag, sociale voortgang, privacygrenzen en offline synchronisatie.
- Alle **63 gecompileerde gamebeelden** hebben dezelfde hashes en metadata als in de oorspronkelijke catalogus.
- De renderbenchmark geeft voor vijf dinoposes met zowel de standaardkleuren als persoonlijke kleuren **tien identieke pixelhashes** bij `-O` en `-Osize`.
- De kaartcontrole decodeert beide bestanden met Swift `JSONDecoder` en vergelijkt alle 30.687 Double-bitpatronen, landcodes en geneste arraylengtes.
- Op **iPhone 18 Pro, iOS 27.0** slagen `testMapScrollPerformance` en `testTimeZoneAtlasCapitalsAndAnswerReveal`. De kaarttest controleert hele uren, kwartieren en vijfminuten, inclusief voorbeelden, kaartanimaties en het onthullen van antwoorden. Ook de extra herhaling van de scrolltest slaagt.

### Scrollmeting en meetvariatie

De simulatorruns gebruiken Release, arm64 en dezelfde iPhone. Alleen voor de bestaande testfixtures is via de opdrachtregel `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG` toegevoegd. De referentierun forceert `SWIFT_OPTIMIZATION_LEVEL=-O` en lege assetoptimalisatie; de nieuwe runs gebruiken de nieuwe Release-instellingen. Dit wijzigt geen projectinstellingen voor de uiteindelijke app.

| Gemiddelde over drie iteraties | Referentie | Nieuwe build | Herhaling nieuwe build |
| --- | ---: | ---: | ---: |
| Scrollsignpostduur | 2,588 s | 2,637 s | 2,663 s |
| CPU-tijd per reeks | 6,644 s | 7,481 s | 7,783 s |
| CPU-cycli | 28,382 miljard | 27,972 miljard | 26,318 miljard |
| Uitgevoerde CPU-instructies | 67,522 miljard | 59,342 miljard | 58,716 miljard |
| Gemeten piek fysiek geheugen | 265,599 MB | 357,529 MB | 201,275 MB |

De eerste nieuwe run liet meer geheugengebruik zien; daarom is uitsluitend die scrolltest herhaald. De herhaling heeft juist een lagere piek dan de referentie. Er is dus geen blijvende geheugentoename aangetoond. De scrollsignpostduur verschilt maximaal 2,90%. CPU-tijd en geheugen variëren tussen simulatorruns; deze metingen bewijzen geen identieke snelheid op fysieke apparaten. Het aantal CPU-cycli en instructies neemt in beide nieuwe runs af.

De afzonderlijke renderbenchmark is twaalfmaal per compilatiestand uitgevoerd, met afwisselende volgorde. De mediaan voor tien renders is 0,330 s met `-O` en 0,317 s met `-Osize`; alle pixelhashes blijven gelijk. Deze microbenchmark is een aanvullende controle, geen voorspelling van volledige spelprestaties.

De succesvolle simulatortests staan in `.build/size-ui-before-final.xcresult`, `.build/size-ui-after.xcresult` en `.build/size-ui-repeat.xcresult`. Simulatorproducten staan onder `/tmp/dino-size-ui-products-20261104`, omdat de Desktop-fileprovider Finder-metadata aan tijdelijke appbundels toevoegde en daardoor eerdere pogingen vóór de tests bij codesigning blokkeerde.

## Overige onderzochte mogelijkheden

- De eerdere grote assetopruiming is al uitgevoerd; zie [AssetOptimization.md](AssetOptimization.md). Ontwerpbeelden, screenshots, testlogs en `.build` worden niet als appresources gebundeld. Opruimen daarvan maakt de gebruikersdownload niet kleiner.
- De drie icoon-PNG's zijn identiek. Een proef met één gedeeld bronbestand behoudt echter alle zes gecompileerde varianten en bespaart geen relevante bundelruimte; deze wijziging is niet overgenomen.
- De app gebruikt geen externe Swift-packages of grote meegeleverde audio- of videobestanden die verwijderd kunnen worden.
- Dead-code stripping, optimalisatie over de hele module en het strippen van distributiesymbolen waren al actief. De afzonderlijke dSYM blijft beschikbaar voor crashanalyse.
- Verliesgevende beeldcompressie, lagere resoluties, het verwijderen van Swift-reflectiemetadata en achteraf downloaden van spelbeelden zijn niet toegepast. Die kunnen respectievelijk het beeld, SwiftUI-gedrag of de offline spelervaring veranderen.

## Bronnen

- [Apple: Reducing your app's size](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size) — onderscheid tussen lokale bundles, distributie en downloadgrootte; rapportage per toestelvariant.
- [Apple: Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference) — Swift Optimize for Size (`-Osize`), stripping en reflectiemetadata.
- De bij Xcode 27.0 geleverde `AssetCatalogCompiler.xcspec` beschrijft `space` als optimalisatie voor een kleinere gecompileerde assetcatalogus. De daadwerkelijk gemaakte catalogi zijn apart vergeleken.
