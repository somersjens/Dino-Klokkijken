# Slaapvallei — eerste redesignronde, 18 oktober 2026

De eerste verbeterslag richt zich op wereld 2 uit het aangeleverde voorbeeld. De gedetailleerde jungle en Kristalgrot zijn de referentie voor de dichtheid van de aankleding. Het landschap bestaat uit native SwiftUI/Canvas-geometrie.

## Beeld en beweging

- Zeven grote en kleine wilgen hebben gelaagde kruinen met afzonderlijke bladtakken. Takken buigen vanaf hun aanhechting; de stammen en wortels blijven staan. Zilveren blauwgroene bladeren krijgen subtiele saliekleurige lichtranden.
- Elke wilg draagt drie warme messing lantaarns met glas, dakjes, ophangogen en een ster. Ze slingeren enkele graden rond hun ophangpunt, met een eigen ritme voor de lichtsterkte.
- Twee beekjes volgen de buitenzijde van het slingerpad. De oevers hebben ongelijke contouren, kleine stenen en begroeiing. De in- en uitmondingen sluiten met gladde bochten aan op de zijkanten.
- Vier kleine watervallen hebben rotswanden, planten, waterdraden, schuim en uitdijende rimpels. Langzame reflecties bewegen door de beekjes. Het houten bruggetje staat nu op de werkelijke beek.
- Extra rotsplateaus, klokbloemen en lavendelkleurige kristallen geven de oevers meer diepte. Glinsteringen zitten op de toppen van de kristallen. Vuurvliegjes zweven en twinkelen; sterren en waterreflecties hebben afzonderlijke ritmes.

De statische ondergrond, stammen en tuinen blijven los van de bewegende lagen. Kleine Canvas-vlakken draaien maximaal twintig keer per seconde, alleen binnen de kaartviewport en als de app actief is. Dieptemaskers houden water en licht achter voorliggende rotsen en beplanting; een aparte uitsparing beschermt het pad en de levelknoppen. Bij **Minder beweging** tonen alle effecten dezelfde stilstaande compositie.

De boomposities, beekgeometrie, watervallen en kristalpunten komen uit `SleepValleyLayout`. De kaart gebruikt `SleepValleyLife` voor de animaties. De bestaande statische wereldpreview gebruikt dezelfde nieuwe wilgen en lantaarns in rust.

## Visuele controle

Native renders op [320](Screenshots/SleepValleyFirstPass/native-320.png), [393](Screenshots/SleepValleyFirstPass/native-393.png), [834](Screenshots/SleepValleyFirstPass/native-834.png) en [1194](Screenshots/SleepValleyFirstPass/native-1194.png) punten breed. De simpele genummerde cirkels in deze auditbeelden zijn markeringen; de daadwerkelijke spelinterface staat in de simulatorscreenshots.

Vier afzonderlijke tijdstippen controleren bladbeweging, lantaarns, water en glinsteringen. Twee renders op verschillende tijdstippen met de stilstandoptie controleren dat Minder beweging hetzelfde beeld behoudt.

## Verificatie

De [definitieve iOS-simulatorbuild](WorldTestLogs/SleepValleyFirstPass/final-build.log) slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn gericht op wereld 2 uitgevoerd: twee geslaagde tests op [iPhone 17](WorldTestLogs/SleepValleyFirstPass/iphone-playability.log) en twee op [iPad Pro 11-inch](WorldTestLogs/SleepValleyFirstPass/ipad-playability.log), zonder fouten. Ze controleren de entree, ontgrendeling en het tikgebied van level 11, een halfuurantwoord en het openen van de wereldbaas.

De uiteindelijke native beelden op alle vier breedtes en de echte simulatorbeelden zijn visueel gecontroleerd. De vier animatietijdstippen verschillen; de twee stilstaande renders zijn pixelgelijk. [Meetresultaten](WorldTestLogs/SleepValleyFirstPass/visual-checks.json). `git diff --check` is schoon.

Tijdens de eerste controle faalde `testWorldBannersHaveBalancedClearance` op beide apparaten. De afstand boven en onder het titelbord verschilt ongeveer twaalf punten. Een aparte build met het oorspronkelijke landschap van vóór deze redesignronde reproduceert dezelfde afwijking op iPhone: 188,11 tegenover 200,22 punten bij een tolerantie van vier. [Controle van de oorspronkelijke versie](WorldTestLogs/SleepValleyFirstPass/baseline-banner-spacing.log). De bordafstand is in deze landschapsronde niet aangepast.

[Voor en na](Screenshots/SleepValleyFirstPass/before-after.jpg). Definitieve simulatorscreenshots: [iPhone-entree](Screenshots/SleepValleyFirstPass/native-world-2-iphone.png), [iPad-entree](Screenshots/SleepValleyFirstPass/native-world-2-ipad.png), [iPhone-baasomgeving](Screenshots/SleepValleyFirstPass/scenery-depth-world-2-iphone.png) en [iPad-baasomgeving](Screenshots/SleepValleyFirstPass/scenery-depth-world-2-ipad.png).

De UI-tests gebruiken geïsoleerde Debug-testprofielen.
