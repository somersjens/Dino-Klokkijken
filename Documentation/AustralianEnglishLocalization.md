# Australisch Engels in Dino Klokkijken

De App Store-code, de Xcode-bundel en de voorkeur voor de voorleesstem zijn `en-AU`. De app biedt **English (Australia)** aan en toont *Dino Time* onder het appicoon. De regionale teksten gebruiken onder meer *colour*, *grey*, *personalise* en *synchronised*. *Practise* is het werkwoord en *practice* het zelfstandig naamwoord. De les gebruikt *analog clock*, de spelling van het Australische rekenprogramma. [Apple’s App Store-codes](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes.md) · [Australian Government Style Manual over spelling](https://www.stylemanual.gov.au/grammar-punctuation-and-conventions/spelling) · [Practice en practise](https://www.stylemanual.gov.au/style-manual-resources/quick-guides/quick-guide-common-misspellings-and-word-confusion) · [Australian Curriculum AC9M2M04](https://www.australiancurriculum.edu.au/resources/work-samples/mathematics/year-2/ws04-measuring-time/)

Bewerk gedeelde tekst onder `en`. Draai `python3 Tools/sync-english-localizations.py` om de volledige Australische en Canadese stringtabellen te vullen. Gebruik `--check` om te controleren of die tabellen gelijklopen met de bron. [Synchronisatiescript](../Tools/sync-english-localizations.py)

## Kloktaal, antwoord en uitleg

De bestaande Engelse les oefent *o’clock*, *quarter past*, *half past* en *quarter to*, zoals het Australische rekenprogramma. Na het halve uur benoemt de analoge les het volgende uur. De woordstenen beoordelen de aangeboden analoge zin. Bij een klok kiezen of instellen telt het tijdstip. Digitale formuleringen zoals *seven fifteen* en *seven thirty* geven hetzelfde tijdstip weer. [Australian Curriculum, uitwerking voor Year 2](https://www.australiancurriculum.edu.au/curriculum-information/revised-f-2-australian-curriculum-mathematics/revised-f-2-mathematics-content/)

| Tijd | Formulering met woordstenen | Referentie in de uitleg |
| --- | --- | --- |
| 07:00 | seven o’clock | precies 7 uur |
| 07:01 | one past seven | 1 minuut na 7 |
| 07:05 | five past seven | 5 minuten na 7 |
| 07:14 | fourteen past seven | 14 minuten na 7 |
| 07:15 | quarter past seven | 15 minuten na 7 |
| 07:16 | sixteen past seven | 16 minuten na 7 |
| 07:20 | twenty past seven | 20 minuten na 7 |
| 07:25 | twenty-five past seven | 25 minuten na 7 |
| 07:29 | twenty-nine past seven | 29 minuten na 7 |
| 07:30 | half past seven | 30 minuten na 7 |
| 07:31 | twenty-nine to eight | 29 minuten vóór 8 |
| 07:35 | twenty-five to eight | 25 minuten vóór 8 |
| 07:40 | twenty to eight | 20 minuten vóór 8 |
| 07:44 | sixteen to eight | 16 minuten vóór 8 |
| 07:45 | quarter to eight | 15 minuten vóór 8 |
| 07:46 | fourteen to eight | 14 minuten vóór 8 |
| 07:55 | five to eight | 5 minuten vóór 8 |
| 07:59 | one to eight | 1 minuut vóór 8 |
| 08:00 | eight o’clock | precies 8 uur |

De lokale formatter gebruikt `am` en `pm` in kleine letters en een vaste spatie bij de 12-uursnotatie. De spelinstelling of apparaatvoorkeur bepaalt de gewone uurcyclus. De speciale 24-uursles begint altijd met een 24-uursklok. Na een fout toont de hint bijvoorbeeld hoe 17:05 naar 5:05 pm wordt omgezet. Het voorbeeld noemt ook *midday* en *midnight*. De dagdelen blijven instelbaar. Over de daggrens wordt 23:55 plus tien minuten 00:05 en 00:05 min tien minuten 23:55. [Australian Government Style Manual over datums en tijden](https://www.stylemanual.gov.au/grammar-punctuation-and-conventions/numbers-and-measurements/dates-and-time)

| 24 uur | 12 uur |
| --- | --- |
| 00:00 | 12:00 am |
| 00:05 | 12:05 am |
| 12:00 | 12:00 pm |
| 12:05 | 12:05 pm |
| 17:05 | 5:05 pm |
| 23:59 | 11:59 pm |

## Tijdzones en stem

De vragen beginnen in Canberra. Vanuit Canberra is Brisbane tijdens de Australische zomertijd één uur vroeger. Buiten die periode hebben de steden dezelfde tijd en is Nouméa één uur later. Adelaide ligt het hele jaar dertig minuten achter Canberra. Darwin ligt in januari negentig minuten en in juli dertig minuten achter. Perth ligt in januari drie en in juli twee uur achter. De datum van de opgave verschijnt als bijvoorbeeld *15 January*. De les gebruikt de IANA-zones van de steden op die datum. Opgaven met hele uren kiezen bestemmingen met een geheel uurverschil. [Tourism Australia over tijdzones](https://www.australia.com/en-gb/facts-and-planning/about-australia/time-zones.html) · [ACT Government over zomertijd](https://www.act.gov.au/living-in-the-act/public-holidays-school-terms-and-daylight-saving) · [Nouvelle-Calédonie over UTC+11](https://mobi-juridoc.gouv.nc/juridoc/jdjonc.nsf/F344DFB93200E7454B2583CA0014F274/%24File/9709.pdf?openelement=)

De stemkeuze geeft een geïnstalleerde Australische stem voorrang. Als die ontbreekt, kan een andere geschikte Engelse stem voorlezen. [Apple over regionale stemmen](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice/language)

## Verificatie

- `Tools/test-dino.sh --australian-localization` controleert de spreekvraag op alle 1.440 tijdstippen, referentie-uren in de hints, de twee uurcycli, stemvoorkeur, generatie en beoordeling voor alle vraagtypen en tijdsoorten en de tijdzones in elke maand en rond beide zomertijdovergangen.
- De 2.333 Australische controles en 2.506.339 controles in de volledige kernsuite zijn geslaagd. In de Xcode-build staan 566 Australische spelstrings en drie Info.plist-waarden. Van de spelstrings wijken er 17 af van de gedeelde Engelse tekst.
- De iOS-tests openen de app in Australisch Engels, toetsen de taalkeuze op een bestaande speler en controleren de voorbeeldtekst en foutuitleg van de 24-uursles. Op iPhone en iPad is de tijdzonekaart vanuit Canberra in portret en landscape getest. De bestaande Nederlands-Engelse klokles, de Duitse 24-uursles en de Canadese tijdzonekaart zijn als regressie getest.
- Voor publicatie staan een onafhankelijke Australische taalreview, het beluisteren van de lokale stem en VoiceOver op een fysiek toestel, een upgrade vanaf een eerdere App Store-build op een toestel en de definitieve App Store-screenshots open. Laat de taalreviewer specifiek luisteren naar *one past*, *quarter to*, de precieze minuten en de uitspraak van plaatsnamen.

## App Store-concept voor Australië

| Veld | Voorstel |
| --- | --- |
| Appnaam | Tell the Time with Dino |
| Ondertitel | Read analog & digital clocks |
| Promotietekst | Practise telling the time with Dino. Explore ten worlds, read analog and digital clocks, and make your own. |
| Zoekwoorden | maths,minutes,hours,practise,elapsed,school,timetable,quarter,half,year 2 |
| Versietekst | Australian English is now available, with local spelling, am and pm clock displays, and time-zone questions starting in Canberra. |

**Description**

What time is half past seven? Join Dino in ten worlds with 100 levels and learn to read analog and digital clocks.

Read the hour, half hour and quarter hour. Move the clock hands, build times with word tiles and work out how many minutes go by. As you progress, try timetables, flight times and time zones.

Choose the times you want to practise, work through examples and personalise your clocks and Dino with your favourite colours.

| Screenshot | Tekstvoorstel |
| --- | --- |
| Klok aflezen | Read the clock hands |
| Spreekvraag | Say it in words |
| Klok zetten | Set the time yourself |
| Wereldkaart | Explore ten worlds with Dino |
| Oefenmenu | Practise at your own pace |
| Tijdzonekaart | Start your journey in Canberra |

Gebruik de bestaande Engelse contactpagina en privacyverklaring. Naam en ondertitel tellen 23 en 28 tekens. De zoekwoorden tellen 73 UTF-8-bytes. [Ondersteuning](https://www.hakketjak.com/dino-time/contact/#en) · [Privacyverklaring](https://www.hakketjak.com/dino-time/privacy/#en) · [App Store-velden en limieten](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) · [Naam en ondertitel](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-compliance-information/)

Gebruik voor Game Center de bestaande Engelse `name`, `before` en `after` voor de 16 achievements en `titleEN` voor de 12 ranglijsten. De Engelse formuleringen passen ook in Australië. Gebruik dezelfde IDs, het bestaande gehele scoreformaat en de bestaande beelden bij het toevoegen van `en-AU` in App Store Connect. [Achievements in het project](GameCenterAchievements.json) · [Ranglijsten in het project](GameCenterLeaderboards.json) · [Apple over achievements](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-achievements/) · [Apple over ranglijsten](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/)
