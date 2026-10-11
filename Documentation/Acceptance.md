# MVP-acceptatie — 11 oktober 2026

De app is in het bestaande native SwiftUI-project gebouwd, met de originele dino-asset. De kernlogica en de echte scherminteracties worden afzonderlijk gecontroleerd.

| Scenario's uit de opdracht | Controle |
| --- | --- |
| 1–3 Naam, eigen klok, standaardklok | UI-tests: lege naam blokkeert Verder; naam invoeren; eigen kleur; standaardklok overslaan. |
| 4–7 Kaart, startpositie, eerste level, ontgrendeling | Kerncontrole van 10 configuraties en initiële levels `[1, 10]`; UI doorloopt alle 9 gewone levels. |
| 8–11 Sterren bij 2/5, 3/5, 4/5 en 5/5 | Alle scoregrenzen automatisch getest; UI speelt 2/5, 3/5 en de volledige normale route met 5/5. |
| 12–13 Hoogste sterren behouden en Dino verplaatsen | Kerncontrole van hoogste score, blanco beginpunt en hoogste behaalde level; UI controleert 3/5 → 0/5, behoud van ontgrendeling en herstart. |
| 14–18 Directe boss, 10/10, normale 5/10, onvoldoende 9/10 en 4/10 | Volledige kernmatrix 0–10 met/zonder normale route; UI speelt directe 10/10, normale route met 5/10 en directe 9/10. |
| 19–20 Analoge en digitale klok | Alle 24 × 60 tijden mathematisch gecontroleerd; 03:00, 03:30, 03:45, 12:00, voorloopnullen, aanraak-snapping en plus/min-omslag. UI gebruikt beide klokken in alle vraagtypen. |
| 21–23 Thema's, later wijzigen, herstart | Kerncontrole van alle profielvelden en echte UserDefaults-opslag; UI test klok aanpassen in onboarding en instellingen, beëindigen en opnieuw openen. |
| 24 Geen geluid of spraak | Actieve target bevat geen audio-, speech- of StoreKit-code; geen audioresources verpakt of initialisatie aangeroepen. |
| 25 Telefoon en tablet | Echte speelroute op iPhone 18 Pro; personalisatie en boss op iPad A16; aanvullende controle van portret/landschap en bereikbare knoppen. Screenshots visueel nagekeken. |
| 26 Bestaande taalfunctionaliteit | Bestaande voorkeurssleutel en live taalwissel behouden; uitsluitend Nederlands en Engels. UI controleert de twee taalkeuzes, Engelse schermen en taalbehoud na herstart. |

## Uitgevoerde tests

- `Tools/test-dino.sh`: **110.415 geslaagde controles**, waaronder 3.000 gegenereerde levelpogingen, alle vraagtypen, unieke antwoorden, wisselende antwoordposities, dubbele taps, onvolledige pogingen en resetgedrag.
- iPhone 18 Pro / iOS 27: volledige normale wereld en boss, 0 sterren/herhaling/herstart, directe perfecte boss en klokpersonalisatie.
- iPad A16 / iPadOS 27: boss 9/10 zonder voorgaande levels, klokpersonalisatie en herstart, landschapstand en live taalwissel.
- iPhone SE (3e generatie) / iOS 26.1: onboarding, portret/landschap, bereikbare bediening en live taalwissel. Een achterblijvende navigatietitel bij taalwissel op iOS 26 is hersteld en opnieuw getest.
- Zowel Debug- als Release-build slagen.

De onafhankelijke testopslag en vaste random seed zijn uitsluitend beschikbaar in debug-builds. Productie vraagt geen account, speelt willekeurige vragen en bewaart het spelersprofiel lokaal. De testresultaten gebruiken simulatoren; er is geen fysiek apparaat getest.

Alle spelteksten zijn vertaald in Nederlands en Engels. De overige talen en oude spelonderdelen zijn verwijderd. Wereld 2 is bewust gesloten, met het label Binnenkort.

## Aanpassingen na de eerste versie

| Verzoek | Controle |
| --- | --- |
| Direct starten met naam | De eerste zichtbare invoer is `onboarding.name`; geen losse Start-stap. Lege naam blokkeert Verder. De knop blijft op iPhone SE bereikbaar met toetsenbord. |
| Geen 2/1-antwoordrasters | De generator maakt uitsluitend twee of vier opties. Alle 3.000 pogingen controleren dit. UI controleert twee volledige rijen van twee. |
| Foute antwoorden zelf bekijken | UI wacht drie seconden na een fout en controleert dat vraag 1/10 blijft staan. Alle vier de klokken blijven zichtbaar; Verder opent pas daarna vraag 2/10. |
| Transparante dino, vaste titel | De originele PNG is ongewijzigd hernoemd naar `dino-idle`; geen wit kader. De dino staat bij de klok, buiten de titel. Screenshots controleren de plaatsing. |
| Backflip bij maximale punten | Alle acht poses zijn ongewijzigd hernoemd en gekoppeld. UI controleert dat de backflip alleen verschijnt bij 5/5 of 10/10, ook bij herhaling. |
| Nieuwe themakleur | Primaire kleur en AccentColor zijn #81D349; tekst op groene knoppen is donker. |
| Oude game en talen weg | Bronbestanden, resourcecatalogus en projectverwijzingen opgeschoond; een nieuwe build verpakt alleen en.lproj en nl.lproj. |

## Tweede verfijning

- Sterren, voortgang, correcte antwoorden, kristallen en trofeeën gebruiken groen.
- De klok staat los van Dino in het midden; op iPhone SE en iPad wordt het midden vóór/na feedback automatisch vergeleken.
- De nieuwe duimenbeelden zijn hernoemd en spelen bij ieder correct antwoord; door naar de volgende vraag na 0,72 seconde, zonder tekstbanner.
- De salto gebruikt een doorlopende rotatie en sprongbaan, gecorrigeerde beeldoriëntaties en uitgelijnde draaipunten. De bewegingscurve wordt op 120 tijdstappen per seconde gecontroleerd op onderbroken rotatie en hoogte.
- Een nieuw profiel heeft kaartpositie 0 (blanco beginpunt, geen speelbaar level). De positie volgt het hoogste behaalde level en blijft na een slechtere herhaling bewaard.
- Startkaarten tonen geen vragenaantal of instructiesubtitel. De eigen verlaten-kaart is visueel bekeken in portret en landschap; annuleren houdt dezelfde vraag vast, verlaten keert terug naar de kaart.
- Nieuwe UI-runs: drie controles op iPhone SE en drie op iPad geslaagd; volledige normale wereld, directe perfecte boss en herhaling/herstart op iPhone 18 Pro geslaagd.
- Na de visuele kaartcontrole zijn de scrollankers vervangen door vaste rijen. Aanvullende UI-tests controleren Dino volledig in het scherm bij level 1 en 10, inclusief herstart; geslaagd op iPhone 18 Pro en iPhone SE. De definitieve Release-build slaagt.


## Junglelandschap en speelse header

- Alle landschapselementen zijn uit shapes opgebouwd in één statische Canvas. Het decor loopt achter de titel en over de hele scrollroute door; de sierlijke vormen onderscheppen geen aanrakingen.
- De ingang heeft boomkruinen en lianen, de middenroute een rotswaterval en lagune, en de boss een open plek met mosstenen. Het zandpad blijft vrij voor levelknoppen en Dino.
- De laatste 560 punten mengen het junglepalet met een apart horizonpalet. Begroeiing maakt plaats voor lage silhouetten en nevel. De preview van wereld 2 blijft gesloten.
- De header heeft een dinoportret met naam, een levelbadge, het verdiende sterrentotaal zonder maximum en een pauzeknop. De badges hebben beperkte breedte op tablets; de onderrand bestaat uit zachte golven.
- UI-controle op iPhone 18 Pro / iOS 27 en iPad A16 / iPadOS 27: vaste positie van de header tijdens scrollen, juiste volgorde van de onderdelen, pauzeren en hervatten, en verandering van 0 naar 3 sterren na een voltooid level. Op beide apparaten geslaagd.
- De bestaande UI-controle voor vier antwoordkeuzes en blijvende foutfeedback slaagt op iPhone. Op iPad slagen landschapstand en taalwisseling via de instellingen in het pauzemenu.
- Ook op iPhone SE (3e generatie) / iOS 26.1 slagen de header-, pauze-, sterren-, foutfeedback- en portret/landschapcontroles. De kernsuite slaagt met 110.536 controles.
