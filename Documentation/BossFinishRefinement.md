# Verfijning van de eindbaasgebieden

27 oktober 2026.

De nieuwste afwerking staat in [Bazen op de bestaande wereldgrond](BossGrounding.md).

De standplaatsen van wereld 1, 3, 4, 5, 6, 8 en 10 sluiten nu als één vloer aan op het speelpad. De losse afgeronde plateaus en smalle verbindingsstroken zijn vervangen door doorlopende grondvormen. Wereld 2, 7 en 9 behouden hun eerdere ontwerp.

- **Jungle:** een bredere bosopening met grondkorrel, onregelmatige grasranden en kleine bloemen.
- **Vulkaan:** aansluitende asgrond met basaltgruis en een ruimere, vloeiende lava-uitgang.
- **Dorp:** vlakke bestrating met doorlopende, verspringende voegen en een afgewerkte plantenrand. De rivier draait over een langere boog naar buiten.
- **Kristalgrot:** een natuurlijke rotsvloer met onregelmatige voorrand, mineraallijnen en kleine kristalsplinters.
- **Stad:** een plein dat vanuit de bestaande straatbestrating opent, met verspringende voegen, schuine hoeken en een lage plantenbak. Het losse verhoogde vlak is vervallen.
- **Tijdmachine:** de rechter waterloop verlaat het pad vanuit de verticale tangent bij level 78. Hij volgt één ruime buitenboog naar een afvoer op de oorspronkelijke onderste kadelaag. De laatste lozingen eindigen in die doorlopende waterloop. Het loshangende klokrek naast de baas is verwijderd; de omgeving zelf levert de aansluitende architectuur en waterwerken. Het eindplein heeft vlakke bestrating met een messing inleg.
- **Kasteel:** een aangesloten kalkstenen hofvloer met kleinere voegen, een bloemenrand en een ruimere grachtuitgang.

De omhooggeschoven put van de vorige versie eindigde vóór de laatste lozing. Daardoor viel er nog water onder de afvoer voor de wand. Nu eindigen afvoer en kade weer op dezelfde hoogte en landen alle lozingen vóór de put in het kanaal.

[Zeven verfijnde gebieden](Screenshots/BossFinishRefinement/overview-393.png) · [Wereld 8: vorige en verfijnde aansluiting op tablet](Screenshots/BossFinishRefinement/world-8-refinement-834.png) · [Telefoon](Screenshots/BossFinishRefinement/world-8-refinement-393.png).

## Controle

- Alle tien landschappen gerenderd op 320, 393, 600, 834 en 1194 punten; de zeven gewijzigde eindgebieden visueel beoordeeld.
- **114.155 geometriecontroles geslaagd op twaalf breedtes:** droge ondergrond, complete figuren, vrije decorruimte, aansluitende kadehoogte, naar buiten lopend water en alle negen lozingen in de echte waterloop. [Audit](WorldTestLogs/BossFinishRefinement/geometry-audit.swift) · [Geometrie](WorldTestLogs/BossFinishRefinement/geometry.log).
- Alle zeven gewijzigde eindbaasgebieden geopend op iPhone en iPad. [Schermtests](WorldTestLogs/BossFinishRefinement/ui.log).
- De laatste vier water- en lava-uitgangen aanvullend op beide apparaten gecontroleerd. [Definitieve schermtests](WorldTestLogs/BossFinishRefinement/water-ui.log).
- De iOS-app en schermtests compileren. [Build](WorldTestLogs/BossFinishRefinement/ios-build.log).

De native beelden gebruiken vereenvoudigde levelstenen. De appbeelden tonen de werkelijke interface: [wereld 8 op iPhone](Screenshots/BossFinishRefinement/world-8-iphone.png) en [iPad](Screenshots/BossFinishRefinement/world-8-ipad.png).
