# Dino en klokken personaliseren — 14 oktober 2026

De welkomstflow heeft eerst Dino, daarna de analoge en digitale klok. De titel staat direct bovenaan, zonder taalmenu, voortgangsbalk of terugknop. Horizontaal vegen over Dino of de klok gaat terug of verder; de gekozen kleuren blijven behouden. De standaardtaal volgt het apparaat, ook bij opnieuw activeren van de app. Een expliciete taalkeuze in Instellingen blijft bewaard. Nederlands en Engels worden ondersteund; Nederlandse/Engelse regiovarianten worden herkend.

De vaste onderknop staat los op het landschap, zonder materiaal- of achtergrondvlak. De opties scrollen binnen een eigen gebied boven die knop. In het spel staat een groene **Klaar**-knop onderaan alle drie de personalisatiepagina's, en ook onderaan de klokeditor in Instellingen. Het karakter linksboven opent altijd eerst **Dino**, met **Analoog** en **Digitaal** als aparte pagina's rechts. De pagina's zijn bereikbaar via de knoppen of door te vegen. Wijzigingen worden direct opgeslagen en door de spelklokken gebruikt; de huidige vraag en invoer blijven behouden.

Alle optieteksten zijn gecentreerd en gebruiken de 17-puntsstijl van de dino-editor. Dunne scheidingslijnen staan tussen de klokopties; de vormkeuzes hebben geen aparte kop. Analoog biedt de kleuren van beide wijzers, de wijzerplaat en rand, daarna de vorm, wijzerstijl en normale/Romeinse cijfers. Alle analoge kleurenrijen hebben vijf presets en een vrije kleurkiezer. Zwart staat vóór wit bij de wijzerplaat; wit en normale cijfers blijven standaard. De wijzer- en cijferschakelaars staan naast hun labels. De digitale klok heeft aparte cijfer-/achtergrondkleuren, drie vormen en vier dikkere cijferstijlen.

Onderaan de opties staat **Oorspronkelijke kleuren** / **Restore original colors**, zoals in de dino-editor. Deze actie herstelt alleen kleuren, met behoud van vorm, wijzerstijl en cijfers. De resetpijlen bovenaan zijn verwijderd.

Identieke digitale cijfer-/achtergrondkleuren of een wijzer die gelijk is aan de wijzerplaatkleur tonen direct onder het voorbeeld **O nee, nu kun je de tijd niet zien!**, in donkerrood (`#8F2435`). Afronden blijft mogelijk en herstelt alleen de onleesbare klok naar de volledige standaardinstellingen. Het spel behoudt leesbare kleuren tijdens het bewerken. Alle klokeditorvoorbeelden tonen de actuele lokale tijd en lopen automatisch mee; opgaveklokken blijven de tijd van de vraag tonen.

De hulpnummers **1** en **2** op de voorbeeldkaart blijven zwart op wit. Pijl en bolletje sluiten zonder onderbreking aan, met dezelfde rand; de pijl volgt de wijzerkleur. Dit werkt voor witte wijzers op een zwarte wijzerplaat en voor de oorspronkelijke kleuren, zowel boven de analoge als digitale klok.

## Verificatie

- Xcode Debug-build van het gedeelde project: geslaagd.
- `Tools/test-dino.sh`: **444.891 controles geslaagd**, inclusief klokmathematica, wisselende minuten, profielen, kleurenherstel, standaardklokken bij gelijke kleuren en behoud van de huidige vraag/invoer. [Log](ClockCustomizationTestLogs/personalization-layout-core.log).
- iPhone 17 (iOS 26.5) en iPad (A16, iOS 27): `testPersonalizerGreenFootersAndCenteredOptions` geslaagd. Alle drie de groene onderknoppen, gecentreerde opties, waarschuwing en behoud van vraag 1/5. [iPhone](ClockCustomizationTestLogs/personalization-footer-iphone.log), [iPad](ClockCustomizationTestLogs/personalization-footer-ipad.log).
- Op beide apparaten: `testExampleHintsStayBlackAndConnectedWithWhiteHands` geslaagd; de schermafbeeldingen van witte wijzers en de oorspronkelijke kleuren zijn visueel gecontroleerd. [iPhone](ClockCustomizationTestLogs/connected-hints-iphone.log), [iPad](ClockCustomizationTestLogs/connected-hints-ipad.log).
- `testWelcomeTopTitlesDeviceLanguageAndPreviewSwipes` is op beide apparaten geslaagd: Engelse/Nederlandse apparaatstaal zonder handmatige keuze, alle drie de hogere titels, gecentreerde labels, heen-/terugvegen met behoud van kleuren en de actieve afrondknop. [iPhone](ClockCustomizationTestLogs/welcome-navigation-iphone.log), [iPad](ClockCustomizationTestLogs/welcome-navigation-ipad.log).
- Ook de afgeronde landschapsovergang is gecontroleerd: iPad geslaagd en iPhone geslaagd op een aparte simulator. De gedeelde iPhone-simulator werd tegelijk door andere tests bediend; de aparte simulator bevestigde dat er geen aanpassing aan de rotatie-instellingen nodig was. De tijdelijke configuratiewijziging is teruggedraaid. [iPhone](ClockCustomizationTestLogs/welcome-navigation-iphone.log), [iPad](ClockCustomizationTestLogs/welcome-landscape-ipad.log).

## Beelden

| Scherm | iPhone | iPad |
| --- | --- | --- |
| Hogere titel bij Dino | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-dino-iphone.png) | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-dino-ipad.png) |
| Gecentreerde analoge opties | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-analog-iphone.png) | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-analog-ipad.png) |
| Donkerrode waarschuwing | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-digital-red-warning-iphone.png) | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-digital-red-warning-ipad.png) |
| Groene onderknop in het spel | [Bekijk](Screenshots/ClockCustomization/personalize-green-footer-in-level-iphone.png) | [Bekijk](Screenshots/ClockCustomization/personalize-green-footer-in-level-ipad.png) |
| Welkomstscherm in landschap | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-landscape-iphone.png) | [Bekijk](Screenshots/ClockCustomization/welcome-top-title-landscape-ipad.png) |
| Witte wijzers, zwarte hulpnummers | [Bekijk](Screenshots/Examples/example-connected-white-hand-hints-iphone.png) | [Bekijk](Screenshots/Examples/example-connected-white-hand-hints-ipad.png) |
