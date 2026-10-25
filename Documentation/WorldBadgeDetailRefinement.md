# Wereldbadges: laagvolgorde en zijdecoratie — 25 oktober 2026

De afwerking staat in de native `WorldBannerPainter` in [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift).

| Wereld | Aanpassing |
| --- | --- |
| 3 · Vulkaanland | De onderste lavalijn wordt vóór de kleine voorgrondstenen getekend, zodat de uiteinden erachter verdwijnen. |
| 4 · Klokdorp | De klokkentorens staan vóór de klimplanten. De struikjes en bloemen staan lager bij de torenvoeten. De bovenste takken sluiten doorlopend aan op de zijstelen. |
| 5 · Kristalgrot | Verschillende hellingshoeken laten de kristallen aan beide kanten in een lichte boog uitwaaieren. De rotsvoet dekt hun aanzet af. |
| 6 · Klokstad | Zeven torens met koepels, spitsen, vensters en gouden dakranden vormen verschillende dieptelagen. Rechts loopt een gebogen verhoogde baan vóór de toren en achter de metalen bevestigingen. Voetstukken met tandwielen en wolken verbinden de zijkanten met de onderrand. De torenhoogtes blijven afgestemd op de vaste bordhoogte, ook op smalle schermen. |
| 7 · Slaapvallei | De lantaarnpaal loopt tot in de begroeiing en heeft een bevestiging aan de zijkant. Beide lantaarns hangen aan de bovenboog. Wolken liggen vóór de bovenhoeken; bladeren en stenen vervangen het figuurtje linksonder. |
| 9 · Tijdpiraten | De bovenste touwuiteinden verdwijnen achter het wereldplaatje. Onderaan loopt het touw door achter de schelp en de klok. |

Gespiegelde klokconstructies houden dezelfde afgelezen tijd. Teksten, bordhoogte en levelposities blijven behouden.

[Overzicht van de zes aangepaste badges](Screenshots/WorldBadgeDetailRefinement/six-worlds-354-nl.png) · [Klokstad](Screenshots/WorldBadgeDetailRefinement/world-6-354-nl.png) · [Smalle Engelse badges](Screenshots/WorldBadgeDetailRefinement/six-worlds-284-en.png) · [Brede Nederlandse badges](Screenshots/WorldBadgeDetailRefinement/six-worlds-564-nl.png).

De native controlebeelden omvatten alle tien werelden op 284, 354 en 564 punten in het Nederlands en Engels. Ze gebruiken dezelfde tekenpaden als de app; alleen de renderhuls en lokalisatie zijn aangepast voor de macOS-controle.

[Buildlog](WorldTestLogs/WorldBadgeDetailRefinement/build.log) · [Native renderlog](WorldTestLogs/WorldBadgeDetailRefinement/native-render.log).

De bestaande UI-controle `testWorldBannersHaveBalancedClearance` is geslaagd op een aparte iPhone 18 Pro met iOS 27: alle negen wereldgrenzen, 133,093 seconden, nul fouten. De laatste broncode is daarbij opnieuw gebouwd. De afbeeldingen komen rechtstreeks uit het geslaagde testresultaat; de zes aangepaste badges zijn ook in hun kaartomgeving visueel beoordeeld.

[Definitieve build en simulatortest](WorldTestLogs/WorldBadgeDetailRefinement/iphone.log) · [Zes badges in de app](Screenshots/WorldBadgeDetailRefinement/six-worlds-iphone.png) · [Klokstad in de app](Screenshots/WorldBadgeDetailRefinement/world-6-iphone.png).
