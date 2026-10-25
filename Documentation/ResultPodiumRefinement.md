# Wereldpodiums na een level — 23 oktober 2026

De rots onder Dino had voor vrijwel alle werelden dezelfde omtrek en facetten. De nieuwe podiumtekeningen geven elke wereld een eigen constructie, oppervlak, zijversiering en aansluiting op de grond. Het goud van de beloningssterren blijft het centrale aandachtspunt.

| Wereld | Podium | Afwerking en aansluiting |
| --- | --- | --- |
| 1 · Dino Jungle | Zacht belichte natuursteen met grote minerale vlakken | Moskussens, hangende ranken, kleine bladeren, kiezels en de bestaande volle junglebeplanting |
| 2 · Woestijn | Door wind afgesleten zandsteen met gebogen sedimentlagen | Ingesloten ammonietfossielen, droge sprieten, zandkleurige rotsen en fijne windribbels |
| 3 · Vulkaanland | Hoekig basalt met afzonderlijke zuilvlakken | Gloeiende breuken aan de randen, basaltgroepen en warme lichtreflecties |
| 4 · Klokdorp | Gemetseld tuinpodium met afgeronde steenblokken, kroonlijst en trede | Terracotta bloembakken, madeliefachtige bloemen, mos en een dorpslantaarn |
| 5 · Kristalgrot | Geslepen kwarts met eigen hoekige omtrek en doorschijnend ogende facetten | Paarse en turquoise kristallen, heldere facetnaden en kleine mineraalsplinters |
| 6 · Klokstad | Getrapt blauwgroen metaal met een gebogen gevel | Verzonken ventilatiepanelen, art-decoranden, klinknagels, gekalibreerde bovenring en straatlantaarns |
| 7 · Slaapvallei | Koele, zacht belichte steen met rustige facetten | Ingegraveerde sterrenbeelden, koel mos, lichtgevende paddenstoelen en kleine vuurvliegjes |
| 8 · Tijdmachine | Messing machineplateau met gelaagde metaalranden | Instrumenten, leidingen, tandwielen, schroeven, turquoise lichtnaden en kalibratiestrepen |
| 9 · Tijdpiraten | Gelaagde kuststeen met een houten dek als bovenvlak | Planknaden, spijkers, touw met knopen, meerpalen, schelpen en zandsporen |
| 10 · Tijdkasteel | Gehouwen kalkstenen sokkel met kroonlijst, voegen en brede voet | Blauwe banieren met gouden kronen, koninklijke standaarden en losse steenblokken |

De volgende verfijning op 24 oktober houdt de volledige sterren vrij binnen een rustig podiumdisplay en verbindt de wereldlandschappen verder. Zie [Vrije sterruimte en verbonden eindlandschappen](ResultSceneUnity.md) voor de actuele indeling en controles.

De actuele versie heeft compactere stenen, relatief grotere sterren en doorlopend materiaal zonder afzonderlijk voorpaneel. [Huidige verhoudingen en controles](ResultStoneProportions.md).

## Compositie en uitvoering

`ResultWorldPodium.swift` bevat de wereldpaletten, de afzonderlijke podiumgeometrie en de decoratie. `ResultWorldPodium` tekent in 1000 × 455 eenheden. `ResultPodiumSurround` gebruikt dezelfde oorsprong, met extra ruimte rond de sokkel. De achterversiering, het lichaam, Dino en de lage voorversiering zijn afzonderlijke lagen. Dat houdt de ornamenten naast de sterren en laat de onderste details de sokkel aan het terrein verbinden.

De bestaande `ResultLayout` blijft de voeten, bovenkant en sterren samen positioneren. Dino's doorlopende sprong, salto, pirouette en de onthulling van de sterren gebruiken hun bestaande ankers. De beloning heeft dezelfde afmetingen en toegankelijkheidslabels. De gloed achter Dino, de glinsteringen en de contactschaduw volgen nu het wereldmateriaal. De gloed is zachter, zodat het landschap beter zichtbaar blijft.

De wereldselectie volgt `DinoWorld.themeID`: de Woestijn is wereld 2 / thema 7 en Slaapvallei wereld 7 / thema 2. Alle vormen, oppervlakken en ornamenten zijn native Canvas-paden met deterministische details. Er zijn geen rasterassets, externe bronnen of permanente animatielussen toegevoegd. De gedeelde oude rots en de vervangen podiumversiering zijn verwijderd; de moshelper voor het jungleterrein blijft beschikbaar.

## Controle

- Debug-testbuild: geslaagd.
- Bestaande corecontroles: **822.227 controles geslaagd**.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), beide iOS 26.5. Alle twintig wereldweergaven zijn vastgelegd en visueel bekeken op materiaal, voetpositie, laagvolgorde, sterren en ruimte rond de bediening.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, sterrenoverzicht, boss-resultaten en Engelse tekst.
- Kleine iPhone SE (3e generatie, iOS 26.1): jungle, Kristalgrot en Tijdmachine visueel gecontroleerd. Voeten, beloningen en knoppen blijven binnen de compositie; de zijornamenten raken de bediening niet.
- Drie UI-testuitvoeringen, nul fouten. `git diff --check` is schoon. De drie tijdelijke testsimulators zijn na afloop opgeruimd.

De eerste poging op reeds geopende simulators is afgebroken: een andere app verscheen op het gedeelde apparaat. De definitieve beelden en resultaten komen uitsluitend van afzonderlijke tijdelijke testsimulators.

[Buildverslag](WorldTestLogs/ResultPodiumRefinement/build.log) · [Corecontroles](WorldTestLogs/ResultPodiumRefinement/core.log) · [iPhone](WorldTestLogs/ResultPodiumRefinement/iphone-worlds.log) · [iPad](WorldTestLogs/ResultPodiumRefinement/ipad.log).

## Beelden

[Alle tien podiums op iPhone](Screenshots/ResultPodiumRefinement/wereldpodiums-overzicht.jpg) · [Alle tien op iPad](Screenshots/ResultPodiumRefinement/ipad-podiums-overzicht.jpg) · [Nul tot drie sterren](Screenshots/ResultPodiumRefinement/beloningsstaten.jpg).

[Kleine iPhone: jungle](Screenshots/ResultPodiumRefinement/compact/world-01.png) · [Kristalgrot](Screenshots/ResultPodiumRefinement/compact/world-05.png) · [Tijdmachine](Screenshots/ResultPodiumRefinement/compact/world-08.png) · [Verslag kleine iPhone](WorldTestLogs/ResultPodiumRefinement/compact.log).
