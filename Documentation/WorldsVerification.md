# Tien werelden — verificatie

De game bevat honderd levels. Wereld 2 t/m 10 zijn getekend met native SwiftUI-paden, shapes en Canvas, in dezelfde vormtaal en met dezelfde levelafstand als de bestaande jungle. De negen ImageGen-beelden in [WorldConcepts](WorldConcepts) dienen uitsluitend als inspiratie en maken geen deel uit van de app-assets.

De verdere uitwerking van 13 oktober voegt ook de junglewachter toe en vervangt alle bazen door gedetailleerdere karakters met gedragen klokken. Zie [de tien bazen en hun nieuwe verificatie](BossRefinementVerification.md).

## Implementatie

- [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift) bevat de jungle, `ThemedWorldLandscape` en `WorldThemePreview`. [WorldBossArt.swift](../Dino/Views/WorldBossArt.swift) tekent de tien eindbazen met hun gedragen klokken. Decor gebruikt afgeronde volumes, kleurvlakken, schaduwen en highlights. Klokken worden met berekende wijzerstanden getekend.
- [WorldMap.swift](../Dino/Views/WorldMap.swift) gebruikt hetzelfde slingerpad en dezelfde levelknoppen voor alle werelden. De dino blijft de bestaande losse sprite. Boss-previews en previews van de volgende wereld gebruiken Canvas.
- [LevelConfiguration.swift](../Dino/Core/LevelConfiguration.swift) deelt levels 1–100 op in tien blokken met elk negen normale levels en één boss. Minuutstappen en vraagtypes volgen het wereldthema.
- Na een wereldvoltooiing opent de knop voor de volgende wereld het eerste level daarvan. Na level 100 staat Coming soon; level 101 bestaat niet.
- Wereldvoortgang, sterren en gemeten tijden ondersteunen alle honderd levels. Bestaande jungleprofielen blijven leesbaar. De perfecte boss-route en de normale route worden per wereld beoordeeld. Reset en optionele iCloud-sync behandelen alle werelden.

## Controles

- `Tools/test-dino.sh`: **361.179 controles geslaagd**. Getest zijn onder meer beide boss-routes in alle werelden, honderd levelconfiguraties, minuutbereik, unieke antwoordkeuzes, klokparen, tijdsduur, ontgrendeling, lokale opslag, herstart en cloud-merge/reset.
- Xcode `build-for-testing`: geslaagd voor de iOS-simulator.
- iPhone 18 Pro en iPad Air 13-inch, iOS 27: elke nieuwe wereld geopend, het eerste level gestart en één vraag correct beantwoord. Levelknoppen zijn minimaal 44 punten breed en komen onder de vaste header in beeld.
- Op beide apparaten staat Coming soon zichtbaar onder de boss van level 100. Er is geen level 101 en geen oude Coming soon-preview na level 10.
- Op iPhone is de junglebaas met 10/10 gewonnen, Slaapvallei via de voltooiingskaart gestart en een halve-urenvraag correct beantwoord. Na herstart blijft de junglevoortgang behouden. De voltooiingskaart toont de volgende wereld als getekende preview.
- Geen verwijzingen naar de concept-PNGs in `Dino`, de assetcatalogus of het Xcode-project. De conceptbestanden worden niet in de app gebundeld.

UI-tests gebruiken uitsluitend een aparte debug-opslag en vaste random seed. De wereldfixture markeert voorgaande bosses als perfect gewonnen, zodat alle hoofdstukken afzonderlijk kunnen worden gecontroleerd zonder gebruikersvoortgang te wijzigen.

## Verdere uitwerking van de kaarten

De nieuwe werelden hebben negen grotere scènes langs de buitenkant van de bochten, aangevuld met kleinere scènes aan de andere rand. Gebouwen, planten, rotsen en voorwerpen delen een ondergrond, zachte slagschaduwen en licht van linksboven. De boss-snelkoppelingen volgen nu dezelfde kaartvorm als de jungle, met een eigen themakleur. De kaartdino krijgt in alle hoofdstukken dezelfde grondschaduw.

- Slaapvallei: treurwilgen, vijvertjes, oevers, paddenstoelen, nachtelijke bloemen en lichtpuntjes.
- Vulkaanland: rotsfacetten, basalt, lavagloed, breuklijnen en verschillende vulkaan- en poelscènes.
- Dino Dorp: dakpannen, schoorstenen, kozijnen, deurknoppen, tuinhekjes, fruitbomen, fonteinen en straatjes.
- Kristalgrot: rotswanden, gelaagde kristallen, mineraalglans en kleine kristalsplinters.
- Dino Stad: terrassen, verlichte ramen, tramrails, bankjes, plantenbakken, lantaarns en zijstraten.
- Dag-en-nachtbos: bomen met takken en bladaccenten, ondergroei, bloemen en een overgang naar nachtkleuren.
- Tijdmachine: portaalspiralen, tandwielen met open middens, koperen buizen, werkbanken, bouten en zandlopers.
- Tijdpiraten: kustlijnen, steigers met houtnerf, schatkisten, schelpen, scheepstuig en klokken op de zeilen.
- Dinokasteel: metselwerk, banieren, vlaggen, muurtjes, tuinen, grachten en toegangsstraatjes.

Alle eindbazen hebben aanvullende materiaal- en kostuumdetails, zoals tenen, schubben, veren, klinknagels, vleugeladers, riemen en kroonstenen. De bestaande groene hoofddino met zijn rode `12:34`-bandana blijft dezelfde sprite.

[Overzicht van de native boss-previews](Screenshots/WorldsRefined/worlds-detail-overview.png). De [volledige Canvas-exports](Screenshots/WorldsRefined) laten de omgevingsshapes zonder levelinterface zien. Dit zijn renders van de SwiftUI-code voor visuele controle; ze worden niet als achtergrondafbeeldingen in de app gebruikt.

Na de verdere uitwerking is de [simulatorbuild](WorldTestLogs/refined-build.log) opnieuw geslaagd. Op zowel [iPhone](WorldTestLogs/refined-iphone.log) als [iPad](WorldTestLogs/refined-ipad.log) zijn de twee wereldtests opnieuw uitgevoerd: iedere nieuwe wereld openen en een vraag beantwoorden, plus Coming soon na level 100. Beide testsuites melden **twee tests zonder fouten**. Alle onderstaande screenshots zijn met de verfijnde kaarten vernieuwd.

Xcode bleef op beide apparaten na de geslaagde tests hangen bij het afsluiten van het resultaatrapport. Alleen de eigen Xcode-testprocessen zijn gestopt nadat de screenshots en logs waren bewaard. De testsuites zijn geslaagd; het afsluiten van de Xcode-rapportage is niet succesvol afgerond. De eerdere [iPhone-run](WorldTestLogs/iphone.log), inclusief junglevoltooiing en herstartcontrole, is eveneens bewaard.

## Screenshots

De screenshots tonen de daadwerkelijke shape-kaarten, niet de conceptbeelden.

| Wereld | iPhone | iPad |
| --- | --- | --- |
| 2 — Slaapvallei | [kaart](Screenshots/Worlds/native-world-2-iphone.png) | [kaart](Screenshots/Worlds/native-world-2-ipad.png) |
| 3 — Vulkaanland | [kaart](Screenshots/Worlds/native-world-3-iphone.png) | [kaart](Screenshots/Worlds/native-world-3-ipad.png) |
| 4 — Dino Dorp | [kaart](Screenshots/Worlds/native-world-4-iphone.png) | [kaart](Screenshots/Worlds/native-world-4-ipad.png) |
| 5 — Kristalgrot | [kaart](Screenshots/Worlds/native-world-5-iphone.png) | [kaart](Screenshots/Worlds/native-world-5-ipad.png) |
| 6 — Dino Stad | [kaart](Screenshots/Worlds/native-world-6-iphone.png) | [kaart](Screenshots/Worlds/native-world-6-ipad.png) |
| 7 — Dag-en-nachtbos | [kaart](Screenshots/Worlds/native-world-7-iphone.png) | [kaart](Screenshots/Worlds/native-world-7-ipad.png) |
| 8 — Tijdmachine | [kaart](Screenshots/Worlds/native-world-8-iphone.png) | [kaart](Screenshots/Worlds/native-world-8-ipad.png) |
| 9 — Tijdpiraten | [kaart](Screenshots/Worlds/native-world-9-iphone.png) | [kaart](Screenshots/Worlds/native-world-9-ipad.png) |
| 10 — Dinokasteel | [kaart](Screenshots/Worlds/native-world-10-iphone.png) | [kaart](Screenshots/Worlds/native-world-10-ipad.png) |
| Na level 100 | [Coming soon](Screenshots/Worlds/native-world-10-coming-soon-iphone.png) | [Coming soon](Screenshots/Worlds/native-world-10-coming-soon-ipad.png) |

Voorbeeld van een halve-urenvraag: [iPhone](Screenshots/Worlds/native-world-2-question-iphone.png) en [iPad](Screenshots/Worlds/native-world-2-question-ipad.png).

## Game Center

De bestaande Game Center-leaderboards publiceren per-level resultaten voor Wereld 1. De algemene sterren- en levelscore tellen alle honderd levels mee. Resultaten van de overige werelden worden lokaal en via optionele iCloud-sync opgeslagen. Er worden geen ongeconfigureerde leaderboards voor levels 11–100 opgevraagd. Tests gebruiken nagebootste cloudopslag; live iCloud- en Game Center-uitwisseling zijn niet in deze simulatorcontrole getest.
