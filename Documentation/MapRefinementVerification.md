# Levelpad, antwoordvergelijking en speeltijd — 12 oktober 2026

De simulatorbuild slaagt. `Tools/test-dino.sh` slaagt met 112.640 controles voor spelregels, opslag, scoring, synchronisatie en naamvalidatie. De timingtests controleren onder meer 1–60 seconden per vraag, lange inactiviteit, dubbele taps, feedbacktijd, bewaren na herstart, de koppeling van tijd aan de juiste score en snellere herhalingen via Game Center.

Zes relevante schermtests slagen op een tijdelijke iPhone 17-simulator met iOS 26.5:

- `testStartPointCleanCardAndExitCancel`: centraal startpunt, kleinere dino, startkaart onder de HUD, spelen en verlaten.
- `testDinoStandsOnCompletedLevel`: na vijf goede antwoorden staan de voeten op het midden van de behaalde levelcirkel.
- `testManualExamplesAndClockComparison`: voorbeelden uitsluitend via het vraagteken, zonder dino; analoge en digitale fouten tonen beide antwoorden.
- `testFourChoicesAndPersistentWrongAnswer`: rood/groen bij meerkeuze, geen feedbackbalk, Verder blijft beschikbaar.
- `testLevelFriendsRowsWithTimings`: naam, sterren en gemeten tijd in dezelfde rij, hele rij opent het profiel en kan terugkeren naar Spelen.
- `testFriendMapAndProfilesWithTestFixtures`: kaartavatars, onbekende resultaten, vriendenprofielen en levelresultaten.

De screenshots zijn visueel gecontroleerd en staan in [Screenshots/MapRefinement](Screenshots/MapRefinement). De vriendenbeelden gebruiken uitsluitend de bestaande Debug-testfixtures, geen echte accounts.

Voor online speeltijden moeten de tien aanvullende klassieke timingboards uit [GameCenterLeaderboards.json](GameCenterLeaderboards.json) in App Store Connect worden ingericht. De bestaande twaalf resultaatboards blijven werken zonder deze toevoeging. Oude beste resultaten zonder bijpassende meting tonen een onbekende tijd. Echte Game Center-uitwisseling is hier niet uitgevoerd.
