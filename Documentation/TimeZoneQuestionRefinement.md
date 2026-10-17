# Vraagtype 19: hoofdsteden op een platte wereldkaart

De vraag noemt direct de gezochte hoofdstad, bijvoorbeeld **Hoe laat is het in Ankara?** De kaart toont precies twee stadsmarkeringen. Bij de groene referentiestad staat de gegeven tijd onder het punt; bij de oranje bestemming staan een vraagteken en het uurverschil. Die tijd is rood als de stad eerder is en lichtgroen — dezelfde kleur als een positief uurverschil — als de stad later is. Een goed antwoord en **Toon antwoord** tonen de bestemmingstijd. Een foute eerste poging houdt de tijd verborgen.

Het voorbeeld zet twee dezelfde klokken naast elkaar, met een grijs **+0** ertussen. Dat ene verschilknopje wordt daarna **+1** of **−1**, dan **+2** of **−2**, en de rechterklok verandert mee. Een positief verschil blijft lichtgroen; elk negatief verschil, zoals **−1** of **−2**, is rood. Die kleur geldt in het voorbeeld en onder de vraag. Bij de echte nieuwe tijd stopt het, en pas dan verschijnt die tijd ook bij de bestemming op de kaart. Na een fout antwoord verschijnt diezelfde reeks onder de kaart zodra het goede antwoord volgt, of via **Toon antwoord**.

De gekozen speltaal bepaalt de referentiestad: Nederlands gebruikt Amsterdam, Engels Londen. Dit is een eenvoudige taalvoorkeur, zonder locatiegegevens. De overige steden zijn echte hoofdsteden van bekende landen. Turkije gebruikt Ankara; Istanbul is geen hoofdstad. Een paar gebruikt altijd verschillende landen én verschillende tijdzones.

| Gekozen tijdsoort | Bereik |
| --- | --- |
| Hele en halve uren | Hoofdsteden in Europa met één uur verschil |
| Kwartieren en tien minuten | Europa en omgeving, maximaal drie uur verschil |
| Vijf minuten en mix | Verder gelegen hoofdsteden, minimaal vier uur verschil |

De kaart past de uitsnede aan de afstand en schermverhouding aan. Nabije steden krijgen een ingezoomde Europese kaart; verre steden een breder deel van de wereld. De stadslabels hebben verbindingslijntjes naar hun geografische punten en wijken uit als ze elkaar of een stadsmarkering zouden afdekken. De kaart gebruikt zachte zeekleuren, lichte landen, subtiele landsgrenzen en gestippelde tijdzonegrenzen. Onderaan staan relatieve uurverschillen. De kleuren sluiten aan op het bestaande spel. iPad gebruikt een bredere kaart; voorbeelden houden een compactere kaart. In iPad-landschap wordt de kaart minder hoog, zodat de vraag en alle vier antwoorden samen in beeld passen.

De kaart heeft geen hoekbijschriften: geen titel, datum, legenda of 24-uursklok. Het uurverschil tussen de twee steden komt uit Foundation/IANA op de datum van vandaag om 12:00 UTC. De gekozen hoofdsteden houden hele uurverschillen. De gestippelde banden blijven de vereenvoudigde winterkaart van 15 januari 2026; een band kan daardoor in de zomertijd een uur verschillen van het stadslabel. Een verre uitsnede houdt dezelfde vorm, maar schuift omhoog zodat er geen lege strook boven het land blijft. Alle antwoordkeuzes behouden de gekozen minutensoort, zijn uniek en bevatten het juiste antwoord precies eenmaal. Berekeningen over middernacht blijven geldig.

## Kaartgegevens

`Dino/Resources/TimeZoneMap.json` bevat lokaal gebundelde, vereenvoudigde geometrie uit [Natural Earth](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/), beschikbaar in het publieke domein:

- [Landsgrenzen, 1:110m](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson).
- [Tijdzones, 1:10m](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_time_zones.geojson).

De brongeometrie is vereenvoudigd met een tolerantie van 0,16 graad. Tijdzonekenmerken zijn naar de vaste lesdatum omgerekend met hun IANA-identificaties. Gewijzigde zones in Turkije, Marokko, Belarus, Jordanië, Syrië, Kazachstan, Armenië, Azerbeidzjan en Georgië zijn gecorrigeerd met landsgrenzen. Gebieden met hetzelfde uurverschil zijn samengevoegd. Het is een educatieve kaart met vereenvoudigde grenzen. Er is geen internetverbinding of kaartaccount nodig tijdens het spelen.

De geografische ligging van alle 21 hoofdsteden is gecontroleerd tegen de gebundelde tijdzonevlakken en de IANA-offset op de lesdatum; alle bestemmingen liggen in het passende tijdzonevlak.

## Verificatie

De kerncontroles dekken beide talen, alle zes minutensoorten, verschillende hoofdsteden en tijdzones, vier unieke antwoordkeuzes, middernacht en de uitsnede op smalle voorbeelden, iPhone en iPad. Alle mogelijke hoofdstadlabels worden op vijf kaartformaten gecontroleerd op overlap, afsnijden en het afdekken van stadsmarkeringen.

De gerichte UI-tests zijn `testTimeZoneAtlasCapitalsAndAnswerReveal`, `testTimeZoneAtlasEnglishUsesLondon` en de bestaande `testExpandedExamplesRefreshTheirQuestionAndAnswer`. Ze controleren titel, referentietijd, verborgen bestemmingstijd, voorbeeldverversing, antwoordonthulling en iPad-landschap.

Op 16 oktober 2026 geslaagd:

- `Tools/test-dino.sh`: **662.340 controles**.
- Beide nieuwe UI-tests op iPhone 17 Pro en iPad Pro 11-inch, iOS 26.5.
- De bestaande UI-test voor het verversen van uitgebreide voorbeelden op iPhone.
- Aanvullende iPad-run met controles dat titel en onderste antwoordrij na draaien volledig binnen het zichtbare vraaggebied staan.
- Definitieve simulatorbuild en `git diff --check`.

Visueel gecontroleerd: [nabije steden op iPhone](Screenshots/TimeZoneQuestions/iphone-nearby.png), [verre steden op iPhone](Screenshots/TimeZoneQuestions/iphone-worldwide.png), [Engelse vraag](Screenshots/TimeZoneQuestions/iphone-english.png), [voorbeeldkaart](Screenshots/TimeZoneQuestions/iphone-example.png) en [iPad-landschap](Screenshots/TimeZoneQuestions/ipad-landscape.png).
