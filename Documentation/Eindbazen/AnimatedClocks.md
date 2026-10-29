# Transparante eindbazen met bewegende klokvlakken

De exports van 27 oktober 2026 vervangen de eerdere afbeeldingen met witte achtergrond. De tien actieve assetnamen blijven `boss-<thema>-<art-ID>`. De oorspronkelijke PNGs staan ongewijzigd in [References](References); ze worden niet meer in de assetcatalogus opgenomen.

De nieuwe exportvolgorde verschilt van de bestaande art-ID's:

| Speelwereld | Thema / art-ID | Nieuwe export | Klokvlakken |
| --- | --- | --- | --- |
| 1 | Jungle / 1 | 1 | 1 bronzen halsklok |
| 2 | Woestijn / 7 | 5 | 1 grote klok aan leren banden |
| 3 | Vulkaan / 3 | 2 | 3 gouden klokbroches op de sjerp |
| 4 | Klokdorp / 4 | 3 | 1 gouden klok op de staf |
| 5 | Kristalgrot / 5 | 4 | 1 borstklok tussen kristallen |
| 6 | Klokstad / 6 | 10 | 2 gouden klokken op de vleugels |
| 7 | Slaapvallei / 2 | 9 | 1 klok in het dekentje |
| 8 | Tijdmachine / 8 | 6 | 2 klokjes op de hoed |
| 9 | Tijdpiraten / 9 | 7 | 1 hangende klok aan de papegaai |
| 10 | Tijdkasteel / 10 | 8 | 1 klok in de kroon |

`WorldBossArt.swift` tekent de veertien klokvlakken met een roomkleurig verloop, twaalf afgeronde uurmarkeringen, afzonderlijke taps toelopende wijzers, een kleine slagschaduw en een gouden as. Jungle en Woestijn gebruiken donkere wijzers; de overige klokken blauwgroene wijzers. De foto bevat de oorspronkelijke rand, glasvorm, bevestiging en eventuele vingers. Het omgekeerde alfakanaal begrenst de shapes exact tot de uitgesneden klokvlakken. Ook het half afgedekte klokje van de triceratops behoudt zijn occlusie.

`WorldClockMotion` deelt de snelheidsafspraak met Klokstad: de minutenwijzer van Klokstad doet 24 seconden over een omwenteling, die van de eindbazen 12 seconden. De uurwijzer beweegt in de juiste verhouding mee en doet 144 seconden over een omwenteling. Berekening gebeurt rechtstreeks uit verstreken tijd; er is geen opeenstapeling van timerfouten. Alle kaartklokken volgen dezelfde kaartanimatie-epoch.

De landschappen, dino's en bevestigingen blijven in hun bestaande statische lagen. Een klein Canvas boven ieder klokgebied vernieuwt alleen de klokvlakken met maximaal 30 beelden per seconde. Buiten de viewport en wanneer de app inactief is, staat de tijdlijn stil. **Verminder beweging** toont de oorspronkelijke klokstand zonder animatie. Wereldpreviews gebruiken dezelfde renderer en een afzonderlijke kleine kloklaag. De klokken van Klokstad delen de dieptelaag van hun dino, zodat een dichterbij staand huis ook de bijbehorende klok correct afdekt; de jungle gebruikt de bestaande voorgrondmaskers.

Verificatie: de gerichte coretest `--boss-clocks` voert 4.618 controles uit op de dubbele snelheid, de uur/minuutverhouding, overgangen over twaalf, volledige omwentelingen, negatieve begintijd en de dagovergang. Native renders op twee tijdstippen controleren beweging in ieder van de veertien vlakken; buiten de klokgebieden verandert geen enkele pixel van de dino's.

De simulatorbuild en de bestaande audit van alle tien eindbaaslevels zijn geslaagd op een afzonderlijke iPhone 18 Pro-simulator met iOS 27. De audit opent iedere kaart en levelkaart; alle tien levelkaarten blijven speelbaar.

Na de correctie aan de dieptelaag van de stad is `testWorldBossSceneryRemainsPlayable` opnieuw gericht voor wereld 6 geslaagd. Het klokvlak achter de voorste gevel blijft afgedekt; de zichtbare vleugelklok draait mee.
