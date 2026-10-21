# Wereld 8 — tweede verbeterslag

Vervolg: [derde ronde — samenhang, magie en afwerking](TimeMachineThirdPass.md).

21 oktober 2026. Deze ronde verwerkt de vijf opmerkingen op de eerste versie.

- De grijze steenblokken en de ronde platforms onder de machines zijn verwijderd, evenals de voetplaat bij Professor Pendel. Alleen zachte contactschaduwen verankeren de objecten op de doorlopende grond. De messing voeten en behuizingen van de apparaten zelf blijven onderdeel van de machines.
- Alle losse toegangsbruggetjes en zijpaadjes zijn verwijderd.
- De open plekken krijgen grotere pompen, werkbanken met glaswerk, gereedschapswagens, tandwielrekken, telescopen, koperbuizen en voorraadkisten. Kleinere openingen worden gevuld met koperrollen, losse tandwielen, gereedschap, bouwtekeningen en plantenbakken. Op 393 punten breed staan 45 extra groepen, op 834 punten breed 84. De verdeling wordt per kaartafmeting gecachet en reserveert ruimte voor de grote machines, wateruitlaten, route en eindbaas. Een klein deel van de buitenste inrichting mag door de schermrand worden afgesneden.
- De digitale tijdschermen zijn verwijderd. Kleine analoge drukmeters vervangen het scherm in het bedieningspaneel; de grote analoge klokken blijven bewegen.
- De vervaagde werkplaatsen, platformen en losse architectuurribben aan de zijkanten zijn verwijderd. De nieuwe inrichting heeft dezelfde dekkende materialen als de grote machines.

De bestaande portaalspiralen, tandwielen, omkerende zandlopers, waterstromen en reactor blijven bewegen. De extra inrichting deelt de dieptevolgorde met het landschap en houdt waar nodig bewegende delen achter voorliggende objecten. De aansluiting op wereld 7 en 9 blijft doorlopend.

## Beelden uit de app

| Beeld | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree | [Open](Screenshots/TimeMachineSecondPass/time-machine-entrance-iphone.png) | [Open](Screenshots/TimeMachineSecondPass/time-machine-entrance-ipad.png) |
| Eerste werkplaatsen | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-74-iphone.png) | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-74-ipad.png) |
| Midden van de kaart | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-77-iphone.png) | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-77-ipad.png) |
| Reactor en eindbaas | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-80-iphone.png) | [Open](Screenshots/TimeMachineSecondPass/time-machine-route-80-ipad.png) |

## Controle

De [simulator-testbuild](WorldTestLogs/TimeMachineSecondPass/build.log) slaagt. De bestaande gerichte tests `testTimeMachineWorkshopRouteRemainsPlayable` en `testWorldBossSceneryRemainsPlayable` slagen op [iPhone](WorldTestLogs/TimeMachineSecondPass/iphone.log) en [iPad](WorldTestLogs/TimeMachineSecondPass/ipad.log): **vier geslaagde testuitvoeringen**. Ze openen level 71, controleren de klokbediening, scrollen langs de nieuwe inrichting en openen de wereldbaas. Er zijn geen nieuwe tests of aanpassingen aan spelregels nodig geweest.

Native composities op [320](Screenshots/TimeMachineSecondPass/native-320.png), [393](Screenshots/TimeMachineSecondPass/native-393.png), [834](Screenshots/TimeMachineSecondPass/native-834.png) en [1194](Screenshots/TimeMachineSecondPass/native-1194.png) punten zijn visueel gecontroleerd. De [plaatsingscontrole](WorldTestLogs/TimeMachineSecondPass/native-render.log) rapporteert op negen breedtes alle negen hoofdmachines en nul routecontacten in 9.477 onderzochte punten van hun hoofdvormen. Deze controle is een steekproef, geen volledige botsingsanalyse van alle tekenpaden.

Vier animatiebeelden verschillen en twee beelden met **Minder beweging** zijn pixelgelijk ([meetresultaat](WorldTestLogs/TimeMachineSecondPass/visual-checks.json)). De actuele appbeelden zijn op beide apparaten visueel bekeken. `git diff --check` is schoon. De onafhankelijke wijzigingen elders in de gedeelde werkmap zijn behouden.
