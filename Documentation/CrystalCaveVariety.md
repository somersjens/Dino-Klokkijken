# Afwisselende rotsen en ingewerkte diamanten — 27 oktober 2026

> Deze ontwerpvariant is op verzoek teruggedraaid. De app gebruikt opnieuw de versie met de diamantgroepjes uit CrystalCaveUnity.md.

De grot heeft een nieuwe compositie. De regelmatige reeks van 56 gelijksoortige kristalboeketten is vervangen door twintig afzonderlijk geplaatste mineraalplekken en diamanten in de voegen van de wandstenen.

- De twee oevers krijgen ongelijke tussenruimten, verschillende afstanden tot de rotsrand en rustige stukken zonder grote kristallen.
- Lange schuine kristallen, brede ruwe diamanten, lage aders, afgebroken scherven, kleine kristaldruses en enkele hoge uitlopers hebben verschillende aantallen, verhoudingen en groeirichtingen. De geometrie varieert onafhankelijk van de kleur.
- Diamanten zijn gedeeltelijk door steen bedekt en liggen ook tussen de overlappende wandstenen. De losse, complete voetplaatjes zijn grotendeels verdwenen.
- Wandstenen hebben wisselende breedten en hoogten, onregelmatige breukcontouren, verschillende facetverdelingen en verspringende voegen. Er is geen vast raster meer. Brede horizontale platen wisselen af met hoge rotsblokken.
- Vijf koele mineraalpaletten en vier kristalsneden variëren door de hele grot. Materiaal en vorm blijven stabiel tijdens scrollen. Tien kleine glinsteringen volgen dezelfde geometrie als de betreffende edelsteen.

De bestaande afstand tot het pad, de mijnwerkplaatsen, beide klokdisplays en de eindbaas blijft onderdeel van de plaatsing. De aanpassingen zitten uitsluitend in de grotcode in `JungleLandscape.swift`; bestaande wijzigingen in andere onderdelen van de gedeelde checkout zijn behouden.

## Vergelijking

[Vorige versie](Screenshots/CrystalCaveUnity/walls-393.png) · [Nieuwe verdeling op telefoon](Screenshots/CrystalCaveVariety/walls-393.png) · [Nieuwe verdeling op brede tablet](Screenshots/CrystalCaveVariety/walls-1194.png)

[320 punten](Screenshots/CrystalCaveVariety/walls-320.png) · [834 punten](Screenshots/CrystalCaveVariety/walls-834.png) · [Onderste grotdeel](Screenshots/CrystalCaveVariety/lower-834.png)

De statische controlerenders gebruiken hulpcirkels voor de levels en een oudere vectorbaas als stand-in. De daadwerkelijke levelstenen, bewegende mijnwerkers, lampen en bossafbeelding worden afzonderlijk in de simulator gecontroleerd.

## Verificatie

De native compositie is visueel gecontroleerd op 320, 393, 834 en 1194 punten breed. De simulatorbuild slaagt; `git diff --check` is schoon.

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` slagen gericht voor wereld 5 op iPhone 18 Pro en iPad Pro 13-inch (M5): **vier geslaagde testuitvoeringen, nul fouten**. Ze controleren het openen en spelen van level 41 en het openen van de eindbaas via level 50 met geïsoleerde Debug-testvoortgang.

[Appbeeld iPhone](Screenshots/CrystalCaveVariety/entrance-iphone.png) · [Appbeeld iPad](Screenshots/CrystalCaveVariety/entrance-ipad.png) · [Eindbaas iPhone](Screenshots/CrystalCaveVariety/boss-iphone.png) · [Eindbaas iPad](Screenshots/CrystalCaveVariety/boss-ipad.png)

[Buildlog](WorldTestLogs/CrystalCaveVariety/build.log) · [iPhone-tests](WorldTestLogs/CrystalCaveVariety/iphone.log) · [iPad-tests](WorldTestLogs/CrystalCaveVariety/ipad.log) · [Wijzigingen van deze ronde](WorldTestLogs/CrystalCaveVariety/cave-only.diff)
