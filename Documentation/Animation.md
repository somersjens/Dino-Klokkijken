# Dino-animaties

De aangeleverde afbeeldingen zijn losse poses. Ze verschillen ook in gezicht en houding; alle beelden snel na elkaar afspelen of in elkaar laten overvloeien maakt Dino onrustig en veroorzaakt dubbele contouren. Daarom gebruikt elke korte antwoordreactie één duidelijke pose, die met een kleine beweging wordt geanimeerd. Er staat steeds precies één Dino-afbeelding in beeld.

- **Goed antwoord:** `dino-thumbs-up-08`, een korte nadruk van maximaal 3,5% in grootte, met de voeten op dezelfde plek. De beweging duurt 0,52 seconde, daarna blijft de pose nog even staan. Volgende vraag na 0,72 seconde, zonder tekstbanner.
- **Fout antwoord:** `dino-wrong-answer-04`, één rustige kanteling van maximaal 2 graden gedurende 0,5 seconde. Daarna blijft de verbaasde pose staan naast het juiste antwoord in de vaste balk boven Verder, tot de speler doorklikt. De Dino-overlay bij de vraag wordt tijdelijk verborgen, zonder de klokruimte te wijzigen, zodat er ook op kleine schermen precies één reactie zichtbaar is. De zes nieuwe afbeeldingen zijn hernoemd naar `dino-wrong-answer-01` t/m `06`.
- **Salto naar het resultaat:** de Dino naast de laatste vraag blijft in één gedeelde laag bestaan terwijl het resultaat verschijnt. Zijn positie en grootte bewegen gedurende 1,22 seconde van de vraag naar de resultaatplek; dezelfde figuur maakt onderweg de salto en landt daar. Alleen poses `dino-backflip-01`, `03`, `07` en `08` worden gebruikt, voor afzet, draai, landing en eindpose. Dezelfde ingetrokken pose blijft zichtbaar gedurende de hele draai. De sprong en volledige rotatie lopen continu door, zonder overlappende sprites. Duur: 1,62 seconde; één keer bij maximale punten. Scrollen volgt daarna de resultaatplek direct.
- **Minder beweging:** alleen de duidelijke reactie/eindpose; geen draaiing, sprong, kanteling of vergroting.

De originele PNG's blijven ongewijzigd bewaard, inclusief de ongebruikte poses. Dino staat in een vaste overlay en verandert nooit de indeling of het midden van de klok.

De startkaart wordt binnen dezelfde scène getoond. **Spelen** maakt de sessie gereed en laat de kaart gedurende 0,24 seconde verdwijnen terwijl het level verschijnt. Er wordt geen systeem-sheet meer afgewacht. De kaart kan via Levelkaart, tikken buiten de kaart of omlaag slepen aan de greep worden gesloten. Met Minder beweging wordt de kaart alleen vervaagd en verplaatst Dino zich zonder sprong of draai.

Kerncontroles bewaken een volledige draai zonder hoeksprongen, een doorlopende sprongbaan, één vaste afbeelding per antwoordreactie en een stilstaande pose na afloop. De UI-controle bewaakt dat de foutreactie en het juiste antwoord blijven staan totdat Verder wordt gekozen.

De startovergang en één Dino op vraag en resultaat zijn gecontroleerd op iPhone SE en iPad A16. De native iPad-opname is per tiende seconde beoordeeld: de startkaart blijft niet hangen en Dino reist zonder verdwijning of dubbele figuur naar zijn landingsplek. Een korte preview staat in `Documentation/Animations/play-and-result-transition-ipad.mp4`.
