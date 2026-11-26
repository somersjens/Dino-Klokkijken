# Canadees Engels in Dino Klokkijken

De App Store-code, Xcode-bundel en voorkeur voor de voorleesstem zijn `en-CA`. In de app heet de keuze **English (Canada)**. De appnaam blijft *Learn to Tell Time with Dino* en onder het appicoon staat *Dino Time*. De regionale versie gebruikt *colour*, *grey* en *Start practising*. Het zelfstandig naamwoord blijft *practice*. De provincie British Columbia gebruikt *analog clock* in haar rekenprogramma, dus die benaming delen we met de Engelse basis. Apple’s productnaam *Game Center* komt ook in Canadese teksten zo voor. [Apple’s App Store-codes](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes.md) · [Language Portal of Canada over spelling](https://our-languages.canada.ca/en/writing-tips-plus/spelling-international-variations) · [Practice en practise](https://our-languages.canada.ca/en/writing-tips-plus/practice-practise) · [British Columbia Mathematics 4](https://curriculum.gov.bc.ca/curriculum/mathematics/4)

Bewerk gedeelde tekst onder `en` en Canadese spellingregels in het synchronisatiescript. Draai daarna `python3 Tools/sync-english-localizations.py` om de volledige Canadese bundel te vullen. SwiftUI gebruikt die volledige bundel bij het opzoeken van lokale sleutels. `--check` controleert of de gegenereerde teksten gelijklopen met de Engelse bron. [Synchronisatiescript](../Tools/sync-english-localizations.py)

## Kloktaal en beoordeling

De gedeelde Engelse les oefent *o’clock*, *past*, *half past* en *to*. Het rekenprogramma van British Columbia gebruikt onder meer *half past* en *quarter to* en behandelt analoge klokken, digitale klokken, de twee uurcycli en minuten. In tekst komen vormen als *seven fifteen* en *seven thirty* ook voor. Bij de woordstenen kiest het kind uit de aangeboden woorden voor de analoge formulering. Als het een klok kiest of instelt, wordt het tijdstip beoordeeld. [British Columbia Mathematics 4](https://curriculum.gov.bc.ca/curriculum/mathematics/4) · [Language Portal of Canada over geschreven en gesproken tijden](https://our-languages.canada.ca/en/writing-tips-plus/time-of-day)

| Tijd | Formulering met woordstenen | Uur en referentie in de uitleg |
| --- | --- | --- |
| 07:00 | seven o’clock | 7, het hele uur |
| 07:01 | one past seven | 7, 1 minuut na het hele uur |
| 07:05 | five past seven | 7, 5 minuten na het hele uur |
| 07:14 | fourteen past seven | 7, 14 minuten na het hele uur |
| 07:15 | quarter past seven | 7, 15 minuten na het hele uur |
| 07:16 | sixteen past seven | 7, 16 minuten na het hele uur |
| 07:20 | twenty past seven | 7, 20 minuten na het hele uur |
| 07:25 | twenty-five past seven | 7, 25 minuten na het hele uur |
| 07:29 | twenty-nine past seven | 7, 29 minuten na het hele uur |
| 07:30 | half past seven | 7, een halfuur na het hele uur |
| 07:31 | twenty-nine to eight | 8, 29 minuten vóór het volgende uur |
| 07:35 | twenty-five to eight | 8, 25 minuten vóór het volgende uur |
| 07:40 | twenty to eight | 8, 20 minuten vóór het volgende uur |
| 07:44 | sixteen to eight | 8, 16 minuten vóór het volgende uur |
| 07:45 | quarter to eight | 8, 15 minuten vóór het volgende uur |
| 07:46 | fourteen to eight | 8, 14 minuten vóór het volgende uur |
| 07:55 | five to eight | 8, 5 minuten vóór het volgende uur |
| 07:59 | one to eight | 8, 1 minuut vóór het volgende uur |
| 08:00 | eight o’clock | 8, nieuw uur |

De digitale klok volgt de gekozen of automatische uurcyclus. De `en-CA`-formatter van Apple toont bijvoorbeeld `5:05 PM` voor 17:05 en behoudt `17:05` in 24-uursmodus. In begeleidende tekst zijn *a.m.* en *p.m.* gangbaar. 00:00 en 00:05 vallen in `AM`, 12:00, 12:05 en 23:59 in `PM`. Bij rekenen komt 00:05 tien minuten na 23:55, en 23:55 tien minuten vóór 00:05. De begrippen *morning*, *afternoon*, *evening* en *night* volgen dezelfde instelbare daggrenzen als de gedeelde Engelse les. [Language Portal of Canada over tijdnotatie](https://our-languages.canada.ca/en/writing-tips-plus/time-of-day)

## Tijdzones en stem

De tijdzonevragen beginnen in Ottawa. Halifax is één uur later en Regina één of twee uur vroeger, afhankelijk van het seizoen in Ottawa. St. John’s is anderhalf uur later in oefeningen die een halfuur verschil toelaten. De drie provinciehoofdsteden worden aan het Canadese aanbod toegevoegd en iedere berekening gebruikt de tijdzone van de stad en de referentiedatum van de vraag. [Provincies en hoofdsteden](https://www.canada.ca/en/intergovernmental-affairs/services/provinces-territories.html) · [Canadese tijdzones en zomertijd](https://nrc.canada.ca/en/certifications-evaluations-standards/canadas-official-time/time-zones-daylight-saving-time)

De stemkeuze geeft `en-CA` voorrang. Als die stem ontbreekt, kan de app een andere geschikte geïnstalleerde Engelse stem gebruiken. De Nederlandse en Duitse spellen hebben hun eigen taalprofiel. [Apple over taal en regio bij voorlezen](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice/language)

## Controle in het project

- `Tools/test-dino.sh --canadian-localization` vergelijkt de spreekvragen op alle 1.440 tijdstippen met de gedeelde Engelse les, controleert de voorbeelden in de tabel, de tijdweergave rond middag en middernacht, de stemvoorkeur, de zes tijdfamilies en twintig vraagtypen, en alle tijdzoneniveaus per kalendermaand.
- De iOS-tests controleren geërfde Engelse teksten, Canadese spelling, de lesroute en Ottawa als beginstad op een gebouwd toestelprofiel. De volledige kernsuite omvat ook de Nederlandse, generiek Engelse en Duitse regressies.
- De verificatie slaagde met 2.086 gerichte Canadese controles, 2.504.006 controles in de volledige kernsuite en vijf UI-tests op iPhone en iPad. De Canadese bundel is gecontroleerd tegen de Engelse bron en de veertien regionale tekstafwijkingen. De simulators controleerden ook de Duitse les en het terugschakelen van een opgeslagen taalkeuze naar de systeemtaal.
- Voor publicatie staan een onafhankelijke Canadese taalreview, het daadwerkelijk beluisteren van de stem en VoiceOver op een fysiek toestel, en de definitieve App Store-screenshots open.

## App Store-tekst voor Canada

| Veld | Voorstel |
| --- | --- |
| Appnaam | Learn to Tell Time with Dino |
| Ondertitel | Read analog & digital clocks |
| Promotietekst | Practise telling time with Dino. Explore ten worlds, build your own clocks and learn at your own pace. |
| Zoekwoorden | clock,analog,digital,math,grade,minutes,hours,practice,elapsed,school,timetable |
| Versietekst | Canadian English is now available, with Canadian spelling and time-zone questions that start in Ottawa. |

**Description**

What time is half past seven? Join Dino in ten worlds with 100 levels and learn to read analog and digital clocks.

Read whole hours, half hours and quarter hours. Move the clock hands, build times with word tiles and work out how many minutes go by. Later, try timetables, flight times and time zones.

Choose the times you want to practise and see how the examples work. Give your Dino your favourite colours and design clocks of your own.

| Screenshot | Tekstvoorstel |
| --- | --- |
| Klok aflezen | Read the clock hands |
| Spreekvraag | Say it in words |
| Klok zetten | Set the time yourself |
| Wereldkaart | Explore ten worlds with Dino |
| Oefenmenu | Practise at your own pace |
| Tijdzonekaart | What time is it in Halifax? |

Voor de Canadese winkelpagina zijn de bestaande Engelse contactpagina en privacyverklaring geschikte projectlinks. Gebruik voor Game Center de Engelse `name`, `before` en `after` van de 16 achievements en `titleEN` van de 12 ranglijsten als tekst voor `en-CA`. De namen en beschrijvingen hebben geen regionale spellingvarianten nodig. [Ondersteuning](https://www.hakketjak.com/dino-time/contact/#en) · [Privacyverklaring](https://www.hakketjak.com/dino-time/privacy/#en) · [Achievements in het project](GameCenterAchievements.json) · [Ranglijsten in het project](GameCenterLeaderboards.json) · [Apple over de winkelvelden](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
