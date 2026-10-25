# Native begin- en eindvormen voor alle werelden

23 oktober 2026.

De aansluitingen zijn opnieuw opgebouwd in de oorspronkelijke landschapspainters. De algemene `WorldBoundaryPainter`, `WorldJoinContour`, overgangstegels en kopieën van hele inkomende landschappen zijn verwijderd. De eigen shapes van iedere wereld bepalen nu de entree en de uitgang. Nieuwe grond wordt onder bestaande rotsen, gebouwen en waterlopen getekend.

De lava- en basaltgeometrie van Vulkaanland is behouden, inclusief de oorspronkelijke verspringende bochten naar de zijkanten. Rivierpaden, oeverstenen, stroming en hun occlusiemaskers blijven dezelfde volledige geometrie gebruiken. De nieuwe vloer mag die oevers niet bedekken.

[Vergelijking vulkaan → dorp](Screenshots/NativeWorldEnds/volcano-village-before-after.png).

| Aansluiting | Native afwerking |
| --- | --- |
| Jungle → Woestijn | De eerste echte woestijnduin begint in de laatste jungleclearing. Zandkorrel en een lichte windrand horen bij de woestijnvloer; de jungle behoudt zijn groene vegetatie. |
| Woestijn → Vulkaan | De oorspronkelijke gedeelde lava-inlaten en basaltmassa blijven intact. Het zandbed heeft een fysieke duinrand. De as langs de weg krijgt een taps begin en einde; er loopt geen rechte asstrook door de vorige speelbocht. |
| Vulkaan → Dorp | De eigen dorpsweide ligt onder de oorspronkelijke uitgaande basaltbanken. Lava, rotsen en puin blijven hun bochten naar de zijkanten volgen. |
| Dorp → Kristalgrot | Het gras loopt met afgeronde uitlopers de grot in. De eigen rotswanden groeien pas naar binnen nadat de rechter dorpswaterstroom volledig is geëindigd. De dorpsrivieren behouden hun volledige oevers. |
| Kristalgrot → Stad | De oorspronkelijke grotstenen lopen door tot in de eerste stadsstraat en wijken aan beide kanten op verschillende hoogtes naar buiten. De eerste volledige stadsgevels staan tegen de rotsformaties. |
| Stad → Slaapvallei | De parkbodem heeft een kleine, onregelmatige mosrand onder de laatste stadsbebouwing en spoorwerken. De bestaande beekjes, poelen, watervallen en oevers blijven volledig. |
| Slaapvallei → Tijdmachine | De nachtelijke bodem loopt door. De eigen terrassen, bronhuizen, kades en gebouwen vormen het begin van het klokwerkkoninkrijk. Er ligt geen afzonderlijke stenen overgangsplaat tussen. |
| Tijdmachine → Tijdpiraten | De strandvloer begint onder de laatste klokwerkkade. Het metselwerk loopt door tot de onderkant van de volledige afvoerputten. Afvoerputten, vallend water en hun voeten blijven volledig zichtbaar. Het piratenwater komt via de bestaande zij-inlaten binnen. |
| Tijdpiraten → Tijdkasteel | De kustbodem loopt door onder de eigen kasteelmuren, tuinbanken en grachten. De volledige piratenkust draait eerst naar buiten; de koninklijke waterlopen beginnen vanuit hun eigen zijmondingen. De ondergrond loopt ook na level 100 door. |

De oorspronkelijke native details blijven de wereld herkenbaar maken. Materiaalverlopen binnen zand, steen en begroeiing geven volume. De 32-punts kleurvervagingsstroken en de kleurverlopen van de oude grotbenadering zijn verwijderd.

## Beelden

Alle negen aansluitingen zijn afzonderlijk beoordeeld op vier breedtes: 320, 393, 834 en 1194 punten. Dat zijn 36 native SwiftUI/Canvas-renders. De auditbeelden gebruiken vereenvoudigde levelstenen en een verkort vaardigheidslabel.

[Telefoon](Screenshots/NativeWorldEnds/overview-393.png) · [Smalle telefoon](Screenshots/NativeWorldEnds/overview-320.png) · [iPad](Screenshots/NativeWorldEnds/overview-834.png) · [Brede iPad](Screenshots/NativeWorldEnds/overview-1194.png).

[Definitieve appbeelden op iPhone](Screenshots/NativeWorldEnds/app-overview-iphone.png) · [Definitieve appbeelden op iPad](Screenshots/NativeWorldEnds/app-overview-ipad.png).

## Controles

- **819.584 kerncontroles geslaagd**, inclusief gedeelde levelafstand en bordruimte voor alle negen grenzen. [Log](WorldTestLogs/NativeWorldEnds/core.log).
- **1.680 geometriecontroles geslaagd** op zes breedtes. Dorpskanalen, slaapvalleibeekjes, pirateninlaten, kasteelgrachten en lava-uitlaten verlaten de hoofdstukken met hun volledige oevers via de zijranden. [Log](WorldTestLogs/NativeWorldEnds/water-endpoints.log) en [auditcode](WorldTestLogs/NativeWorldEnds/water-endpoint-audit.swift).
- De iPhone- en iPad-schermtests voor alle negen borden en alle tien speelbare eindbazen slagen. [Log](WorldTestLogs/NativeWorldEnds/boss-and-spacing-ui.log).
- De native renderer compileert en alle 36 beelden worden gegenereerd. [Compilatie](WorldTestLogs/NativeWorldEnds/native-build.log) en [renderlog](WorldTestLogs/NativeWorldEnds/native-renders.log).

De definitieve versie slaagt opnieuw op iPhone en iPad voor alle negen borden en het kaarteinde na level 100. [Definitieve schermtestlog](WorldTestLogs/NativeWorldEnds/final-ui.log).

De vulkaanuitgang, beide grotopeningen, de metrobuurt en beide tijdmachine-einden zijn daarna verder uitgewerkt. Zie [de gerichte verlengingen en nieuwe beelden](WorldExtensions.md).
