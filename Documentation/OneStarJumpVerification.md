# Startschermsprong bij één ster

Bij één ster gebruikt het resultaat dezelfde acht beelden en dezelfde afzet-, vlucht- en landingsmomenten als de sprong aan het einde van het startscherm. De gedeelde Dino vertrekt vanuit zijn portret linksboven. De ronde uitsnede opent tijdens het vertrek naar het volledige lichaam, met behoud van de gekozen kleuren.

De resultaatsovergang krijgt 0,24 seconde; daarna volgen 0,14 seconde voorbereiding en 0,62 seconde vlucht. Dino bereikt de bestaande steen op 1,00 seconde. Een kleinere sprongboog past bij het vertrek bovenaan het scherm. De vlucht behoudt zijn tempo tot het voetcontact, waarna de oorspronkelijke landingsbeelden kort inveren en naar rust herstellen. De ster verschijnt na de landing. Bij Minder beweging staat Dino direct stil op de steen.

## Controles

- De Debug-build voor iOS Simulator slaagt.
- De eerste `Tools/test-dino.sh`-run slaagt met 862.784 controles. De nieuwe controles bewaken de juiste animatie bij één ster, alle acht poses op 30 en 60 Hz, exact voetcontact bij aankomst, vooraf klaargezette kleuren en stilstand bij Minder beweging.
- Na gelijktijdige wijzigingen aan de gedeelde animatiecode slaagt de laatste Debug-build opnieuw, evenals de eenstertest op iPhone. Alle 9.600 gerichte animatiecontroles slagen. De laatste volledige kernsuite faalt bij de kleurcontrole voor `dino-stumble-01`: de stekelhooglichten wijken af van de rustpose. Die aparte struikelanimatie is niet aangepast voor deze sprongwijziging; de fout staat in `OneStarJumpTestLogs/core-final.log`.
- `testOneStarOpeningJumpFromPortraitToStone` slaagt op iPhone 18 Pro en iPad (A16), beide met iOS 27. De test speelt een volledig level met 3/5, gekozen kleuren, één Dino, de landing op de steen, één ster, stilstand na afloop en opnieuw spelen.
- Op iPad slagen ook `testTwoStarPirouetteFromQuestionToStone` en `testPlayCardAndContinuousResultDino`, voor twee en drie sterren.
- De iPhone-opname is per 0,1 seconde bekeken: het portret blijft zichtbaar tijdens de schermovergang, opent naar het volledige lichaam en de acht poses volgen de verplaatsing naar de steen. De voeten landen vóór de ster verschijnt; daarna blijft Dino stil staan.

[Korte simulatoropname](Animations/one-star-opening-jump-iphone.mp4) · [Tussenbeelden](Screenshots/OneStarJump/iphone-sequence.jpg) · [Landing iPhone](Screenshots/OneStarJump/iphone-landing.png) · [Landing iPad](Screenshots/OneStarJump/ipad-landing.png).
