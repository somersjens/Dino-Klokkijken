# Eindlevel met native landschap

Het eindscherm behoudt de compositie van het voorbeeld: een levelbord, een open zonnige plek met heuvels, Dino op een steen en drie gouden beloningssterren. De achtergrond, de steen en het bord zijn opgebouwd met native SwiftUI/Canvas-paden. De eerdere illustraties dienen alleen nog als vormreferentie.

Het bovenste bord heeft nu eigen materialen en ornamenten voor alle tien werelden, met behoud van zijn vorm en tekstplaatsing. De aparte achterlaag, het paneel en de voorversiering kunnen onafhankelijk worden aangepast en geanimeerd. [Wereldvarianten, animatie-instellingen en controles](NativeResultSignDesign.md).

## Opbouw en aanpassingen

- `ResultScenery` tekent vier afzonderlijke lagen: lucht, verte, gras en begroeiing. Wolken, heuvels, doorlopende grasbanken, grassprietjes, bloemen, takken, lianen en bladeren zijn getekende vormen. De oude achtergrondillustraties worden hier niet meer geladen.
- De bladeren delen `DinoFoliageLeaf`, `DinoFoliageFold` en `DinoFoliageVeins` met de levelkaart. Een afzonderlijk palet gebruikt de `themeID` van de wereld; de wereldvolgorde bepaalt de kleuren niet.
- De lagen kunnen later afzonderlijk bewegen. `windPhase` biedt een aangrijpingspunt voor bladbeweging; er draait nog geen permanente achtergrondanimatie.
- De score staat met zijn materiaalvlak direct onder het houten bord in de lucht. De vrijgekomen ruimte onder de steen laat Dino en het podium nog iets zakken. Eén layout berekent de voetlijn, het stenen bovenoppervlak en de sterren op de voorzijde samen, zodat ze ook op een kleine iPhone bij elkaar blijven passen.
- De leveltitel is 10% kleiner en optisch gecentreerd op het hout.
- Het landschap heeft een voller uitgewerkte onderkant: 1.250 onregelmatig verdeelde graspollen met gevulde, gebogen sprieten, zachte lichtvlekken, meerdere overlappende bladgroepen en varens, en kleine bloemen. De bladeren hebben licht over hun breedte, een donkerdere onderzijde, zachte slagschaduw en subtiele nerven.
- De native plantenlagen delen de positie en schaal van de steen. Hoge bladeren groeien achter de zijkanten; grotere, bredere bladgroepen groeien vóór de steen en bedekken de onderste zijvlakken. Mossige kappen hangen over de bovenranden en een doorlopende mosmat groeit rondom de voet. De beloningssterren staan vóór deze begroeiing.
- Kaartsterren zijn van 22 naar 26 punten vergroot en staan dichter onder de levelcirkel. De zijsterren draaien iets minder, met de middelste ster licht verhoogd.
- Verdiende sterren hebben vanaf het begin hun gouden uiterlijk, maar blijven volledig transparant tot hun eigen vlucht start. Onverdiende grijze sterren verschijnen pas nadat de beloningsanimatie klaar is. Zo is er geen grijze ster zichtbaar die later goud wordt of opnieuw komt aanvliegen.

## Native steen en laagvolgorde

`ResultRock` tekent de steen zonder rasterbeeld. `ResultStonePainter` bevat de brede, afgeronde buitenvorm en het vlakke bovenvlak van de eerdere steen, in tekenruimte van 1000 × 455. De bestaande verhouding van 2,2:1, podiumpositie en voetlijn blijven behouden. Alle facetten gebruiken één mineraalpalet met subtiele verschillen in belichting en zachte naden. Het palet neemt licht en gereflecteerde grondkleur uit de omgeving over: warmer in de zonnige werelden, koeler in de Slaapvallei en Kristalgrot. De textuur is teruggebracht tot enkele subtiele korrels en ondiepe putjes.

`ResultMossPainter` tekent hetzelfde rustige mos op de steen en rond zijn voet: een vloeiende buitenvorm, zachte contactschaduw en enkele brede lichtvlakken. De duizenden spikkels, kleine randlobben en fijne plukjes zijn vervangen door eenvoudige moskussens die bij de bladeren passen. De kleuren komen uit hetzelfde gras- en bladpalet. De woestijn behoudt zijn eigen droge begroeiing en krijgt geen groene moskappen.

Van achter naar voor:

1. Achtergrond, licht en grondschaduw.
2. Hoge planten en het achterste mosbed.
3. De native steen met mos over de bovenranden.
4. Voetschaduw en Dino op het bovenvlak.
5. Het voorste mosbed, grotere bladeren, gras en bloemen over de onderste steenrand en zijvlakken.
6. Beloningssterren of trofee, met de feestdeeltjes ervoor.

Alle steen- en mosvormen staan in `Dino/Views/LevelResult.swift`. De gegenereerde steen wordt nergens meer geladen in de appcode.

## Eerdere steenillustratie

Bestand: `Assets.xcassets/result-stone.imageset/result-stone.png`.

Deze eerdere illustratie is gemaakt met de ingebouwde imagegen-tool en blijft bewaard als materiaal- en vormreferentie. De steen in de app wordt volledig getekend; het onderstaande prompt is de herkomst van het oude asset.

### Gebruikte prompt

Use case: precise-object-edit. Asset type: isolated transparent stone podium sprite for a children's dinosaur game. Input image is the edit target and material/shape reference. Keep ONLY the central stone boulder, removing absolutely all surrounding leaves, grass, daisies, pebbles and decorative plants. Re-render the rock alone, centered and nearly filling a landscape canvas about 2.2:1. A broad squat naturally rounded gray-beige boulder with a broad gently flattened sunlit top on which a dinosaur can stand. Front view with a small amount of top surface visible, same perspective as reference. Rounded faceted contours, restrained cracks and mottled stone texture, warm cream bounce light across the upper-left top plane, soft shaded lower front. Keep the front face broad and quiet for separate reward stars to be overlaid. Remove the moss as well, so the whole object is bare stone. Same polished 3D storybook rendering style as the reference. Genuine transparent alpha background, narrow empty margin only. NO foliage, NO moss, NO lawn, NO flowers, NO scenery, NO floor or ground plane, NO stand or base, NO dinosaurs, NO stars, NO text, NO colored background. Exactly one isolated bare stone, all edges fully visible.

## Beelden

[Verbeterslag: voor en na](Screenshots/NativeStonePolish/before-after.png) · [Nieuwe steen op iPhone](Screenshots/NativeStonePolish/result-iphone.png) · [Kleine iPhone](Screenshots/NativeStonePolish/result-compact.png) · [iPad](Screenshots/NativeStonePolish/result-ipad.png) · [Slaapvallei](Screenshots/NativeStonePolish/result-night.png) · [Woestijn](Screenshots/NativeStonePolish/result-desert.png).

Eerdere uitvoering:

[Native steen op iPhone](Screenshots/NativeResultStone/result-iphone.png) · [Kleine iPhone](Screenshots/NativeResultStone/result-compact.png) · [iPad](Screenshots/NativeResultStone/result-ipad.png) · [Zonder gouden sterren](Screenshots/NativeResultStone/result-zero-stars.png).

## Verificatie van de verbeterslag op 19 oktober 2026

- De Debug-testbuild met het aangepaste steenpalet, het vereenvoudigde mos en de grotere voorste bladeren slaagt. [Buildverslag](WorldTestLogs/NativeStonePolish/build.log).
- Visueel gecontroleerd op afzonderlijke tijdelijke simulators: iPhone 17 (iOS 26.5), iPhone SE 3e generatie (iOS 26.1) en iPad Pro 11-inch M5 (iOS 26.5). De voorste bladeren overlappen de zijkanten van de steen; voeten, sterren en bediening blijven vrij.
- Op iPhone zijn het jungleresultaat met nul en drie sterren, de woestijn, de Slaapvallei en de Kristalgrot bekeken. De koele werelden gebruiken een koeler steenpalet; de woestijn behoudt zijn droge begroeiing. [Kristalgrot](Screenshots/NativeStonePolish/result-crystal.png) · [Nul sterren](Screenshots/NativeStonePolish/result-zero-stars.png).
- `git diff --check` is schoon. De aanpassingen blijven native paden en verlopen, zonder nieuwe rasterassets.

## Eerdere verificatie van de native steen

- De Debug-testbuild met de native steen slaagt. `testResultRewardStatesAndNavigation` slaagt op iPhone 17 en op een aparte schone iPad Pro 11-inch (M5), beide met nul fouten. Hij controleert nul tot drie sterren, de score onder het houten bord, bereikbare bediening, opnieuw spelen, verdergaan, teruggaan naar de kaart, het sterrenoverzicht, boss-resultaten en de woestijnwereld.
- Het perfecte resultaat is daarnaast visueel gecontroleerd op iPhone SE (3e generatie). De titel, voetlijn, steen, sterren, score en bediening passen op het compacte scherm. Ook de iPhone- en iPad-previews zijn visueel nagekeken op de mosranden en de overlapping van de voorste bladeren.
- De eerste run op de gedeelde iPad werd beëindigd met `signal kill`. De volledige herhaling op de schone simulator slaagt. Het oorspronkelijke verslag blijft bewaard in [ipad-interrupted.log](WorldTestLogs/NativeResultStone/ipad-interrupted.log).
- De controle is uitgevoerd in portretstand. De fixtures gebruiken afzonderlijke Debug-opslag; de tijdelijke testapparaten zijn na afloop opgeruimd.
- `git diff --check` is schoon. De appcode bevat geen verwijzing meer naar `result-stone`.

[Testbuild](WorldTestLogs/NativeResultStone/build.log) · [iPhone-test](WorldTestLogs/NativeResultStone/iphone.log) · [iPad-test](WorldTestLogs/NativeResultStone/ipad.log).
