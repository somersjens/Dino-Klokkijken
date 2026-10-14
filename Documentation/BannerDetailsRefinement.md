# Wereldbanners — verdere afwerking, 14 oktober 2026

Alle tien banners hebben samengestelde zijornamenten die over de bordrand vallen. De jungle gebruikt volle bladclusters met wisselende maten, standen en kleuren, gebogen lianen, vouwen, gebogen nerven en contactschaduwen. De bladcontour, bladvouw en nerven zijn dezelfde SwiftUI-shapes als rond het dinoportret in de HUD; de gedeelde geometrie staat in JungleLandscape.swift en wordt door AdventureHeader.swift gebruikt.

De andere werelden hebben eveneens complete assemblages met onderdelen vóór en achter de plaat. De titel houdt eigen vrije ruimte tussen de ornamenten. Het hout of metaal van het wereldnummer sluit aan op de hoofdplaat. Randen hebben een verhoogde buitenrand, een binnenrand met lichtaccenten en een zichtbare onderkant.

De subtitels zitten op een eigen bevestigd lint, met twee bevestigingen, gevouwen uiteinden, materiaalverlopen, een afgewerkte zoom en een klein klokzegel. Elke beschrijving krijgt de kleuren en materialen van zijn wereld. Het kasteel gebruikt bijvoorbeeld een blauw lint met lichte tekst, de stad een koel paneel en Slaapvallei een lichtpaars lint met stiksels.

| Wereld | Zijornamenten |
| --- | --- |
| Dino Jungle | Overlappende bladwaaiers, lianen, gevouwen bladeren en kleine bloemen |
| Slaapvallei | Zachte blauwgroene bladclusters, halve manen, sterren en pareldetails |
| Vulkaanland | Verschillende basaltlagen, steenfacetten, lavanaden en amberkleurige kristallen |
| Dino Dorp | Bladkransen, kleine huisgevels met raampjes, vlaggetjes en bloemen |
| Kristalgrot | Gevarieerde kristallen met gedraaide standen, facetten, lichtstrepen en gloed |
| Dino Stad | Kleine stadsdelen, metaalplaten, lichtindicatoren, circuits en bouten |
| Dag-en-nachtbos | Warme en koele bladclusters met een zon, maan en lichtpuntjes |
| Tijdmachine | Meerdere tandwielen, klokjes, verbindingsstangen, assen en bevestigingen |
| Tijdpiraten | Gebogen ankers, gevlochten touw, golven, schelpen en houtnerf |
| Dinokasteel | Kasteeltorentjes, steenvoegen, bladkransen, kronen, edelstenen en geborduurde vaandels |

[Overzicht van alle tien native banners](Screenshots/BannerDetails/ten-world-banners-native.png).

Voor Dag-en-nachtbos zijn twee titelregels toegestaan op een smal scherm. De subtitels hebben afzonderlijke ruimte naast het klokzegel en passen hun lettergrootte aan wanneer dat nodig is. De native renders zijn gecontroleerd op een breedte van 284 punten voor een smalle telefoonlay-out en 564 punten voor de maximale bordbreedte op een tablet. [Vergelijking van beide breedtes](Screenshots/BannerDetails/narrow-and-tablet-native.png).

De afbeeldingen zijn documentatie en renders van de SwiftUI-code. De game tekent de banners zelf met shapes en Canvas.

De [simulatorbuild](WorldTestLogs/BannerDetails/iphone-build.log) is geslaagd.

De bestaande testNativeWorldChaptersAndMinuteQuestions is volledig geslaagd op iPhone 17 met iOS 26.5: één test met negen hoofdstukcontroles en nul fouten, afgerond in 220,512 seconden. De test legt eerst de nieuwe jungle-entree vast, opent daarna het eerste level van ieder volgend hoofdstuk en beantwoordt daar een klokvraag. [Testlog](WorldTestLogs/BannerDetails/all-worlds-iphone.log). De brede lay-out hierboven is met native renders gecontroleerd; voor deze wijziging is geen nieuwe iPad-simulatoraudit uitgevoerd.

| Wereld | Actuele iPhone-kaart |
| --- | --- |
| 1 | [kaart](Screenshots/BannerDetails/world-1-iphone.png) |
| 2 | [kaart](Screenshots/BannerDetails/world-2-iphone.png) |
| 3 | [kaart](Screenshots/BannerDetails/world-3-iphone.png) |
| 4 | [kaart](Screenshots/BannerDetails/world-4-iphone.png) |
| 5 | [kaart](Screenshots/BannerDetails/world-5-iphone.png) |
| 6 | [kaart](Screenshots/BannerDetails/world-6-iphone.png) |
| 7 | [kaart](Screenshots/BannerDetails/world-7-iphone.png) |
| 8 | [kaart](Screenshots/BannerDetails/world-8-iphone.png) |
| 9 | [kaart](Screenshots/BannerDetails/world-9-iphone.png) |
| 10 | [kaart](Screenshots/BannerDetails/world-10-iphone.png) |
