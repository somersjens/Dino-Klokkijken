# Tijd optellen en aftrekken via het hele uur — 31 oktober 2026

Vraagtypen 18 (trein), 19 (tijdzones) en 20 (vlucht) delen één rekenroute voor voorbeelden, antwoorduitleg en replay:

Uren worden afzonderlijk opgeteld of afgetrokken. Bij een verschuiving met minuten wordt eerst zo nodig de dichtstbijzijnde uurgrens in de juiste richting bereikt. Daarna volgen stappen van één uur en het exacte resterende aantal minuten. Bij uitsluitend hele uren blijven de beginminuten behouden.

| Beginsom | Kloktijden tijdens de uitleg | Afzonderlijke stappen |
| --- | --- | --- |
| 14:40 + 2 uur | 15:40 → 16:40 | +60 min, +60 min |
| 14:40 + 2 uur 15 min | 15:00 → 16:00 → 16:55 | +20 min, +60 min, +55 min |
| 14:40 − 2 uur 15 min | 14:00 → 13:00 → 12:25 | −40 min, −60 min, −35 min |
| 23:40 + 1 uur 55 min | 00:00 → 01:00 → 01:35 | +20 min, +60 min, +35 min |
| 00:10 − 45 min | 00:00 → 23:25 | −10 min, −35 min |

Als de verschuiving vóór of precies op de uurgrens eindigt, is er maar één minutenstap. Nul verschil levert geen stappen op. Er is geen overschrijding of richtingswissel; geen stap slaat meer dan één uur over.

Het tempo is gedeeld door de drie vraagtypen en alle niveaus: 1,2 seconde leesrust vóór het rekenen en 0,55 seconde per cijferovergang. Tussen de start van opeenvolgende stappen zit 1,4 seconde, zodat de tijd ongeveer 0,85 seconde stilstaat voor de volgende stap. De klok en de cumulatieve plus- of minwaarde veranderen samen. Herhaald replay annuleert de eerdere reeks; Minder beweging toont meteen de uitkomst.

Bij treinvragen wordt de minuutkolom gebruikt zodra een reisregel minuten bevat. Duren met uitsluitend hele uren hoeven ook tijdens replay geen minutenruimte te reserveren.

Na de laatste cijferovergang wacht de rekenanimatie tot de cijfers zijn uitgeschoven (0,55 seconde). Daarna draait de replaypijl één keer 360 graden linksom in 0,65 seconde. Deze aanwijzing is gedeeld door vraagtypen 18, 19 en 20. Onderbroken reeksen geven geen voltooiingsseintje. Bij Minder beweging vervalt de draaiing.

Bij type 19 vervangt de replayknop de markering van de gekozen hoofdstad op de kaart. Het stadskaartje behoudt de volledige breedte voor de naam. Het tijdsverschil krijgt 6 punten horizontale en 3 punten verticale ruimte binnen de lichte capsule.

## Verificatie

- `--train-durations`: **8.449** geslaagde controles.
- `--time-zones`: **45.055** geslaagde controles.
- `--flight-arrivals`: **50.138** geslaagde controles.
- `--difficulty`: **92.376** geslaagde controles, inclusief voorbeelden met halve uurverschillen.
- Gedekt: iedere mogelijke beginminuut, beide richtingen, exacte uurgrenzen, korte verschuivingen, nul verschil, middernacht en verschuivingen van een hele dag.
- `testTrainDurationCarryInBothLanguages`, `testTimeZoneCardReplayInBothLanguages` en `testFlightTotalHintAndReplayInBothLanguages`: alle drie geslaagd op een geïsoleerde iPhone 17e met iOS 27, in Nederlands en Engels. Deze controles omvatten voorbeelden, antwoordonthulling, herhaald replay, nulwaarden, eindtijd en de uitlijning van de treinberekening.
- Testrapport: `/tmp/dino-hour-bridge-iphone-tests-b1d2.xcresult`.
- De simulatorbuild gebruikt uitsluitend voor deze test `ASSETCATALOG_COMPILER_APPICON_NAME=`. De gewone build wordt geblokkeerd door de al aanwezige appiconen van 1254×1254 pixels, waarvoor Xcode 1024×1024 verwacht. De iconen en de projectinstelling zijn niet gewijzigd.
- `git diff --check`: geslaagd.

## Hele uren en replayseintje — 1 november 2026

- Hele uren worden in één stap toegepast, vanaf iedere beginminuut en in beide richtingen. Alleen verschuivingen met minuten gebruiken de route via een heel uur.
- `--train-durations`: **8.447** geslaagde controles; `--time-zones`: **45.299**; `--flight-arrivals`: **50.382**.
- `testTrainDurationCarryInBothLanguages`, `testTimeZoneCardReplayInBothLanguages` en `testFlightTotalHintAndReplayInBothLanguages`: geslaagd op iPhone 17e met iOS 27. De kaartreplaytest slaagt ook op iPad Air 13-inch (M4), inclusief landschap. Beide talen zijn getest.
- De kaarttest vergelijkt de knoppositie met de geografische positie van de geselecteerde hoofdstad en controleert dat de stadsnaam gecentreerd blijft. De ruimere capsule en nieuwe positie zijn visueel gecontroleerd op beide apparaten.
- De volledige draaibeweging na de laatste cijferovergang is per tussenbeeld in de simulatoropname gecontroleerd. De pijl draait linksom en eindigt weer rechtop; de witte cirkel en aanraakzone blijven stil.
- Definitieve rapporten: `/tmp/dino-replay-cue-final-iphone-c9e4.xcresult` en `/tmp/dino-replay-cue-final-ipad-c9e4.xcresult`. Deze simulatorbuild slaagt met de gewone appicooninstelling.
- Schermbeelden en de korte opname staan in `Documentation/Screenshots/ReplayCue/`; de preview heet `time-zone-replay-cue.mp4`.
- `git diff --check`: geslaagd.

## Rustiger uurstappen en passend vliegticket — 1 november 2026

- Alle niveaus van 18/19/20 delen nu het tempo uit `DinoTimeWalkTiming`: 1,2 seconde vooraf, 0,55 seconde cijferovergang en 1,4 seconde tussen het begin van stappen. Uren gaan één voor één; minuten gebruiken eerst zo nodig de uurgrens.
- `--train-durations`: **8.447** controles; `--time-zones`: **45.303**; `--flight-arrivals`: **50.386**; `--difficulty`: **92.376**. Alle controles geslaagd, inclusief uurstappen in beide richtingen, minutenbruggen en middernacht.
- De replaycontroles voor trein en tijdzones slagen op iPhone in beide talen. De vluchtcontrole slaagt op iPhone en iPad in beide talen, met alle vier de antwoordknoppen volledig binnen het vraagvenster na uitleg en na replay.
- `testFlightHalfHoursWorkedAnswerKeepsAllChoicesVisible` slaagt op iPhone: de derde halfuurvraag, twee foute antwoorden, volledige uitleg en vier zichtbare antwoorden boven Next. Het beeld is visueel gecontroleerd; de totaalwaarde is grijs.
- Definitieve vluchtrapporten: `/tmp/dino-calm-flight-iphone-final-d4f1.xcresult` en `/tmp/dino-calm-flight-ipad-d4f1.xcresult`.
- Beelden: `Documentation/Screenshots/CalmFlight/iphone-flight-half-hours-compact-worked-en.png` en de Nederlandse/Engelse replaybeelden voor iPhone en iPad in dezelfde map.
- `git diff --check`: geslaagd.
