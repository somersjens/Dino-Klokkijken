# Resultaatanimaties in iPad-landscape

De landscape-overgang plaatste Dino vóór het afspelen op volledige grootte boven het scherm. Daardoor waren de voorbereiding en het begin van de val bij nul sterren niet zichtbaar. De val gebruikte daarnaast aparte klokken voor de poses en de verplaatsing; een nieuwe meting van de resultaatsteen kon de verplaatsing overslaan.

Alle vier resultaten vertrekken nu vanuit het gemeten, zichtbare HUD-portret. De val, sprong, pirouette en salto delen één animatieklok op 60 Hz voor poses, verplaatsing en portretuitsnede. Het handcontactgeluid van de val gebruikt dezelfde landingstijd. Een nieuwe meting verandert alleen de bestemming; het vertrekpunt blijft gedurende de hele animatie behouden. Na de landing blijft Dino op de steen tijdens het liggen, opstaan of uitveren.

De tussenbeelden toonden ook een kort afgesneden kop op het hoogste punt van de pirouette. In landscape wordt de hoogte van de sprongboog daarom vooraf passend gemaakt voor de volledige tekenruimte, inclusief de uitlijning van de poses en 16 punten bovenmarge. De animatie gebruikt daarna één vaste hoogtefactor, zodat de boog vloeiend blijft. De afzet-, draai-, landings- en herstelmomenten blijven gelijk. Portret gebruikt de bestaande spronghoogte. Minder beweging toont direct de eindpose op de bestemming.

## Controles

- Kerncontroles bemonsteren alle vier trajecten op 30 en 60 Hz, met kleine en grote iPad-vensters en een kort landscape-venster. Ze bewaken zichtbaar vertrek, doorlopende verplaatsing, exact voetcontact, stilstand tijdens herstel en wijzigingen aan de bestemming. Op 600 stappen per vlucht controleren ze ook de bovenmarge van de volledige opgetilde tekenruimte.
- `testResultAnimationsFromLandscapeLeftPortrait` en `testResultAnimationsFromLandscapeRightPortrait` spelen volledige levels met nul, één, twee en drie sterren. Ze controleren één Dino, de positie in het portret, volledige plaatsing op de resultaatsteen, sterren, bereikbare acties en stilstand na het herstel.
- `testLandscapeResultHasLargeStageAndReachableActions` controleert alle vier scores en terugdraaien naar portret op iPad Pro 13-inch (M5), iPadOS 27.
- `testOpeningArrivesInLandscapeAndDoesNotReplayAfterClosingLevel` controleert de openingssprong en de aankomst op het opgeslagen level in landscape.
- `testWorldJumpLandsInBothLandscapeOrientations` controleert de sprong naar de volgende wereld, het verdwijnen van de vluchtlaag en de exacte voetpositie op de nieuwe steen in beide landscape-richtingen.

De volledige kernsuite slaagt met **1.712.771 controles**. De drie aanvullende iPad-schermtests voor de resultaatindeling, opening en wereldsprong slagen. De resultaatanimaties zijn vanuit volledige levels in beide landscape-richtingen getest op iPad Pro 13-inch (M5), iPadOS 27; de voorafgaande versie is ook opgenomen op iPad Air 11-inch (M4).

Simulatoropnamen worden lokaal bewaard in `Screenshots/LandscapeResultAnimations/`. De val, sprong, pirouette en salto zijn per 0,1 seconde bekeken op voorbereiding, zichtbaarheid, contact en herstel. De definitieve pirouette en salto blijven met het volledige lichaam onder de bovenrand. [Pirouettebeelden](Screenshots/LandscapeResultAnimations/pirouette-final.jpg) en [saltobeelden](Screenshots/LandscapeResultAnimations/backflip-final.jpg) bewaren de visuele controle. Testlogs staan in `LandscapeAnimationTestLogs/`.

De macOS-kernrunner sluit UIKit-audio uit. Voor deze controle is alleen de aanroep om geluid in of uit te schakelen vervangen door een tijdelijke lege hostimplementatie in `/tmp/DinoCoreAudioStub.swift`; de appbuild en simulatortests gebruiken de echte audiolaag.
