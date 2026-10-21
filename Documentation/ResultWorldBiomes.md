# Landschappen op de eindschermen — 20 oktober 2026

De eindschermen gebruikten, behalve de woestijn, dezelfde heuvels, palmen, grasmat en brede junglebladeren met een ander kleurpalet. Het terrein volgt nu het landschap van de wereld. De bestaande jungle en de eigen woestijntekening blijven behouden.

| Wereld | Achtergrond en terrein | Podium en details eromheen |
| --- | --- | --- |
| 1 · Dino Jungle | Bestaande zonnige heuvels, palmen, gras, bladeren en varens | Natuursteen, mos en jungleplanten |
| 2 · Woestijn | Bestaande zandduinen en droge woestijndecoratie | Droge zandsteen en woestijnbegroeiing |
| 3 · Vulkaanland | Vulkanen met kraters, rook, lavastromen, basaltzuilen en vonken | Donker basalt met warme breuklijnen en rotsen; geen jungleplanten of mos |
| 4 · Klokdorp | Huisjes, pannendaken, klokkentoren, beek en bestrating | Warme steen met mos, bloembakken en bloemen |
| 5 · Kristalgrot | Rotswanden, stalactieten, kristallen en een ondergrondse poel | Koel kwarts met kristalnaden en losse kristalgroepen |
| 6 · Klokstad | Skyline, raamgevels, klokkentoren, straatlampen en plein | Blauwgroen metaal met klinknagels, randen en lampen |
| 7 · Slaapvallei | Nachtlucht, maan, sterren, wilgen, beek en lichtgevende paddenstoelen | Koele steen met mos, wilgen en paddenstoelen |
| 8 · Tijdmachine | Lichtende ringen, tandwielen, leidingen en metalen vloer | Messing met klinknagels en tandwielen |
| 9 · Tijdpiraten | Zee, zeilschip, eiland, branding, zand en palmen | Gelaagde zandsteen met schelpen en verweerd hout |
| 10 · Tijdkasteel | Kasteelmuren, kantelen, torens, blauwe banieren en binnenplaats | Licht kalksteen met voegen, steenblokken en banieren |

## Implementatie

`ResultBiomePainter` in `Dino/Views/ResultWorldScenery.swift` tekent de acht nieuwe omgevingen, de decoratie achter en voor het podium en de details op het podium. Alle vormen blijven native SwiftUI/Canvas-paden. Er zijn geen rasterassets toegevoegd en er is geen permanente achtergrondanimatie.

`ResultScenery`, `ResultRockPlanting` en `ResultStonePainter` in `Dino/Views/LevelResult.swift` kiezen het landschap, de decoratie en het materiaal op basis van `DinoWorld.themeID`. Daardoor blijven de omgewisselde woestijn en Slaapvallei correct gekoppeld. Mos verschijnt uitsluitend bij jungle, Slaapvallei en dorp. Het wereldbord behoudt zijn eigen bestaande materiaal en versiering.

De gedeelde layout blijft verantwoordelijk voor Dino's voetpositie, het podium, de score, sterren, trofee en de bediening. De nieuwe decoratie gebruikt dezelfde podiumcoördinaten en staat achter de beloningen. De afzonderlijke decors ontvangen geen aanrakingen en blijven verborgen voor VoiceOver.

## Controle

`testAllWorldResultScenery` opent alle tien werelden met dezelfde drie sterren, controleert de score en de bereikbaarheid van de drie knoppen en bewaart per wereld een screenshot. De bestaande `testResultRewardStatesAndNavigation` controleert nul tot drie sterren, opnieuw spelen, verdergaan, terug naar de kaart en boss-resultaten.

De definitieve testuitslagen en visuele beoordeling worden hieronder vastgelegd na de simulatorcontrole.
