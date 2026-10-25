# Wereldbadges in het leveloverzicht — 23 oktober 2026

Alle tien wereldbadges zijn opnieuw afgewerkt in de native SwiftUI-tekening van [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift). De titels krijgen lichte letters met een dunne gekleurde contour en een kleine dieptewerking. Oerwoud, Woestijn, Klokdorp, Slaapvallei en Tijdmachine gebruiken ronde letters; Vulkaanland, Kristalgrot en Klokstad stevigere rechte letters; Tijdpiraten en Tijdkasteel klassieke schreefletters.

De lettergrootte volgt de daadwerkelijk gemeten vertaalde titel. Eén echte tekstweergave houdt de naam toegankelijk; de contour wordt in een decoratief Canvas getekend. Het wereldnummer krijgt meer letterruimte. De beschrijving heeft een iets hoger vlak en kan op twee regels staan, ook bij de langere Nederlandse teksten van Slaapvallei en Tijdmachine.

De materialen hebben meer kleur en duidelijkere licht- en schaduwranden. Het titelvlak is breder, met een ingewerkte onderrand, kleine hoekinleg en een subtiel motief onder de naam. Basalt, kristal en stadmetaal hebben afgeschuinde hoeken. Hout houdt zijn nerf; de piraten behouden hun touwrand en de slaapvallei haar gestikte rand.

| Wereld | Eigen afwerking |
| --- | --- |
| Oerwoud | Warm hout, groene nummerplaat, bladkransen en bloemen |
| Woestijn | Zandsteen en afgewerkte expeditievaantjes met een voetafdruk en zon |
| Vulkaanland | Donker basalt, goudgele letters en verschillende lavarotsen per zijde |
| Klokdorp | Honingkleurig hout, huisjes, vlaggetjes en luchtiger bladwerk |
| Kristalgrot | Gefacetteerde plaat, mintkleurige letters en ongelijke gekleurde kristalgroepen |
| Klokstad | Blauw metaal, mintkleurige letters en verschillende gebouwhoogtes |
| Slaapvallei | Lavendel, lichte ronde letters, blauw bladwerk en maanmedaillons |
| Tijdmachine | Messing, ivoorkleurige letters, tandwielen en bewegende klokjes |
| Tijdpiraten | Verweerd hout, schreefletters, een anker links en een scheepswiel rechts |
| Tijdkasteel | Goud en blauw, schreefletters, een kroon links en een schild met edelsteen rechts |

[Alle tien badges in het Nederlands](Screenshots/WorldBadgeRedesign/ten-worlds-nl.png) · [Alle tien in het Engels](Screenshots/WorldBadgeRedesign/ten-worlds-en.png).

De 82 native controlebeelden omvatten alle tien werelden op 284, 354 en 564 punten, Nederlands en Engels, plus hoog contrast op 284 punten en twee overzichtsbeelden. De afbeeldingen dienen alleen als controle; de app blijft de badges met SwiftUI en Canvas tekenen. De vaste bannerhoogte en het middelpunt tussen de levels blijven behouden. De bestaande tijdmachineanimatie blijft de zichtbaarheid en Minder beweging volgen.

## Verificatie

- De definitieve simulatorbuild en de laatste broncodebuild zijn geslaagd: [testbuild](WorldTestLogs/WorldBadgeRedesign/final-build.log) · [laatste build](WorldTestLogs/WorldBadgeRedesign/final-source-build.log).
- De native renders zijn visueel gecontroleerd op titelcontouren, tekstpassing en de aansluiting van de ornamenten.
- De bestaande afstandscontrole is geslaagd op iPhone 17 voor wereld 2 en 10 (29,619 seconden, nul fouten) en op iPad A16 voor wereld 10 (24,698 seconden, nul fouten): [iPhone](WorldTestLogs/WorldBadgeRedesign/iphone-spacing.log) · [iPad](WorldTestLogs/WorldBadgeRedesign/ipad-spacing-10.log). De beelden van beide apparaten zijn ook visueel bekeken.
- De uitgebreide wereld-/vraagtest is niet afgerond: de test runner werd met `signal kill` beëindigd, ook tijdens een kortere herhaling. De gerichte kaartcontroles hierboven zijn wel geslaagd. Dit is geen geslaagde volledige UI-regressietest.
