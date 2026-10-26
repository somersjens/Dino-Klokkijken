# Vraagteksten in Nederlands en Engels — 26 oktober 2026

Alle twintig oefenvormen en het oudere activiteitvraagtype zijn nagekeken. De oefennamen zijn waar nodig aangescherpt. De vraagkop in het spel, het voorbeeld en de voorgelezen vraag delen één vertaling.

- Klokkeuze: “Welke van de twee klokken geeft twaalf uur aan?” / “Which of the two clocks shows twelve o’clock?” Het aantal blijft twee of vier, afhankelijk van de vraag.
- Goed/fout: “De klok geeft drie uur aan. Klopt dat?” / “The clock shows three o’clock. Is that correct?”
- Rekenen: eerst de begintijd, daarna de vraag naar een latere of eerdere tijd. Bijvoorbeeld: “Het is drie uur. Hoe laat is het 1 uur later?” / “It is three o’clock. What time will it be 1 hour later?”
- Tijdzones: “De klok in Parijs loopt 1 uur voor”, met een aparte slotvraag. Het uurverschil staat in de gewone tekstkleur.
- Alleen richtingswoorden krijgen groen of rood: vooruit/forward, later, eerder/earlier, voor/ahead en achter/behind. Tijdstippen en tijdsduren behouden de gewone titelkleur, ook in het richtingslabel onder de rekenklok.
- Titels herhalen geen dagdeel. De referentieklokken geven de benodigde context via 24-uurscijfers of AM/PM. Dagdeelvragen en tijdomschrijvingen waarbij het dagdeel bij het antwoord hoort, behouden die informatie.

De kerncontrole leest de echte `Localizable.xcstrings` en controleert alle vraagtypen in beide talen op alle 24 uren, inclusief verschillende minuutstanden, het aantal invulvelden en de kleurmarkering. De digitale controles dekken AM/PM, 00:00 en 12:00. `Tools/test-dino.sh`: **1.043.487 controles geslaagd**.

Gerichte schermcontroles geslaagd op iOS 27:

- iPhone 18 Pro: `testQuestionTitlesIncludeTimeInWords` en `testRefinedArithmeticTitlesInDutchAndEnglish`, inclusief de voorbeelden en 12-uursantwoordklokken.
- iPhone 18 Pro: `testAdvanceAnalogPlacesTheStartClockAboveTheClockYouTurn`.
- iPad (A16): `testTimeDescriptionsAndArithmeticExampleSizes`, met de definitieve woordkleur in beide rekenlabels en behoud van de dagdelen bij 24-uursomschrijvingen.

Visueel gecontroleerd: [klokkeuze](Screenshots/QuestionWordingRefinement/clock-choice-nl-iphone.png), [later met een donkerblauwe tijdsduur](Screenshots/QuestionWordingRefinement/addition-label-nl-ipad.png) en [eerder met een donkerblauwe tijdsduur](Screenshots/QuestionWordingRefinement/subtraction-label-nl-ipad.png).
