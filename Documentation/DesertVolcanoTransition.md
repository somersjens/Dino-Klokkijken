# Woestijn → Vulkaanland

20 oktober 2026.

De overgang gebruikt aan beide kanten van de hoofdstukgrens dezelfde vulkaanondergrond, rotsplaatsingen en lavapaden. Een overlap van 400 punten vervangt de losse lavastroom en de horizontale vervaging. Rotsen die de grens kruisen worden met hun volledige contour doorgetekend.

De twee lavastromen komen later binnen, volgens de groene lijnen op de iPhone- en iPad-schetsen. De rechter tak begint eerder dan de linker; beide komen uit een zijrand van Vulkaanland en sluiten vloeiend op de geulen langs het pad aan. De basaltgrond volgt exact dezelfde latere inlaat, met extra breedte bij schuine bochten zodat de lava ook daar door vulkanisch gesteente wordt omgeven. Boven die grens blijven de zandkleuren en windvormige duinranden van de woestijn zichtbaar. Zandige as mengt geleidelijk met de woestijn. De volledige woestijnwachter blijft vrij van de nieuwe losse stenen.

De rijen gestapelde blokken zijn vervangen door ongelijk gevormde en gedraaide rotsvlakken met gebroken ruggen en scheuren. Het terrein deelt één basaltkleur, met kleinere losse brokken eroverheen. Bij de woestijn blijven de losse stenen dicht langs de rotsrand; hun kleur mengt daar naar zand en oker.

De vulkanen gebruiken de vrije ruimte op brede schermen voor aanzienlijk grotere silhouetten. Op iPhone krijgen ze extra hoogte; de eerste vulkaan is daarna op alle breedtes met exact 20% verkleind. De voorliggende puinstenen behouden hun natuurlijke verhoudingen. De plaatsing houdt rekening met de gehele voet, inclusief voorliggende rotsen. Een onregelmatige puinvoet en overlappende keien verbinden de kegels met de ondergrond. De laatste woestijndecoratie staat vóór het inkomende terrein en de effecten, zodat de mesa’s en de woestijnwachter compleet blijven. Rook en lavalicht van grotere vulkanen lopen eveneens over de hoofdstukgrens door.

De binnenrand van het basalt en de zandige schouders gebruiken dezelfde middenlijn als de speelweg. Daardoor volgen de randen dezelfde bochten, met een gelijkmatige afstand tot het pad. De rotsmassa bij de entree volgt de werkelijke lavabocht vanaf de zijrand en gaat pas bij het einde van die inlaat over naar de rand langs de speelweg. De oude, vroeger beginnende terreinlijn is verwijderd.

De volledige vulkaankegel staat vóór de inkomende hoofdstroom, inclusief de bewegende lava. Alleen de eigen uitstroom van de vulkaan wordt op zijn flank getekend. Die gebruikt vanaf de krater tot aan de hoofdgeul één doorlopend pad, één breedte, hetzelfde kleurverloop en dezelfde animatiefase. Daardoor is er bij het middelste puntje van de voet geen naad of kleurwissel. De slagschaduw laat de lava daar vrij; de puinstenen blijven vóór de voet staan. De gewone geulen na de inlaat houden vrije ruimte rond de hele vulkaan.

De titel van Vulkaanland staat drie punten hoger, zodat de vrije ruimte boven en onder het bord gelijk is. De levelposities, speelroute en tikgebieden behouden hun afmetingen. De bewegende lava gebruikt dezelfde volledige paden boven en onder de grens; de bestaande pauzering buiten beeld en ondersteuning voor Minder beweging blijven van toepassing.

## Visuele controle

Native SwiftUI/Canvas-renders van de twee aangrenzende hoofdstukken zijn gecontroleerd op [320](Screenshots/VolcanoAlignedBanks/join-320.png), [393](Screenshots/VolcanoAlignedBanks/join-393.png), [834](Screenshots/VolcanoAlignedBanks/join-834.png) en [1194](Screenshots/VolcanoAlignedBanks/join-1194.png) punten breed. De genummerde baassteen is in deze auditbeelden vereenvoudigd tot een kroonmarkering.

De schermtests gebruiken afzonderlijke debug-opslag voor wereld 2 en 3. De screenshotmap blijft lokaal en is uitgesloten van Git-synchronisatie.

## Verificatie

De definitieve simulatorbuild slaagt. De actuele controle van `testWorldBannersHaveBalancedClearance` met wereld 2 en 3 slaagt op iPhone 17 en iPad Pro 11-inch. Tijdens de gezamenlijke uitvoering werd de iPhone-testlancering door het systeem gestopt; de afzonderlijke herhaling slaagt volledig. [Gezamenlijke testlog](WorldTestLogs/VolcanoAlignedBanks/ui-tests.log) · [geslaagde iPhone-herhaling](WorldTestLogs/VolcanoAlignedBanks/iphone-retry.log). De eerdere spelcontroles voor vragen, tikgebieden en beide eindbazen blijven vastgelegd in [de vorige testronde](WorldTestLogs/VolcanoLaterInlets/ui-tests.log).

Actuele appbeelden: [iPhone](Screenshots/VolcanoAlignedBanks/app-iphone.png) · [iPad](Screenshots/VolcanoAlignedBanks/app-ipad.png). Alle vier native renders en `git diff --check` slagen.

De terreinberekening is daarnaast gecontroleerd op 320, 393, 520, 600, 744, 834, 1024 en 1194 punten breed. Op alle acht breedtes zijn vijf vulkanen geplaatst. De **97.240 silhouetmetingen** vinden geen overlap met het pad of de hoofdstromen ná de zij-inlaten. De aansluitingen vanaf de kraters lopen ononderbroken door tot de hoofdgeulen, vrij van het pad en alle levelstenen. De basaltbedding heeft geen gaten en begint boven de latere zij-inlaten buiten beeld. De eerste vulkaan is op elke breedte exact 20% kleiner; de vier andere behouden hun grootte. De raaklijnen van beide inlaten sluiten vloeiend aan. [Geometriecontrole](WorldTestLogs/VolcanoAlignedBanks/geometry.log).


## Laatste afwerking: vloeiende rotsrand

De twee knikken bij de inlaten zijn verwijderd. De offsetberekening begint nu op de echte horizontale monding van de stroom; het onzichtbare verticale aanloopstuk telt niet meer mee. De rotsrand wordt bovendien met aaneengesloten kubische boogsegmenten getekend, zodat de bolling zonder hoek in de volgende lijn overgaat.

Gecontroleerd op negen breedtes, inclusief de 402 punten van het aangeleverde iPhonebeeld. Alle 109.395 silhouetmetingen, aansluitingen, vrije ruimte langs het pad en de basaltdekking slagen. [Geometriecontrole](WorldTestLogs/VolcanoSmoothBanks/geometry.log). Nieuwe native previews: [iPhone](Screenshots/VolcanoSmoothBanks/join-393.png) · [iPad](Screenshots/VolcanoSmoothBanks/join-834.png) · [breed iPad](Screenshots/VolcanoSmoothBanks/join-1194.png).

De kaartwijziging bouwt succesvol tegen de opgeslagen projectversie in een tijdelijke kopie. [Buildlog](WorldTestLogs/VolcanoSmoothBanks/build.log). De gelijktijdig gewijzigde werkmap wordt bij de volledige build geblokkeerd door de ontbrekende `ResultBiomePainter` in `LevelResult.swift`; die wijziging is buiten deze kaartcorrectie gehouden.
