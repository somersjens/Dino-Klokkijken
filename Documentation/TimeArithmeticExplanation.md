# Rekenuitleg — type 14 en 15

Alle pijlen en rekenstrepen gebruiken hetzelfde donkerblauw als de vraagtitel (`DinoStyle.ink`, `#193B53`). De losse rekentekens bij de strepen zijn lichtgroen bij optellen en lichtrood bij aftrekken. Hoog contrast gebruikt de donkere varianten.

De uur- en minuutkolom staan op gelijke afstand van de middenklok en zijn iets naar binnen geplaatst. Beide rekentekens staan rechts van hun eigen kolom. De rekenstrepen eindigen bij de rechterkant van het teken. De pijlen beginnen op gelijke afstand van het geschilderde klokvlak en de duurcapsule; de vier punten interne klokpadding tellen niet als zichtbare rand.

Na het eerste foute antwoord verschijnt de bovenste berekening, inclusief de vier pijlen, beide rekenstrepen en de tussentotalen. Bij vier antwoordkeuzes blijft de leerling daarna kiezen. De hint eindigt direct onder de tussentotalen: er is geen verborgen eindklok, pijlenruimte of middernachttekst die alvast hoogte reserveert.

Pas wanneer de vraag sluit, wordt de eindklok daadwerkelijk in de indeling ingevoegd. De antwoordopties schuiven tijdens dezelfde rustige ease-in-out-overgang omlaag. Ook de gemeten hoogte van de omringende vraagillustratie animeert mee. De vraag sluit via **Toon antwoord**, een goed herkansingsantwoord of het uitsluiten van alle foute opties. De twee eindpijlen verschijnen dan ook; eventuele correcties zoals `−1` en `+60` staan naast het verticale deel van hun eigen pijl.

De bovenste uitleg start bij het afsluiten niet opnieuw. Er is geen automatische scroll naar het rekenblok. Een nieuwe vraag of een nieuw voorbeeld reset de animatie; Verminder beweging slaat animaties en wachttijden over.

De UI-test `testTimeArithmeticHintAppearsDuringRetryAndResultWaitsUntilClosed` controleert beide vraagtypen, alle drie afsluitroutes, de verborgen eindtijd tijdens de herkansing en het resetten bij de volgende vraag. Hij bewaakt ook de compacte afstand tussen de tussentotalen en de antwoordopties, en controleert dat de extra ruimte pas ontstaat als de eindklok wordt ingevoegd. De bestaande test `testTimeDescriptionsAndArithmeticExampleSizes` controleert de voorbeelden, gelijke klokmaten en de positie van de zijkolommen.

## Verificatie — 31 oktober 2026

- Definitieve compacte hint, uitklappen van de eindtijd, alle drie afsluitroutes en reset: geslaagd op iPhone 18 Pro en iPad Pro 13-inch (M5), iOS 27.
- Voorbeelden, gelijke klokmaten en kolomposities: geslaagd op iPhone 18 Pro en iPad mini (A17 Pro), iOS 27.
- Screenshots visueel gecontroleerd op beide schermformaten: donkerblauwe pijlen, lichte tekens rechts, gelijke bronafstand en compacte hint zonder lege eindrij.
- Een aanvullende run op iOS 26.5 werd beëindigd met SIGKILL in de testrunner; de herhaling op iOS 27 is geslaagd.
- `git diff --check`: geslaagd.

Lokale screenshots: [compacte hint](Screenshots/iphone/time-arithmetic-add-hint.png), [eindantwoord](Screenshots/iphone/time-arithmetic-add-result.png), [aftrekken](Screenshots/iphone/time-arithmetic-subtract-result.png), [iPad](Screenshots/ipad/time-arithmetic-subtract-result.png).
