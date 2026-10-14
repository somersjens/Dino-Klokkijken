# Dino-kleur en vaste onderrand

Gecontroleerd op 14 oktober 2026.

Alle zeven gebruikte poses delen nu de helderheid en verzadiging van de gewone Dino. De correctie werkt per lichaamsdeel, vóór het toepassen van de gekozen kleur. Dit voorkomt dat roze bij de foutreactie verbleekt, terwijl schaduwen, textuur, ogen, mond, bandanacijfers en transparantie behouden blijven. De originele PNG’s zijn ongewijzigd.

Tijdens alle vragen staat één Dino rechts aan de onderrand. Zijn anker staat buiten de ScrollView. De gemeten vraaghoogte bepaalt zijn formaat; lange vragen en lage schermen krijgen een kleinere Dino. Een vaste onderruimte voorkomt overlap met antwoordbediening. Verder staat links van de Dino. Klokken reserveren geen zijruimte meer voor hem. De gedeelde laag ontvangt antwoordreacties expliciet, zodat een stilstaand anker de overgang naar duim of foutreactie niet tegenhoudt.

## Controles

- `Tools/test-dino.sh`: **394.885 controles geslaagd**. Nieuwe bitmapcontroles vergelijken schaduwen, middenkleur, hooglichten en verzadiging van alle zeven poses voor standaardkleuren en twee aangepaste paletten, inclusief roze/paars. Ze bewaken ook transparantie en ongewijzigde gezichtdetails.
- iPhone 18 Pro en iPad A16, iOS 27: **3 gerichte UI-tests per apparaat geslaagd**. Deze controleren de aangepaste kleuren, vaste positie tijdens scrollen, grote koppelvragen, kleinere Dino in een lage weergave, bereikbare Verder-knop, blijvende foutreactie en de doorlopende salto naar het resultaat.
- iPhone 17 Pro, iOS 26.1: bestaande layout-/taaltest **geslaagd**, inclusief liggende gameweergave en pauzescherm.
- iPhone 17, iOS 26.5: klokvergelijking en voorbeelden **geslaagd**. De simulator schakelde bij de rotatiecontroles niet naar liggend beeld; deze controle is daarom op iOS 26.1 en 27 bevestigd. De bestaande oriëntatieconfiguratie is behouden.
- `git diff --check`: geen whitespacefouten.

## Beelden

- [Gewone Dino onderin op iPhone](Screenshots/CompanionRefinement/companion-pink-idle-bottom-iphone.png)
- [Foutreactie met dezelfde roze kleur](Screenshots/CompanionRefinement/companion-pink-wrong-bottom-iphone.png)
- [Kleiner bij een grote vraag](Screenshots/CompanionRefinement/companion-large-pair-question-iphone.png)
- [Liggende iPhone-weergave](Screenshots/CompanionRefinement/companion-question-landscape-iphone.png)
- [Foutreactie op iPad](Screenshots/CompanionRefinement/companion-pink-wrong-bottom-ipad.png)
- [Liggende iPad-weergave](Screenshots/CompanionRefinement/companion-question-landscape-ipad.png)
