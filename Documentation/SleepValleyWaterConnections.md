# Slaapvallei — klokjes en wateraansluitingen, 18 oktober 2026

## Aanpassingen

- De losse wekkers langs het pad zijn vervangen door paddenstoelen en begroeiing. Het klokicoontje in het titelbord is nu een maan. Dommels dekentje heeft een maan met sterren in plaats van een klok; dezelfde tekening verschijnt op de kaart en de baasstartkaart.
- Elk klein stroompje volgt nu de werkelijke beekbocht. Toevoer, overlooprand, vallend water en uitstroom gebruiken dezelfde kanaalgeometrie. De toevoer begint ruim boven de rand; de uitstroom buigt beneden door en mengt geleidelijk terug in de beek.
- Bewegende waterdraden lopen van de toevoer door de val naar de uitstroom. Kleine schuimplekken laten het water eronder zichtbaar. Rimpels bewegen met de uitstroom mee.
- Het water ligt achter de voorliggende tuinen en boomkruinen. Oeverstenen en bloemen flankeren het kanaal; er ligt geen afsluitend rotsblok boven de toevoer of onder de uitstroom.
- Het bestaande begin van beide beekjes blijft behouden. De rechterbeek buigt onderaan eerder naar buiten en verdwijnt, afhankelijk van de schermbreedte, 164–170 punten vóór de linkerbeek.
- De rechterlavastroom begint hoger, in de laatste 220 punten van Slaapvallei. Dezelfde stroomgeometrie, kleuren en animatiefase lopen door in Vulkaanland. De korte terreinvervaging bij de wereldgrens laat de lava zichtbaar. De linker lava-ingang en de levelindeling zijn gelijk gebleven.

## Beelden

[Watervalaansluiting voor en na](Screenshots/SleepValleyWaterConnections/waterfall-before-after.jpg).

Overgang 2 → 3 op [320](Screenshots/SleepValleyWaterConnections/transition-320.png), [393](Screenshots/SleepValleyWaterConnections/transition-393.png), [834](Screenshots/SleepValleyWaterConnections/transition-834.png) en [1194](Screenshots/SleepValleyWaterConnections/transition-1194.png) punten breed. Deze native auditbeelden gebruiken eenvoudige genummerde routecirkels; de echte spelinterface is afzonderlijk in de simulator gecontroleerd.

## Verificatie

De [definitieve iOS-simulatorbuild](WorldTestLogs/SleepValleyWaterConnections/final-build.log) slaagt. `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn voor wereld 2 én 3 uitgevoerd op [iPhone 17](WorldTestLogs/SleepValleyWaterConnections/iphone-playability.log) en [iPad Pro 11-inch](WorldTestLogs/SleepValleyWaterConnections/ipad-playability.log): vier geslaagde testuitvoeringen, nul fouten. Deze tests openen beide werelden, beantwoorden een vraag en openen beide wereldbazen met geïsoleerde Debug-profielen.

Native composities en de overgang zijn op vier breedtes visueel gecontroleerd. Voor alle vier stroompjes is de middellijn bij toevoer, overlooprand, voet en uitstroom vergeleken met de echte beeklijn; de afwijking is kleiner dan 0,001 punt. De rechterbeek eindigt op alle breedtes eerder; de lava is op de wereldgrens al zichtbaar en blijft buiten het pad. [Geometriecontrole](WorldTestLogs/SleepValleyWaterConnections/native-geometry.log).

Vier animatietijdstippen verschillen. De twee renders met de stilstandoptie zijn pixelgelijk en hebben identieke bestandsinhoud. [Meetresultaten](WorldTestLogs/SleepValleyWaterConnections/visual-checks.json). `git diff --check` is schoon.
