# Treinvraag 18 — uitlijning en tijdsduur

Vertrek, beide treinen, overstap en aankomst gebruiken dezelfde pictogramkolom, ook wanneer de uitleg opent. Na het eerste foute antwoord schuift de bestaande duurtekst naar links en verschijnt rechts de duur in HH:MM. Dezelfde kolom toont het omgerekende totaal.

Alleen de uitgewerkte som gebruikt vaste kolommen voor het plusteken, de uren en de minuten. Reisregels en totaal reserveren ook het lege tekenvak; de groene optelling bij aankomst gebruikt dat vak voor de plus. Bevat een reisregel minuten, dan toont iedere regel in die minuutkolom twee cijfers: bijvoorbeeld `1h 00 min`, `05 min` en `+2h 00 min`. Driecijferige opgetelde minuten blijven volledig zichtbaar. Bij uitsluitend hele uren vervalt de minuutkolom.

Vóór de uitleg passen de gekleurde duurvakjes precies om hun oorspronkelijke tekst. Een vakje met alleen minuten reserveert geen plek voor uren; een vakje met alleen uren reserveert geen plek voor minuten. Pas bij de uitleg openen de uitgelijnde kolommen en verschijnen de even brede HH:MM-vakjes.

De overgang duurt 0,65 seconde. Dezelfde gekleurde capsules veranderen vloeiend van breedte; hun oorspronkelijke tekst vervaagt vóór de HH:MM-notatie verschijnt. Tegelijk klappen de tussenpijlen in en openen de beschrijvende kolommen en de totaalrij binnen hun eigen ruimte. De reisregels behouden hun identiteit en de antwoordknoppen blijven op hun plek.

Het aankomstpictogram is vergroot. Zodra replay beschikbaar is, vervangt de kleinere replaypijl het pictogram op dezelfde plek links van het aankomstlabel. Na de laatste cijferovergang draait de pijl één keer 360 graden in 0,65 seconde. Bij Minder beweging blijft de pijl stil.

Het totaal gebruikt korte eenheden en telt de uren en minuten op zoals ze op de drie reisregels staan, vóór het omwisselen van zestig minuten voor een uur:

| Reisregels | Korte totaaltekst | HH:MM |
| --- | --- | --- |
| 40 min + 30 min + 50 min | 120 min | 02:00 |
| 40 min + 30 min + 1 uur 10 min | 1 uur 80 min / 1h 80 min | 02:20 |

De drie duurteksten gebruiken een vaste lettergrootte, ook bij een korte eerste rit naast een langere tweede rit. De duurkolom blijft onafhankelijk van de persoonlijke 12-/24-uursklok. Het rekenblok reserveert vooraf de hoogte van de optelling, zodat de antwoordknoppen bij het openen van de uitleg blijven staan.

De uitgewerkte uitleg en het voorbeeld laten de aankomsttijd oplopen vanaf de vertrektijd. Een groene pluswaarde links van de klok loopt tegelijk mee. De replay-knop begint opnieuw bij nul, met alle gebruikte eenheden meteen zichtbaar: bijvoorbeeld `+0 uur 00 min` of `+0h 00 min`. De trein gebruikt dezelfde tweestapsroute als tijdzones (19) en vluchten (20): eerst minuten toevoegen tot het volgende hele uur, daarna de resterende reistijd in één stap. Bijvoorbeeld `14:40 + 2:15 → 15:00 (+20 min) → 16:55 (+1:55)`. Een reistijd met uitsluitend hele uren wordt direct in één stap toegevoegd, ook bij vertrek op een tijd met minuten. Begint de reis al op een heel uur, of eindigt zij vóór het volgende hele uur, dan volstaat eveneens één stap. Het tempo blijft 0,9 seconde leesrust aan het begin, 0,35 seconde voor iedere cijferovergang en 0,8 seconde tussen stappen. Er is geen overschrijding gevolgd door aftrekken. Een nieuwe vraag, een nieuw voorbeeld of replay annuleert de eerdere animatie. Verminder beweging toont direct de eindtijd. Tijdens een herkansing blijft de aankomst verborgen tot de speler het antwoord toont of goed kiest.

## Verificatie — 31 oktober 2026

De laatste wijziging aan de gedeelde rekenroute en de actuele schermtestresultaten staan in [Tijd optellen en aftrekken via het hele uur](HourBoundaryReplayVerification.md). Onderstaande opnamen tonen de eerder aangepaste weergave en overgang.

- De gerichte kernsuite met `--train-durations`: **8.449 controles geslaagd**, inclusief de bovenstaande voorbeelden, nulminuten, voorloopnullen, beide eenheden vanaf nul, duren boven 24 uur en de tweestapsroute via een heel uur.
- `testDayScheduleHasTwoActivitiesAndBreak` en `testTrainDurationCarryInBothLanguages`: geslaagd op iPhone 17e en iPad Air 13-inch (M4), beide met iOS 27. Getest: uitlijning, duurteksten en HH:MM, totaal, voorbeeld/verversen, herkansing, antwoordweergave, groene pluswaarde en twee snelle replay-tikken. De test leest bij iedere controle het actuele klokelement opnieuw uit, ook na het vervangen van het vraagteken.
- `testWorkedAnswersKeepTheOptionsInPlace`: geslaagd op iPhone 17e; antwoordposities blijven gelijk tijdens en na de uitleg.
- Nederlandse en Engelse screenshots op beide apparaten gecontroleerd, inclusief compacte beginvakjes, nulwaarden voor uren én minuten bij replay en uitgelijnde totaalwaarden. De beelden zijn rechtstreeks uit de eigen testrapporten geëxporteerd en staan onder `Documentation/Screenshots/iphone/train-smooth-*.png` en `Documentation/Screenshots/ipad/train-smooth-*.png`. Ook de tussenbeelden van de overgang zijn gecontroleerd; de oude en nieuwe duurtekst overlappen niet.
- De definitieve schermtests staan in `/tmp/dino-train-smooth-iphone-final-a31c.xcresult` en `/tmp/dino-train-smooth-ipad-final-a31c.xcresult`; de voorbeeld-/herkansingscontrole in de overeenkomstige `*-reveal-a31c.xcresult`-rapporten. Een korte opname staat in `Documentation/Screenshots/iphone/train-smooth-reveal-and-replay.mp4`.
- `git diff --check`: geslaagd.
