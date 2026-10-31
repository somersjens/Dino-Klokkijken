# Vluchtvraag: totaalhint en replay — 29 oktober 2026

Vraagtype 20 is de vluchtvraag. Na het eerste foute antwoord toont het ticket bij een tijdzoneverschil de totale tijdverschuiving van vliegduur en tijdzoneverschil. De aankomsttijd blijft een vraagteken tijdens de herkansing. Sinds 30 oktober reserveert de totaalrij geen ruimte meer vóór een fout. Sinds 31 oktober klappen de scheidingslijn en het totaal binnen hun eigen ruimte open: de hoogte groeit in 0,45 seconde, zonder fade of schuifbeweging over de waarden erboven. Bij Minder beweging verschijnt de rij direct. Bij dezelfde tijdzone vervallen de scheidingslijn en het totaal, ook na een fout en tijdens replay of een voorbeeld.

De aankomstanimatie gebruikt dezelfde rekenroute als de treinreis (18) en tijdzones (19): hele uren, gevolgd door één korte minutencorrectie. Een verschuiving van 1 uur en 55 minuten wordt 1 uur, 2 uur en daarna 5 minuten terug. De gedeelde berekening ondersteunt ook negatieve verschuivingen en middernacht.

Rechtsboven op het ticket staat tijdens de uitleg en in voorbeelden een ronde replayknop. Deze begint de tijdanimatie opnieuw bij de vertrektijd en behoudt de totaalhint. Herhaald tikken annuleert de vorige animatie. Bij Minder beweging verschijnt direct de eindtijd.

## Verificatie

- De gerichte kernsuite `--flight-arrivals` slaagt met **48.180 controles** voor vluchten, tijdzones en de gedeelde rekenroute.
- `testFlightTotalHintAndReplayInBothLanguages` slaagt op aparte iPhone 18 Pro- en iPad Pro 13-inch (M5)-simulators met iOS 27, in Nederlands en Engels.
- De schermtest controleert de verborgen hint vóór een fout, het totaal na één fout, de verborgen aankomst tijdens een herkansing, behoud na een voorbeeld, replay in het voorbeeld en de vraag, dubbele replay, vaste antwoordposities tijdens replay en het verdwijnen van de hint bij de volgende vraag.
- De hint en de plaatsing van de replayknop zijn visueel gecontroleerd op beide schermformaten. `git diff --check` slaagt.

De testresultaten staan lokaal in `.build/FlightHintReplay-Isolated-iPhone.xcresult` en `.build/FlightHintReplay-Isolated-iPad.xcresult`. Schermbeelden staan in `/tmp/DinoScreenshots/iphone/flight-*.png` en `/tmp/DinoScreenshots/ipad/flight-*.png`.

## Compact ticket en uitklappende hint — 30 oktober 2026

De vooraf verborgen totaalrij is verwijderd. Het ticket groeit nu pas bij de eerste fout, met een gecombineerde schuif- en vervaaganimatie van 0,45 seconde. Op kleine schermen schuift de vraag na het openen zo nodig mee om alle antwoordkeuzes boven de vaste onderknop te houden. De rij blijft bij replay volledig open.

`testFlightTotalHintAndReplayInBothLanguages` slaagt op iPhone 18 Pro en iPad Pro 13-inch (M5), met iOS 27 en beide talen. De test vergelijkt nu ook de hoogte vóór en na de fout en controleert dat de onderste antwoordkeuze binnen het vraagvenster blijft. De compacte vraag en de geopende hint zijn op beide schermformaten visueel gecontroleerd. De aanvullende controle `testWorkedAnswersKeepTheOptionsInPlace` slaagt op iPhone: na het verschijnen van de hint blijven de keuzes tijdens de verdere uitleg op hun plek.

De resultaten van deze update staan in `.build/FlightReveal-Final-iPhone.xcresult` en `.build/FlightReveal-Final-iPad.xcresult`. `git diff --check` slaagt.

## Uitklappen zonder overlap en zonder overbodig totaal — 31 oktober 2026

De fade en verplaatsing van de totaalrij zijn vervangen door een uitklap van de hoogte. De rij houdt haar normale formaat; een clip maakt haar van boven naar beneden zichtbaar binnen de nieuw geopende ruimte. Daardoor kan het totaal niet door de vliegduur of tijdzonewaarde heen bewegen. In ingeklapte toestand ontbreekt de rij ook in de toegankelijkheidsweergave.

Bij een tijdzoneverschil van nul vervallen de scheidingslijn en het totaal volledig. Dat geldt voor de vraag, het voorbeeld en replay. Het ticket behoudt na een fout zijn compacte hoogte; de vliegduur blijft de enige benodigde duur.

`testFlightTotalHintAndReplayInBothLanguages` en `testFlightSameZoneDoesNotShowTotal` slagen op iPhone 18 Pro en iPad Pro 13-inch (M5), beide met iOS 27 en Nederlands/Engels. De controles omvatten de hoogte vóór en na een fout, de antwoorden boven de onderknop, voorbeelden, replay en het ontbreken van een totaal bij dezelfde tijdzone. De uitklap is bovendien beeld voor beeld gecontroleerd in een lokale simulatoropname; de waarden erboven blijven vrij van overlap.

Resultaten: `.build/FlightUnfold-Final-iPhone.xcresult` en `.build/FlightUnfold-Final-iPad.xcresult`. De lokale opname staat in `/tmp/dino-flight-unfold-final-20261031.mp4`. `git diff --check` slaagt.
