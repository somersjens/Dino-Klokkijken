# Afwerking van de eindbaaswerelden

27 oktober 2026.

De volgende feedbackronde staat in [Jungleroute en eindbaashoven](BossCourtyards.md). De aanvullende screenshotfeedback is verwerkt in wereld 1, 2, 4, 5, 6, 8 en 10. De eindbaasplekken sluiten op de eigen wereldgrond aan, zonder extra verbinding naar de hoofdweg. Wereld 7 is behouden.

| Wereld | Aanpassing |
| --- | --- |
| 1 — Jungle | Kleinere, zichtbare boomkruinen en meer verspreide bomen aan beide kanten. De laatste rechterboom staat vóór de vrijgehouden baasruimte. Level 10 blijft centraal, met level 9 in de linkerbocht. |
| 2 — Woestijn | Het ringetje zandsteenheuvels onder de baas is verwijderd. Ook de laatste cactus en rots uit de gewone decoratielaag staan nu links; de laatste buitenste tabletformatie staat hoger. De baas staat op zand met een zachte schaduw. |
| 4 — Klokdorp | De kadepaden volgen de normaal van de daadwerkelijke rivierbocht. Daardoor drukken ze de buitenste oeverrand bij de uitgang niet meer weg. Ook de aansluitpunten van de dorpspaden volgen die oever. |
| 5 — Kristalgrot | De losse stenen boog is weg. Vloer, gesteente, wandlagen en overhangende rotsen gebruiken lichter blauwgroen en zilverblauw, passend bij de baas. Vloerlicht en contactschaduw laten zijn voeten op de grotgrond landen. |
| 6 — Klokstad | Een extra gevel vult de rechter bouwkavel boven de laatste spoorbocht. De gereserveerde ruimte volgt de werkelijke illustratie met marge; funderingen blijven vrij van de rails en de volledige baas. De eerder vergrote baas blijft behouden. |
| 8 — Tijdmachine | Helder lila keert terug in de vloer, terrassen, gevels, brugdelen en laatste waterputten. Blauw water en gouden metaal blijven herkenbaar. De baas krijgt gereflecteerd vloerlicht en een donkere, zachte contactschaduw op de bestaande bestrating. |
| 10 — Tijdkasteel | Een volledig kasteel met torens staat achter de koning op de droge binnenoever. De gevel past ook op een smalle iPhone. De dieptevolgorde houdt de koning vóór het kasteel. |

[Overzicht telefoon](Screenshots/WorldSceneryFinish/overview-393.png) · [Smalle telefoon](Screenshots/WorldSceneryFinish/overview-320.png) · [Overzicht tablet](Screenshots/WorldSceneryFinish/overview-834.png).

De native overzichten gebruiken vereenvoudigde levelstenen. Volledige hoofdstukken staan naast de overzichtsbeelden in dezelfde map, als `full-world-N-393.png` en `full-world-N-834.png`.

## Verificatie

- **1.159.521 kerncontroles geslaagd**, inclusief nieuwe controles op werkelijk zichtbare boomkruinen aan beide kanten, ook bij de laatste junglebochten. [Kernlog](WorldTestLogs/WorldSceneryFinish/core.log).
- **134.117 geometriecontroles geslaagd** op twaalf breedtes, van 320 tot 1366 punten: droge standplaatsen, volledige illustraties binnen beeld, vrije rails en gevels, een droge kasteelfundering binnen beeld en intacte wateraansluitingen. [Geometrie en renders](WorldTestLogs/WorldSceneryFinish/native.log).
- iOS-app en schermtests compileren. [Buildlog](WorldTestLogs/WorldSceneryFinish/ios-build.log).
- De zeven aangepaste eindbaasgebieden slagen op **iPhone 18 Pro en iPad Pro 13 inch**. Iedere eindsteen blijft bereikbaar, minimaal 44 punten breed en opent het juiste level. De jungle-eindsteen staat centraal met de voorganger links. [Schermtestlog](WorldTestLogs/WorldSceneryFinish/ui.log).

[Echte iPhone-schermen](Screenshots/WorldSceneryFinish/iphone-overview.png) · [Echte iPad-schermen](Screenshots/WorldSceneryFinish/ipad-overview.png).
