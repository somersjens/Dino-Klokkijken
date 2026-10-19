# Tijdkasteel — eerste redesignronde, 19 oktober 2026

Het aangeleverde koninkrijksontwerp is de richting voor deze eerste verbeterslag van wereld 10. De gelaagde omgevingen van Vulkaanland, Kristalgrot en Slaapvallei dienen als referentie voor de aankleding. Het landschap wordt volledig met native SwiftUI/Canvas-geometrie getekend.

## Landschap

- De aparte blauwe luchtstrook, zon en wolken zijn vervangen door doorlopende warme steengrond. Verre paleizen en torens vervagen boven de entree in een zachte nevel. De achtergrond sluit aan op het einde van Tijdpiraten en op de bestaande afsluiting na level 100.
- Twee ommuurde waterlopen volgen de bochten langs het gouden speelpad. Ze hebben lichte stenen randen, onregelmatig verdeelde waterreflecties en twee kleine cascades met gemetselde wanden, afzonderlijke waterdraden en schuim. De waterlopen komen via de zijtuinen binnen en verlaten de kaart ook via de zijkanten.
- Gemetselde tuinmuren met boognissen, bloeiende richels en klimop verbinden de grotere scènes. De paleispleinen lopen naar de buitenrand door. Op brede iPads krijgen de buitenste tuinen extra torens, cipressen en standbeelden.
- Twee hoge trappen hebben elk vijftien afzonderlijke treden, versmalling naar de bovenste overloop, stenen zijwanden, balusters, leuningen, pijlers, blauwe kroonvaandels en gouden lantaarns.
- Twee gekroonde langnekstandbeelden staan op stenen sokkels met een gouden embleem. Ze hebben een uitgesneden dino-silhouet, afzonderlijke poten, staart, vriendelijk gezicht, steenvoegen, kroonstenen en wat klimop. Kleinere exemplaren vullen de buitenste tablettuinen.
- Een grotere paleispartij heeft een hoge centrale kap, meerdere torens op verschillende dieptes, boogramen, een blauwe kroondeur en een trapvormige toegang. De bestaande koninklijke poort blijft bij Chronos staan.
- Fonteinen hebben meerdere schalen, waterbogen, overlopende waterdraden, bassinranden en rimpels. Volle cipressen met afzonderlijke bladclusters, meer roze en witte bloemen en lantaarns vullen de tuinen.
- Torens krijgen rijker blauw op hun daken, dakpannen, schaduwkanten, kroonlijsten, kraagstenen, raam- en deurdiepte, verweerde steenblokken en kleine breukjes. De kloktoren toont 10:25 met bijpassende analoge wijzers en Romeinse kwartiermarkeringen.

## Opbouw en afbakening

`CastleKingdomLayout` legt de grote scènes naast het daadwerkelijke kubische speelpad. Ook de bovenkant van torens en de voet van trappen tellen mee bij hun plaatsing. De grotere architectuur deelt de bestaande volgorde op grondcontact met de eindbaas. Het plan wordt per tekenbeurt één keer opgebouwd en hergebruikt voor de plaatsing van de tuindetails.

`CastleWorldPainter` tekent het landschap. De bestaande wereldpreviews delen de bijgewerkte toren-, bloem- en materiaaldetails. Deze ronde voegt statische omgevingsdetails toe; afzonderlijke water- en vlaganimaties zijn een mogelijke vervolgronde.

De HUD, titelbordindeling, levelstenen, speelroute, spelvragen en voortgang zijn voor dit redesign niet aangepast. Gelijktijdige wijzigingen in de gedeelde werkmap buiten het kasteelgedeelte zijn behouden.

## Beelden

De native composities zijn gerenderd op [320](Screenshots/CastleFirstPass/native-320.png), [393](Screenshots/CastleFirstPass/native-393.png), [834](Screenshots/CastleFirstPass/native-834.png) en [1194](Screenshots/CastleFirstPass/native-1194.png) punten breed. Deze controlebeelden tonen de echte landschaps- en levelsteencode met genummerde hulplabels; de vaste HUD en kaartdino zijn daarin weggelaten.

[Voor en na](Screenshots/CastleFirstPass/before-after.jpg) toont het volledige landschap op iPhonebreedte.

Ook de overgang 9→10 is op alle vier breedtes vastgelegd: [iPhonebreedte](Screenshots/CastleFirstPass/transition-9-10-393.png) en [brede iPad](Screenshots/CastleFirstPass/transition-9-10-1194.png).

## Verificatie

De [native renderbuild](WorldTestLogs/CastleFirstPass/native-build.log) en de [definitieve iOS-simulatorbuild](WorldTestLogs/CastleFirstPass/final-build.log) slagen. Alle vier compositiebreedtes en de overgangen zijn visueel gecontroleerd. `git diff --check` is schoon.

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions`, `testWorldBossSceneryRemainsPlayable` en `testComingSoonOnlyAfterLevelHundred` zijn gericht op wereld 10 uitgevoerd met `DINO_TEST_WORLD_IDS=10`. Ze controleren het openen van level 91 en het goed beantwoorden van een vraag, het tikgebied en openen van de eindbaas, en Coming soon onder level 100 zonder level 101. De tests zijn voor dit redesign niet aangepast.

Op iPhone 17 en iPad Pro 11-inch (M5), beide met iOS 27, slagen **zes schermtestuitvoeringen, nul fouten**. De [iPhone-log](WorldTestLogs/CastleFirstPass/iphone.log) en [iPad-log](WorldTestLogs/CastleFirstPass/ipad.log) zijn bewaard. De laatste bronwijziging na de iPhone-tests verzacht alleen het grondkleurverloop bij de wereldgrenzen; de definitieve versie is daarna opnieuw gebouwd, native gerenderd en op iPad getest. Het paleisgebied is ook in die definitieve iPhone-build visueel vastgelegd.

| Appbeeld | iPhone | iPad |
| --- | --- | --- |
| Entree en eerste level | [Beeld](Screenshots/CastleFirstPass/entrance-iphone.png) | [Beeld](Screenshots/CastleFirstPass/entrance-ipad.png) |
| Eerste vraag | [Beeld](Screenshots/CastleFirstPass/question-iphone.png) | [Beeld](Screenshots/CastleFirstPass/question-ipad.png) |
| Koninklijke poort en Chronos | [Beeld](Screenshots/CastleFirstPass/boss-iphone.png) | [Beeld](Screenshots/CastleFirstPass/boss-ipad.png) |
| Afsluiting na level 100 | [Beeld](Screenshots/CastleFirstPass/ending-iphone.png) | [Beeld](Screenshots/CastleFirstPass/ending-ipad.png) |

[Het centrale paleisgebied op iPhone](Screenshots/CastleFirstPass/palace-iphone.png) laat de trappen, grote fontein en paleistorens samen zien. De simulatorcontroles gebruiken uitsluitend afzonderlijke Debug-testprofielen; de twee tijdelijke testapparaten worden na de controle verwijderd.

Een [vergelijking van alleen het kasteelgedeelte](WorldTestLogs/CastleFirstPass/castle.diff) legt deze ronde vast zonder de gelijktijdige dorpswijzigingen in dezelfde bronfile op te nemen. Alle overige bestaande werkmapwijzigingen zijn behouden.
