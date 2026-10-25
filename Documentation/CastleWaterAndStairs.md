# Tijdkasteel — water en trapaansluitingen, 21 oktober 2026

De twee rivieren hebben stromende reflecties en meedrijvende rimpels. De drie fonteinen krijgen bewegende waterbogen, druppels, overlopende schalen en uitdijende bassinrimpels. Beide cascades hebben sneller vallende waterstrepen en schuim dat stroomafwaarts verdwijnt. De watervalvoet gebruikt dezelfde riviercontour en breedte als de stroom; de losse ovale plas is verwijderd.

De waterlaag draait op 20 beelden per seconde in kleine zichtbare vlakken. Stenen architectuur blijft in de bestaande terreinlaag. Vaste maskers houden bruggen, trappen en andere voorgrond voor het water. De animatie pauzeert buiten beeld, bij een inactieve app en met **Minder beweging**.

## Trappen en wandelpaden

- Alle acht trapvluchten hebben dezelfde loopbreedte en rustigere hoeken. Het aantal treden volgt de lengte van de vlucht.
- Voorplein, tussenbordes en onderkade hebben gedeelde aansluitpunten. De korte decoratieve toegangstreden zijn vervangen door een vrij bovenbordes. Bestratingsvoegen maken de vlakke bordessen herkenbaar.
- Brugdekken en hun leuningen eindigen naast de trapingang. De leuning staat daardoor niet meer midden voor de volgende trap.
- De pasvormcontrole houdt ook de volledige bordessen vrij van de rivier. Het paleis staat verder achter de toegang; plantenbakken, bloemperken en tuinpoorten houden afstand tot de trapvluchten.
- De zijpaadjes bij de entree en afsluiting zijn verwijderd. Wandelpaden en heggen volgen de rivier tot buiten beeld.

## Verificatie

De native composities zijn visueel gecontroleerd op [320](Screenshots/CastleWaterAndStairs/native-320.jpg), [393](Screenshots/CastleWaterAndStairs/native-393.jpg), [834](Screenshots/CastleWaterAndStairs/native-834.jpg) en [1194](Screenshots/CastleWaterAndStairs/native-1194.jpg) punten. De geometriecontrole op tien breedtes controleert acht trapvluchten, twaalf bordessen en negen bruggen per breedte. Alle **51.505 meetpunten** binnen de geteste trapcontouren blijven vrij van rivier en speelroute. Alle negen daadwerkelijk gerenderde brugbogen laten de bestaande rivier door. [Render- en geometrielog](WorldTestLogs/CastleWaterAndStairs/native-render.log).

Vaste animatiemomenten op 0,00 en 0,65 seconde tonen verandering bij beide cascades en alle fonteinen die in beeld staan. Binnen de geteste trap- en speelroutemaskers veranderen **nul pixels**, zowel op 393 als op 834 punten. Ook zonder scrollen in de echte iPhone-app bewegen rivier, fontein en cascade. [Animatiecontrole](WorldTestLogs/CastleWaterAndStairs/animation.log) · [Appbeeld met water en trappen](Screenshots/CastleWaterAndStairs/water-and-stairs-iphone.jpg).

De definitieve simulatorbuild slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions`, `testWorldBossSceneryRemainsPlayable` en `testComingSoonOnlyAfterLevelHundred` controleren level 91, een spelvraag, de bereikbaarheid van de eindbaas en de afsluiting na level 100. Ze zijn gericht uitgevoerd op iPhone 18 Pro en iPad Air 13-inch (M4), beide met iOS 27, met afzonderlijke testprofielen. **Zes geslaagde testuitvoeringen, nul fouten.**

[Build](WorldTestLogs/CastleWaterAndStairs/build.log) · [iPhone-tests](WorldTestLogs/CastleWaterAndStairs/iphone.log) · [iPad-tests](WorldTestLogs/CastleWaterAndStairs/ipad.log) · [Entree op iPad](Screenshots/CastleWaterAndStairs/entrance-ipad.jpg) · [Afsluiting op iPad](Screenshots/CastleWaterAndStairs/ending-ipad.jpg) · [Wijzigingen in het kasteelgedeelte](WorldTestLogs/CastleWaterAndStairs/castle.diff).

## Vervolg — 22 oktober 2026

Heggen en wandelpaden worden nu op een vaste afstand van dezelfde riviercontour gelegd. De horizontaal verschoven kopieën zijn vervangen door afstandscontouren. De zichtbare bovenzijde van de heg volgt die contour eveneens. Vloeiende riviermonden sluiten bij de entree en afsluiting met passende raaklijnen aan, zodat de parallelle paden geen scherpe punten vormen. Beide oevers lopen buiten beeld door.

De fonteinstralen vertrekken omhoog uit de bovenste sproeier en vallen in gebogen banen terug naar het bassin. Ook de overloop buigt eerst over de schaalrand. Bewegende losse druppels vervangen de rechte, gestreepte waterbanen. [Fontein: voor en na](Screenshots/CastleFlowRefinement/fountain-before-after.jpg).

Bij de cascades stopt het metselwerk aan de oevers. Zachte kleurovergangen en afzonderlijk bewegende waterlinten vervangen de harde diagonale snijlijn. [Cascade: voor en na](Screenshots/CastleFlowRefinement/cascade-before-after.jpg).

De tussenbordessen zijn breder en minder diep: 76 × 24 tekenpunten in plaats van 64 × 36. Een dunne rand, lichte bestrating in perspectief en aansluitende zijleuningen maken er een horizontaal loopvlak van. Beide trappen sluiten op de werkelijke vloeruiteinden aan. [Bordes: voor en na](Screenshots/CastleFlowRefinement/platform-before-after.jpg). De digitale klok is van de toren verwijderd; de analoge wijzerplaat blijft staan.

De [geometriecontrole](WorldTestLogs/CastleFlowRefinement/native-render.log) controleert de afstanden op tien schermbreedtes. De gemeten contourpunten wijken minder dan 0,002 punt af van de gekozen afstand tot de rivier. De heggen blijven vrij van de speelroute, alle twaalf bordessen en acht trapvluchten liggen droog, en de negen brugbogen laten het water door. Er zijn 55.579 meetpunten in de geteste trapcontouren gecontroleerd.

Native beelden op [320](Screenshots/CastleFlowRefinement/native-320.jpg), [393](Screenshots/CastleFlowRefinement/native-393.jpg), [834](Screenshots/CastleFlowRefinement/native-834.jpg) en [1194](Screenshots/CastleFlowRefinement/native-1194.jpg) punten zijn visueel gecontroleerd. De [animatievergelijking](WorldTestLogs/CastleFlowRefinement/animation.log) bevestigt beweging bij de zichtbare fonteinen en cascades, met nul veranderde pixels binnen de trap- en speelroutemaskers. De [definitieve simulatorbuild](WorldTestLogs/CastleFlowRefinement/build.log) slaagt. [Bronvergelijking van deze vervolgronde](WorldTestLogs/CastleFlowRefinement/castle.diff).

De drie bestaande schermtests voor level 91 en een spelvraag, de eindbaas en de afsluiting na level 100 slagen opnieuw op iPhone 18 Pro en iPad Air 13-inch (M4), beide met iOS 27: **zes geslaagde uitvoeringen, nul fouten**. Ook tijdelijke lege en kleine beginlayouts zijn gecontroleerd. [iPhone-tests](WorldTestLogs/CastleFlowRefinement/iphone.log) · [iPad-tests](WorldTestLogs/CastleFlowRefinement/ipad.log) · [Werkelijke entree op iPhone](Screenshots/CastleFlowRefinement/entrance-iphone.jpg) · [Werkelijke afsluiting op iPad](Screenshots/CastleFlowRefinement/ending-ipad.jpg).

## Afwerking van bordessen en brugtoegangen — 22 oktober 2026

De vier tussenbordessen zijn teruggebracht naar 64 × 24 tekenpunten, met afgeronde hoeken en een dunne, gebogen voorrand. De uitwaaierende vloer en geknikte binnenleuning zijn vervangen door een compacte vloer en een leuning die vloeiend aansluit op de richting van beide trapvluchten. De lantaarn staat op de leuninglijn. [Bordes: voor en na](Screenshots/CastleLandingsAndBridgeEntries/landing-before-after.jpg).

Bij alle negen bruggen buigt de heg nu naar de werkelijke eindpalen van de brugleuning. Het grondniveau, de hoogte van de heg en de randen van het brugdek bepalen de opening. Een kort, afgerond en licht verbreed toegangsvlak met passende bestrating verbindt het wandelpad met het brugdek. De losse onderbrekingen van vaste lengte zijn daarmee vervangen door herkenbare brugtoegangen. [Brugtoegang: voor en na](Screenshots/CastleLandingsAndBridgeEntries/bridge-before-after.jpg) · [Alle negen aansluitingen](Screenshots/CastleLandingsAndBridgeEntries/all-bridges.jpg).

De native beelden zijn gecontroleerd op [320](Screenshots/CastleLandingsAndBridgeEntries/native-320.jpg), [393](Screenshots/CastleLandingsAndBridgeEntries/native-393.jpg), [834](Screenshots/CastleLandingsAndBridgeEntries/native-834.jpg) en [1194](Screenshots/CastleLandingsAndBridgeEntries/native-1194.jpg) punten. De [geometriecontrole op tien breedtes](WorldTestLogs/CastleLandingsAndBridgeEntries/native-render.log) bevestigt dat alle hegretouren de eindpalen raken en de volledige toegangsvlakken vrij blijven van de beschermde speelroute. Alle twaalf bordessen en acht trapvluchten liggen droog; alle negen gerenderde brugbogen laten het water door. De [animatievergelijking](WorldTestLogs/CastleLandingsAndBridgeEntries/animation.log) meet nul veranderde pixels binnen de trap-, bordes- en speelroutemaskers.

De [definitieve simulatorbuild](WorldTestLogs/CastleLandingsAndBridgeEntries/build.log) slaagt. De bestaande schermtests voor level 91 en een spelvraag en voor de bereikbaarheid van de eindbaas slagen op iPhone 18 Pro en iPad Air 13-inch (M4), beide met iOS 27: **vier geslaagde uitvoeringen, nul fouten**. [iPhone-tests](WorldTestLogs/CastleLandingsAndBridgeEntries/iphone.log) · [iPad-tests](WorldTestLogs/CastleLandingsAndBridgeEntries/ipad.log) · [Entree op iPhone](Screenshots/CastleLandingsAndBridgeEntries/entrance-iphone.jpg) · [Afsluiting op iPad](Screenshots/CastleLandingsAndBridgeEntries/ending-ipad.jpg) · [Bronvergelijking](WorldTestLogs/CastleLandingsAndBridgeEntries/castle.diff).

## Vrije heggen en aflooptrapjes — 25 oktober 2026

De heggen stoppen vóór de brugtoegangen, met minstens twaalf geschaalde tekenpunten vrije ruimte rond de trapjes. Ze buigen niet meer door tot tegen de brugpalen. Alle negen bruggen hebben aan de kant van het wandelpad drie stenen aflooptreden en een klein bordes op de droge oever. Het bordes houdt ook in scherpe bochten afstand tot de speelroute. De trapjes worden samen met de brug getekend en zitten daardoor ook in het masker van het bewegende water.

[Voor en na op telefoon- en tabletbreedte](Screenshots/CastleBridgeDescents/bridge-before-after.jpg).

De native composities zijn visueel gecontroleerd op 320, 393, 834 en 1194 punten breed. De geometriecontrole op tien breedtes controleert 105.441 punten in de treden en bordessen: alle aansluitingen blijven droog en vrij van de speelroute; de heggen houden hun vrije ruimte. De definitieve simulatorbuild slaagt. De gewijzigde brugtoegangen zijn ook in de iPhone-app bekeken.
