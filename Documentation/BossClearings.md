# Vrije eindbaasplaatsen

27 oktober 2026.

De nieuwste afwerking staat in [Bazen op de bestaande wereldgrond](BossGrounding.md).

De verdere materiaal- en waterafwerking staat in [Verfijning van de eindbaasgebieden](BossFinishRefinement.md).

De eindbaasplaatsen van wereld 1, 3, 4, 5, 6, 8 en 10 zijn opnieuw ingepast in hun eigen landschap. De drie goedgekeurde ontwerpen van wereld 2, 7 en 9 behouden hun plaatsing en ondergrond.

| Wereld | Aanpassing |
| --- | --- |
| 1 — Jungle | Een open plek naast de laatste steen, een kort bospad en een verplaatste laatste boom. De volledige voetafdruk van planten, bomen en dieren houdt de baas vrij. |
| 3 — Vulkaan | De rechter lavabaan draait vanuit de verticale tangent bij de laatste bocht naar buiten. De eigen basaltbank volgt dezelfde lijn; de baas staat op de droge asgrond eronder. |
| 4 — Dorp | De rechter rivier verlaat het dorp vóór het eindplein. Water, oevers, boten en perceelplaatsing gebruiken dezelfde uitgang. Een betegelde dorpsplaats sluit aan op het speelpad. |
| 5 — Kristalgrot | De rechter rotswand wijkt geleidelijk terug rond een ruime nis met zichtbare grotvloer. De laatste boog staat verder omhoog; kristallen houden de hele figuur vrij. |
| 6 — Stad | Een breder plein staat dichter bij de eindsteen en vrij van het spoor. Gebouwen houden de volledige baas vrij, inclusief vleugels en gedragen klokken. |
| 8 — Tijdmachine | De rechter afvoer eindigt boven de baas. De laatste rechter bouwlaag eindigt eerder en de laatste uitvinding verhuist naar links. De baas staat op een droog kadeplein met messing details; op brede tablets staat daarnaast een eigen klokwerkrek. |
| 10 — Kasteel | De rechter gracht volgt één vloeiende uitgang vóór het eindplein. Een kalkstenen binnenplaats sluit aan op het pad, met de bestaande bruggen en gebouwen erachter. |

De nieuwe posities worden gemeten vanaf het pad, zodat bazen op brede tablets bij hun eindsteen blijven. Lichaam, levende klokken, decorreserveringen en animatiemaskers gebruiken dezelfde standplaats. De bestaande drie losse klokoverlays boven de oude tijdmachinebaas zijn verwijderd: de meegeleverde figuur heeft zijn eigen klokvlakken.

Na de eerste visuele ronde zijn de lava- en grachtbochten verfijnd, de natuurlijke open plekken minder regelmatig gemaakt en de volledige staarten op smalle schermen gecontroleerd.

[Overzicht van de zeven aangepaste plaatsen](Screenshots/BossClearings/native-overview-393.png) · [Wereld 8 voor en na](Screenshots/BossClearings/world-8-before-after.png).

[Appbeelden op iPhone](Screenshots/BossClearings/app-overview-iphone.png) · [iPad](Screenshots/BossClearings/app-overview-ipad.png). De native auditbeelden gebruiken vereenvoudigde levelstenen; de appbeelden bevatten de echte interface en Dino.

## Verificatie

- Native landschappen beoordeeld op 320, 393, 600, 834 en 1194 punten, inclusief de drie behouden werelden.
- **108.528 geometriecontroles geslaagd.** De audit controleert op twaalf breedtes de volledige figuur, droge grond, grotwand, vulkanen/losse stenen, stadsspoor/gevels en tijdmachinegebouwen, afvoerputten, bruggen, lampen en apparaten. [Auditcode](WorldTestLogs/BossClearings/geometry-audit.swift) · [Resultaat](WorldTestLogs/BossClearings/native.log).
- **1.137.112 kerncontroles geslaagd**, met nieuwe regressiecontroles voor de vrijgehouden jungleplaats en de relatie tussen standplaats en eindsteen. [Kernlog](WorldTestLogs/BossClearings/core.log).
- De eindbaastest voor alle tien werelden slaagt op iPhone en iPad. [iPhone](WorldTestLogs/BossClearings/iphone.log) · [iPad](WorldTestLogs/BossClearings/ipad.log).
- De laatste vulkaanreservering is aanvullend op beide apparaten getest. [Gerichte schermtest](WorldTestLogs/BossClearings/volcano-final.log).
- iOS-app en schermtests compileren. [Buildlog](WorldTestLogs/BossClearings/ios-build.log).
- De eindbaas-schermtest wacht nu expliciet tot de openingsanimatie klaar is en de levelsteen bedienbaar wordt. De eerdere directe controle kon tijdens de opening een nog uitgeschakelde knop lezen.
