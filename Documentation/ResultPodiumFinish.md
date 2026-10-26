# Doorlopende steencontouren en dragende voeten — 26 oktober 2026

Dit verslag beschrijft de tussenstap met brede natuurstenen voeten. De verdere afwerking per wereld herstelt onder meer de ronde woestijnsteen, voegt de houten piratenkist toe en verplaatst mos, sterren en versiering. [Huidige uitvoering en controles](ResultThemeDetails.md).

De afgeronde stenen krulden aan de onderzijde naar binnen. Losse rotsen of zandvlakjes rond de hoeken konden die overhang niet oplossen. Bovendien dekte het kleinere bovenvlak de linkerschouder van de woestijnsteen niet volledig, waardoor daar een donkere driehoek zichtbaar bleef.

De natuurstenen hebben nu een contour die tot aan de grond doorloopt, met een brede, vrijwel vlakke voet. De kap en de buitencontour gebruiken exact hetzelfde kroonpad, inclusief beide schouders. Sedimentlagen en minerale facetten lopen door tot in de voet. De afzonderlijke zandheuveltjes en achterliggende woestijnrotsen zijn verwijderd.

De contactschaduw volgt de werkelijke onderrand van elke steen, inclusief de zijhoeken. De vroegere schaduw onder alleen het midden en de schaduw rond het hele zwevende silhouet zijn vervangen. De ondergrond gebruikt de voorste voetpositie van het betreffende thema. Planten, kristallen en schelpen staan op hun bijbehorende grondlijn.

| Wereld | Afwerking en visuele controle |
| --- | --- |
| 1 · Jungle | Doorlopende natuurstenen voet met uitlopende facetten; bladwortels en bloemen verplaatst naar de voet; graspollen volgen de grondcontour. |
| 2 · Woestijn | Eén zandsteenplateau met afgeronde kroon en brede voet; geen bruine schouderdriehoek of losse hoekvormen; alle sedimentlagen lopen door tot in de voet. |
| 3 · Vulkaanland | Basaltkap sluit exact aan op de linkercontour; de contactschaduw volgt de hoekige zuilvoet; breuklijnen en basaltgroepen blijven verbonden. |
| 4 · Klokdorp | Bovenvlak volgt de gemetselde sokkel; afgeschuinde trede en gevoegde voet zijn over de volledige breedte uitgewerkt, inclusief de zijkanten. |
| 5 · Kristalgrot | Brede, gefacetteerde kwartsvoet met doorlopende facetnaden; bovenvlak sluit op de schouder aan; kristalgroepen en splinters wortelen aan de nieuwe voet. |
| 6 · Klokstad | Gebogen metaaldek, bovenrand en voet gebruiken hetzelfde perspectief; de volledige verbrede voet krijgt materiaal en een doorlopende onderrand. |
| 7 · Slaapvallei | Koele natuursteen met brede, doorlopende voet; de bladeren en paddenstoelen sluiten op die nieuwe grondlijn aan. |
| 8 · Tijdmachine | Messing dek, gebogen randen en verbrede voet sluiten op elkaar aan; turquoise naden volgen diezelfde randen. |
| 9 · Tijdpiraten | Doorlopende kuststenen voet onder het houten dek; meerpalen staan buiten de voet met zichtbare schachten en grondcontact; schelpen volgen de nieuwe grondlijn. |
| 10 · Tijdkasteel | Gehouwen bovenvlak volgt de sokkel; een volledige, gevoegde voet en afgeschuinde trede sluiten aan op de binnenplaats. |

De contouren en materialen staan in `Dino/Views/ResultWorldPodium.swift`, de terreinpositie in `ResultWorldScenery.swift` en de junglewortels in `LevelResult.swift`. De logische tekenruimte en bestaande ankers voor Dino en de sterren blijven behouden. De natuurstenen voet loopt onderaan door tot circa y=476; `ResultPodiumGeometry.groundFrontY` koppelt de achtergrond aan die werkelijke voetpositie. De materiaalkeuze volgt `themeID`, inclusief de omgewisselde woestijn en Slaapvallei. De tekeningen blijven native Canvas-paden.

## Verificatie

- Debug-build voor tests: geslaagd.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), beide iOS 26.5. Alle twintig scènes visueel beoordeeld op kap, zijranden, voet, decoratie, grondcontact en sterruimte.
- Alle tien thema’s aanvullend op iPhone zonder gouden sterren vastgelegd en bekeken, zodat het volledige materiaal en de hoeken zichtbaar blijven. De woestijnschouders en beide voetuiteinden zijn ook op volledige resolutie bekeken.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, sterrenoverzicht en eindbaasresultaten.
- Eigen iPhone SE (3e generatie, iOS 26.5): jungle, woestijn, Kristalgrot, Slaapvallei en Tijdpiraten zonder gouden sterren bekeken. De woestijn ook met één, twee en drie gouden sterren bekeken. De bredere voeten blijven binnen de compositie en boven de bediening.
- Drie bestaande UI-tests uitgevoerd, nul fouten. `git diff --check` is schoon. De drie eigen testsimulators zijn na afloop verwijderd.

[Buildverslag](WorldTestLogs/ResultGroundedStone/build.log) · [iPhone-test](WorldTestLogs/ResultGroundedStone/iphone.log) · [iPad-tests](WorldTestLogs/ResultGroundedStone/ipad.log).

## Beelden

[Nieuwe woestijnsteen op volledige resolutie](Screenshots/ResultGroundedStone/woestijn-detail.png) · [Vergelijking van de contouren](Screenshots/ResultGroundedStone/woestijn-vergelijking.jpg) · [Alle tien stenen op iPhone](Screenshots/ResultGroundedStone/podiums-iphone.jpg) · [Alle tien op iPad](Screenshots/ResultGroundedStone/podiums-ipad.jpg) · [Alle materialen zonder gouden sterren](Screenshots/ResultGroundedStone/materialen-zonder-goud.jpg) · [Kleine iPhone](Screenshots/ResultGroundedStone/compact-overzicht.jpg).
