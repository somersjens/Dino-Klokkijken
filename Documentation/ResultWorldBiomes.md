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

De podiums zijn op 23 oktober verder uitgewerkt met eigen silhouetten, constructies en materialen voor alle tien werelden. Zie [Wereldpodiums na een level](ResultPodiumRefinement.md) voor de huidige uitvoering en controles.

De verfijning van 24 oktober voegt vrije sterruimte en doorlopende oevers, terrassen, pleinen en bouwdelen toe. De grondafwerking volgt de werkelijke podiumpositie. [Actuele landschapssamenhang en sterruimte](ResultSceneUnity.md).

De huidige afwerking verwijdert de steruitsparingen en materiaalvervaging volledig. Voorgrondbladeren overlappen de steen, mos heeft een complete organische contour en de grond sluit zonder extra horizontale strook aan. Dit geldt voor alle tien werelden. [Doorlopend materiaal en natuurlijke lagen](ResultNaturalLayers.md).

## Implementatie

`ResultBiomePainter` in `Dino/Views/ResultWorldScenery.swift` tekent de acht nieuwe omgevingen. De huidige podiumtekeningen en decoratie staan in `Dino/Views/ResultWorldPodium.swift`. Alle vormen blijven native SwiftUI/Canvas-paden. Er zijn geen rasterassets toegevoegd en er is geen permanente achtergrondanimatie.

`ResultScenery` kiest het landschap op basis van `DinoWorld.themeID`; `ResultPodiumPalette` gebruikt dezelfde identiteit voor het podium en de bijbehorende decoratie. `ResultRockPlanting` verzorgt aanvullend de bestaande volle junglebeplanting. Daardoor blijven de omgewisselde woestijn en Slaapvallei correct gekoppeld. Mos verschijnt uitsluitend bij jungle, Slaapvallei en dorp. Het wereldbord behoudt zijn eigen bestaande materiaal en versiering.

De gedeelde layout blijft verantwoordelijk voor Dino's voetpositie, het podium, de score, sterren, trofee en de bediening. De nieuwe decoratie gebruikt dezelfde podiumcoördinaten en staat achter de beloningen. De afzonderlijke decors ontvangen geen aanrakingen en blijven verborgen voor VoiceOver.

## Controle

`testAllWorldResultScenery` opent alle tien werelden met dezelfde drie sterren, controleert de score en de bereikbaarheid van de drie knoppen en bewaart per wereld een screenshot. De bestaande `testResultRewardStatesAndNavigation` controleert nul tot drie sterren, opnieuw spelen, verdergaan, terug naar de kaart en boss-resultaten.

De definitieve controles van de doorontwikkelde podiums staan in [Wereldpodiums na een level](ResultPodiumRefinement.md): alle tien werelden zijn op iPhone en iPad vastgelegd en gecontroleerd, en de belonings- en navigatietest slaagt op iPad.
