# Vulkaanland — eerste verbeterslag

18 oktober 2026. Eerste uitbreiding van wereld 3, met de gelaagde omgevingen van wereld 1 en 5 en het aangeleverde vulkaanconcept als richting. De wereld blijft volledig native SwiftUI: geen achtergrondafbeelding of nieuwe rasterassets.

## Landschap

- Twee lavabeddingen slingeren langs de route en verlaten het landschap via de zijkanten. De geulen hebben donkere basaltwanden, warme randen en een bewegende, lichtere stroom.
- Grotere basaltvelden vullen ook op brede iPads de buitenranden. Onregelmatige breukvlakken, verweerde bovenkanten en oplichtende scheuren geven de ondergrond meer samenhang.
- 36 gevarieerde rotsgroepen verbinden de grotere scènes. Elke groep bevat meerdere stenen, verschillende facetten, een gloeiende breuklijn en soms kristallen of begroeiing.
- Drie nieuwe kraters staan verspreid langs de route. Ze hebben een gespleten rotswand, een hete kratermond en een lavastroom naar een poel aan hun voet.
- De vier bestaande grote lavavallen en de kleinere val bij de entree hebben stromende banen, uitdijende rimpels en kleine spetters bij de landing.
- De kraters en de vulkaan bij de entree pruttelen met afzonderlijke bellen: groeien, openbarsten, een kring en enkele druppels. Vonken volgen een kleine boog terug naar beneden.
- Negen bronnen hebben een eigen rook- of stoomlaag. De pluimen groeien, drijven en vervagen vanuit hun daadwerkelijke krater of poel.

## Opbouw en beweging

`VolcanoWorldLayout` deelt de rotsposities en lavacontouren tussen de statische omgeving en de animaties. Het bestaande routeverloop bepaalt de vrije ruimte rond elke bocht.

De statische omgeving blijft apart van de bewegende lagen. De lavabeddingen worden in stroken van maximaal 320 punten geanimeerd; kraters en vallen hebben een eigen begrensd tekenvlak. Alleen zichtbare vlakken verversen, maximaal 20 keer per seconde. De animatie pauzeert als de app niet actief is of **Minder beweging** aanstaat. In die laatste stand blijft één vaste, uitgewerkte compositie zichtbaar.

Statische maskers plaatsen de beweging achter voorliggende rotsen en de eindbaas. Een afzonderlijke vrije strook rond het pad houdt rook, spetters en stroomaccenten uit de levelknoppen. Alle lavastroken gebruiken dezelfde oorsprong en padlengte, zodat stroomaccenten doorlopen over de grenzen tussen de tekenvlakken.

De implementatie staat in [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift), bij `VolcanoWorldLayout`, `VolcanoWorldLife`, `VolcanoLifePainter` en `VolcanoWorldPainter`.

## Beelden

[Voor en na](Screenshots/VolcanoFirstPass/before-after.jpg). Deze compositierenders gebruiken de native omgevingscode, met neutrale levelmarkeringen om de veranderingen goed te kunnen vergelijken.

[320 punten](Screenshots/VolcanoFirstPass/native-320.png) · [393 punten](Screenshots/VolcanoFirstPass/native-393.png) · [834 punten](Screenshots/VolcanoFirstPass/native-834.png) · [1194 punten](Screenshots/VolcanoFirstPass/native-1194.png).

[Animatiemoment 1](Screenshots/VolcanoFirstPass/motion-0.png) · [moment 2](Screenshots/VolcanoFirstPass/motion-1.png) · [moment 3](Screenshots/VolcanoFirstPass/motion-2.png) · [moment 4](Screenshots/VolcanoFirstPass/motion-3.png).

## Verificatie

- De simulatorbuild en de native renderbuild slagen.
- `Tools/test-dino.sh`: **795.547 controles geslaagd**.
- Native composities visueel gecontroleerd op 320, 393, 834 en 1194 punten breed.
- De vier animatiemomenten verschillen op pixelniveau. Twee renders met **Minder beweging** op verschillende tijdstippen zijn pixel voor pixel gelijk.
- De level- en eindbaascontroles slagen op iPhone 17 en iPad Pro 11-inch met iOS 27: **vier testuitvoeringen, nul fouten**, met de hieronder beschreven extra selector. Wereld 3 opent, de eerste klokvraag wordt correct beantwoord en de eindbaasstartkaart opent.
- `git diff --check` is schoon.

De ongewijzigde schermtests vinden de knop `level.play` niet: iOS geeft alle onderdelen in de startkaart de bovenliggende identifier `level.startCard`. Een afzonderlijke diagnose op de oorspronkelijke kaart bevestigt dat de tik werkt en dat **Spelen** zichtbaar is. De bestaande wereld-3-afstandstest faalt ook op de oorspronkelijke kaart, doordat hij de tekstgrenzen aan beide kanten exact gelijk verwacht; de gevonden afstanden blijven ruim boven 40 punten. Er is daarom voor deze controle een tijdelijke kopie van de bestaande level- en eindbaastests gebruikt, met **Spelen** als extra selector. De tests en identifiers in de werkmap zijn hiervoor niet aangepast.

Echte appbeelden: [entree iPhone](Screenshots/VolcanoFirstPass/entrance-iphone.png), [entree iPad](Screenshots/VolcanoFirstPass/entrance-ipad.png), [eindbaas iPhone](Screenshots/VolcanoFirstPass/boss-iphone.png), [eindbaas iPad](Screenshots/VolcanoFirstPass/boss-ipad.png).

Logs: [build](WorldTestLogs/VolcanoFirstPass/build.log), [native renders](WorldTestLogs/VolcanoFirstPass/native-render.log), [spelcontroles](WorldTestLogs/VolcanoFirstPass/core-tests.log), [iPhone-controle](WorldTestLogs/VolcanoFirstPass/iphone-review.log), [iPad-controle](WorldTestLogs/VolcanoFirstPass/ipad-review.log), [diagnose op oorspronkelijke kaart](WorldTestLogs/VolcanoFirstPass/tap-diagnostic.log).

Dit is de eerste verbeterslag. Het titelbord, de HUD en de bestaande schaal van pad en levelknoppen blijven het vertrekpunt voor een volgende detailronde.

## Tweede verbeterslag — vulkaanvoet en droge rotsposities

De grote vulkaan heeft nu een volledig dekkende rotswand tot aan de voet. Het eerdere transparantiemasker is verwijderd: de lavabedding en de bewegende stroomaccenten zijn niet langer door de berg heen zichtbaar. Alleen de grondschaduw en de afzonderlijke rook blijven zacht.

De twee losse palmbomen en het stenen bruggetje zijn uit Vulkaanland verwijderd, inclusief hun ongebruikte tekenfuncties. Twee kleine, oude decoraties op de lavabedding zijn eveneens verwijderd. De omgevingsklokken bij de lavavallen blijven zichtbaar.

Losse stenen gebruiken nu een vaste, willekeurig ogende verdeling over droge grond. Verschillende groottes en groepjes van één tot drie stenen vervangen de herhaalde brede sokkels. De plaatsing reserveert ruimte voor de volledige lavageul, de poelen, de vulkanen, het pad en de eindbaas. Posities worden per kaartafmeting gecachet en blijven gelijk tijdens scrollen.

De iOS-build en de native renders slagen. Op 320, 393, 834 en 1194 punten breed zijn **161 losse rotsposities** gecontroleerd met in totaal **15.939 meetpunten**: geen contact met de lavageulen. Twee meetpunten onderaan de grote vulkaan hebben volledige dekking (`alpha = 1`). De vier animatiemomenten verschillen; de twee beelden met Minder beweging zijn identiek. `git diff --check` is schoon.

[Voor/na vulkaanvoet](Screenshots/VolcanoSecondPass/before-after-top.jpg) · [Voor/na verspreiding en verwijderde bomen/brug](Screenshots/VolcanoSecondPass/before-after-middle.jpg) · [iPhonebreedte](Screenshots/VolcanoSecondPass/native-393.png) · [Brede iPad](Screenshots/VolcanoSecondPass/native-1194.png) · [Gecontroleerd appbeeld op iPhone](Screenshots/VolcanoSecondPass/entrance-iphone.png) · [Geometrie- en dekkingscontrole](WorldTestLogs/VolcanoSecondPass/native-render.log) · [iOS-build](WorldTestLogs/VolcanoSecondPass/build.log).

## Derde verbeterslag — alleen driehoekige vulkanen op droge grond

De vijf lavavallen op basaltzuilen zijn volledig verwijderd, inclusief de kleine variant bij de entree, hun bronposities en hun animatiecode. De wereldpreviews gebruiken nu ook driehoekige vulkanen.

De kaart heeft vijf actieve, driehoekige vulkanen. Hun posities en afmetingen volgen de droge ruimtes bij de ruimste bochten. De plaatsing controleert meerdere stroken door het volledige silhouet: kratermond, hellingen, voet, rotsjes en poel. De volledige segmenten van de lavageulen en het pad krijgen extra vrije ruimte; daardoor blijven ook schuine bochten vrij. Op smalle schermen kunnen vulkanen deels aan de buitenrand staan. Minimaal 74% van hun breedte blijft in beeld. De rook, bellen, vonken en lava op hun hellingen blijven geanimeerd.

De plaatsingscontrole slaagt op **320, 375, 393, 402, 430, 600, 744, 834, 1024 en 1194 punten**. Op elke breedte staan alle vijf vulkanen. In totaal zijn **54.600 meetpunten** gecontroleerd: geen overlap van de vulkanen met de lavageulen of het pad. De losse stenen blijven eveneens buiten de lava. De native composities zijn visueel gecontroleerd op 320, 393, 834 en 1194 punten. De bewegende beelden verschillen; Minder beweging levert twee identieke beelden op.

[Voor/na](Screenshots/VolcanoThirdPass/before-after.jpg) · [Nieuwe kaart op iPhonebreedte](Screenshots/VolcanoThirdPass/native-393.png) · [Nieuwe kaart op iPadbreedte](Screenshots/VolcanoThirdPass/native-834.png) · [Plaatsingscontrole](WorldTestLogs/VolcanoThirdPass/native-render.log) · [iOS-build](WorldTestLogs/VolcanoThirdPass/build.log).

## Vierde verbeterslag — grote vulkanen in de buitenbochten

Alle vijf vulkanen gebruiken nu de hoge bergvorm. Hun voeten vullen afwisselend de brede buitenbochten; op een telefoon zijn de bergen circa 128–181 punten hoog, op een iPad circa 233–245 punten. De plaatsing volgt het taps toelopende silhouet in twaalf stroken en beperkt de schaalcorrectie. Zo blijft de berg groot terwijl ook de bovenste helling de inkomende lavageul vrijlaat. Aan een smalle schermrand mag de brede flank doorlopen buiten beeld; minstens 60% van de volle breedte en de krater blijven zichtbaar. De laatste vulkaan houdt ruimte vrij boven de eindbaas.

De twee lavageulen liggen dichter langs de weg: hun basisafstand tot het midden van het pad is van 158 naar 102 schaalpunten gebracht, met kleinere uitslagen. De droge rotsgrond loopt mee naar binnen. Dit geeft de vulkanen meer ruimte in de bochten.

Elke geul heeft nu vijf bewegende stroken langs de lokale richting van de stroom. Lichte en donkere banen lopen met verschillende snelheden; bredere warme golven schuiven ertussendoor. Dit gebruikt hetzelfde principe als de eerdere afstromende lava, nu over de volledige kronkelende geulen. De vaste middenreflectie is zachter zodat de beweging zichtbaar blijft. Alle tekenvlakken delen dezelfde paden en animatiefase. Minder beweging en pauzeren buiten beeld blijven actief.

De iOS-build slaagt. Op tien breedtes van 320 tot 1194 punten zijn alle vijf grote vulkanen aanwezig. **163.800 meetpunten** in hun silhouetten raken nergens de lavageulen of het pad. Ook **325 losse rotsposities** blijven buiten de lava. De 32 animatiebeelden verschillen; twee beelden met Minder beweging zijn pixel voor pixel gelijk. Native composities zijn visueel gecontroleerd op 320, 393, 834 en 1194 punten.

[Voor/na](Screenshots/VolcanoFourthPass/before-after.jpg) · [Stromingsanimatie](Screenshots/VolcanoFourthPass/lava-flow.gif) · [iPhonebreedte](Screenshots/VolcanoFourthPass/native-393.png) · [iPadbreedte](Screenshots/VolcanoFourthPass/native-834.png) · [Plaatsingscontrole](WorldTestLogs/VolcanoFourthPass/native-render.log) · [iOS-build](WorldTestLogs/VolcanoFourthPass/build.log).

## Vijfde verbeterslag — trage lavanaden, aangesloten vulkanen en meer stenen

De korte, felle streepjes en brede bewegende golven zijn vervangen door lange, zachte lichtaccenten. De stroming door de hoofdgeulen gaat van 48–64 naar 3,2–4,52 punten per seconde. Ook de lava op de hellingen beweegt langzamer. De hoofdgeulen bestaan nu uit zeven fijne, vertakkende lavanaden: een centrale stroom van 4,2 schaalpunten en zijlijnen van 0,6–1,2 schaalpunten. De zijlijnen komen onderweg samen en wijken weer uiteen; hun helderheid verschilt. Basalt blijft zichtbaar tussen de lijnen.

Op iedere grote vulkaan vloeien vijf dunne lavalijntjes op verschillende hoogtes samen. De hoofdstroom loopt door tot de voet en sluit daar aan op een doorlopende zijtak naar de dichtstbijzijnde lavageul. De losse poelen aan de vulkaanvoeten zijn verwijderd. Statische lava en bewegende reflecties gebruiken dezelfde paden. De laatste zijtak houdt de eindbaasruimte vrij; op brede schermen zoekt de laatste vulkaan daarvoor een hogere plek in de buitenbocht.

De vaste verdeling van losse stenen bevat nu meer rotsblokken, kleine keien en puin. Grotere stenen worden eerst geplaatst, kleinere groepjes vullen de droge tussenruimtes. Op telefoonbreedtes staan nu **72 rotsgroepen**, tegenover circa 13–19 in de vorige versie. De plaatsing houdt zowel de hoofdgeulen als de nieuwe zijtakken vrij.

De iOS-build slaagt. Op tien schermbreedtes van 320 tot 1194 punten sluiten alle vijf vulkanen exact aan op hun zijtak en de hoofdgeul. Geen zijtak kruist het pad of de eindbaasruimte. Alle 163.800 meetpunten in de vulkaansilhouetten blijven vrij van het pad en de hoofdgeulen; de 909 rotsgroepen in deze tien composities raken geen lava. De 48 animatiebeelden verschillen, terwijl twee beelden met Minder beweging identiek zijn. Native composities zijn gecontroleerd op 320, 393, 834 en 1194 punten.

[Voor/na](Screenshots/VolcanoFifthPass/before-after.jpg) · [Rustige stromingsanimatie](Screenshots/VolcanoFifthPass/lava-flow.gif) · [iPhonebreedte](Screenshots/VolcanoFifthPass/native-393.png) · [iPadbreedte](Screenshots/VolcanoFifthPass/native-834.png) · [Aansluitings- en plaatsingscontrole](WorldTestLogs/VolcanoFifthPass/native-render.log) · [iOS-build](WorldTestLogs/VolcanoFifthPass/build.log).

## Zesde verbeterslag — zichtbare stroming, basaltblokken en geen zigzags

De zwakke, lange reflecties zijn vervangen door afgeronde lavatongen: een hete lichte voorkant met een zachter oranje verloop en een donkerder afkoelend spoor. Ze schuiven over de werkelijke lengte van de gebogen geulen, zijtakken en vulkaanhellingen. De beweging blijft rustig, met circa zes punten per seconde in de hoofdgeulen. Het grotere contrast en de duidelijk afgebakende voorkant maken de verplaatsing zichtbaar. De dunne vertakkende lavanaden en de aangesloten vulkanen blijven behouden. De benodigde geometrie wordt vooraf opgebouwd; alle tekenvlakken gebruiken dezelfde posities en fase.

De losse oranje zigzagkrassen op de basaltgrond en de kleine oranje krassen op losse stenen zijn verwijderd. Er staan meer rotsblokken, kleinere keien en puin, met een nieuwe hoekige basaltvorm tussen de ronde stenen. Groepen krijgen extra losse steentjes. Op telefoonbreedtes passen nu 76–110 rotsgroepen, tegenover 72 in de vorige versie, en de grotere blokken nemen meer oppervlak in.

De iOS-build slaagt. De plaatsingscontrole op tien breedtes vindt alle vijf aangesloten vulkanen en geen lava onder de 1.233 rotsgroepen in deze composities. De 163.800 meetpunten in de bergen blijven vrij van het pad en de hoofdgeulen. De 48 animatiebeelden verschillen; Minder beweging levert twee identieke beelden op.

De stroming is daarnaast gecontroleerd in de draaiende app op een tijdelijke iPhone 17 met iOS 27, met afzonderlijke testvoortgang. Twee screenshots zonder scrollen of aanraken tonen verplaatste lava-accenten. In een uitsnede met alleen de hoofdgeul verschillen 1.958 pixels met meer dan 18 RGB-niveaus. De tijdelijke simulator is na de controle verwijderd.

[Voor/na](Screenshots/VolcanoSixthPass/before-after.jpg) · [Stromingsanimatie](Screenshots/VolcanoSixthPass/lava-flow.gif) · [Actueel appbeeld](Screenshots/VolcanoSixthPass/app-motion-0.png) · [Bewegingsdetail in de app](Screenshots/VolcanoSixthPass/app-flow-detail.png) · [Plaatsingscontrole](WorldTestLogs/VolcanoSixthPass/native-render.log) · [Bewegingscontrole](WorldTestLogs/VolcanoSixthPass/app-motion.txt) · [iOS-build](WorldTestLogs/VolcanoSixthPass/build.log).

## Zevende verbeterslag — vloeiende aansluitingen en complete rotsranden

De zijstromen verlaten de vulkaanvoet vloeiend en sluiten in de richting van de hoofdgeul aan. Hun laatste stuk volgt de hoofdgeul, zodat het uiteinde binnen de stroom ligt. De hoofdgeul wordt daarna getekend; daardoor steekt er geen donkere eindkap of haakje meer uit de aansluiting. Beide stromen gebruiken dezelfde kleurverdeling over de kaart, zodat ook de kleur bij de samenkomst aansluit.

Rond het lichte pad liggen nu zandkleurige asbermen, met daarbuiten warmere, donkere as- en basaltgrond. Het groen verschijnt pas vlak voor de overgang naar Dino Dorp. De renderer van het hoofdpad en de levelstenen zijn niet aangepast. In vier vergelijkingsbeelden zijn **445.891 egale lichte padpixels identiek** aan de vorige versie.

Grote basaltblokken krijgen nu een eigen gesloten contour, afgeronde randen, een schaduw en een afgewerkte donkere voorzijde. De volledige vorm past op de oever; rotsvlakken worden niet meer tegen de gebogen oeverrand afgeknipt. Ook losse keien houden hun volledige vorm binnen het scherm. De rotsen worden onderaan kleiner of blijven uit de smaller wordende oever weg, zodat de laatste grote vlakken een complete voet houden.

De plaatsingscontrole op tien breedtes van 320 tot 1194 punten controleert **611 complete basaltblokken** en **1.240 losse rotsgroepen**. Geen blokcontour kruist de oeverrand; losse stenen worden niet door het scherm afgesneden en raken geen lava. Alle vijf vulkanen houden een vrije plek naast de hoofdstromen. De laatste segmenten van alle zijstromen vallen exact op de hoofdgeul. De iOS-build slaagt; de nieuwe ondergrond en de overgang naar wereld 4 zijn ook in de draaiende iPhone-app bekeken. De 48 animatiebeelden verschillen en twee beelden met Minder beweging zijn identiek.

[Voor/na onderkant van de wereld](Screenshots/VolcanoSeventhPass/before-after.jpg) · [Actueel appbeeld bij eindbaas en overgang](Screenshots/VolcanoSeventhPass/boss-transition-iphone.png) · [Stromingsanimatie](Screenshots/VolcanoSeventhPass/lava-flow.gif) · [Complete contouren en aansluitingen](WorldTestLogs/VolcanoSeventhPass/native-render.log) · [Licht pad behouden](WorldTestLogs/VolcanoSeventhPass/trail-pixels.txt) · [iOS-build](WorldTestLogs/VolcanoSeventhPass/build.log).
