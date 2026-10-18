# Slaapvallei — tweede redesignronde, 18 oktober 2026

De tweede ronde bouwt voort op de bewegende wilgen en lantaarns van de eerste ronde. De nadruk ligt op natuurlijkere vormen en meer diepte rond het pad.

## Uitwerking

- De twee beekjes hebben geen doorlopende parallelle rotsranden meer. Zachte mosoevers, een dunne onderbroken waterlijn en onregelmatige steengroepjes omlijsten water met kleurverloop en ondergedompelde kiezels.
- Op vijf plaatsen verbreedt het water tot een poel. Vijftien waterleliebladeren liggen in deze poelen; vijf dragen een lichte bloem. Langzaam uitdijende rimpels blijven binnen de watercontour.
- Riet, lisdodden, lage bloemen en mos groeien langs de werkelijke waterkant. De poelbreedte, oeverplanten, lelies en reflectiemaskers gebruiken dezelfde geometrie.
- De wilgen hebben drie ongelijke lagen met afwisselend geplaatste bladeren, verschillende taklengtes en zacht buigende uiteinden. Verbindende takken liggen achter alle bladlagen. Warm licht van de lantaarns valt subtiel op het omliggende blad.
- Boomstammen hebben knoesten en extra schorslijnen. Zachte grondschaduwen vervangen de vlakke ellipsen onder bomen en tuinen.
- Rotsen en terrassen hebben afgeronde contouren, steenbreuken, mosranden en kleine bloemen. Groepjes verre bomen, zachtere hellingen en langzaam drijvende nevel geven de vallei meer diepte, ook op brede tablets.

De beweging blijft beperkt tot kleine zichtbare Canvas-vlakken, maximaal twintig updates per seconde. De bestaande ondersteuning voor **Minder beweging** en pauzeren buiten beeld blijft van toepassing. Volledige rivierpaden worden alleen voorbereid voor de watervlakken, niet voor elke boom of kristalglinstering.

## Beelden

[Vergelijking met de eerste ronde](Screenshots/SleepValleySecondPass/before-after.jpg).

Native composities op [320](Screenshots/SleepValleySecondPass/native-320.png), [393](Screenshots/SleepValleySecondPass/native-393.png), [834](Screenshots/SleepValleySecondPass/native-834.png) en [1194](Screenshots/SleepValleySecondPass/native-1194.png) punten. De genummerde cirkels in deze native auditbeelden zijn routeaanduidingen; de echte interface wordt apart in de simulator gecontroleerd.

## Verificatie

De [definitieve iOS-simulatorbuild](WorldTestLogs/SleepValleySecondPass/final-build.log) slaagt. `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn voor wereld 2 uitgevoerd op [iPhone 17](WorldTestLogs/SleepValleySecondPass/iphone-playability.log) en [iPad Pro 11-inch](WorldTestLogs/SleepValleySecondPass/ipad-playability.log): vier geslaagde testuitvoeringen, nul fouten. De tests gebruiken geïsoleerde Debug-profielen en controleren level 11, een halfuurantwoord en het openen van de wereldbaas.

Native beelden op 320, 393, 834 en 1194 punten breed zijn visueel gecontroleerd. Op elke breedte controleert de renderer 24 punten langs de rand van elk van de vijftien leliebladeren; alle punten liggen binnen het betreffende wateroppervlak. Rond alle tien levelposities controleert hij 48 punten op een kring met een straal van 48 punten; geen van deze punten ligt in het water. [Geometriecontrole](WorldTestLogs/SleepValleySecondPass/native-geometry.log).

Vier animatietijdstippen verschillen. De twee renders met de stilstandoptie zijn zowel in RGB-pixels als in bestandsinhoud identiek. [Meetresultaten](WorldTestLogs/SleepValleySecondPass/visual-checks.json). `git diff --check` is schoon.

Definitieve simulatorbeelden: [iPhone-entree](Screenshots/SleepValleySecondPass/native-world-2-iphone.png), [iPad-entree](Screenshots/SleepValleySecondPass/native-world-2-ipad.png), [iPhone-baasomgeving](Screenshots/SleepValleySecondPass/scenery-depth-world-2-iphone.png) en [iPad-baasomgeving](Screenshots/SleepValleySecondPass/scenery-depth-world-2-ipad.png).

De bordafstand en levelindeling zijn in deze ronde niet gewijzigd. De eerder vastgestelde afwijking van de bordafstandstest staat in de [controle van de eerste ronde](SleepValleyFirstPass.md).
