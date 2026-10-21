# Wereld 8 — samenhang, magie en afwerking

21 oktober 2026. De derde ronde vervangt de verspreide inrichting door complete opstellingen en geeft de wereld een herkenbare lichtsfeer.

## Compositie en sfeer

De beige en grijsgroene vloer is vervangen door violetblauw, met opaalachtige aders, zachte turquoise en lila lichtvelden en geprojecteerde lichtkringen rond de machines. De entree begint nog steeds in de aansluitkleur van wereld 7 en de uitstroom mengt naar wereld 9. Er is geen nieuwe luchtstrook toegevoegd.

Losse voorraadkisten, tandwielen, koperrollen en vloerpapieren zijn verwijderd. De extra apparatuur is nu samengesteld uit vier soorten complete opstellingen: condensatoren met een tank en een glazen verzamelstolp, proefbanken onder een kap, meetklokken met ingesloten slingerwerk en een observatorium. Elk apparaat hoort bij een nabijgelegen hoofdmachine. Dunne messing leidingen sluiten de energievoorziening aan; kleine lichtpulsen bewegen erdoor. De opstellingen hebben gezamenlijke frames, bevestigingen en een logisch grondcontact.

Een lichte overlapping met de hoofdmachine verbindt de silhouetten. De voorste oppervlakken volgen de bestaande dieptevolgorde en de animatiemaskers. Op 393 punten breed zijn er acht aanvullende opstellingen en op 834 punten breed 21; deze bevatten meerdere onderdelen per opstelling.

## Afwerking van de objecten

- Messing krijgt fijne lichte snijranden. Tandwielen hebben verhoogde ringranden, een verdiepte as en een afgewerkte bevestiging.
- Glazen tanks hebben een tweede reflectielijn, een vloeistofrand, schaalstreepjes, bouten en klemmende boven- en onderringen.
- Portalen krijgen een dubbele lichte binnenrand en een dieper blauwviolet energieveld. De drie hoofdportalen dragen verschillende bekroningen: een tandwiel, een analoge klok en een lichtjuweel.
- De laboratoria combineren ivoorkleurig materiaal, indigo email en messing. Bloeiende ranken volgen hun kolommen. Op de daken en stolpen zitten kleine lichtaccenten.
- Onder de stolpen zweven nu gefacetteerde kristallen met een lichtkern en een fijne baanring.
- Zandlopers keren tussen vaste messing steunen om. Hun voeten blijven op de grond staan.

Zachte vonkjes bewegen rond de uitvindingen. De nieuwe lichtlaag gebruikt stroken van 320 punten hoog, maximaal vijftien updates per seconde en vooraf berekende leidingpaden. De laag pauzeert buiten beeld en bij een inactieve app. Zowel licht als mechanismen tonen een vaste fase bij **Minder beweging**. De speelroute wordt uit de lichtlaag uitgespaard.

De eerder verwijderde grijze sokkels, zijpaadjes, digitale displays en vervaagde achtergrondobjecten blijven verwijderd.

## Beelden uit de app

| Beeld | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree | [Open](Screenshots/TimeMachineThirdPass/time-machine-entrance-iphone.png) | [Open](Screenshots/TimeMachineThirdPass/time-machine-entrance-ipad.png) |
| Eerste uitvindingen | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-74-iphone.png) | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-74-ipad.png) |
| Middendeel | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-77-iphone.png) | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-77-ipad.png) |
| Reactor en eindbaas | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-80-iphone.png) | [Open](Screenshots/TimeMachineThirdPass/time-machine-route-80-ipad.png) |

[Detail van materialen en glas](Screenshots/TimeMachineThirdPass/material-detail.png). Native auditbeelden zijn visueel gecontroleerd op [320](Screenshots/TimeMachineThirdPass/native-320.png), [393](Screenshots/TimeMachineThirdPass/native-393.png), [834](Screenshots/TimeMachineThirdPass/native-834.png) en [1194](Screenshots/TimeMachineThirdPass/native-1194.png) punten breed. De genummerde cirkels in deze auditbeelden zijn routeaanduidingen; de echte interface staat in de appbeelden.

## Controle

De [simulator-testbuild](WorldTestLogs/TimeMachineThirdPass/build.log) slaagt. `testTimeMachineWorkshopRouteRemainsPlayable` en `testWorldBossSceneryRemainsPlayable` slagen op [iPhone](WorldTestLogs/TimeMachineThirdPass/iphone.log) en [iPad](WorldTestLogs/TimeMachineThirdPass/ipad.log): **vier geslaagde testuitvoeringen**. Ze controleren de entree, de klokbediening van level 71, scrollen langs de nieuwe inrichting en het openen van de eindbaas. De daadwerkelijke appbeelden zijn op beide apparaten visueel bekeken.

Vier native animatiebeelden verschillen; twee renders met Minder beweging zijn pixelgelijk ([meetresultaat](WorldTestLogs/TimeMachineThirdPass/visual-checks.json)). De bestaande [plaatsingscontrole](WorldTestLogs/TimeMachineThirdPass/native-render.log) vindt op negen breedtes alle negen hoofdmachines en nul routecontacten in 9.477 onderzochte punten van hun hoofdvormen. Dit is een steekproef, geen volledige botsingsanalyse van alle nieuwe tekenpaden. `git diff --check` is schoon.

Tijdens het bouwen verscheen in de gelijktijdig gewijzigde piratengeometrie een aanroep van `Path.subtracting`, die iOS 17 vereist terwijl het project iOS 16 als minimum instelt. Een beschikbaarheidscontrole behoudt deze uitsnede op iOS 17 en hoger. iOS 16 gebruikt de oorspronkelijke kustcontour als terugval. Andere onafhankelijke wijzigingen in de gedeelde werkmap zijn behouden.
