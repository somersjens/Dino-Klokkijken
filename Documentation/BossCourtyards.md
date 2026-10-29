# Jungleroute en eindbaashoven

27 oktober 2026. Aanvullende afwerking van wereld 1, 4 (Klokdorp, bevestigd door de gebruiker), 5, 8 en 10.

De jungleroute begint én eindigt centraal. Twee brede golven houden de tussenliggende stenen afwisselend links en rechts; level 9 blijft links van level 10. Bomen staan minder op elkaar en hebben verschillende hoogtes. Palmen, lage begroeiing en twee bemoste ruïnes wisselen de boomkruinen af. Eén ruïne met bloemen vult de hoek boven de junglebaas. Die hele groep schuift op bredere schermen mee omhoog, zodat de grotere baas de decoratie niet naar buiten drukt. De volledige decoraties blijven vrij van het pad en de baas.

De dakpannen, bankjes en werkende ophaalbruggen van Klokdorp hebben warmere koper-, honing- en oranjetinten die aansluiten op de oranje dorpsbaas. Het water en de complete buitenoever behouden hun aansluiting.

In de grot is het laatste overhangende rotsdeel met de losse hangende diamant boven de baas verwijderd. De laatste rechter mijnwerkplek ligt bij een echte wandnaad.

De tijdmachinebaas staat op een betegeld terras dat doorloopt tot de bestaande kanaalkade. Een gemetselde voorrand en een lage achterrand geven de vloer een herkenbare hoogte. Boven de baas sluit een kloknis met werkbank, kolommen en begroeiing aan op de laatste bebouwing. Die klok gebruikt dezelfde bewegende wijzers en maskers als de andere gevelklokken. De hele standruimte ligt op de terrasvloer; de nis blijft boven de gereserveerde illustratie. Er is geen extra verbinding naar de hoofdweg.

Het kasteel staat op de buitenoever van de rechter slotgracht, boven de koning. Een korte brug komt uit bij het eigen voorhof. De twee eerdere lange eindtrappen zijn vervangen door deze kasteelhof. De volledige gevel past binnen het scherm en staat vrij van de koning. Het water behoudt zijn bestaande loop. De plaatsing van de gevel wordt per schermmaat berekend en gecachet.

[Telefoonoverzicht](Screenshots/BossCourtyards/overview-393.png) · [Smalle telefoon](Screenshots/BossCourtyards/overview-320.png) · [Tabletoverzicht](Screenshots/BossCourtyards/overview-834.png).

[Jungleroute voor/na](Screenshots/BossCourtyards/jungle-route-comparison.png) · [Tijdmachine voor/na](Screenshots/BossCourtyards/world-8-comparison.png) · [Kasteel voor/na](Screenshots/BossCourtyards/world-10-comparison.png) · [Grot voor/na](Screenshots/BossCourtyards/world-5-comparison.png).

De native overzichten gebruiken vereenvoudigde levelstenen. Volledige hoofdstukken staan als `full-world-N-393.png` en `full-world-N-834.png` in dezelfde map.

## Verificatie

- **1.151.622 kerncontroles geslaagd**, inclusief de centrale eerste en laatste junglesteen, twee brede golven, zichtbare bomen op beide oevers en vrijgehouden volledige decoraties. [Kernlog](WorldTestLogs/BossCourtyards/core.log).
- **127.771 geometriecontroles geslaagd** op twaalf breedtes, 320–1366 punten: complete terrasvloer onder de tijdmachinebaas, vrije kloknis, droge kasteelfundering aan de buitenoever, volledige gevel binnen beeld en geen overlap met de koning. Ook de eerdere water-, rail- en bazencontroles blijven slagen. [Native log](WorldTestLogs/BossCourtyards/native.log).
- iOS-app en schermtests compileren. [Buildlog](WorldTestLogs/BossCourtyards/ios-build.log).
- De centrering van junglesteen 1 én 10 en de speelbaarheid van de vijf aangepaste eindbaasgebieden slagen op **iPhone 18 Pro en iPad Pro 13 inch**. [Schermtestlog](WorldTestLogs/BossCourtyards/ui.log).
- Na de laatste correctie van de kloknis is wereld 8 opnieuw op beide apparaten geslaagd. De klok blijft op zijn eigen achterwand vóór de oudere bebouwing. [Controle wereld 8](WorldTestLogs/BossCourtyards/clock-ui.log).

[Echte iPhone-beelden](Screenshots/BossCourtyards/iphone-overview.png) · [Echte iPad-beelden](Screenshots/BossCourtyards/ipad-overview.png) · [Level 1 centraal op iPhone](Screenshots/BossCourtyards/iphone-jungle-central-start.png).

De laatste aanpassing voor de jungle is apart gecontroleerd met **111.175 route- en begroeiingscontroles**. Daarbij wordt ook gecontroleerd of de ruïne werkelijk zichtbaar blijft boven de baas op iedere breedte. [Gerichte junglecontrole](WorldTestLogs/BossCourtyards/jungle.log).
De definitieve jungleplaatsing is daarna opnieuw geslaagd op iPhone en iPad. [Laatste schermcontrole jungle](WorldTestLogs/BossCourtyards/jungle-ui.log).
