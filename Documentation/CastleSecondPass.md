# Tijdkasteel — verbonden hoven, trappen en bruggen, 19 oktober 2026

De tweede ronde werkt het koninkrijk verder uit. De losse grote trappen zijn vervangen door vier hofpartijen met gedeelde bordessen, toegangsbruggen en duidelijke bestemmingen. De nieuwe vormgeving blijft native SwiftUI/Canvas.

## Verbindingen

Elke hofpartij heeft een bovenhof, twee lange trapvluchten, een tussenbordes met een tuinpoort en een lagere kade. Boven en onder sluit een stenen brug aan op het wandelpad aan de andere kant van het water. Zo ontstaat per hof een volledige wandelroute.

| Bovenhof | Onderweg | Aankomst beneden |
| --- | --- | --- |
| Gekroond dinostandbeeld op een ommuurd voorplein | Twee trappen en een balkon met toegang tot de rozentuin | Kade met een boogbrug naar de promenade |
| Paleis met blauwe daken en kroonpoort | Twee trappen, een tuinbalkon, een open sierhek en kleine fontein | Kade met een tweede paleisbrug |
| Verhoogde fonteintuin | Twee trappen en een bordes naast de formele bloembedden | Een lagere tuinbrug |
| Grote open kroonpoort en wachttoren | Twee trappen en een tuinbalkon bij de laatste hofpartij | Brug en promenade naar het eindplein |

Er zijn **acht lange trapvluchten**, naast **vier korte toegangstrappen** op de bovenste voorpleinen. De treden, zijwanden, balusters, leuningen, vaandels en lantaarns volgen dezelfde eindpunten als de stenen bordessen. Er staat geen bloembak midden in een trapingang.

De kloktoren staat op een eigen kade op de droge buitenoever. Een aparte toegangsbrug maakt de **negende koninklijke brug**. De bruggen hebben open gemetselde bogen, afzonderlijke sluitstenen, bestrating, dubbele balustrades, vergulde sierbollen, kroonvaandels en lantaarns. Hun buitenste dekuiteinden komen op de echte hofbordessen uit. De bestaande beek loopt zichtbaar door onder de boog.

## Heggen en aankleding

- Volle, gesnoeide heggen volgen de gebogen promenades. Hun volumes lopen tot op de grond door; de bovenzijde heeft afzonderlijke blaadjes, lichte randen en roze rozen.
- Bij iedere brug is de heg onderbroken voor de toegang. De tuinkamers hebben eveneens een opening op de plek waar het grindpad van het tussenbordes binnenkomt.
- De formele parterres hebben omlopende heggen, ronde plantenperken, roze en witte bloemen, een eigen pad en op brede schermen bankjes met kroonornamenten en cipressen.
- De nieuwe poorten hebben echte doorgangen. Sommige hebben blauwe torenkapjes en stenen kronen; de kleinere poorten hebben goudaccenten en opengedraaide smeedijzeren hekken.
- Bredere tuinterrassen, gemetselde wanden, extra torens en standbeelden vullen de iPad-randen. De promenades sluiten aan het begin en einde weer op het hoofdpad aan.

## Plaatsing

`CastleKingdomLayout.District` deelt de bovenste, middelste en onderste bordessen tussen de trapvluchten en bruggen. De trappen staan op de buitenoever; ze zijn geen losse decorstukken die boven een beek zijn gelegd.

De plaatsing controleert de werkelijke gestrookte kanaalvorm, inclusief de ronde binnenrand van de scherpe uitmonding. De boven- en ondermarge van de trapvoet en de stenen zijwanden tellen mee. Gemeten oeverranden worden binnen een tekenbeurt hergebruikt. Alle vormen blijven los van de bestaande speelroute en levelbediening.

## Beelden en controles

[Voor en na](Screenshots/CastleSecondPass/before-after.jpg) vergelijkt deze ronde met de eerste verbeterslag. De native landschapscomposities zijn vastgelegd op [320](Screenshots/CastleSecondPass/native-320.png), [393](Screenshots/CastleSecondPass/native-393.png), [834](Screenshots/CastleSecondPass/native-834.png) en [1194](Screenshots/CastleSecondPass/native-1194.png) punten breed. Ook de overgang vanuit Tijdpiraten is opnieuw gerenderd op deze vier breedtes.

De geometriecontrole is uitgevoerd op 320, 375, 393, 402, 430, 600, 744, 834, 1024 en 1194 punten. **58.920 meetpunten** in de daadwerkelijke trapcontouren blijven vrij van de speelroute en de kanaaloevers. Op iedere breedte staan alle acht lange trapvluchten; minstens 55% van de breedte van iedere vlucht blijft in beeld. Alle negen bruggen overspannen de werkelijke beek en hebben droge eindpunten op beide oevers.

Voor de negen bruggen zijn ook losse renders gemaakt. In elk van de daadwerkelijk getekende bogen zijn vier punten op de bestaande beeklijn gecontroleerd: alle 36 punten laten het water door de transparante opening zien. Dat controleert de uitgesneden brugopening afzonderlijk van de kaartachtergrond.

[Native render- en geometriecontrole](WorldTestLogs/CastleSecondPass/native-render.log) · [Definitieve simulatorbuild](WorldTestLogs/CastleSecondPass/final-build.log) · [Vergelijking van het kasteelgedeelte](WorldTestLogs/CastleSecondPass/castle.diff) · [Controle van de overige broncode](WorldTestLogs/CastleSecondPass/scope-check.txt).

De definitieve simulatorbuild slaagt. De bestaande `testNativeWorldChaptersAndMinuteQuestions`, `testWorldBossSceneryRemainsPlayable` en `testComingSoonOnlyAfterLevelHundred` zijn gericht voor wereld 10 uitgevoerd op iPhone 17 en iPad Pro 11-inch (M5), beide met iOS 27: **zes geslaagde schermtestuitvoeringen, nul fouten**. Ze controleren het openen van level 91 en het goed beantwoorden van een vraag, de bereikbaarheid en bediening van de eindbaas en de afsluiting na level 100 zonder level 101.

[Schermtests op iPhone](WorldTestLogs/CastleSecondPass/iphone.log) · [Schermtests op iPad](WorldTestLogs/CastleSecondPass/ipad.log).

| Werkelijk appbeeld | iPhone | iPad |
| --- | --- | --- |
| Verbonden trappen, tuinbordes en bruggen | [Beeld](Screenshots/CastleSecondPass/connections-iphone.png) | [Beeld](Screenshots/CastleSecondPass/connections-ipad.png) |
| Entree | [Beeld](Screenshots/CastleSecondPass/entrance-iphone.png) | [Beeld](Screenshots/CastleSecondPass/entrance-ipad.png) |
| Eerste vraag | [Beeld](Screenshots/CastleSecondPass/question-iphone.png) | [Beeld](Screenshots/CastleSecondPass/question-ipad.png) |
| Eindbaas en laatste hofpartij | [Beeld](Screenshots/CastleSecondPass/boss-iphone.png) | [Beeld](Screenshots/CastleSecondPass/boss-ipad.png) |
| Afsluiting | [Beeld](Screenshots/CastleSecondPass/ending-iphone.png) | [Beeld](Screenshots/CastleSecondPass/ending-ipad.png) |

De native beelden, overgang en daadwerkelijke appbeelden zijn visueel gecontroleerd. De tests gebruiken afzonderlijke Debug-testprofielen en zijn voor deze ronde niet aangepast. De twee speciaal aangemaakte simulatoren zijn na de controle verwijderd. `git diff --check` is schoon.

De broncontrole bevestigt dat het volledige kaartbestand `WorldMap.swift` en alle broncode vóór en na het kasteelgedeelte gelijk zijn aan het begin van deze ronde. De HUD, levelstenen, hoofdroute, vragen en voortgang behouden hun bestaande gedrag.
