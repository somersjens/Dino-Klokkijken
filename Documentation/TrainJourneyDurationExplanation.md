# Treinvraag 18 — uitlijning en tijdsduur

Vertrek, beide treinen, overstap en aankomst gebruiken dezelfde pictogramkolom, ook wanneer de uitleg opent. Na het eerste foute antwoord schuift de bestaande duurtekst naar links en verschijnt rechts de duur in HH:MM. Dezelfde kolom toont het omgerekende totaal.

De duurteksten gebruiken afzonderlijke, vaste kolommen voor het plusteken, de uren en de minuten. Reisregels en totaal reserveren ook het lege tekenvak; de groene optelling bij aankomst gebruikt dat vak voor de plus. Ontbrekende uren of minuten houden hun plek. Zo staan bijvoorbeeld `1h`, `1h` en `+2h` onder elkaar, naast de uitgelijnde minutenwaarden `33 min`, `109 min` en `49 min`.

Het aankomstpictogram is vergroot. Zodra replay beschikbaar is, vervangt de kleinere replaypijl het pictogram op dezelfde plek links van het aankomstlabel.

Het totaal gebruikt korte eenheden en telt de uren en minuten op zoals ze op de drie reisregels staan, vóór het omwisselen van zestig minuten voor een uur:

| Reisregels | Korte totaaltekst | HH:MM |
| --- | --- | --- |
| 40 min + 30 min + 50 min | 120 min | 02:00 |
| 40 min + 30 min + 1 uur 10 min | 1 uur 80 min / 1h 80 min | 02:20 |

De drie duurteksten gebruiken een vaste lettergrootte, ook bij een korte eerste rit naast een langere tweede rit. De duurkolom blijft onafhankelijk van de persoonlijke 12-/24-uursklok. Het rekenblok reserveert vooraf de hoogte van de optelling, zodat de antwoordknoppen bij het openen van de uitleg blijven staan.

De uitgewerkte uitleg en het voorbeeld laten de aankomsttijd oplopen vanaf de vertrektijd. Een groene pluswaarde links van de klok loopt tegelijk mee. De replay-knop begint opnieuw bij nul. Dit gebruikt dezelfde stappen als vraag 19: hele uren en één laatste minuutcorrectie, met dezelfde pauzes en cijferovergangen. Een nieuwe vraag, een nieuw voorbeeld of replay annuleert de eerdere animatie. Verminder beweging toont direct de eindtijd. Tijdens een herkansing blijft de aankomst verborgen tot de speler het antwoord toont of goed kiest.

## Verificatie — 29 oktober 2026

- De gerichte kernsuite met `--train-durations`: **7.228 controles geslaagd**, inclusief de bovenstaande voorbeelden, korte eenheden, voorloopnullen, duren boven 24 uur en dezelfde stappen als vraag 19.
- `testDayScheduleHasTwoActivitiesAndBreak` en `testTrainDurationCarryInBothLanguages`: geslaagd op iPhone 17e en iPad Air 13-inch (M4), beide met iOS 27. Getest: uitlijning, duurteksten en HH:MM, totaal, voorbeeld/verversen, herkansing, antwoordweergave, groene pluswaarde en twee snelle replay-tikken. De test leest bij iedere controle het actuele klokelement opnieuw uit, ook na het vervangen van het vraagteken.
- `testWorkedAnswersKeepTheOptionsInPlace`: geslaagd op iPhone 17e; antwoordposities blijven gelijk tijdens en na de uitleg.
- Nederlandse en Engelse screenshots op beide apparaten visueel gecontroleerd, inclusief volledige uurteksten en driecijferige minuten. De beelden zijn rechtstreeks uit de eigen testrapporten geëxporteerd en staan onder `Documentation/Screenshots/iphone/train-columns-aligned-*.png` en `Documentation/Screenshots/ipad/train-columns-aligned-*.png`.
- `git diff --check`: geslaagd.
