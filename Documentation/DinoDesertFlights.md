# Dino-Desert — overgang, opgraving en vliegende dino’s

19 oktober 2026. Verfijning van wereld 2 na de tweede redesignronde.

- De blauwe luchtstrook bovenaan de woestijn is verwijderd. Achter het titelbord loopt nu dezelfde warme zandondergrond door. Ook het koele overgangspalet aan het einde van de jungle is vervangen door zand- en zandsteenkleuren.
- Alle paaltjes en omheiningstouwen rond het skelet zijn verwijderd. De fossielkuil, botten en het opgravingsgereedschap blijven zichtbaar.
- Vijf kleine vliegende dino’s steken de kaart in beide richtingen over. De animatie bouwt voort op de kleine dino’s in wereld 5. De vliegers hebben een eigen bruin palet voor hun lijfjes, kammen en vleugelmembranen, met brede afgeronde kaken, neusgaten en kleine tanden.
- De vleugels bewegen, de vlucht heeft een lichte opwaartse boog en iedere dino keert pas buiten beeld om. De vliegroutes liggen tussen de levelstenen. De dieren tekenen boven het pad en onder de bedienbare levelknoppen.
- Kleine Canvas-vlakken verversen maximaal twintig keer per seconde. Alleen zichtbare dieren worden getekend. De animatie pauzeert buiten de viewport en wanneer de app niet actief is. **Minder beweging** toont een vaste pose.

De vluchtlaag behoudt ook vóór het verschijnen van de eerste dino de volledige kaartmaat. Daardoor kan de viewportmeting de animatie betrouwbaar starten. De titel is drie punten naar boven optisch gecentreerd; een extra afstandscontrole vond eerder een verschil van 6,4 punten tussen de vrije ruimte boven en onder de tekst.

## Bruine dinokoppen

Na de eerste vliegronde zijn de puntige snavels vervangen door brede reptielenkaken en een duidelijke kam achter de kop. Alle vijf vliegers gebruiken hetzelfde bruine palet. [Nieuwe koppen en vleugelstanden](Screenshots/DinoDesertBrownFlights/flight-designs.png) · [Op kaartformaat](Screenshots/DinoDesertBrownFlights/entrance-393.png). De nieuwe koppen zijn in beide richtingen en meerdere vleugelstanden visueel gecontroleerd, ook op de native kaarten van 320, 393, 834 en 1194 punten breed. De [iOS-simulatorbuild](WorldTestLogs/DinoDesertBrownFlights/simulator-build.log) slaagt.

## Beelden en controles

Native kaarten op [320](Screenshots/DinoDesertFlights/native-320.png), [393](Screenshots/DinoDesertFlights/native-393.png), [834](Screenshots/DinoDesertFlights/native-834.png) en [1194](Screenshots/DinoDesertFlights/native-1194.png) punten. Deze auditbeelden gebruiken genummerde stenen op de echte levelposities. [Vliegende dino’s en vleugelstanden](Screenshots/DinoDesertFlights/flight-designs.png) · [Opgraving zonder omheining](Screenshots/DinoDesertFlights/landmarks.png).

De vluchtberekening is op vier breedtes over vier minuten bemonsterd: **48.000 meetstappen**, met **261 richtingswisselingen buiten beeld**. Tijdens zichtbare verplaatsingen komt de kijkrichting steeds overeen met de bewegingsrichting. Twee renders op verschillende tijden met de stilstandoptie zijn pixelgelijk; die optie gebruikt dezelfde tijd-nulroute als Minder beweging. De actieve renders verschillen aantoonbaar. [Meetgegevens](WorldTestLogs/DinoDesertFlights/visual-checks.json).

`testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn gericht op wereld 2 én 5 uitgevoerd op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. Daarmee zijn de levelknoppen, een eerste vraag, de HUD en het openen van beide eindbazen gecontroleerd. [iPhone-testlog](WorldTestLogs/DinoDesertFlights/iphone-tests.log) · [iPad-testlog](WorldTestLogs/DinoDesertFlights/ipad-tests.log).

Echte appbeelden: de entree op [iPhone](Screenshots/DinoDesertFlights/entrance-iphone.png) en [iPad](Screenshots/DinoDesertFlights/entrance-ipad.png), en de baasomgeving op [iPhone](Screenshots/DinoDesertFlights/boss-iphone.png) en [iPad](Screenshots/DinoDesertFlights/boss-ipad.png). Drie opeenvolgende opnamen met 2,5 seconden tussenruimte bevestigen ook de live verplaatsing: [eerste](Screenshots/DinoDesertFlights/live-flight-iphone-0.png), [tweede](Screenshots/DinoDesertFlights/live-flight-iphone-1.png), [derde](Screenshots/DinoDesertFlights/live-flight-iphone-2.png).

`testWorldBannersHaveBalancedClearance` slaagt na de definitieve kleur- en centreringaanpassing op beide apparaten: **twee extra schermtests, nul fouten**. [iPhone-overgang](WorldTestLogs/DinoDesertFlights/transition-iphone-tests.log) · [iPad-overgang](WorldTestLogs/DinoDesertFlights/transition-ipad-tests.log). De laatste simulatorbuild en `git diff --check` slagen.

De screenshotmap blijft lokaal en is, zoals andere testbeelden, uitgesloten van Git-synchronisatie.
