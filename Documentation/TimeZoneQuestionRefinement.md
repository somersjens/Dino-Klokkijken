# Vraagtype 19: hoofdsteden op een platte wereldkaart

De vraag noemt direct de gezochte hoofdstad, bijvoorbeeld **Hoe laat is het in Ankara?** De kaart toont precies twee stadsmarkeringen. Bij de groene referentiestad staat de gegeven tijd onder het punt; bij de oranje bestemming staan een vraagteken en het uurverschil. Die tijd is rood als de stad eerder is en lichtgroen — dezelfde kleur als een positief uurverschil — als de stad later is. Een goed antwoord en **Toon antwoord** tonen de bestemmingstijd. Een foute eerste poging houdt de tijd verborgen.

Het voorbeeld animeert de tijd direct in het bestemmingskaartje op de wereldkaart. De bestemming begint op dezelfde tijd als de referentiestad, met nul uur verschil. Het verschil en de tijd veranderen samen tot de echte bestemmingstijd bereikt is. Rechtsboven in het bestemmingskaartje staat een replayknop om de animatie opnieuw vanaf nul af te spelen. Opnieuw tikken tijdens het afspelen vervangt de lopende animatie. Onder de kaart staan geen losse digitale klokken of verschilknopjes meer. Na een fout antwoord verschijnt dezelfde animatie in het kaartje zodra het goede antwoord volgt, of via **Toon antwoord**. Een nieuwe, onbeantwoorde vraag houdt het vraagteken en toont geen replayknop. Bij Verminder beweging verschijnt de uitkomst direct.

De animatie telt in hele uren en gebruikt daarna één korte minutencorrectie. Een verschil van 1 uur en 55 minuten wordt **+1 uur, +2 uur, −5 minuten**; bij een negatief verschil worden de richtingen omgedraaid. Een verschil van precies een half uur wordt vooruit toegevoegd. De klok en het cumulatieve verschil blijven in iedere stap exact gelijk lopen, ook over middernacht.

De gekozen speltaal bepaalt de referentiestad: Nederlands gebruikt Amsterdam, Engels Londen. Dit is een eenvoudige taalvoorkeur, zonder locatiegegevens. De overige steden zijn echte hoofdsteden van bekende landen. Turkije gebruikt Ankara; Istanbul is geen hoofdstad. Een paar gebruikt altijd verschillende landen én verschillende tijdzones.

| Verborgen moeilijkheid | Bereik bij iedere tijdsoort |
| --- | --- |
| Kennismaken | Hoofdsteden in Europa met één uur verschil |
| Vertrouwd | Europa en omgeving, maximaal drie uur verschil |
| Uitdagen | Verder gelegen hoofdsteden, vanaf drieënhalf uur verschil |

De kaart past de uitsnede aan de afstand en schermverhouding aan. Nabije steden krijgen een ingezoomde Europese kaart; verre steden een breder deel van de wereld. De stadslabels hebben verbindingslijntjes naar hun geografische punten en wijken uit als ze elkaar of een stadsmarkering zouden afdekken. De kaart gebruikt zachte zeekleuren, lichte landen, subtiele landsgrenzen en gestippelde tijdzonegrenzen. Onderaan staan relatieve uurverschillen. De kleuren sluiten aan op het bestaande spel. iPad gebruikt een bredere kaart; voorbeelden houden een compactere kaart. In iPad-landschap wordt de kaart minder hoog, zodat de vraag en alle vier antwoorden samen in beeld passen.

De kaart heeft geen hoekbijschriften: geen titel, datum, legenda of 24-uursklok. Het uurverschil tussen de twee steden komt uit Foundation/IANA op de datum van vandaag om 12:00 UTC. De gekozen hoofdsteden houden hele of halve uurverschillen. New Delhi gebruikt de echte IANA-zone Asia/Kolkata. Hele-urenvragen sluiten halfuurverschillen uit; overige tijdsoorten behouden hun raster. De voorbeeldreeks eindigt zo nodig met een halve uurstap en toont bijvoorbeeld +5½. Recente bestemmingen worden afgewisseld. Zie de [herziene selectieregels](AdaptiveDifficultyVerification.md). De gestippelde banden blijven de vereenvoudigde winterkaart van 15 januari 2026; een band kan daardoor in de zomertijd een uur verschillen van het stadslabel. Een verre uitsnede houdt dezelfde vorm, maar schuift omhoog zodat er geen lege strook boven het land blijft. Alle antwoordkeuzes behouden de gekozen minutensoort, zijn uniek en bevatten het juiste antwoord precies eenmaal. Berekeningen over middernacht blijven geldig.

## Kaartgegevens

`Dino/Resources/TimeZoneMap.json` bevat lokaal gebundelde, vereenvoudigde geometrie uit [Natural Earth](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/), beschikbaar in het publieke domein:

- [Landsgrenzen, 1:110m](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson).
- [Tijdzones, 1:10m](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_time_zones.geojson).

De brongeometrie is vereenvoudigd met een tolerantie van 0,16 graad. Tijdzonekenmerken zijn naar de vaste lesdatum omgerekend met hun IANA-identificaties. Gewijzigde zones in Turkije, Marokko, Belarus, Jordanië, Syrië, Kazachstan, Armenië, Azerbeidzjan en Georgië zijn gecorrigeerd met landsgrenzen. Gebieden met hetzelfde uurverschil zijn samengevoegd. Het is een educatieve kaart met vereenvoudigde grenzen. Er is geen internetverbinding of kaartaccount nodig tijdens het spelen.

De geografische ligging van de oorspronkelijke 21 hoofdsteden is gecontroleerd tegen de gebundelde tijdzonevlakken en de IANA-offset op de lesdatum; alle bestemmingen liggen in het passende tijdzonevlak.

## Verificatie

De kerncontroles dekken beide talen, alle zes minutensoorten, verschillende hoofdsteden en tijdzones, vier unieke antwoordkeuzes, middernacht en de uitsnede op smalle voorbeelden, iPhone en iPad. Alle mogelijke hoofdstadlabels worden op vijf kaartformaten gecontroleerd op overlap, afsnijden en het afdekken van stadsmarkeringen.

De gerichte UI-tests zijn `testTimeZoneAtlasCapitalsAndAnswerReveal`, `testTimeZoneAtlasEnglishUsesLondon` en de bestaande `testExpandedExamplesRefreshTheirQuestionAndAnswer`. Ze controleren titel, referentietijd, verborgen bestemmingstijd, voorbeeldverversing, antwoordonthulling en iPad-landschap.

De controle `--time-zones` in `DinoCoreTests` dekt ook korte minutencorrecties in beide richtingen, over middernacht en bij nul verschil. Op 29 oktober 2026 slaagden **43.097** tijdzone-, animatie- en kaartindelingscontroles. `testTimeZoneCardReplayInBothLanguages` controleert het opnieuw afspelen tijdens voorbeelden en antwoorduitleg, herstarten tijdens het afspelen, de vaste referentietijd en de positie van de replayknop binnen het bestemmingskaartje.

De replaytest slaagde in Nederlands en Engels op iPhone 18 Pro en iPad Pro 13-inch (iOS 27), inclusief iPad-landschap. De tikken raken het midden van de zichtbare knop: SwiftUI geeft bij gepositioneerde kaartlabels niet altijd een bruikbaar toegankelijkheidsactivatiepunt terug. Visueel gecontroleerd: [voorbeeld op iPhone](Screenshots/TimeZoneQuestions/iphone-in-card-example.png) en [antwoorduitleg op iPad](Screenshots/TimeZoneQuestions/ipad-in-card-answer.png). De losse klokkenrij ontbreekt.

Ook de volledige kernsuite slaagde: **1.228.552 controles**. De bronbestanden zijn voor deze run gekopieerd naar een tijdelijke momentopname, omdat andere wijzigingen in dezelfde werkmap tijdens compilatie werden opgeslagen. De vertaalcatalogus is daarbij meegelezen; assets zijn vanuit de projectmap gecontroleerd. De simulatorbuild, de vertaalcatalogus en `git diff --check` zijn geslaagd.

Op 16 oktober 2026 geslaagd:

- `Tools/test-dino.sh`: **662.340 controles**.
- Beide nieuwe UI-tests op iPhone 17 Pro en iPad Pro 11-inch, iOS 26.5.
- De bestaande UI-test voor het verversen van uitgebreide voorbeelden op iPhone.
- Aanvullende iPad-run met controles dat titel en onderste antwoordrij na draaien volledig binnen het zichtbare vraaggebied staan.
- Definitieve simulatorbuild en `git diff --check`.

Visueel gecontroleerd: [nabije steden op iPhone](Screenshots/TimeZoneQuestions/iphone-nearby.png), [verre steden op iPhone](Screenshots/TimeZoneQuestions/iphone-worldwide.png), [Engelse vraag](Screenshots/TimeZoneQuestions/iphone-english.png), [voorbeeldkaart](Screenshots/TimeZoneQuestions/iphone-example.png) en [iPad-landschap](Screenshots/TimeZoneQuestions/ipad-landscape.png).
