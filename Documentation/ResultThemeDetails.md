# Afwerking per wereld — 26 oktober 2026

De podiums zijn per wereld aangepast op materiaal, decoratie, laagvolgorde en de ruimte rond de sterren.

| Wereld | Uitvoering |
| --- | --- |
| 1 · Jungle | Het mos is smaller en loopt over de buitenste schouders naar de zijkanten. De ruimte op het bovenvlak naast Dino’s voeten blijft open. |
| 2 · Woestijn | De steen heeft weer een afgeronde omtrek. Eén doorlopende zandduin loopt achter de zijranden en vóór de onderrand, zodat de ronde steen gedeeltelijk in het zand staat. De kap en de schouders delen dezelfde contour. |
| 3 · Vulkaanland | Bestaand basaltontwerp behouden en opnieuw visueel gecontroleerd. |
| 4 · Klokdorp | Het grote gemetselde voorvlak loopt verder naar beneden; de trede begint lager. De sterren staan iets hoger en zijn iets kleiner, met vrije ruimte boven de onderrand. |
| 5 · Kristalgrot | Ook de grote kristalgroepen worden vóór de steen getekend, aan beide buitenzijden. De kleinere kristallen en splinters sluiten daarop aan. |
| 6 · Klokstad | De metalen voet begint lager, zodat het grote voorvlak meer ruimte biedt. De kleinere sterren zijn iets omlaag geplaatst voor een gelijkmatiger verdeling binnen het voorvlak; ook onder de gloed en schaduw blijft zichtbaar metaal boven de voet. |
| 7 · Slaapvallei | Mos over de buitenste schouders; alle bladparen rond de steen en de ingegraveerde sterrenbeelden zijn verwijderd. De paddenstoelen zijn groter en staan in groepen, met hun kappen binnen de schermrand. |
| 8 · Tijdmachine | De metalen randen, leidingen, tandwielen en wijzerplaten worden in de voorgrondlaag vóór de steen getekend. Dubbele, deels bedekte kleine wijzerplaten zijn verwijderd. De sterren zijn hoger geplaatst en hebben dezelfde kleinere maat als in 6 en 9, zodat ze midden in het lagere voorvlak passen. |
| 9 · Tijdpiraten | Een houten kist vervangt de zandsteen: een houten deksel, planken met nerven en knoesten, zijschoren, een omlijst voorvlak, metalen bevestigingen en touwgrepen. Het hout en de constructie lopen door tot aan de onderkant. De kleinere sterren zijn na de laatste correctie iets omlaag geplaatst voor een gelijke verdeling van de ruimte binnen de omlijsting. |
| 10 · Tijdkasteel | De hangende banieren zijn breder en langer, met grotere kronen. De twee losse standaarden direct naast de sokkel en hun voeten zijn verwijderd. De verdere achtergrondversiering blijft onderdeel van het kasteel. |

## Uitvoering

`ResultWorldPodium.swift` bevat de materialen, contouren en decoratielagen. `ResultLayout` in `LevelResult.swift` kiest nu de stermaat en de hoogte per wereld. De bestaande karakterpositie, sprongen, beloningstoestanden, score en navigatie gebruiken hun bestaande ankers.

De wereldkeuze volgt `DinoWorld.themeID`: woestijn is wereld 2 / thema 7 en Slaapvallei wereld 7 / thema 2. De objecten blijven native Canvas-tekeningen. Er zijn geen rasterassets toegevoegd.

## Controle

### Laatste correcties: centrering in wereld 6, 8 en 9

De sterren volgen de beschikbare voorvlakken. In 6 is alleen het verticale anker van 268 naar 294 verplaatst: de rij staat iets lager, met dezelfde sterbreedte van 19% en een gelijkmatiger verdeling van de ruimte boven en onder de sterren. In 8 is het verticale anker 272 (voorheen 292) en de sterbreedte 19% van de podiumbreedte (voorheen 23,5%). In 9 blijft de sterbreedte 19%; het verticale anker is 308 (voorheen 284). Hiermee staan de sterren hoger in het lagere machinevoorvlak en lager in het houten voorvlak. Dino's maat, contactpunt en positie, de podiumtekening en de rest van de layout zijn bij deze correcties niet aangepast.

- De testbuild is geslaagd.
- `testAllWorldResultScenery`, beperkt tot wereld 8 en 9, is geslaagd op iPhone 17, iPhone SE (3e generatie) en iPad Pro 11-inch (M5), iOS 26.5: drie tests, nul fouten.
- Alle zes nieuwe beelden zijn op volledige afbeeldingsgrootte bekeken op de ruimte rond de rij, de grootste middelste ster, gloed en schaduw. De ruimte boven en onder de sterren is nu gelijkmatiger verdeeld binnen het voorvlak.
- Wereld 6 is na het verlagen van de rij apart met dezelfde UI-test op alle drie apparaten gecontroleerd: drie tests, nul fouten. De drie detailbeelden tonen een gelijkmatiger verdeling van de ruimte en vrije sterpunten boven de metalen voet, inclusief hun gloed en schaduw.

[Huidige sterren in 8 en 9](Screenshots/ResultStarCentering/sterren-8-en-9.png) · [iPad: 8](Screenshots/ResultStarCentering/ipad/wereld-8-detail.png) · [9](Screenshots/ResultStarCentering/ipad/wereld-9-detail.png) · [Kleine iPhone: 8](Screenshots/ResultStarCentering/compact/wereld-8-detail.png) · [9](Screenshots/ResultStarCentering/compact/wereld-9-detail.png) · [Build](WorldTestLogs/ResultStarCentering/build.log) · [iPhone-test](WorldTestLogs/ResultStarCentering/iphone.log) · [iPad-test](WorldTestLogs/ResultStarCentering/ipad.log) · [Compacte test](WorldTestLogs/ResultStarCentering/compact.log).

[Huidige sterren in 6](Screenshots/ResultCityStarCentering/iphone/wereld-6-detail.png) · [iPad](Screenshots/ResultCityStarCentering/ipad/wereld-6-detail.png) · [Kleine iPhone](Screenshots/ResultCityStarCentering/compact/wereld-6-detail.png) · [Build](WorldTestLogs/ResultCityStarCentering/build.log) · [iPhone-test](WorldTestLogs/ResultCityStarCentering/iphone.log) · [iPad-test](WorldTestLogs/ResultCityStarCentering/ipad.log) · [Compacte test](WorldTestLogs/ResultCityStarCentering/compact.log).

### Eerdere correctie: sterren in wereld 6 en 9

De eerdere beoordeling van de sterruimte in 6 en 9 was te ruimhartig: de gloed en schaduw lieten op de afbeeldingen te weinig duidelijke ruimte boven de onderste rand. Wereld 4 behoudt zijn bestaande afmetingen en positie.

De sterbreedte in 6 en 9 werd 19% van de podiumbreedte (voorheen 22% en 21%). Het verticale anker in de Canvas-coördinaten werd toen 268 voor 6 (voorheen 285) en 284 voor 9 (voorheen 296). De gloed, schaduw, draaiing en grotere middelste ster bleven behouden; de kleinere maat en hogere positie maakten daarvoor ruimte binnen het grote voorvlak. De laatste correcties hierboven vervangen deze verticale ankers.

- De testbuild is geslaagd.
- `testAllWorldResultScenery`, beperkt tot wereld 6 en 9, is geslaagd op iPhone 17, iPhone SE (3e generatie) en iPad Pro 11-inch (M5), iOS 26.5: drie tests, nul fouten.
- Beide nieuwe eindschermen zijn op alle drie schermformaten op volledige afbeeldingsgrootte visueel bekeken, inclusief de sterpunten, gloed en schaduw boven de metalen voet en houten onderlijst.
- `git diff --check` is schoon. De drie tijdelijke simulators zijn na de controle verwijderd.

[Nieuwe iPhone-details](Screenshots/ResultStarMargins/sterren-6-en-9.png) · [Nieuwe iPad: 6](Screenshots/ResultStarMargins/ipad/wereld-6-detail.png) · [9](Screenshots/ResultStarMargins/ipad/wereld-9-detail.png) · [Kleine iPhone: 6](Screenshots/ResultStarMargins/compact/wereld-6-detail.png) · [9](Screenshots/ResultStarMargins/compact/wereld-9-detail.png) · [Build](WorldTestLogs/ResultStarMargins/build.log) · [iPhone-test](WorldTestLogs/ResultStarMargins/iphone.log) · [iPad-test](WorldTestLogs/ResultStarMargins/ipad.log) · [Compacte test](WorldTestLogs/ResultStarMargins/compact.log).

### Eerdere ronde: alle tien werelden

- Debug-build voor tests: geslaagd.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), beide iOS 26.5. Alle twintig eindschermen met drie sterren zijn vastgelegd en visueel gecontroleerd.
- Alle tien materialen zijn op iPhone ook zonder gouden sterren bekeken, zodat de contour, het hout, de voegen en de voorgrondlagen zichtbaar blijven.
- Eigen iPhone SE (3e generatie, iOS 26.5): alle tien thema’s met drie sterren visueel gecontroleerd op afsnijding, decoratie, sterruimte en ruimte boven de bediening.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, sterrenoverzicht en eindbaasresultaten.
- De eerdere berekening met gedraaide sterpixels (alpha > 128) gaf alleen de ruimte rond het dekkende deel van de ster aan. Deze controle was onvoldoende voor de zichtbare gloed en schaduw in 6 en 9; de aanvullende correctie hierboven vervangt die beoordeling.
- Drie bestaande UI-tests uitgevoerd, nul fouten. `git diff --check` is schoon. De drie eigen testsimulators zijn na afloop verwijderd.

[Build](WorldTestLogs/ResultThemeDetails/build.log) · [iPhone-test](WorldTestLogs/ResultThemeDetails/iphone.log) · [iPad-tests](WorldTestLogs/ResultThemeDetails/ipad.log) · [Sterruimte](WorldTestLogs/ResultThemeDetails/star-clearance.log).

## Beelden

De overzichten hieronder documenteren de eerdere ronde. Voor de huidige stermaat en positie in 6, 8 en 9 gelden de laatste correcties hierboven.

[Alle tien op iPhone](Screenshots/ResultThemeDetails/podiums-iphone.jpg) · [iPad](Screenshots/ResultThemeDetails/podiums-ipad.jpg) · [Kleine iPhone](Screenshots/ResultThemeDetails/podiums-compact.jpg) · [Alle materialen zonder goud](Screenshots/ResultThemeDetails/materialen-zonder-goud.jpg) · [Sterren in 4, 6 en 9](Screenshots/ResultThemeDetails/sterren-details.jpg).

[Ronde woestijnsteen in het zand](Screenshots/ResultThemeDetails/woestijn-detail.png) · [Kristallen vóór de steen](Screenshots/ResultThemeDetails/kristalgrot-detail.png) · [Mos en paddenstoelen](Screenshots/ResultThemeDetails/slaapvallei-detail.png) · [Machineonderdelen vóór de steen](Screenshots/ResultThemeDetails/tijdmachine-detail.png) · [Houten kist](Screenshots/ResultThemeDetails/houten-kist-detail.png) · [Hangende banieren](Screenshots/ResultThemeDetails/kasteel-detail.png).
