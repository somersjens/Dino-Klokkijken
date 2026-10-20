# Native levelbord per wereld

Het levelbord op het eindscherm wordt volledig getekend in `Dino/Views/ResultLevelSign.swift`. De app laadt het eerdere `result-sign`-beeld niet meer. Het oude asset blijft als vormreferentie bewaard.

## Vorm en plaatsing

De bestaande `ResultLayout` bepaalt dezelfde breedte, hoogte en bovenmarge. Het getekende bord gebruikt de 3:1-verhouding van de eerdere illustratie binnen dat kader. De brede, licht gebogen plank, afgeronde schouders en opgetrokken onderkant zijn overgenomen als paden. Ook de tekst blijft op dezelfde plek: lettergrootte `breedte × 0.1233`, horizontale marge `breedte × 0.19` en verticale verschuiving `hoogte × 0.01`.

De tekening bestaat uit een achterlaag met ornamenten, een paneel met materiaal en rand, de native leveltekst en een voorlaag met kleine details. De versiering blijft aan de uiteinden; het midden is vrij voor de titel.

## Uitwerking van randen en bevestigingen

De verbeterslag gebruikt het oorspronkelijke jungleconcept als leidraad. De buitenvorm, tekstmaten en plaatsing blijven behouden. De zijwand is in twee dieptelagen opgebouwd, met een afgeronde buitenlip, een verdiept voorvlak, licht over de schouders en een donkere onderrand. De houten varianten hebben honingkleurige planken, gebogen nerven, uitgesneden planknaden, houtknopen en kleine gebogen eindbarsten. De rand volgt de vorm van het bord; het is geen los rechthoekig kader.

Het junglebladwerk bestaat uit overlappende groepen die via stelen aan een doorlopende liaan groeien. Enkele bladeren vouwen vóór de houten hoeken, met een zachte contactschaduw, een lichtvangende rand, nerven en een donkerdere vouw. De jungle heeft inmiddels eigen bredere bladpaden voor de versiering van dichtbij; de andere bladwerelden gebruiken de fijnere gedeelde geometrie van de levelkaart.

Ook de kleine bladeren aan de achtergrondlianen naast het bord hebben een vaste aansluiting: hun wortelpunt wordt nu op dezelfde Bézier-kromme als de liaan berekend. Een losse schatting van de bladpositie veroorzaakte daar zichtbare gaten.

De andere werelden krijgen dezelfde zorg voor aansluitingen:

- De Slaapvallei heeft een bevestigd kettinkje voor de onderste ster en verbonden bladgroepen rond de manen.
- Basalt en kristallen delen een rotsbasis die achter het bord doorloopt. De vlammen staan in een kleine stenen houder.
- Vlaggenlijnen in Klokdorp hangen tussen zichtbare bevestigingen; korte stelen verbinden de onderste bladeren.
- Verhoogde eindplaten en klinknagels verbinden de gebouwen, tandwielen en buizen met het paneel. Tandwielen en klokjes hebben een dikkere zijwand en een uitgewerkte rand.
- Piratentouwen keren aan beide uiteinden terug naar het hout en eindigen in knopen bij het steenaccent en de schelp.
- Kasteelbanieren hangen aan een dwarsstang met bevestigingen en sluiten op de zijrand aan.

De bevestigingen en versiering delen per zijde dezelfde animatietransformatie. De bestaande instellingen voor kantelen, meebewegende zijkanten en accentlicht blijven beschikbaar.

## Verdere verfijning van de jungle- en kristalhoeken

De jungle gebruikt afzonderlijke composities voor links en rechts. De rechter groeiplaats ligt verder naar buiten, zodat de bladeren daadwerkelijk op de rechter schouder van het bord aansluiten. De bovenste steel kruist de houten rand niet meer. De bladeren hebben een vollere, gebogen buitenvorm, zachtere nerven, een apart belichte vouw en verschillende groentonen. De onderste bladwortels liggen direct op de zijrand. De eerdere verbindingslijntjes zijn verwijderd; de doorlopende liaan loopt achter het hout.

De houtvezels hebben verschillende lengtes en diktes. De grote golfvorm in de onderste plank is vervangen door een kortere eindnerf bij de zijkant; houtknopen staan op verschillende hoogtes. De materiaaldiepte eindigt in de eigen randkleur in plaats van de groene omgevingsschaduw, zodat de onderrand van het hout bruin blijft.

In de Kristalgrot is de losse diamant op het bovenvlak verwijderd. De bovenste kristallen groeien uit een gezamenlijke rotsbasis achter de rand. De onderste kristallen staan in een zichtbaar stenen voetstuk dat hun uiteinden bedekt. Een dunne mineraalader verbindt die basis met de rand; de eerdere losse siersteen en lange eindplaat zijn hier niet meer nodig. De prisma's hebben een topvlak, een zijvlak en subtiele reflecties. `accentGlow` blijft beschikbaar voor latere animatie; in rust wordt geen extra lichtvlek rondom de kristallen getekend.

## Wereldvarianten

De stijl volgt de stabiele `DinoWorld.themeID`. Wereldvolgorde en tekenstijl zijn daardoor losgekoppeld.

| Wereld | Materiaal en versiering |
| --- | --- |
| Dino Jungle | Warm hout, groene bladeren en lianen |
| Woestijn | Zandsteen, palmtakken en groene steenaccenten |
| Vulkaanland | Donkere basaltplaat, koperkleurige rand, lavanaden en kleine vlammen |
| Klokdorp | Licht eikenhout, dakjes en vlaggetjes |
| Kristalgrot | Koel mineraal, paarse kristallen en lichtaccenten |
| Klokstad | Geborsteld blauwgroen metaal, gebouwen, tandwielen en klinknagels |
| Slaapvallei | Lila maansteen, zilverblauwe bladeren, maantjes en sterren |
| Tijdmachine | Messing, tandwielen, buizen en kleine klokjes |
| Tijdpiraten | Verweerd hout, touw, schelpen en turquoise accenten |
| Tijdkasteel | Lichte steen, gouden rand, torentjes en blauwe banieren |

## Bord en achtergrond als gezamenlijke bovenrand

`DinoResultHeaderBackdrop` tekent de achtergrondhoeken met hetzelfde `ResultSignPalette` en dezelfde tekenhelpers als het bord. De oude, vaste junglebladeren en lianen zijn uit de landschapslaag verwijderd, zodat er geen tweede plantenrand meer door de bordversiering heen groeit.

De echte bordpositie wordt vanuit `ResultLayout` doorgegeven, inclusief de veilige schermranden. De begrenzingen van de getekende bladeren bepalen hoe hoog de achtergrondkroon komt. Zo kan een donkerder blad bewust achter een bordhoek lopen, terwijl de bordtekst en het materiaalvlak vrij blijven. De achtergrond gebruikt grotere vormen, zachtere kleuren en minder contrast dan de versiering op het bord. De dunne buitenlianen hebben bladwortels die op hun eigen kromme liggen.

- Jungle, Slaapvallei en Klokdorp hebben een bladkroon met de bladvorm en tinten van hun bord. De jungle deelt nu ook zijn gebogen bladsilhouet tussen voor- en achtergrond.
- Woestijn en Tijdpiraten hebben slankere palmtakken; bij de piraten volgt een bevestigd touw de bovenste tak.
- Vulkaanland heeft donkere rotsranden met lavanaden, de Kristalgrot een rotsgewelf met hangende kristallen en het Tijdkasteel een gehouwen stenen kader. Facetten, afgeschuinde binnenranden en contactschaduw geven deze hoeken volume.
- Klokstad en Tijdmachine hebben doorlopende metalen balken of buizen, met tandwielen en klinknagels op de aansluitingen.

De wereldidentiteit volgt de stabiele `themeID`. De plaatsing past zich aan de beschikbare ruimte aan: op een kleine iPhone blijft het bord het belangrijkste ornament; op iPad kunnen de grotere achtergrondvormen verder in de buitenste ruimte doorlopen. Voor een latere animatie is `windPhase` behouden; er is geen nieuwe permanente animatie toegevoegd.

## Animaties en aanpassen

`DinoResultSignPose` biedt vier onafhankelijk animeerbare waarden:

- `tilt`: kanteling van het hele bord inclusief de tekst.
- `leftSway` en `rightSway`: beweging van de linker- en rechterversiering rond hun eigen bevestigingspunt.
- `accentGlow`: lichtsterkte van de kristal- en lava-accenten.

`DinoResultLevelSign` interpoleert deze waarden via `AnimatablePair`. De standaardwaarden zijn nul; er is geen permanente timer of nieuwe automatische animatie. Bij **Verminder beweging** gebruikt het bord de ruststand. Materialen en kleuren staan in `ResultSignPalette`; de geometrie en wereldmotieven staan apart in `ResultSignPainter`.

De leveltekst behoudt zijn VoiceOver-label en de wereldnaam is toegevoegd als toegankelijke waarde.

## Previews

[Bord en achtergrond samen: jungle](Screenshots/ResultHeaderComposition/before-after-jungle.png) · [Kristalgrot](Screenshots/ResultHeaderComposition/before-after-crystal.png) · [Klokstad](Screenshots/ResultHeaderComposition/before-after-city.png) · [Alle bovenranden per wereld](Screenshots/ResultHeaderComposition/header-worlds.png).

[Nieuwe jungle en Kristalgrot voor en na](Screenshots/ResultSignCorners/before-after.png) · [Detail rechter junglehoek](Screenshots/ResultSignCorners/jungle-corner-detail.png) · [Laatste wereldborden](Screenshots/ResultSignCorners/level-sign-worlds.png).

Eerdere verbeterslag:

[Verfijnde wereldborden](Screenshots/NativeSignPolish/level-sign-worlds.png) · [Jungle voor en na](Screenshots/NativeSignPolish/before-after-jungle.png) · [Jungle op iPhone](Screenshots/NativeSignPolish/world-01.png) · [Kleine iPhone](Screenshots/NativeSignPolish/compact-world-01.png) · [iPad](Screenshots/NativeSignPolish/ipad-world-01.png).

Eerdere native uitvoering:

[Alle tien wereldborden](Screenshots/NativeResultSign/level-sign-worlds.png) · [Jungle](Screenshots/NativeResultSign/world-01.png) · [Woestijn](Screenshots/NativeResultSign/world-02.png) · [Level 100](Screenshots/NativeResultSign/world-10.png).

## Controle van de gezamenlijke bovenrand op 20 oktober 2026

- De Debug-testbuild slaagt met de wereldafhankelijke achtergrondhoeken en de verfijnde steenranden.
- Alle tien werelden zijn visueel gecontroleerd op een afzonderlijke iPhone 17-simulator (iOS 26.5). De controle omvat aansluitingen, laagvolgorde, titelruimte, kleur en samenhang tussen achtergrond en bord. Het Tijdkasteel is met `Level 100` vastgelegd.
- Jungle en Kristalgrot zijn daarnaast bekeken op iPhone SE 3e generatie (iOS 26.1) en iPad Pro 11-inch M5 (iOS 26.5). De kaderpositie volgt de echte bordpositie inclusief de veilige schermranden; score en bediening behouden hun bestaande plaats.
- De screenshots gebruiken afzonderlijke Debug-opslag. De drie eigen testsimulators zijn na afloop afgesloten en verwijderd. Dit is een visuele controle met een geslaagde testbuild; er is voor deze verfijning geen nieuwe geautomatiseerde UI-test uitgevoerd.
- `git diff --check` is schoon. Alle nieuwe vormen zijn native paden en verlopen; er zijn geen rasterassets toegevoegd.

[Buildverslag](WorldTestLogs/ResultHeaderComposition/build.log) · [Tien werelden](WorldTestLogs/ResultHeaderComposition/worlds.log) · [Laatste steenafwerking](WorldTestLogs/ResultHeaderComposition/stone-final.log) · [Kleine iPhone](WorldTestLogs/ResultHeaderComposition/compact.log) · [iPad](WorldTestLogs/ResultHeaderComposition/ipad.log).

## Controle van de verbeterslag op 19 oktober 2026

- De Debug-testbuild met de verfijnde bordtekening slaagt. De dubbele argumentlabels in de tekenhelpers zijn ook opgeruimd; het bordbestand levert geen compilerwaarschuwingen.
- Alle tien wereldborden zijn op een afzonderlijke iPhone 17-simulator (iOS 26.5) visueel gecontroleerd op diepte, randen, aansluitingen, volledige bladvormen en ruimte rond de titel.
- De jungle en `Level 100` zijn daarnaast op iPhone SE 3e generatie (iOS 26.1) en iPad Pro 11-inch M5 (iOS 26.5) bekeken. De leveltitel, de score eronder en de bediening blijven binnen hun bestaande kaders.
- De tekstmaten, toegankelijkheidslabels en animatie-instellingen zijn behouden. De tekening blijft volledig opgebouwd uit paden en verlopen; er zijn geen nieuwe rasterassets.
- `git diff --check` is schoon. De fixtures gebruiken afzonderlijke Debug-opslag; de tijdelijke apparaten zijn na de controles opgeruimd.

[Buildverslag](WorldTestLogs/NativeSignPolish/build.log) · [Wereldcaptures](WorldTestLogs/NativeSignPolish/world-captures.log) · [Laatste aansluitingen](WorldTestLogs/NativeSignPolish/connections.log) · [Kleine iPhone](WorldTestLogs/NativeSignPolish/compact.log) · [iPad](WorldTestLogs/NativeSignPolish/ipad.log).

## Eerdere verificatie van de native omzetting

- De Debug-testbuild slaagt. Het nieuwe bronbestand is toegevoegd aan de app-target in het Xcode-project.
- Alle tien wereldvarianten zijn op een eigen iPhone 17-simulator vastgelegd en visueel nagekeken op materiaal, ornamenten, titelruimte en plaatsing. Wereld 10 is met `Level 100` gecontroleerd.
- De bestaande `testResultRewardStatesAndNavigation` slaagt op een eigen iPad Pro 11-inch (M5), met nul fouten. Deze controleert nul tot drie sterren, de score onder het bord, bereikbare knoppen, opnieuw spelen, verdergaan, terug naar de kaart, sterrenoverzicht, boss-resultaten en de woestijnwereld.
- De appcode laadt `result-sign` niet meer. De bordtekening gebruikt uitsluitend native paden en kleurverlopen. `git diff --check` is schoon.
- De testfixtures gebruiken afzonderlijke Debug-opslag. De tijdelijke testapparaten zijn na de controles opgeruimd.

[Testbuild](WorldTestLogs/NativeResultSign/build.log) · [iPad-schermtest](WorldTestLogs/NativeResultSign/ipad.log) · [Wereldcaptures](WorldTestLogs/NativeResultSign/world-captures.log).
