# Wereldbadges: gesloten aansluitingen en volledige voorgronden

Deze verfijning sluit de openingen tussen wereldnummer, titel en ondertitel. Eén doorlopende ondergrond in het materiaal van de wereld loopt achter de drie onderdelen door. De ondertitel staat vier punten hoger en heeft een iets hoger leesvlak. De titel houdt dezelfde positie op het levelpad.

De zijdecoratie overlapt de bordrand. Bladeren groeien vanaf de jungle- en valleiranden; zandsteen, basalt en kristallen staan vóór de steenplaten. De klokkenhuizen van het dorp, de stadstorens, de kasteeltorens en het piratentouw omkaderen de tekst. De bestaande tijdmachineblokken en tandwielen blijven op de voorgrond. Het piratentouw volgt de buitenrand en kruist de titelletters niet.

Het oerwoud gebruikt voor het bladwerk dezelfde kleuren als de bladeren bij de vriendenknop: `C4DF54`, `78B33F` en `326D37`. Deze bladeren krijgen geen vergrijzende materiaalfilter. Hout en steen behouden de zachtere contrasten van de vorige ronde.

In de woestijn loopt de palmstam tot in de zandvoet. De wortelaanzet wordt door de zandbank en kleine stenen afgedekt. De steen met pootafdruk is verwijderd. Ook de piratenpalm staat op de grond. De kristalgrot heeft een doorlopende rotsvoet met afgeronde, volledig getekende rotscontouren; de rechte afsnijding onder de rotsen is vervangen. Op brede schermen blijven het bovenste junglebladwerk en de kasteeldaken binnen de badgehoogte.

[Alle tien badges, Nederlands](Screenshots/WorldBadgeSceneContinuity/ten-worlds-nl.png) · [Engels](Screenshots/WorldBadgeSceneContinuity/ten-worlds-en.png) · [Jungle](Screenshots/WorldBadgeSceneContinuity/world-1-354-nl.png) · [Woestijn](Screenshots/WorldBadgeSceneContinuity/world-2-284-nl.png) · [Brede kristalgrot](Screenshots/WorldBadgeSceneContinuity/world-5-564-nl.png).

## Controle

De native SwiftUI-renders omvatten alle tien werelden in Nederlands en Engels, op 284, 354 en 564 punten, plus hoog contrast op 284 punten. De aansluitingen, tekstvrijheid, voorgrondlagen en volledige rots-, blad- en dakcontouren zijn visueel gecontroleerd. De afbeeldingen zijn controlebeelden; de app gebruikt de SwiftUI-tekenpaden.

[Buildlog](WorldTestLogs/WorldBadgeSceneContinuity/build.log) · [Renderlog](WorldTestLogs/WorldBadgeSceneContinuity/native-render-build.log).

De bestaande UI-controle `testWorldBannersHaveBalancedClearance` is geslaagd op de aparte iPhone 17-simulator voor wereld 2, 5, 8 en 9: 36,424 seconden, nul fouten ([testlog](WorldTestLogs/WorldBadgeSceneContinuity/iphone-verified.log)). De bijbehorende app-screenshots zijn rechtstreeks uit dat geslaagde testresultaat geëxporteerd: [woestijn](Screenshots/WorldBadgeSceneContinuity/world-2-iphone.png), [kristalgrot](Screenshots/WorldBadgeSceneContinuity/world-5-iphone.png), [tijdmachine](Screenshots/WorldBadgeSceneContinuity/world-8-iphone.png) en [piraten](Screenshots/WorldBadgeSceneContinuity/world-9-iphone.png). De [junglekaart](Screenshots/WorldBadgeSceneContinuity/world-1-iphone.png) is apart vastgelegd om het bladgroen in de omgeving te beoordelen.

Een eerste testrun kwam niet voorbij het opstarten van de simulator door een `Busy`-melding. Die vastgelopen run is gestopt; de herhaling na volledig opstarten is de gebruikte verificatie.
