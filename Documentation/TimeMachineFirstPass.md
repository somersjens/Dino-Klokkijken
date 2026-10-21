# Wereld 8 — Tijdmachine, eerste verbeterslag

Vervolg: [tweede ronde — machines op de grond en vollere inrichting](TimeMachineSecondPass.md).

21 oktober 2026. Het aangeleverde ontwerp is vertaald naar native SwiftUI/Canvas-geometrie. De verder uitgewerkte werelden 3, 5 en 7 zijn gebruikt als referentie voor samengestelde scènes, materiaaldetails en kleine afzonderlijke animatievlakken.

## Uitwerking

- Negen grote werkterrassen: drie portalen, drie open laboratoria, twee grote zandlopers en een tijdreactor bij Professor Pendel. Toegangsbruggetjes verbinden de terrassen met de route.
- Portalen hebben messing segmenten, bouten, draaiende tandwielen, bewegende spiralen, naar binnen lopende lichtkringen en ronddrijvende lichtdeeltjes.
- De laboratoria hebben gebogen daken, open werkruimtes, blauwdrukken, boeken, gereedschap, drukmeters en een uitvinding onder een glazen stolp. Een tandwiel zweeft en draait binnen de stolp. De analoge en digitale klokken volgen dezelfde versnelde tijd.
- Twee glazen zandlopers laten hun bovenste voorraad afnemen en onderin een hoop groeien. Losse zandkorrels vallen door de hals. Aan het einde van iedere cyclus keert de zandloper zichzelf om.
- Elke grote machine heeft een aangesloten koperen uitlaat met een watervalletje en een eigen opvangbak. Bewegende waterdraden, opstijgende belletjes en uitdijende rimpels maken de stroming zichtbaar.
- De reactor heeft een glazen kern, draaiende messing omloopringen en een klok. Stenen funderingen, serviceplatforms, leidingklemmen, mosgroene planten, bloemen en hangende klimop vullen de oevers aan.
- De losse blauwe luchtstrook en entreeboog zijn verwijderd. De ondergrond begint in de aansluitkleur van wereld 7 en loopt geleidelijk naar de warme tinten van wereld 9. Verre werkplaatsen blijven zacht op de achtergrond.

De architectuur wordt met het bestaande landschap gecachet. Negen kleine mechanismelagen tekenen maximaal twintig keer per seconde, pauzeren buiten beeld en wanneer de app inactief is, en volgen **Minder beweging**. Statische maskers houden bewegende delen achter latere terrassen en de eindbaas, en beschermen de speelroute. De wereldpreview gebruikt dezelfde nieuwe composities in rust.

De wijzigingen voor deze opdracht zitten in het Tijdmachine-gedeelte van `Dino/Views/JungleLandscape.swift` en in één gerichte kaarttest. De gedeelde werkmap bevat daarnaast onafhankelijke wijzigingen aan andere schermen en de piratenwereld; die zijn behouden.

## Beelden

De echte app is bekeken op iPhone 17 en iPad Pro 11-inch:

| Beeld | iPhone | iPad |
| --- | --- | --- |
| Entree | [Open](Screenshots/TimeMachineFirstPass/time-machine-entrance-iphone.png) | [Open](Screenshots/TimeMachineFirstPass/time-machine-entrance-ipad.png) |
| Laboratoria en zandlopers | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-74-iphone.png) | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-74-ipad.png) |
| Onderste werkplaatsen | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-77-iphone.png) | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-77-ipad.png) |
| Reactor en eindbaas | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-80-iphone.png) | [Open](Screenshots/TimeMachineFirstPass/time-machine-route-80-ipad.png) |

Daarnaast zijn native composities visueel gecontroleerd op [320](Screenshots/TimeMachineFirstPass/native-320.png), [393](Screenshots/TimeMachineFirstPass/native-393.png), [834](Screenshots/TimeMachineFirstPass/native-834.png) en [1194](Screenshots/TimeMachineFirstPass/native-1194.png) punten breed. De eenvoudige genummerde cirkels in deze auditbeelden markeren de route; de echte levelstenen staan in de appbeelden hierboven.

## Verificatie

De [definitieve simulator-testbuild](WorldTestLogs/TimeMachineFirstPass/final-build.log) slaagt voor arm64 en x86_64.

`testTimeMachineWorkshopRouteRemainsPlayable` en `testWorldBossSceneryRemainsPlayable` slagen op [iPhone](WorldTestLogs/TimeMachineFirstPass/final-iphone.log) en [iPad](WorldTestLogs/TimeMachineFirstPass/final-ipad.log): **vier geslaagde testuitvoeringen**. De gerichte test opent level 71, controleert de instelbare klok en de bereikbare bevestigingsknop, scrollt langs levels 74, 77 en 80 en opent de eindbaas. De tests gebruiken geïsoleerde Debug-voortgang.

De [plaatsingscontrole](WorldTestLogs/TimeMachineFirstPass/native-render.log) onderzoekt negen schermbreedtes van 320 tot 1194 punten. Alle negen grote werkplaatsen zijn aanwezig. In totaal liggen **9.477 onderzochte punten** van de machinesilhouetten buiten de gereserveerde route. Dit is een steekproef van de hoofdvormen; de animatiemaskers beschermen daarnaast de daadwerkelijke route.

De [bewegingscontrole](WorldTestLogs/TimeMachineFirstPass/visual-checks.json) vindt vier verschillende kaartbeelden en zes verschillende tijdstippen voor elk van de vier mechanismetypen, inclusief de omkering van de zandloper. Twee renders met Minder beweging zijn pixelgelijk. Twee appbeelden zonder tussentijdse bediening tonen op beide apparaten veranderde pixels in de portaalregio. De native renders controleren de definitieve zandvorm na de laatste kleine correctie aan de omkering. `git diff --check` is schoon.

Twee oudere testhelpers zijn ook geprobeerd en passen niet bij de huidige leerlijn: `testNativeWorldChaptersAndMinuteQuestions` verwacht antwoordopties bij een instelbare klok ([diagnose](WorldTestLogs/TimeMachineFirstPass/legacy-chapters-ipad.log)); de helper van `testDinoStandsOnCompletedLevel` stelt alleen het uur in bij de minuutvragen van level 71 ([diagnose](WorldTestLogs/TimeMachineFirstPass/legacy-completion-iphone.log)). Deze helpers zijn niet aangepast. De gerichte kaarttest controleert de nieuwe scenery en bediening zonder deze aannames. Volledig uitspelen van level 71 is daarmee niet automatisch bewezen.

Dit is de eerste redesignronde. De hoofdmachines en hun bewegingen vormen de basis voor verdere variatie, fijnere materialen en meer unieke uitvindingen.
