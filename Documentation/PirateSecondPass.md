# Tijdpiraten — kust en ligplaatsen verfijnd

21 oktober 2026. Deze ronde corrigeert de ruimtelijke opbouw van wereld 9 na de eerste verbeterslag.

- De twee piratenschepen hebben een eigen ligplaats in het water. De zandplateaus, kisten, tonnen en steigers die eerder onder de scheepsscènes lagen zijn daar verwijderd. Een plaatsingscontrole reserveert water onder de volledige romp en houdt de schepen grotendeels in beeld op smalle schermen.
- De schatkisten, kampjes en overige landdecoraties staan op brede, vloeiende stranduitlopers. Deze vormen onderdeel van de echte kustcontour. Er ligt geen losse schuim- of waterstrook meer onder hun zandgrond. Ook drie palmgroepen hebben een aansluiting met het strand.
- De grotere rotsgroepen staan meer landinwaarts en langs de oever. Alleen de waterzijde krijgt een dunne schuimrand. Onderwaterstenen, lichtaccenten en koraal blijven in de zee zichtbaar.
- Alle decoratieve digitale klokken uit de piratenscènes zijn verwijderd. Onder de luifels staan houten tafels met uitgerolde schatkaarten, een kompas en munten. Naast de tweede grote schatkist staan een ton, schelp en lantaarn.

`PirateCoastLayout` deelt de landposities, de kustcontour en de scheepsplaatsing. Het water, de schuimrand en de onderwaterdetails gebruiken dezelfde definitieve contour. De nieuwe contour wordt rechtstreeks getekend, met behoud van ondersteuning voor iOS 16. Pad, levelposities, wereldborden, meeuwen en hoofdstukovergangen behouden hun bestaande opbouw.

Implementatie: [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift), bij `WorldSceneryLayout.pirateWaterArea`, `PirateCoastLayout` en `PirateCoastPainter`.

## Beelden

[Vorige versie en verfijnde kust](Screenshots/PirateSecondPass/before-after.jpg) · [boot en schatplek op iPhone](Screenshots/PirateSecondPass/pirate-route-83-iphone.png) · [brede kaart op iPad](Screenshots/PirateSecondPass/pirate-route-82-ipad.png).

Native composities op [320](Screenshots/PirateSecondPass/native-320.png), [393](Screenshots/PirateSecondPass/native-393.png), [834](Screenshots/PirateSecondPass/native-834.png) en [1194](Screenshots/PirateSecondPass/native-1194.png) punten zijn visueel gecontroleerd. De genummerde cirkels in deze composities zijn controlemarkeringen. De simulatorbeelden tonen de echte interface.

## Controles

De [native renderbuild](WorldTestLogs/PirateSecondPass/native-build.log) en [iOS-verificatiebuild](WorldTestLogs/PirateSecondPass/verification-build.log) slagen.

Op tien breedtes van 320 tot 1194 punten zijn beide schepen aanwezig. Per breedte zijn 1.872 punten binnen de daadwerkelijk getekende rompvorm gecontroleerd: alle punten liggen in het water. Daarnaast zijn per breedte 648 punten tussen de twee grote schatplekken en het midden van het strand gecontroleerd: alle punten liggen op droog land. In totaal zijn dit **25.200 geslaagde plaatsingscontroles**. [Geometrie- en renderlog](WorldTestLogs/PirateSecondPass/native-render.log).

De afzonderlijke kaartcontrole uit de eerste ronde is opnieuw uitgevoerd op [iPhone](WorldTestLogs/PirateSecondPass/iphone-verified.log) en [iPad](WorldTestLogs/PirateSecondPass/ipad-verified.log): **vier geslaagde testuitvoeringen, nul fouten**. Deze controle opent level 81, controleert de bedienbare klok, controleerknop en het voorbeeld, keert terug naar de kaart, scrolt langs levels 82, 83, 86 en 87 en opent de eindbaas. De aangepaste controlekopie beantwoordt de klokvraag niet; de tests in de werkmap zijn niet aangepast voor deze ronde.

Vier animatiemomenten verschillen; twee beelden met **Minder beweging** zijn pixelgelijk. [Pixelcontrole](WorldTestLogs/PirateSecondPass/visual-checks.json). De gecontroleerde piratenbroncode komt overeen met de werkmap; `git diff --check` is schoon.
