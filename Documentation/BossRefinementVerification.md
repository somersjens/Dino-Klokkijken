# Eindbazen en werelddetails — 13 oktober 2026

Alle tien werelden hebben nu een eigen, volledig met SwiftUI-shapes getekende eindbaas. De jungle heeft **Tiko de Junglewachter bij level 10**, zichtbaar op de kaart en op de baasstartkaart. Zijn naam is bijgewerkt in Nederlands en Engels. De wereldindeling blijft negen gewone levels gevolgd door één baaslevel.

Elke baas draagt een echte analoge of digitale klok. De bevestiging is onderdeel van de tekening: een geborduurd dekje, klokbroches op een sjerp, een ketting, een harnas, een stenen uitsparing, een borstscherm, een hoed, een kroon of een vastgehouden staf. De piraat heeft een papegaai op zijn schouder die de klokketting met zijn snavel draagt. De kaart en startkaart gebruiken dezelfde karakterrenderer in [WorldBossArt.swift](../Dino/Views/WorldBossArt.swift). Losse klokken en zandlopers in het decor blijven omgevingsdetails.

| Wereld | Baas | Gedragen klok | Tijd |
| --- | --- | --- | --- |
| 1 — Dino Jungle | Tiko de Junglewachter | Klokketting op bladpantser | 08:00 |
| 2 — Slaapvallei | Dommel de Droomsaurus | Zacht klokdekje met stiksels, bies en franjes | 07:30 |
| 3 — Vulkaanland | Magma de Vuurtriceratops | Diagonale sjerp met drie klokbroches | 01:15 / 04:45 / 08:15 |
| 4 — Dino Dorp | Burgemeester Tik-Tak | Klokstaf, zichtbaar vastgehouden | 05:20 |
| 5 — Kristalgrot | Prisma de Kristalbewaker | Klok in een uitgeholde borstkas van steen | 02:17 |
| 6 — Dino Stad | Neon de Klokrobot | Ingebouwd digitaal borstscherm | 12:45 |
| 7 — Dag-en-nachtbos | Tweelicht de Bosuil | Borstklok met harnas en digitale 24-uursaanduiding | 20:00 |
| 8 — Tijdmachine | Professor Pendel | Tovenaarshoed met drie klokjes in drie maten | 06:25 / 10:10 / 03:00 |
| 9 — Tijdpiraten | Kapitein Zandloper | Papegaai met klokhangertje in zijn snavel | 09:30 |
| 10 — Dinokasteel | Koning Chronos | Grote klok ingebouwd in de kroon | 10:25 |

De wijzers worden uit dezelfde tijd berekend als de digitale aanduidingen en de toegankelijke waarde van de preview. De urenwijzer volgt ook de minutenfractie. De analoge klokken hebben een gelaagde metalen rand, twaalf markeringen, vier cijfers, afzonderlijke wijzers, een as en glasreflectie.

De vijf verdere varianten krijgen ieder een ander silhouet en een andere klokbevestiging. Dommels klok is in het dekje geborduurd en heeft geen metalen glasreflectie. De kleine hoedklokjes hebben proportioneel kleinere wijzers en assen; het kleinste klokje gebruikt markeringen in plaats van onleesbaar kleine cijfers. De preview houdt extra hoogte vrij voor Pendels hoed en Chronos' kroon. [Overzicht van deze vijf varianten](Screenshots/BossVariants/five-boss-variants.png).

De build van deze vijf varianten is geslaagd. De bestaande audit van alle tien baasstartkaarten is opnieuw volledig geslaagd op iPhone 17 met iOS 26.5: één test, tien wereldcontroles, nul fouten, afgerond in 155,974 seconden. [Buildlog](WorldTestLogs/BossVariants/iphone-build.log) · [UI-testlog](WorldTestLogs/BossVariants/all-bosses-iphone.log). De eerdere poging struikelde over een tegenstrijdige simulator-AX-melding over de tikbaarheid van level 20; de helper controleert nu de zichtbare knopgrenzen, tikt op het midden en verifieert dat de bijbehorende startkaart opent. [AX-fout](WorldTestLogs/BossVariants/initial-activation-point-check.log) · [wisselende tikbaarheid](WorldTestLogs/BossVariants/initial-hittability-check.log).

Deze verdere variatie is visueel gecontroleerd met native renders en actuele iPhone-captures. De voorafgaande iPad-audit hieronder hoort bij de vorige accessoires; de iPad-audit is voor deze vijf wijzigingen niet opnieuw uitgevoerd.

| Variant | Actuele iPhone-kaart | Actuele iPhone-startkaart |
| --- | --- | --- |
| Klokdekje | [kaart](Screenshots/BossVariants/boss-2-map-iphone.png) | [start](Screenshots/BossVariants/boss-2-start-iphone.png) |
| Sjerp | [kaart](Screenshots/BossVariants/boss-3-map-iphone.png) | [start](Screenshots/BossVariants/boss-3-start-iphone.png) |
| Tovenaarshoed | [kaart](Screenshots/BossVariants/boss-8-map-iphone.png) | [start](Screenshots/BossVariants/boss-8-start-iphone.png) |
| Papegaai | [kaart](Screenshots/BossVariants/boss-9-map-iphone.png) | [start](Screenshots/BossVariants/boss-9-start-iphone.png) |
| Kroon | [kaart](Screenshots/BossVariants/boss-10-map-iphone.png) | [start](Screenshots/BossVariants/boss-10-start-iphone.png) |

De bazen hebben nieuwe silhouetten, gebogen ledematen, duidelijke handen en voeten, irissen met reflecties, oogleden, snuiten en materiaalverlopen. De outfits zijn individueel uitgewerkt: bladpantser, slaapmuts, triceratopshoorns, burgemeestersvest en hoed, kristalkroon en steenfacetten, robotgewrichten en bouten, veren, vleugels en bril, piratenvest en hoed, of kroon en mantel. De bazen worden boven de overgangsmist getekend, zodat hun voeten en gedragen klokken helder blijven.

De omgeving is eveneens verder verfijnd: asymmetrische boomkruinen met bladclusters, boomschors, rotsfacetten en mineraalspikkels, variërende kristalhoogtes met geslepen randen, waterlelies, rimpels en oeverriet. Dorpshuizen hebben gevarieerde gevelkleuren, dakraampjes, houten deuren, luiken, bloembakken en lantaarns. Licht komt consequent van linksboven; afgeronde onderdelen gebruiken volumeverlopen en zachte contactschaduwen.

[Overzicht van alle tien native ontwerpen](Screenshots/BossRefinement/ten-bosses-native-overview.png). De PNGs zijn uitsluitend documentatie en renders van de SwiftUI-code; de game tekent de shapes zelf. De groene speler met zijn rode `12:34`-bandana en de honderd levels blijven behouden. Na level 100 staat Coming soon.

De nieuwe UI-controle `testAllTenBossesHaveClockArtwork` opent elk baaslevel, controleert de klokwaarde en de ligging van de preview onder de vaste header, en bewaart een screenshot. Bij de jungle wordt ook de zichtbare baas op de kaart vastgelegd. De fixtures gebruiken een eigen opslag en veranderen geen spelersvoortgang.

Bij de voorafgaande verfijning van alle tien bazen zijn de simulatorbuilds geslaagd voor [iPhone](WorldTestLogs/BossRefinement/iphone-build.log) en [iPad](WorldTestLogs/BossRefinement/ipad-build.log). De volledige audit van alle tien bazen is afzonderlijk geslaagd op [iPhone 17](WorldTestLogs/BossRefinement/all-bosses-iphone.log) en [iPad A16](WorldTestLogs/BossRefinement/all-bosses-ipad.log), beide met iOS 26.5: één test met tien wereldcontroles, zonder fouten, per apparaat. Xcode heeft beide runs volledig afgerond. De screenshothelper bewaart gecomprimeerde PNG-captures en geeft tijdelijke beeldbuffers direct vrij.

De junglebaas is tevens met 10/10 gewonnen in `testDirectPerfectBoss`; de volgende wereld is geopend en de voortgang bleef na herstart bewaard. `testComingSoonOnlyAfterLevelHundred` is op beide apparaten geslaagd. Deze geslaagde spelregelcontroles staan in [het iPhone-log](WorldTestLogs/BossRefinement/iphone-progression.log) en [het iPad-log](WorldTestLogs/BossRefinement/ipad-coming-soon.log). Die eerdere runs bevatten nog de aanvankelijke mislukte audit via de hoofdstuksnelkoppeling; de definitieve audit gebruikt de ronde baaslevelpunten en de geslaagde logs hierboven.

Onderstaande simulatorbeelden horen bij die voorafgaande brede verfijning. De vijf nieuwe accessoires staan in het variantenoverzicht en de actuele iPhone-captures hierboven.

| Wereld | iPhone: kaart / startkaart | iPad: kaart / startkaart |
| --- | --- | --- |
| 1 | [kaart](Screenshots/BossRefinement/jungle-guardian-map-iphone.png) / [start](Screenshots/BossRefinement/boss-1-start-iphone.png) | [kaart](Screenshots/BossRefinement/jungle-guardian-map-ipad.png) / [start](Screenshots/BossRefinement/boss-1-start-ipad.png) |
| 2 | [kaart](Screenshots/BossRefinement/boss-2-map-iphone.png) / [start](Screenshots/BossRefinement/boss-2-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-2-map-ipad.png) / [start](Screenshots/BossRefinement/boss-2-start-ipad.png) |
| 3 | [kaart](Screenshots/BossRefinement/boss-3-map-iphone.png) / [start](Screenshots/BossRefinement/boss-3-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-3-map-ipad.png) / [start](Screenshots/BossRefinement/boss-3-start-ipad.png) |
| 4 | [kaart](Screenshots/BossRefinement/boss-4-map-iphone.png) / [start](Screenshots/BossRefinement/boss-4-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-4-map-ipad.png) / [start](Screenshots/BossRefinement/boss-4-start-ipad.png) |
| 5 | [kaart](Screenshots/BossRefinement/boss-5-map-iphone.png) / [start](Screenshots/BossRefinement/boss-5-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-5-map-ipad.png) / [start](Screenshots/BossRefinement/boss-5-start-ipad.png) |
| 6 | [kaart](Screenshots/BossRefinement/boss-6-map-iphone.png) / [start](Screenshots/BossRefinement/boss-6-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-6-map-ipad.png) / [start](Screenshots/BossRefinement/boss-6-start-ipad.png) |
| 7 | [kaart](Screenshots/BossRefinement/boss-7-map-iphone.png) / [start](Screenshots/BossRefinement/boss-7-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-7-map-ipad.png) / [start](Screenshots/BossRefinement/boss-7-start-ipad.png) |
| 8 | [kaart](Screenshots/BossRefinement/boss-8-map-iphone.png) / [start](Screenshots/BossRefinement/boss-8-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-8-map-ipad.png) / [start](Screenshots/BossRefinement/boss-8-start-ipad.png) |
| 9 | [kaart](Screenshots/BossRefinement/boss-9-map-iphone.png) / [start](Screenshots/BossRefinement/boss-9-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-9-map-ipad.png) / [start](Screenshots/BossRefinement/boss-9-start-ipad.png) |
| 10 | [kaart](Screenshots/BossRefinement/boss-10-map-iphone.png) / [start](Screenshots/BossRefinement/boss-10-start-iphone.png) | [kaart](Screenshots/BossRefinement/boss-10-map-ipad.png) / [start](Screenshots/BossRefinement/boss-10-start-ipad.png) |
