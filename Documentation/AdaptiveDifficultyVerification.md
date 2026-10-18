# Verborgen vraagmoeilijkheid — 18 oktober 2026

De 20 oefentypen delen met het avontuur één vraaggenerator. Elke combinatie van vraagtype en tijdsoort heeft drie interne stappen: `introduction`, `familiar` en `challenge`. Dat levert **20 × 6 × 3 = 360 categorieën** op. De speler krijgt geen moeilijkheidskeuze, badge, extra level of nieuw label voor deze stappen.

## Minuutgroepen en nadruk

| Tijdsoort | Mogelijke minuten / antwoordopties | Kennismaken | Vertrouwd | Uitdagen |
| --- | --- | --- | --- | --- |
| Hele uren | 00 | Duidelijke wijzerstanden, twee keuzes | Alle uren, vier gevarieerde keuzes | Vergelijkbare klokstanden en naburige uren |
| Halve uren | 00, 30 | Halve uren met duidelijke wijzerstanden | Meer uren en opties | Vergelijkbare standen en moeilijker tijdrekenen |
| Kwartieren | 00, 15, 30, 45 | Kwart over, herhaling van heel/half | Kwart over en half | Nadruk op kwart voor |
| 10 minuten | 00, 10, 20, 30, 40, 50 | Tien over | Twintig en veertig | Nadruk op tien voor |
| 5 minuten | Alle veelvouden van vijf, inclusief 00 | Vijf en tien over | Minuten rond half | Nadruk op vijftig en vijfenvijftig |
| Minuten | 00–59, bediening per minuut | Exacte minuten vóór het kwartier | Exacte minuten rond half | Exacte minuten richting het volgende uur |

De generator kiest in circa 75% van de trekkingen de nadruk van de actuele stap. De overige trekkingen herhalen bekende posities. Op de uitdagende stap kan iedere minuut van de gekozen groep het juiste antwoord zijn; opties gebruiken steeds de volledige groep. Kwartiervragen bevatten dus ook halve uren en vijfminutenvragen kunnen bijvoorbeeld :00, :15, :30 en :45 als juist antwoord of alternatief aanbieden.

Eenvoudige meerkeuzevragen bieden bij kennismaken twee antwoorden, daarna vier. Goed/fout behoudt twee opties, dagdelen vier en de koppel- en sorteerborden hun bestaande omvang. Bij kennismaken liggen afleiders verder uit elkaar; bij uitdagen liggen minuten en uren dichter bij elkaar. Hele en halve uren krijgen daardoor ook drie onderscheidbare stappen.

Rekenvragen veranderen daarnaast inhoudelijk: eerst één minuutstap, daarna meer stappen en uiteindelijk gecombineerde uur-/minuutbewegingen. Eenvoudige optel-, aftrek- en reeksopgaven vermijden middernacht en waar mogelijk een uurovergang. Verstreken tijd groeit van één stap via maximaal 90 naar maximaal 180 minuten. Treinopgaven krijgen langere activiteiten. Vluchten beginnen met alleen tijdsduur en voegen daarna kleine en grotere tijdzoneverschillen toe. Wereldkaarten beginnen met één uur verschil, gebruiken vervolgens regionale en uiteindelijk verre hoofdsteden. Dit werkt binnen iedere tijdsoort.

`Zeg de tijd` ondersteunt ook alle losse minuten in Nederlands en Engels. Bestaande woorden voor vijf minuten, kwartieren en halve uren blijven behouden; andere minuten krijgen een passende selecteerbare woordvorm.

## Aanpassing tijdens het spelen

- Een nog onbekende combinatie begint bij kennismaken, ook bij rechtstreeks starten van een boss.
- Drie goede **eerste** antwoorden achter elkaar verhogen de interne leerstand met één stap.
- Een fout eerste antwoord verlaagt de opgeslagen stand met één stap, begrensd op kennismaken. Ook de direct volgende vraag krijgt maximaal die lagere stap, wanneer een gemengde reeks van vraagtype wisselt.
- Een goede herkansing, extra fouttik, getoond antwoord, onbeantwoorde vraag of voorbeeld verandert de leerstand niet opnieuw.
- In avontuur bepaalt iedere vraagcombinatie in de [vaste leerlijn](LevelCurriculum.md) de basis. Een eerste kennismaking blijft eenvoudig. Een opgeslagen terugval na een fout verlaagt de basis tijdelijk; na drie goede eerste antwoorden per stap herstelt het geplande niveau. Een goede route bereikt daardoor werkelijk de moeilijkste vragen aan het einde.
- Alleen een nog onbeantwoorde vervolgvraag wordt zo nodig vervangen. Vraag-ID, vraagtype, aantal vragen, oorspronkelijke score en gemeten antwoordtijd blijven behouden.

De leerstand staat lokaal in `dino.learning.records.v1`, apart van sterren, oefenrecords en Game Center-/iCloud-resultaten. Hij wordt per combinatie bewaard, hervat na herstart en gewist bij voortgang resetten of alle gegevens verwijderen. Oefenen en avontuur delen deze leerstand. De oude tijdskeuze `mix` en zijn oefenrecords worden bij laden naar `minutes` omgezet; de vraagvolgorde Mix blijft bestaan.

## Controle

`Tools/test-dino.sh`: **803.571 controles geslaagd**, inclusief 72.381 nieuwe controles voor de adaptieve moeilijkheid. De nieuwe controles doorlopen alle 360 categorieën in beide talen, controleren reproduceerbaarheid, minuutgroepen en context, unieke antwoorden, correcte sommen, nadruk versus herhaling, alle zestig gesproken minuutstanden, vooruitgang en terugval, gemengde vervolgvraag, boss-aanpassing, opeenvolgende doeltijden na aanpassing, herkansingen, voorbeelden, opslag/herstart, migratie en beide resets.

De Debug-build voor iOS Simulator slaagt. `testExactMinutesAndHiddenDifficultyProgression` slaagt op **iPhone 17** en **iPad (A16)** met iOS 26.5: zes goede eerste antwoorden laten de opbouw van twee naar vier opties zien, een fout krijgt een lichtere vervolgvraag, de interne namen ontbreken op het scherm en de minutenknop verandert de invoer met één minuut.

Op iPad slaagt bovendien `testPracticeAscendingAndMixCoverAllTypes`: alle twintig typen in Oplopend en Mix, de overgang naar een nieuwe cyclus, de voorbeeldkaarten en de verschillende antwoordborden. De doorlopende digitale oefensessie met twaalf vragen slaagt afzonderlijk op iPhone. De volledige reeks met alle vraagtypen is in deze controle op iPad uitgevoerd; de iPhone-hercontrole richtte zich op de adaptieve flow en minutenbediening.
