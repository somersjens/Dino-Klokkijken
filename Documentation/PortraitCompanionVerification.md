# Dino in het portret en vaste onderknop

Tijdens levels en oefenen staat Dino alleen in de cirkel linksboven. Het portret is het vertrekpunt van dezelfde gedeelde dino die op de resultaatsteen landt. Het persoonlijke kleurenpalet blijft in alle poses zichtbaar.

## Gedrag

- Goede antwoorden tonen de duimen; foute antwoorden tonen de blijvende verwarde pose. De reacties hebben een ruimere uitsnede zodat gezicht en handen in de cirkel passen.
- De backflip en pirouette wachten totdat de resultaatsteen zijn positie heeft doorgegeven. De sprite en de verplaatsing beginnen samen. De ronde uitsnede opent tijdens de afzet in 0,24 seconde naar het hele lichaam. De bestaande landingsposes en offsets blijven behouden.
- De backflip krijgt 0,18 seconde voorbereiding in het portret. De pirouette behoudt zijn bestaande voorbereiding, tempo en afwisseling van poses. De sterren verschijnen na de landing. Minder beweging toont direct de eindpose op de steen.
- Onder de vragen is een vaste strook van 80 punten gereserveerd. **Toon antwoord** en **Verder** staan daarin gecentreerd, maximaal 420 punten breed, boven de onderste veilige schermrand. Scrollen en feedback verplaatsen de knop niet.
- De gedeelde dino heeft één toegankelijkheidselement met de afmetingen van het portret; de oorspronkelijke sprite meldt zich niet dubbel aan.

## Controlebeelden

[Spelen op iPhone](Screenshots/PortraitCompanion/iphone-companion-pink-idle-portrait.png) · [Fout antwoord met vaste knop](Screenshots/PortraitCompanion/iphone-companion-pink-wrong-portrait.png) · [Fout antwoord op iPad](Screenshots/PortraitCompanion/ipad-companion-pink-wrong-portrait.png).

## Verificatie

De Debug-build voor iOS Simulator slaagt. De kernsuite slaagt met **805.472 controles**. De schermtests controleren gekozen kleuren, één dino in het portret, vaste positie tijdens scrollen, de brede onderknop, vier antwoordopties en volledige levels met beide spronganimaties. Op iPhone 17 met iOS 26.5 slagen alle vier gerichte tests:

- `testCompanionPortraitWithCustomColorsAndStickyFooter`
- `testFourChoicesAndPersistentWrongAnswer`
- `testPlayCardAndContinuousResultDino`
- `testTwoStarPirouetteFromQuestionToStone`

Op iPad Pro 11-inch (M5) met iOS 26.5 slagen beide volledige level- en sprongtests. De portretcontroles voor gekozen kleuren, één dino, complexe vragen, scrollen en de vaste onderknop slagen voordat de rotatiecontrole begint. Twee tests eindigen vervolgens met een time-out bij het wachten op landschapstand: `testCompanionPortraitWithCustomColorsAndStickyFooter` en `testCenteredPracticeClocksAndCompanionInPortrait`. De opnamen tonen dat de simulator in portret blijft. De iPad-controle in landschapstand is daarmee niet bevestigd.

De definitieve sprongen zijn beeld voor beeld bekeken: Dino blijft zichtbaar tijdens de schermovergang, komt uit het portret en landt stil op de bestaande steen. [Backflip](Animations/portrait-backflip-iphone.mp4) · [Pirouette](Animations/portrait-pirouette-iphone.mp4).
