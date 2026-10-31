# Rekenuitleg — type 14 en 15

De vertrektijd en de duur hebben elk twee blauwe pijlen naar de buitenste uur- en minuutkolom. De blauwe rekenstrepen lopen naar binnen door; het blauwe plus- of minteken staat vlak boven die verlenging, vrij van de pijlen op de duurregel.

Na het eerste foute antwoord verschijnt de bovenste berekening, inclusief de vier pijlen, beide rekenstrepen en de tussentotalen. Bij vier antwoordkeuzes blijft de leerling daarna kiezen. De eindklok, de twee pijlen ernaartoe en eventuele correcties zoals `−1` en `+60` verschijnen pas wanneer de vraag sluit: via **Toon antwoord**, een goed herkansingsantwoord of het uitsluiten van alle foute opties. De correcties staan naast het verticale deel van hun eigen pijl.

Het openen gebruikt een rustige ease-in-out-overgang. Pijlen worden geleidelijk getekend en hun coördinaten bewegen mee wanneer de indeling verandert. De ruimte voor de eindklok wordt al bij de hint gereserveerd, zodat de uitleg bij het afsluiten niet opnieuw uitklapt. De bovenste uitleg wordt dan niet opnieuw gestart. Er is ook geen automatische scroll naar het rekenblok bij het afsluiten; de vraagtekst en antwoorden blijven op hun plek. Een nieuwe vraag of een nieuw voorbeeld reset de animatie; Verminder beweging slaat de animatie en wachttijden over.

De UI-test `testTimeArithmeticHintAppearsDuringRetryAndResultWaitsUntilClosed` controleert beide vraagtypen, alle drie afsluitroutes, de verborgen eindtijd tijdens de herkansing en het resetten bij de volgende vraag. De bestaande test `testTimeDescriptionsAndArithmeticExampleSizes` controleert ook de voorbeelden, gelijke klokmaten en de positie van de zijkolommen.

## Verificatie — 31 oktober 2026

- `zsh Tools/test-dino.sh`: **1.286.777 controles geslaagd**.
- Voorbeelden en alle drie afsluitroutes gecontroleerd op iPhone 18 Pro en iPad Pro 13-inch (M5), met iOS 27.
- Voorbeelden visueel gecontroleerd: vier buitenwaartse pijlen, blauwe rekentekens en strepen, en de correcties naast hun pijl bij `07:00 − 5 min = 06:55`.
- Definitieve regressietest geslaagd op iPhone 18 Pro en iPad mini (A17 Pro), iOS 27. De test controleert naast zichtbaarheid en reset ook de vaste positie van de startklok en de antwoordkaarten bij het onthullen. De nieuwe feedbackrand en badge bij het goede antwoord worden buiten de positievergelijking gehouden.
- `git diff --check`: geslaagd.

Lokale screenshots: [hint na eerste fout](Screenshots/iphone/time-arithmetic-add-hint.png), [eindantwoord](Screenshots/iphone/time-arithmetic-add-result.png), [lenen van een uur](Screenshots/iphone/time-arithmetic-borrow-example.png), [iPad mini](Screenshots/ipad/time-arithmetic-subtract-result.png).
