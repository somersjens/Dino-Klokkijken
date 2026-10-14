# Zijranden en onderkanten — twee verfijningsrondes, 14 oktober 2026

De tien wereldbanners zijn opnieuw uitgewerkt in de native shapes en Canvas van [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift). De renders hieronder zijn controlebeelden; de game gebruikt deze PNGs niet als achtergronden of bannerassets.

## Ronde 1: ornamenten met een zichtbare constructie

De losse sterren, losse parels, kleine kristalsplinters en drie losstaande golflijnen zijn vervangen door ornamenten met een verbinding en een afgewerkte voet. Het bladwerk groeit langs een doorlopende tak met zijstelen. Bloemen hebben stelen die in de bloemkelk eindigen. Rotsen en kristallen delen een basis waarvan de voorrand de rechte onderkanten bedekt. De metalen onderdelen zijn in een dragende behuizing geplaatst.

De zijranden staan aan beide kanten op dezelfde hoogte. Hun voet blijft aan de onderrand verankerd als de bannerbreedte verandert. De ornamenten schalen begrensd mee, zodat een brede banner geen buitenproportioneel hoge zijstukken krijgt.

[Renders na ronde 1](Screenshots/BannerEdgePolish/round-1-ten-worlds.png) · [Smalle en brede lay-out na ronde 1](Screenshots/BannerEdgePolish/round-1-widths.png).

Bij het opnieuw bekijken vielen drie resterende problemen op: een voorgrondblad bedekte de zon- en maanemblemen, de voeten hadden een harde binnenrand en de achterste draagvormen leken voor verschillende materialen te veel op elkaar.

## Ronde 2: materiaal, aansluiting en overlap

De emblemen zijn vrijgemaakt. De binnenkant van iedere voet is afgerond en de draagvormen hebben nu een eigen contour: facetten voor basalt en kristal, afgerond metaal voor de stad en tijdmachine, een houten schouder voor de piraten en kantelen voor het kasteel. De materiaalranden krijgen licht en schaduw binnen hun eigen vorm.

Het bladwerk heeft zachtere nerven en een lichtverloop vanuit het oppervlak. Extra detail zit in het materiaal zelf: basaltfissuren, kristalranden, ventilatiesleuven, tandwielspaken, houtnerf en steennaden. De dorpsvlaggetjes volgen exact de kromming van hun bevestigingskoord.

Een controle tijdens deze ronde liet zien dat een opstaande glansrand door enkele bladeren en voeten sneed. Die is vervangen door één laag profiel onder de beschrijving. De achterste zijstukken sluiten op dat profiel aan; bladeren, voeten en schelpen liggen ervoor. Zo maakt de afwerking de onderkant compleet zonder de ornamenten af te snijden.

[Definitieve renders van alle tien banners](Screenshots/BannerEdgePolish/round-2-ten-worlds.png) · [Definitieve lay-out op 284 en 564 punten](Screenshots/BannerEdgePolish/round-2-widths.png).

| Wereld | Afwerking van de zijkant |
| --- | --- |
| Dino Jungle | Takken, overlappende bladclusters en bloemen met zichtbare stelen |
| Slaapvallei | Koel bladwerk met ingezette maanmedaillons |
| Vulkaanland | Verbonden basaltkolommen, fissuren en een lavarand in de stenen voet |
| Dino Dorp | Houten drager, huisjes, vastgemaakt vlaggenkoord en bloemen |
| Kristalgrot | Drie kristallen per zijde die uit een gesloten geodevoet groeien |
| Dino Stad | Gebouwen in een metalen behuizing met aangesloten leidingen en ventilatiesleuven |
| Dag-en-nachtbos | Warm en koel bladwerk met vrij zichtbare zon- en maanmedaillons |
| Tijdmachine | Tandwielen op assen en lagers in een messing behuizing |
| Tijdpiraten | Houten drager, anker aan een touw, doorlopende golfkrul en schelp met parel |
| Dinokasteel | Stenen pijlers met kantelen, bevestigd vaandel, kroon en afgewerkte stenen voet |

De beschrijving blijft een compacte inzet tussen de zijranden. Op een smalle banner kunnen lange beschrijvingen twee regels gebruiken. De naamvlakken blijven vrij van grote voorgrondornamenten.

## Controle

Beide rondes zijn als native SwiftUI-renders bekeken. De definitieve smalle en brede renders zijn gecontroleerd op leesbaarheid, zichtbare emblemen, aansluiting van de voeten en overlap met de beschrijving.

De [iPhone-simulatorbuild](WorldTestLogs/BannerEdgePolish/iphone-build.log) en de bestaande testNativeWorldChaptersAndMinuteQuestions zijn geslaagd op iPhone 17 met iOS 26.5: één test met negen hoofdstukcontroles, nul fouten, afgerond in 220,519 seconden. De jungle-entree en alle negen volgende banners zijn vastgelegd en opnieuw visueel bekeken. Ieder volgend hoofdstuk is geopend en de eerste klokvraag is beantwoord. [Testlog](WorldTestLogs/BannerEdgePolish/all-worlds-iphone.log).

De brede lay-out is met native renders gecontroleerd; voor deze versie is geen nieuwe iPad-simulatoraudit uitgevoerd.

| Wereld | Definitieve kaart in de iPhone-game |
| --- | --- |
| 1 | [iPhone](Screenshots/BannerEdgePolish/world-1-iphone.png) |
| 2 | [iPhone](Screenshots/BannerEdgePolish/world-2-iphone.png) |
| 3 | [iPhone](Screenshots/BannerEdgePolish/world-3-iphone.png) |
| 4 | [iPhone](Screenshots/BannerEdgePolish/world-4-iphone.png) |
| 5 | [iPhone](Screenshots/BannerEdgePolish/world-5-iphone.png) |
| 6 | [iPhone](Screenshots/BannerEdgePolish/world-6-iphone.png) |
| 7 | [iPhone](Screenshots/BannerEdgePolish/world-7-iphone.png) |
| 8 | [iPhone](Screenshots/BannerEdgePolish/world-8-iphone.png) |
| 9 | [iPhone](Screenshots/BannerEdgePolish/world-9-iphone.png) |
| 10 | [iPhone](Screenshots/BannerEdgePolish/world-10-iphone.png) |
