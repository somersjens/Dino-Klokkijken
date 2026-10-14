# Doorlopende wereldkaart en titelborden — 13 oktober 2026

Het zandpad loopt over alle negen wereldgrenzen door. Iedere sectie eindigt op de middenlijn met een verticale raakrichting; het volgende pad begint daar en buigt naar het eerste level van de nieuwe wereld. De titelborden liggen boven het pad, zodat het daarachter verder loopt. De zandkleur, breedte, stippellijn en grondschaduw blijven gelijk.

De gedeelde WorldRouteTrail tekent SwiftUI-paden, met een kleine overlap aan beide uiteinden zodat ook de verschoven schaduw aansluit. Dit voorkomt een extra Canvas-textuur over de hele hoogte van iedere wereld. De junglepunten en de volgende hoofdstukken gebruiken dezelfde routecomponent in [WorldMap.swift](../Dino/Views/WorldMap.swift) en [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift).

De uitnodiging om een baas te proberen staat alleen bovenaan de jungle. Bij wereld 2 t/m 10 staan de wereldborden en levelpunten; hun herhaalde baasuitnodigingen zijn verwijderd.

Alle tien wereldborden delen één opbouw: een verhoogd wereldnummer, een titelplaat met afgeronde randen en materiaalverlopen, en een overlappend label voor de klokvaardigheid. Details passen bij de wereld en blijven binnen de tekenruimte. De letters schalen voor lange namen en beschrijvingen. Het bord is als één toegankelijk element gegroepeerd.

| Wereld | Details |
| --- | --- |
| Dino Jungle | Groene titel, houtnerf, geaderde bladeren en warme randen |
| Slaapvallei | Manen, sterren en zachte bladeren |
| Vulkaanland | Basaltplaat, steenfacetten en gloeiende lavanaden |
| Dino Dorp | Houtdetails, vlaggetjes en bladeren |
| Kristalgrot | Koele titelplaat, geslepen kristallen en lichtstrepen |
| Dino Stad | Blauwe metaalplaat, aansluitingen en klinknagels |
| Dag-en-nachtbos | Zon links, maan rechts en twee bladkleuren |
| Tijdmachine | Gouden tandwielen en kleine sterren |
| Tijdpiraten | Houtnerf, touwrand en twee ankers |
| Dinokasteel | Blauwe vaandels en gouden kronen |

[Alle tien native titelborden](Screenshots/WorldFlow/ten-world-banners-native.png).

De jungle-entree begint met blauwe lucht die doorloopt achter de vaste HUD. Zachte wolken, een zon met een lichte gloed, verre rotswatervallen, heuvels en lichtbundels geven diepte. Bladeren en lianen omlijsten de lucht; de bestaande waterval langs het speelpad vormt de overgang naar de nabije jungle. De vriendenknop heeft een bijpassende lichte, gelaagde afwerking.

[Actuele jungle-entree op iPhone](Screenshots/WorldFlow/jungle-entrance-iphone.png) · [Native landschap zonder interface](Screenshots/WorldFlow/jungle-entrance-native.png).

De PNGs zijn documentatie en native renders. De game tekent de titelborden, het landschap en het pad zelf met shapes en Canvas.

## Controles

De definitieve [iPhone-build](WorldTestLogs/WorldFlow/iphone-build.log) is geslaagd. De bestaande testNativeWorldChaptersAndMinuteQuestions is opnieuw geslaagd op iPhone 17 met iOS 26.5: één test met negen hoofdstukcontroles, nul fouten, in 232,925 seconden. De test legt de jungle-entree vast, opent het eerste level van iedere volgende wereld, controleert dat de herhaalde baasbanner ontbreekt en beantwoordt de eerste klokvraag. [Definitief testlog](WorldTestLogs/WorldFlow/chapters-iphone.log).

De afzonderlijke definitieve testComingSoonOnlyAfterLevelHundred is eveneens geslaagd, met nul fouten in 15,823 seconden. Coming soon staat onder level 100 en level 101 bestaat niet. [Testlog](WorldTestLogs/WorldFlow/coming-soon-iphone.log) · [Actueel scherm na level 100](Screenshots/WorldFlow/after-level-100-iphone.png).

De eerste gecombineerde run bevestigde het einde na level 100, maar de simulator beëindigde daarna de testomgeving met signal kill. De audits zijn daarom afzonderlijk uitgevoerd. [Log van die eerste run](WorldTestLogs/WorldFlow/initial-combined-run.log). De nieuwe opmaak is voor deze wijziging op iPhone getest; de eerdere iPad-controles staan in de overige verificatiedocumenten.

| Overgang | Actuele kaart | Eerste klokvraag |
| --- | --- | --- |
| Jungle → Slaapvallei | [kaart](Screenshots/WorldFlow/transition-to-world-2-iphone.png) | [vraag](Screenshots/WorldFlow/world-2-question-iphone.png) |
| Slaapvallei → Vulkaanland | [kaart](Screenshots/WorldFlow/transition-to-world-3-iphone.png) | [vraag](Screenshots/WorldFlow/world-3-question-iphone.png) |
| Vulkaanland → Dino Dorp | [kaart](Screenshots/WorldFlow/transition-to-world-4-iphone.png) | [vraag](Screenshots/WorldFlow/world-4-question-iphone.png) |
| Dino Dorp → Kristalgrot | [kaart](Screenshots/WorldFlow/transition-to-world-5-iphone.png) | [vraag](Screenshots/WorldFlow/world-5-question-iphone.png) |
| Kristalgrot → Dino Stad | [kaart](Screenshots/WorldFlow/transition-to-world-6-iphone.png) | [vraag](Screenshots/WorldFlow/world-6-question-iphone.png) |
| Dino Stad → Dag-en-nachtbos | [kaart](Screenshots/WorldFlow/transition-to-world-7-iphone.png) | [vraag](Screenshots/WorldFlow/world-7-question-iphone.png) |
| Dag-en-nachtbos → Tijdmachine | [kaart](Screenshots/WorldFlow/transition-to-world-8-iphone.png) | [vraag](Screenshots/WorldFlow/world-8-question-iphone.png) |
| Tijdmachine → Tijdpiraten | [kaart](Screenshots/WorldFlow/transition-to-world-9-iphone.png) | [vraag](Screenshots/WorldFlow/world-9-question-iphone.png) |
| Tijdpiraten → Dinokasteel | [kaart](Screenshots/WorldFlow/transition-to-world-10-iphone.png) | [vraag](Screenshots/WorldFlow/world-10-question-iphone.png) |
