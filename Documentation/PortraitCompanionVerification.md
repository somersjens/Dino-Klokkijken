# Dino in het portret en vaste onderknop

Tijdens levels en oefenen staat Dino alleen in de cirkel linksboven. Het portret is het vertrekpunt van dezelfde gedeelde dino die op de resultaatsteen landt. Het persoonlijke kleurenpalet blijft in alle poses zichtbaar.

## Gedrag

- Goede antwoorden spelen de acht nieuwe `dino_applaus_frame_01` t/m `08` af: twee klapbewegingen en herstel naar rust. Foute antwoorden geven één zacht hoofdschudden. Beide behouden dezelfde portretcamera als in rust. Na 0,78 respectievelijk 0,80 seconde staat Dino weer in zijn oorspronkelijke rusthouding. De cirkelrand wordt volledig getekend; alleen echte pixels van de bandana en stekels komen ervoor. Elk nieuw goed antwoord en elke herhaalde fout starten hun reactie opnieuw.
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

## Nieuwe antwoordreeksen · 24 oktober 2026

De nieuwe ChatGPT-beelden zijn gecontroleerd in de iPhone 17-simulator met iOS 26.5. De native build slaagt, evenals de kernsuite met **822.710 controles** en de drie gerichte schermtests hierboven (`testCompanionPortraitWithCustomColorsAndStickyFooter`, `testFourChoicesAndPersistentWrongAnswer` en `testPlayCardAndContinuousResultDino`). De eerste twee tests slaagden samen; de testomgeving viel bij de derde start weg. Die resultaatcontrole slaagt bij een aparte herhaling.

De opname is per 0,1 seconde bekeken. Begin en einde gebruiken dezelfde rustpose, plaats en vergroting. De cirkelrand blijft achter bewegende bandana en stekels volledig zichtbaar; de feedback blijft staan na het herstel. De kleurcontroles omvatten alle zestien nieuwe beelden, behoud van ogen en mond, gelijkmatige helderheid en leesbare opdruk op lichte bandana's.

[Fout antwoord in beweging](Animations/answer-reaction-wrong-iphone.mp4) · [Goed antwoord in beweging](Animations/answer-reaction-correct-iphone.mp4) · [Tussenbeelden fout](Screenshots/AnswerReactions/wrong-portrait-sequence.jpg) · [Tussenbeelden goed](Screenshots/AnswerReactions/correct-portrait-sequence.jpg).

## Verfijning naar één gebaar

De antwoordreacties gebruiken nu één gekozen expressie met doorlopende beweging: een blije opvering bij goed en één zacht hoofdschudden bij fout. Alleen de ingang en uitgang wisselen van afbeelding. De kop is uitgelijnd ten opzichte van rust; de cirkel en camera blijven vast. Voorbereiding, beweging en herstel lopen continu, met een volledig stilstaande rustpose aan beide uiteinden. Minder beweging houdt de gekozen expressie stil.

De Debug-build slaagt en de kernsuite slaagt met **824.165 controles**, waaronder begrensde beweging en continuïteit op 600 tijdstappen per seconde. `testFourChoicesAndPersistentWrongAnswer` slaagt op iPhone 17 met iOS 26.5 en doorloopt zowel een goed als fout antwoord. De simulatoropname is per 0,05 seconde bekeken: het gezicht blijft tijdens elk gebaar gelijk, de cirkel blijft heel en Dino keert terug naar zijn vaste rustplek.

[Huidige foutreactie](Animations/answer-gesture-wrong-iphone.mp4) · [Huidige goedreactie](Animations/answer-gesture-correct-iphone.mp4).
