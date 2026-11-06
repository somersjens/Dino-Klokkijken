# Voorbeelden en compacte vraagindeling — 1 november 2026

- Type 4 laat de buitenste leeshulp en de bijbehorende markeringen pas na de 0,3 seconde durende klokverkleining verschijnen. Verminder beweging toont de hulp direct.
- Het voorbeeld van type 7 gebruikt kleinere analoge en digitale klokken. De genummerde digitale hulppijlen delen de bovenste bedieningsruimte; de knoppen behouden hun tikvlak.
- Het voorbeeld van type 8 gebruikt de gewone groene klaar-knop onder de knop voor een ander voorbeeld. Het instelscript eindigt na het zetten van de wijzers, zonder controleknop of bevestigingstik. Zelf bedienen onderbreekt het script.
- Het voorbeeld van type 9 koppelt de digitale tijd aan een analoge uitlegklok met 13 t/m 23 en 00 buiten de rand. De persoonlijke wijzerplaat en wijzers blijven behouden.
- Typen 14 en 15 passen het volledige tijdsverschil, inclusief plus/min, als één regel aan de beschikbare breedte aan. Voorbeelden beginnen met alleen de tijd en het verschil. Daarna verschijnen de uren, minuten, losse verschillen, subtotalen en uitkomst achtereenvolgens. Een ander voorbeeld begint opnieuw bij de losse waarden.
- Type 17 heeft minder verticale marge en iets kleinere klokken en antwoordstenen. De digitale klokken staan op de verticale middenlijn. Compacte boogpijlen en kleinere tijdsverschillabels passen in de marge rechts van de klokken. De tekst over een dag van 24 uur is verwijderd uit alle schermen en vertalingen.

## Controles

De gerichte kernsuites `--clock-reading-hints`, `--time-reading` en `--answer-inputs` slagen met respectievelijk 110.208, 17.504 en 166.625 controles. De eerste volledige kernrun stopte op de losstaande assetcataloguscontrole voor `AppIcon-for-promo`.

De simulatorbuild slaagt. Op iPhone 18 Pro (iOS 27) slagen de controles voor de tijdreeks na fouten en herkansingen, de Engelse analoge leesklok, de afmetingen van beide rekenvoorbeelden en de compacte rekenuitleg bij twee keuzes. Op iPad mini (A17 Pro, iOS 27) slaagt `testCompactClockExamplesKeepTheirActionsVisible` voor typen 7, 8, 9 en 17, inclusief alle twaalf buitenste uurwaarden, bereikbare digitale bediening en vier volledig zichtbare antwoordstenen.

Visueel gecontroleerde beelden: [type 7 op iPad](Screenshots/QuestionPolish/type7-ipad.png), [type 8 op iPad](Screenshots/QuestionPolish/type8-ipad.png), [24-uursring](Screenshots/QuestionPolish/type9-ipad.png), [compacte reeks](Screenshots/QuestionPolish/type17-ipad.png), [vier antwoordstenen op iPad](Screenshots/QuestionPolish/type17-answers-ipad.png), [vier antwoordstenen op iPhone](Screenshots/QuestionPolish/type17-answers-iphone.png), [optellen](Screenshots/QuestionPolish/type14-iphone.png) en [aftrekken](Screenshots/QuestionPolish/type15-iphone.png).

De bijgewerkte iPhone-hercontrole slaagt eveneens: `testAnalogSettingMinuteExampleUsesSharedControlsAndFixedTarget`, `testCompactClockExamplesKeepTheirActionsVisible` en `testTimeDescriptionsAndArithmeticExampleSizes`. De laatste controle bewaakt voor zowel optellen als aftrekken dat uitkomst en subtotalen bij openen én vernieuwen nog verborgen zijn en pas tijdens de uitleg verschijnen. De twee oude testproblemen zijn gecorrigeerd: de minuutvoorbeelden volgen de actuele reeks vanaf 03:00 en de digitale voorbeeldbediening wordt binnen de voorbeeldkaart opgezocht.

Extra beelden: [type 7 op iPhone](Screenshots/QuestionPolish/type7-iphone.png), [24-uursring op iPhone](Screenshots/QuestionPolish/type9-iphone.png), [opnieuw beginnen met optellen](Screenshots/QuestionPolish/type14-refreshed-iphone.png) en [opnieuw beginnen met aftrekken](Screenshots/QuestionPolish/type15-refreshed-iphone.png).

## Gecentreerde tijdreeks

De eenzijdige marge van de verticale reeks is verwijderd. De klokken en het vraagteken blijven exact gecentreerd vóór en na een fout en in het voorbeeld, ook na vernieuwen. De boogbreedte en tekstgrootte volgen de beschikbare rechtermarge. De gerichte schermtest `testVerticalSequenceClocksStayCenteredWithSideHints` slaagt op iPhone 18 Pro en iPad mini (A17 Pro), beide met iOS 27: centrering binnen één punt, hulplabels rechts binnen beeld en vier volledig zichtbare antwoordstenen. De simulatorbuild en whitespacecontrole slagen.

Beelden: [vraag op iPhone](Screenshots/QuestionPolish/sequence-centered-side-hints-iphone.png), [voorbeeld op iPhone](Screenshots/QuestionPolish/sequence-centered-example-iphone.png), [vraag op iPad](Screenshots/QuestionPolish/sequence-centered-side-hints-ipad.png) en [voorbeeld op iPad](Screenshots/QuestionPolish/sequence-centered-example-ipad.png).
