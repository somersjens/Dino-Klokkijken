# Compactere stenen en grotere sterren — 24 oktober 2026

Dit verslag beschrijft een eerdere tussenstap. De resterende materiaalvervaging en steruitsparingen zijn inmiddels volledig verwijderd. Ook de mosranden, voorgrondbladeren en grondovergangen zijn hersteld voor alle werelden. Zie [Doorlopend materiaal en natuurlijke lagen](ResultNaturalLayers.md) voor de huidige uitvoering.

De vorige uitvoering gaf de sterren een zichtbaar rechthoekig voorvlak. Vooral in Klokstad en Tijdpiraten las dat als een opgeplakte achtergrond. De hoofdstenen waren bovendien groot ten opzichte van de beloningen.

## Verhouding en vorm

De hoofdsteen is ongeveer 14% smaller en lager, met behoud van zijn wereldmateriaal, bovenkant en voetcontact. De sterren zijn fysiek ongeveer 7% groter en beslaan samen circa 71% van de steenbreedte, tegenover ongeveer 57% in de vorige uitvoering. De hoofdvorm omlijst daardoor de beloning met minder leeg materiaal aan de zijkanten.

| Maat | Vorige uitvoering | Nieuwe uitvoering |
| --- | --- | --- |
| Steenbreedte ten opzichte van Dino | 1,62 | 1,40 |
| Sterbreedte ten opzichte van de steen | 19% | 23,5% |
| Voorvlak achter de sterren | Afzonderlijk gevuld en omlijnd paneel | Doorlopend materiaal van de hele steen |
| Materiaaldetails | Uitsparing met zichtbare rechthoekige overgang | Vier zachte verlopen aan de buitenranden |

Het aparte voorvlak is bij **alle tien werelden verwijderd**. Er wordt geen extra kleurvlak of rand over de steen getekend. De oorspronkelijke materiaalgradiënt loopt door. Facetlijnen, zandsteenlagen, voegen en metaalaccenten vervagen vóór de sterren en blijven langs de echte buitenranden herkenbaar. Bij de stad en tijdmachine zijn de zijdetails smaller en zijn de boven- en onderranden naar buiten verplaatst. Bij het kasteel staan de banieren op de zijstenen; het piratentouw loopt over de bovenrand. Het jungle- en vallei-mos blijft op de bovenste schouders.

`ResultPodiumGeometry.rewardBounds` is uitsluitend een onzichtbare vrije ruimte. De drie sterren blijven daarbinnen, inclusief de onthulling en het doorschieten van de veeranimatie. De berekende minimale marge is 9,0 tekeneenheden. De grote wereldachtergronden, score en bediening gebruiken hun bestaande opbouw.

## Controle

- Debug-testbuild: geslaagd.
- Wereld 6 en 9 zijn afzonderlijk visueel beoordeeld op een eigen iPhone-simulator. Het rechthoekige voorvlak en de bijbehorende overgang zijn verdwenen.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), beide iOS 26.5. Alle twintig wereldweergaven zijn visueel bekeken op vorm, grootte, materiaalcontinuïteit en vrije sterpunten.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, boss-resultaten en Engelse tekst.
- iPhone SE (3e generatie, iOS 26.1): wereld 6, wereld 9 en een boss-resultaat met extra uitleg en nul sterren visueel gecontroleerd. De beloningen blijven op de steen en de bediening blijft bereikbaar.
- Berekening van de gedraaide sterkaders over de hele veeranimatie: geslaagd, minimaal 9,0 tekeneenheden marge binnen de onzichtbare vrije ruimte.
- Drie UI-testuitvoeringen, nul fouten. `git diff --check` is schoon. De drie tijdelijke testsimulators zijn na afloop opgeruimd.

[Build](WorldTestLogs/ResultStoneProportions/build.log) · [iPhone](WorldTestLogs/ResultStoneProportions/iphone.log) · [iPad](WorldTestLogs/ResultStoneProportions/ipad.log).

## Beelden

[Wereld 6 en 9 voor en na](Screenshots/ResultStoneProportions/wereld-6-en-9-voor-na.jpg) · [Alle tien stenen en sterren](Screenshots/ResultStoneProportions/stenen-en-sterren-overzicht.jpg) · [iPad](Screenshots/ResultStoneProportions/ipad-overzicht.jpg) · [Nul tot drie sterren](Screenshots/ResultStoneProportions/beloningsstaten.jpg) · [Kleine iPhone](Screenshots/ResultStoneProportions/compact/overzicht.jpg).

[Sterruimteberekening](WorldTestLogs/ResultStoneProportions/star-clearance.log) · [Kleine-iPhone-opnames](WorldTestLogs/ResultStoneProportions/compact.log).
