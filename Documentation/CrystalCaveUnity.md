# Samenhangende kristallen en rotsen — 27 oktober 2026

De grot oogde als een verzameling losse vormen: kleine rotsblokken hadden sterke schaduwen, iedere kristal had een eigen lichtvlek en de groepen wisselden voortdurend van kleur. De oorspronkelijke native tekeningen zijn verder uitgewerkt tot grotere rotslagen met ingebedde mineraalgroepen.

- Grotere, overlappende wandstenen delen een koeler blauwgrijs palet. Zachtere schaduwen en minder contrast tussen de facetten verbinden de stenen tot een wand.
- Iedere kristalgroep groeit uit één rotsbed met een verdiepte ader en een onregelmatige voorrand. De voorrand bedekt de kristalvoeten. Kleine mineraalinleg en gereflecteerd licht verbinden de kleuren met het gesteente.
- Zes asymmetrische silhouetten geven de groepen verschillende hoogten en groeirichtingen. Naburige groepen delen dezelfde mineraalkleur; de losse regenboogaccenten en afzonderlijke lichtvlekken zijn verwijderd. Reflectiestrepen zijn smaller en transparanter.
- Ook de kleinere aders in de wand krijgen een gedeelde rotsvoet. Bewegende glinsteringen gebruiken dezelfde hoogten en groeirichting als de nieuwe kristallen.
- De grotere kristalgroepen houden de twee digitale klokdisplays vrij, naast de bestaande vrije ruimte voor mijnhout en de eindbaas.

De wijzigingen zitten in de grotgeometrie en `CrystalCavePainter`. De gedeelde steenpainter werkt de aansluitende grotstenen bij de stadsingang in hetzelfde materiaal af. Bestaande wijzigingen in de gedeelde checkout zijn behouden.

## Beelden

[Voorheen, 393 punten](Screenshots/CrystalCaveUnity/before-walls-393.png) · [Nieuw, 393 punten](Screenshots/CrystalCaveUnity/walls-393.png)

[320 punten](Screenshots/CrystalCaveUnity/walls-320.png) · [834 punten](Screenshots/CrystalCaveUnity/walls-834.png) · [1194 punten](Screenshots/CrystalCaveUnity/walls-1194.png) · [Onderste grotdeel, telefoon](Screenshots/CrystalCaveUnity/lower-320.png) · [Onderste grotdeel, tablet](Screenshots/CrystalCaveUnity/lower-834.png)

Dit zijn statische native controlerenders met hulpcirkels voor de levelposities. De bewegende lampen, mijnwerkers, daadwerkelijke levelstenen en Dino worden afzonderlijk in de simulator gecontroleerd. De controlerender gebruikt een oude vectorbaas als stand-in; de app behoudt de bestaande bossafbeelding.

## Verificatie

De native beelden zijn op 320, 393, 834 en 1194 punten breed visueel gecontroleerd. De simulatorbuild slaagt. De bestaande hoofdstuktest wacht nu op het einde van de kaartopening voordat hij controleert of het eerste level actief is; zonder die synchronisatie kon de test de tijdelijk uitgeschakelde kaart tijdens de openingsanimatie meten.

`testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` slagen gericht voor wereld 5 op iPhone 18 Pro en iPad Pro 13-inch (M5): **vier geslaagde testuitvoeringen, nul fouten**. De eerste test opent level 41 en beantwoordt een vraag; de tweede opent de grotbaas via level 50. Alle runs gebruiken geïsoleerde Debug-testvoortgang. `git diff --check` is schoon.

[Appbeeld iPhone](Screenshots/CrystalCaveUnity/entrance-iphone.png) · [Appbeeld iPad](Screenshots/CrystalCaveUnity/entrance-ipad.png) · [Eindbaas iPhone](Screenshots/CrystalCaveUnity/boss-iphone.png) · [Eindbaas iPad](Screenshots/CrystalCaveUnity/boss-ipad.png)

[Buildlog](WorldTestLogs/CrystalCaveUnity/build.log) · [iPhone-tests](WorldTestLogs/CrystalCaveUnity/iphone.log) · [iPad-tests](WorldTestLogs/CrystalCaveUnity/ipad.log) · [Native renders](WorldTestLogs/CrystalCaveUnity/native-render.log) · [Diff van alleen deze grotwijziging](WorldTestLogs/CrystalCaveUnity/cave-only.diff)
