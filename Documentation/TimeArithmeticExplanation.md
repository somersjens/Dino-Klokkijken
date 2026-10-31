# Rekenuitleg — type 14 en 15

Alle pijlen en rekenstrepen gebruiken hetzelfde donkerblauw als de vraagtitel (`DinoStyle.ink`, `#193B53`). De losse rekentekens bij de strepen zijn lichtgroen bij optellen en lichtrood bij aftrekken. Hoog contrast gebruikt de donkere varianten.

De uur- en minuutkolom staan op gelijke afstand van de middenklok en zijn iets naar binnen geplaatst. Beide rekentekens staan rechts van hun eigen kolom. De rekenstrepen eindigen bij de rechterkant van het teken. De pijlen beginnen op gelijke afstand van het geschilderde klokvlak en de duurcapsule; de vier punten interne klokpadding tellen niet als zichtbare rand.

Na het eerste foute antwoord verschijnt de bovenste berekening, inclusief de vier pijlen, beide rekenstrepen en de tussentotalen. Bij vier antwoordkeuzes blijft de leerling daarna kiezen. De hint eindigt direct onder de tussentotalen: er is geen verborgen eindklok, pijlenruimte of middernachttekst die alvast hoogte reserveert.

Pas wanneer de vraag sluit, wordt de eindklok daadwerkelijk in de indeling ingevoegd. De antwoordopties schuiven tijdens dezelfde rustige ease-in-out-overgang omlaag. Ook de gemeten hoogte van de omringende vraagillustratie animeert mee. De vraag sluit via **Toon antwoord**, een goed herkansingsantwoord of het uitsluiten van alle foute opties. De twee eindpijlen verschijnen dan ook. Hun horizontale en verticale delen zijn korter; de eindklok staat dichter onder de tussentotalen. Correcties zoals `+1` en `−60` staan boven het horizontale pijldeel, vlak vóór de bocht in de leesrichting. De badges houden ook op smalle schermen voldoende afstand van de cijferblokken.

De tussentotalen hebben geen groene of blauwe omlijning.

Bij twee antwoordopties en bij voorbeelden opent de hele uitleg in één hoogteovergang. De eindklok schuift dus niet na een pauze nog een tweede keer de antwoordopties omlaag. De pijlen worden vervolgens achtereenvolgens getekend. Bij vier opties blijft de hint zoals eerder compact, tot de vraag sluit.

De bovenste uitleg start bij het afsluiten niet opnieuw. Er is geen automatische scroll naar het rekenblok. Een nieuwe vraag of een nieuw voorbeeld reset de animatie; Verminder beweging slaat animaties en wachttijden over.

De UI-test `testTimeArithmeticHintAppearsDuringRetryAndResultWaitsUntilClosed` controleert beide vraagtypen, alle drie afsluitroutes, de verborgen eindtijd tijdens de herkansing en het resetten bij de volgende vraag. Hij bewaakt ook de compacte afstand tussen de tussentotalen en de antwoordopties, en controleert dat de extra ruimte pas ontstaat als de eindklok wordt ingevoegd. De bestaande test `testTimeDescriptionsAndArithmeticExampleSizes` controleert de voorbeelden, gelijke klokmaten en de positie van de zijkolommen. `testTwoChoiceArithmeticRevealsTheCompleteCompactExplanation` controleert beide vraagtypen na één fout bij twee antwoordopties, de volledige uitleg, de kortere ruimte onder de tussentotalen en het resetten na Verder.

## Verificatie — 31 oktober 2026

- Definitieve compacte hint, uitklappen van de eindtijd, alle drie afsluitroutes en reset: geslaagd op iPhone 18 Pro en iPad Pro 13-inch (M5), iOS 27.
- Voorbeelden, gelijke klokmaten en kolomposities: geslaagd op iPhone 18 Pro en iPad mini (A17 Pro), iOS 27.
- Screenshots visueel gecontroleerd op beide schermformaten: donkerblauwe pijlen, lichte tekens rechts, gelijke bronafstand en compacte hint zonder lege eindrij.
- Een aanvullende run op iOS 26.5 werd beëindigd met SIGKILL in de testrunner; de herhaling op iOS 27 is geslaagd.
- `git diff --check`: geslaagd.

Lokale screenshots: [compacte hint](Screenshots/iphone/time-arithmetic-add-hint.png), [eindantwoord](Screenshots/iphone/time-arithmetic-add-result.png), [aftrekken](Screenshots/iphone/time-arithmetic-subtract-result.png), [iPad](Screenshots/ipad/time-arithmetic-subtract-result.png).

## Compactere eindpijlen — 31 oktober 2026

- Tussentotalen zonder omlijning; kortere eindpijlen met correcties vlak vóór de bocht visueel gecontroleerd.
- iPhone 18 Pro, iOS 27: vierkeuze-hint, alle afsluitroutes en de nieuwe tweekeuzecontrole geslaagd.
- iPad mini (A17 Pro), iOS 27: voorbeelden en de nieuwe tweekeuzecontrole geslaagd.
- De tweekeuzecontrole bewaakt ook de kleinere afstand tussen tussentotalen en eindklok, plus reset bij de volgende vraag.
- De gewone build wordt geblokkeerd door de huidige appiconen van 1254 × 1254 in plaats van 1024 × 1024. Schermtests zijn uitgevoerd met de tijdelijke buildinstelling `ASSETCATALOG_COMPILER_APPICON_NAME=`; iconen en projectinstellingen zijn hiervoor niet aangepast.
- `git diff --check`: geslaagd.

[Correcties vóór de bocht](Screenshots/ipad/time-arithmetic-compact-corrections.png) · [volledige uitleg bij twee antwoorden](Screenshots/iphone/time-arithmetic-add-two-choice.png).
