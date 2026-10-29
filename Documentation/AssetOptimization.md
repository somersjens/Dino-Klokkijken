# Assetopruiming en behoud van beeldkwaliteit

Gecontroleerd op 27 oktober 2026. De actuele bestandsnamen, afmetingen, bestandsgroottes en verwijderde beelden staan in [AssetInventory.json](AssetInventory.json).

## Gemeten grootte

| Onderdeel | Voor | Na | Besparing |
| --- | ---: | ---: | ---: |
| Bronbestanden in `Assets.xcassets` | 132,34 MB | 29,66 MB | 77,6% |
| Gecompileerde assetcatalogus (`Assets.car`) | 105,44 MB | 26,26 MB | 75,1% |
| Volledige Release-app voor de simulator | 143,28 MB | 64,02 MB | 55,3% |

MB is hier 1.000.000 bytes. Beide builds gebruiken hetzelfde project, Release, dezelfde SDK en beide simulatorarchitecturen (arm64 en x86_64), zonder signing. Dit meet de lokale appbundel; de App Store-download en een apparaatbuild hebben een andere grootte. Ontwerpreferenties, screenshots en video's onder `Documentation` worden niet in de app gebundeld.

## Opgeruimde beelden

Van de 119 image sets zijn er 56 verwijderd. Over blijven 63 gebruikte image sets, plus het appicoon en de twee bestaande kleurassets. Het gaat om oude duimen- en foutreacties, de eerdere struikelreeks, ongebruikte saltoframes, vijftien vervangen antwoordtekeningen, oude uitslagachtergronden, het podium, de steen en het bord, een screenshot, een trailericoon en de ongebruikte launchklok.

De eerste en laatste klapexports waren identiek. Die twee bestanden vervallen allebei: `DinoCharacter` tekende daar al de gewone idle-dino. Ook de ongebruikte eerste valtekening vervalt; de val begint in dezelfde idle-pose. De tijden en bewegingen blijven gelijk. Alleen voor oude afbeeldingen gebruikte kleurmaskers, kleurkalibraties en preloadverwijzingen zijn mee verwijderd.

## Namen en resoluties

| Namen | Gebruik | Resolutie |
| --- | --- | ---: |
| `dino-idle` | Grote openingsdino, personalisatie, HUD en kaart | 1254 × 1254 |
| `dino-opening-jump-01…08` | Acht poses van de openingssprong, ook bij één ster | 1254 × 1254 |
| `dino-answer-clap-01…06` | Twee klappen na een goed antwoord | 768 × 768 |
| `dino-answer-wrong` | Hoofdschudden na een fout antwoord | 768 × 768 |
| `dino-result-backflip-{crouch,airborne,landing,recover}` | Salto bij drie sterren | 768 × 768 |
| `dino-result-pirouette-01…18` | Draai bij twee sterren, inclusief tussenposes | 768 × 768 |
| `dino-result-fall-02…10` | Vallen en opstaan bij nul sterren; pose 01 is idle | 768 × 768 |
| `dino-world-jump-{crouch,takeoff,airborne,landing,recover}` | Sprong naar een volgende wereld | 768 × 768 |
| `boss-{jungle,desert,volcano,clock-village,crystal-cave,clock-city,sleep-valley,time-machine,pirates,castle}` | Eindbazen en wereldpreviews | 640 × 640 |
| `reward-star` | Uitslag, kaart en sterrenoverzicht | 384 × 384 |
| `AppIcon/app-icon.png` | Appicoon | 1024 × 1024 |

Alle verwijzingen, ook dynamisch samengestelde animatienamen, kleurmaskers, lettergebieden, tests en de renderbenchmark, gebruiken de nieuwe namen. De bestaande Xcode-namen `AppIcon`, `AccentColor` en `LaunchBackground` blijven behouden.

## Kwaliteit op de grootste iPad

De opening is maximaal 580 punten breed; Dino neemt daarvan 102% in. Op een iPad met schaalfactor 2 zijn dat circa 1183 schermpixels. Alle negen grote beelden blijven daarom op 1254 pixels, inclusief hun oorspronkelijke pixels, transparantie en kleurprofiel. Er wordt geen JPEG-compressie of kleurenpaletreductie toegepast.

De overige dinotekeningen werden al vóór deze wijziging door `DinoSpriteColorRenderer` naar 768 pixels verkleind. Nu is dezelfde Core Graphics-verkleining vooraf uitgevoerd, met hoge interpolatiekwaliteit en sRGB. De resultaatdino is maximaal 360 punten breed: 720 schermpixels op de grote iPad, binnen het bestaande raster van 768 pixels. De 640 pixels voor eindbazen waren eveneens al het bestaande renderbudget. De ster is maximaal circa 119 punten breed; 384 pixels laat voldoende ruimte voor Retina-weergave en het verschijnen met een kleine vergroting.

De eindbaasklokken gebruiken nog steeds de oorspronkelijke ontwerpruimte van 1254 punten. Hun renderer rekent de bijgesneden 640-pixelafbeelding terug naar die ontwerpruimte, zodat wijzers, klokvlakken, vingers en banden op dezelfde plaatsen blijven.

Bij alle 54 verkleinde beelden is het opnieuw gedecodeerde resultaat vergeleken met dezelfde verkleining van het origineel. In de premultiplied sRGB-rasters is het maximale kanaalverschil **0 van 255**. Voor de ster is de vergelijking gemaakt op het nieuwe raster van 384 pixels; de overige 53 beelden gebruiken hun bestaande runtime-raster. Bij de negen grote openingsbeelden zijn alle oorspronkelijke pixels exact gelijk gebleven. De PNG's zijn daarna zonder pixelverlies opnieuw gecomprimeerd, met behoud van de relevante kleurmetadata.

## Verificatie

`testAssetCatalog` controleert alle werkelijk afgespeelde poses bij 120 samples per seconde, in normale modus en bij Minder beweging. Daar komen alle acht openingsposes, tien bazen en de ster bij. De controle vereist dat de catalogus precies die beelden bevat, dat elke preload wordt getoond en dat bestandsnamen, `Contents.json` en resoluties overeenkomen.

De volledige core-suite is geslaagd met **1.136.233 controles**. De bestaande regressietests controleren de animatievolgorde, voetregistratie, klapbewegingen, persoonlijke kleuren, transparantie en leesbare bandanaletters. De afzonderlijke 384-pixelthumbnailcontrole laat één extra 8-bits toonstap toe voor het opnieuw verkleinen van een reeds verkleind bronbeeld; de bestaande kleurtolerantie op het werkelijke raster van 768 pixels blijft gelijk. Voor verkleinde poses wordt de voetregistratie binnen één pixel van het werkelijke raster van 768 pixels gecontroleerd; de grote opening behoudt de grens van één pixel op 1254 pixels.

Alle **zes geselecteerde UI-tests zijn geslaagd** op de iPad Pro 13-inch (M5), iOS 27.0, met een schermresolutie van 2064 × 2752 pixels, inclusief de opening in landschap, alle tien bazen, de gepersonaliseerde éénstersprong, de pirouette, de salto en het vallen en opstaan.

Eerdere ontwerpverslagen onder `Documentation` kunnen historische assetnamen bevatten. Deze inventaris en de broncode beschrijven de actuele catalogus.
