# Vrije sterruimte en verbonden eindlandschappen — 24 oktober 2026

De sterren staken bij enkele podiums visueel over lijsten heen. Achter de sterren liepen bovendien voegen, facetnaden, touw of metalen details. De eindschermen krijgen nu een expliciet vrijgehouden display in het podium, plus verder verbonden landschappen voor alle tien werelden.

De opvolgende verfijning verwijdert het zichtbare voorvlak, verkleint de stenen en vergroot de sterren. Zie [Compactere stenen en grotere sterren](ResultStoneProportions.md) voor die tussenstap. De huidige uitvoering verwijdert ook alle materiaalvervaging en steruitsparingen en herstelt de mos-, blad- en grondlagen: [Doorlopend materiaal en natuurlijke lagen](ResultNaturalLayers.md).

## Sterren en display

`ResultPodiumGeometry` beschrijft de gedeelde tekenruimte van 1000 × 455 eenheden. Het display ligt op x=178…822 en y=150…414. De beloningen gebruiken sterren met een nominale breedte van 190 eenheden, een centrale schaal van 1,08 en slechts zes graden draaiing aan de zijkanten. Hun gezamenlijke compositie staat rond y=290. De berekende buitenste vierkanten, inclusief draaiing, laten minimaal 21,9 eenheden marge tot de displayrand. De eigenlijke stercontouren liggen daarbinnen. De kleinere ongevulde sterren passen binnen dezelfde ruimte.

Het display is een rustige verdieping in hetzelfde wereldmateriaal. De materiaaltekening wordt buiten dat vlak gehouden: er zijn geen voegen, facetlijnen, meetinstrumenten, klinknagels of decoratieve details achter de sterren. De onderliggende wereldmaterialen en de decoratie langs de zijkanten blijven zichtbaar. De voorste junglebeplanting en lage versiering hebben dezelfde uitsparing. Het piratentouw loopt boven het display; de meetinstrumenten staan verder naar buiten.

De sterren behouden hun bestaande scorelabels en beloningsafbeelding. Tijdens de onthulling zakken ze slechts een klein stukje in het display; de vroegere val van buiten het vlak is vervangen zodat ook de onthulling binnen de vrije zone blijft. De sprong en andere Dino-animaties blijven aan dezelfde voetlijn gekoppeld.

## Eén landschap per wereld

| Wereld | Doorontwikkeling van het landschap |
| --- | --- |
| Dino Jungle | Verbonden bosranden volgen de heuvels; een smalle beek snijdt in dezelfde grasbank en loopt langs de open plek. De grondcontouren sluiten aan op de voet van het podium. |
| Woestijn | De voet van de mesa's loopt over in de duinen. Verschillende dieptelagen en lange windribbels delen hun richting en zandmateriaal met de open plek bij Dino. |
| Vulkaanland | Een doorlopende caldera met verre bergkammen, lagere basaltbanken en samenhangende lavakanalen vervangt de losse berg-objecten als hoofdmotief. Warme nevel bindt de lagen. |
| Klokdorp | Huizen en klokkentoren staan op één terras. Een brug, tuinranden en bestrating verbinden de beek, huisvoeten en het dorpsplein. Dakpannen, raamsponningen en gevelzijden verdiepen de architectuur. |
| Kristalgrot | Doorlopende gewelven en steenlagen gaan over in rotsbanken. De poel is uitgesneden in de oever en heeft aansluitende reflecties; de kristallen groeien uit diezelfde banken. |
| Klokstad | Een skyline met atmosferische diepte en doorlopende plint vormt de achterkant van het plein. Bestrating, groenranden, lantaarns en geveldetails delen één perspectief en grondniveau. |
| Slaapvallei | Bosranden en zachte oevers verbinden heuvels en beek. De wilgen hebben een samenhangende kroon en afhangende takken; paddenstoelen staan in groepen in de oever. |
| Tijdmachine | Een complete machinehal met wandvakken, portaalringen, dragende steunen en vloerleidingen verbindt de tandwielen en het messing podium. |
| Tijdpiraten | De zee, het eiland en het strand delen één gebogen kustlijn. Branding volgt dezelfde oever, een verweerde kade sluit op de kust aan, en rimpelingen volgen het waterperspectief. |
| Tijdkasteel | Een gemetselde muur met poort en verbonden torens omsluit de binnenplaats. Doorlopende terrassen, perspectivische bestrating en lage tuinranden brengen de sokkel in dezelfde ruimte. |

De achtergrond krijgt de werkelijke podiumpositie via een SwiftUI-boundsanker. Het licht aan de voet, de terreincontouren en de grondsporen volgen daardoor dezelfde sokkel op telefoon en tablet, inclusief de veilige schermranden. Dit gebruikt geen permanent draaiende animatie of nieuwe rasterassets.

## Verificatie

- Debug-testbuild: geslaagd.
- De berekening van de drie gedraaide sterkaders bevestigt minimaal 21,9 eenheden vrije marge binnen het display.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), beide iOS 26.5, met nul fouten. Alle twintig wereldweergaven zijn visueel bekeken op vrije sterruimte, achtergrondopbouw, grondcontact en de laagvolgorde rond het podium.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, boss-resultaten en Engelse tekst.
- iPhone SE (3e generatie, iOS 26.1): dorp, tijdmachine, kristalgrot en een boss-resultaat met nul sterren en extra uitlegtekst visueel gecontroleerd. Alle sterren en de bediening passen binnen hun kaders.
- Na de laatste aanpassing aan de onthulling is de belonings- en navigatietest opnieuw geslaagd op iPad, met nul fouten. Een aanvullende berekening controleert de volledige springovershoot; ook dan blijven alle drie sterkaders binnen het display, met minimaal 14,9 eenheden marge.
- De achtergronden en vaste sterposities zijn bij de laatste wijziging aan de onthulling behouden. `git diff --check` is schoon. De drie eigen testsimulators zijn na afloop opgeruimd.

[Build](WorldTestLogs/ResultSceneUnity/build.log) · [iPhone](WorldTestLogs/ResultSceneUnity/iphone.log) · [iPad](WorldTestLogs/ResultSceneUnity/ipad.log).

## Beelden

[Tien complete wereldscènes](Screenshots/ResultSceneUnity/wereldscenes-overzicht.jpg) · [Detail van de tien sterdisplays](Screenshots/ResultSceneUnity/sterdisplays-overzicht.jpg) · [iPad](Screenshots/ResultSceneUnity/ipad-overzicht.jpg) · [Nul tot drie sterren](Screenshots/ResultSceneUnity/beloningsstaten.jpg) · [Kleine iPhone, inclusief extra uitleg](Screenshots/ResultSceneUnity/compact/overzicht.jpg).

[Verslag kleine iPhone](WorldTestLogs/ResultSceneUnity/compact.log) · [Laatste belonings- en navigatiecontrole](WorldTestLogs/ResultSceneUnity/rewards-final.log).

[Berekening van de sterruimte, inclusief onthulling](WorldTestLogs/ResultSceneUnity/star-clearance.log).
