# Vluchtvraag: totaalhint en replay — 29 oktober 2026

Vraagtype 20 is de vluchtvraag. Na het eerste foute antwoord toont het ticket de totale tijdverschuiving van vliegduur en tijdzoneverschil. De aankomsttijd blijft een vraagteken tijdens de herkansing. De totaalrij reserveert vooraf haar ruimte, zodat de antwoordkeuzes bij het verschijnen van de hint blijven staan. Ook bij een vlucht zonder tijdzoneverschil wordt het totaal getoond.

De aankomstanimatie gebruikt dezelfde rekenroute als de treinreis (18) en tijdzones (19): hele uren, gevolgd door één korte minutencorrectie. Een verschuiving van 1 uur en 55 minuten wordt 1 uur, 2 uur en daarna 5 minuten terug. De gedeelde berekening ondersteunt ook negatieve verschuivingen en middernacht.

Rechtsboven op het ticket staat tijdens de uitleg en in voorbeelden een ronde replayknop. Deze begint de tijdanimatie opnieuw bij de vertrektijd en behoudt de totaalhint. Herhaald tikken annuleert de vorige animatie. Bij Minder beweging verschijnt direct de eindtijd.

## Verificatie

- De gerichte kernsuite `--flight-arrivals` slaagt met **48.180 controles** voor vluchten, tijdzones en de gedeelde rekenroute.
- `testFlightTotalHintAndReplayInBothLanguages` slaagt op aparte iPhone 18 Pro- en iPad Pro 13-inch (M5)-simulators met iOS 27, in Nederlands en Engels.
- De schermtest controleert de verborgen hint vóór een fout, het totaal na één fout, de verborgen aankomst tijdens een herkansing, behoud na een voorbeeld, replay in het voorbeeld en de vraag, dubbele replay, vaste antwoordposities tijdens replay en het verdwijnen van de hint bij de volgende vraag.
- De hint en de plaatsing van de replayknop zijn visueel gecontroleerd op beide schermformaten. `git diff --check` slaagt.

De testresultaten staan lokaal in `.build/FlightHintReplay-Isolated-iPhone.xcresult` en `.build/FlightHintReplay-Isolated-iPad.xcresult`. Schermbeelden staan in `/tmp/DinoScreenshots/iphone/flight-*.png` en `/tmp/DinoScreenshots/ipad/flight-*.png`.
