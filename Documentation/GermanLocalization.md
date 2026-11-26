# Duitse lokalisatie voor Dino Klokkijken

De Duitse app kiest standaard Duits voor Duitsland. De in-app taalcode en Xcode-bundelcode zijn `de`. App Store Connect, de formatteerlocale en de gewenste voorleesstem gebruiken `de-DE`. Andere Duitse systeemregio’s kunnen dezelfde Duitse appteksten gebruiken. De klokles richt zich op algemeen verstaanbaar Duits uit Duitsland. [Apple’s App Store-codes](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes.md)

## Kloktaal en nakijken

De spreekles gebruikt bij de volle uren en losse minuten de volgorde **uur, Uhr, minuten**. De vijfminutenstappen oefenen de gebruikelijke zinnen met *vor*, *nach* en *halb*. De vraag zegt welke constructie wordt geoefend. Het voorbeeld, de antwoordstenen, de beoordeling en de markering op de klok gebruiken dezelfde regel. De vormen *ein Uhr* en *fünf nach eins* krijgen verschillende uurstenen. Bij een analoge klok verwijst *halb acht* naar het uur dat nog moet komen. Die regel geldt ook voor *fünf vor halb acht* en *fünf nach halb acht*. [Schleswig-Holstein, rekenleidraad basisschool](https://fachportal.lernnetz.de/sh/faecher/mathematik/fachanforderungen.html?cid=30024&file=files%2FFachanforderungen+und+Leitf%C3%A4den%2FPrimarstufe%2FLeitfaden+Mathematik+Primarstufe+%282026%29.pdf) · [Goethe-Institut, gesproken uurvormen](https://www.goethe.de/resources/files/pdf270/didaktische-materialien-zu-gfdz-v1.pdf) · [Cornelsen, klokkijken op de basisschool](https://www.cornelsen.de/grundschule/ratgeber/mathematik/uhr-lernen)

Zinnen als *viertel acht* en *dreiviertel acht* betekenen in delen van Duitsland respectievelijk 07:15 en 07:45. Daarnaast komen *zehn vor halb acht* voor 07:20 en *zehn nach halb acht* voor 07:40 voor. Bij een opdracht met woordstenen geeft de instructie aan of het kind de digitale vorm, de constructie met *halb* of die rond het hele uur oefent. De woordbank biedt de gekozen constructie aan. Bij klokkiezen en klokzetten telt de kloktijd. [Atlas zur deutschen Alltagssprache over kwartieren](https://www.atlas-alltagssprache.de/runde-7/f11e/) · [Regionale varianten rond het halfuur](https://www.atlas-alltagssprache.de/uhrzeit/)

| Tijd | Verwachte uitdrukking | Benoemd uur en uitleg |
| --- | --- | --- |
| 07:00 | sieben Uhr | 7, volle uur |
| 07:01 | sieben Uhr eins | 7 en 1 minuut |
| 07:05 | fünf nach sieben | 7, 5 minuten na het hele uur |
| 07:14 | sieben Uhr vierzehn | 7 en 14 minuten |
| 07:15 | Viertel nach sieben | 7, 15 minuten na het hele uur |
| 07:16 | sieben Uhr sechzehn | 7 en 16 minuten |
| 07:20 | zwanzig nach sieben | 7, 20 minuten na het hele uur |
| 07:25 | fünf vor halb acht | 8, 5 minuten vóór :30 |
| 07:29 | sieben Uhr neunundzwanzig | 7 en 29 minuten |
| 07:30 | halb acht | 8, op :30 |
| 07:31 | sieben Uhr einunddreißig | 7 en 31 minuten |
| 07:35 | fünf nach halb acht | 8, 5 minuten na :30 |
| 07:40 | zwanzig vor acht | 8, 20 minuten vóór :00 |
| 07:44 | sieben Uhr vierundvierzig | 7 en 44 minuten |
| 07:45 | Viertel vor acht | 8, 15 minuten vóór :00 |
| 07:46 | sieben Uhr sechsundvierzig | 7 en 46 minuten |
| 07:55 | fünf vor acht | 8, 5 minuten vóór :00 |
| 07:59 | sieben Uhr neunundfünfzig | 7 en 59 minuten |
| 08:00 | acht Uhr | 8, nieuw uur |

## Digitale weergave, dagdelen en tijdzones

De 24-uursles toont het volledige uur op de digitale klok, antwoordtegels en in de uitleg. De les maakt het verschil tussen uren en minuten zichtbaar. De gewone digitale klok behoudt de keuze voor 12- of 24-uursweergave van de speler en gebruikt de Duitse locale voor de notatie. De volledige Duitse tijd in woorden is *null Uhr* om 00:00, *null Uhr fünf* om 00:05, *zwölf Uhr* om 12:00, *zwölf Uhr fünf* om 12:05, *siebzehn Uhr fünf* om 17:05 en *dreiundzwanzig Uhr neunundfünfzig* om 23:59. De dagdeelles behoudt de instelbare grenzen en gebruikt *Morgen*, *Nachmittag*, *Abend* en *Nacht*. Voor duur staan *eine Stunde* en *eine Minute* naast vormen als *zwei Stunden* en *zwei Minuten*. [Unicode CLDR, Duitse tijdnotatie](https://unicode.org/cldr/charts/45/verify/dates/de.html)

De tijdzoneles vertrekt vanuit Berlijn. Stadsnamen zoals *Brüssel*, *Kairo* en *Neu-Delhi* staan in de Duitse taalbundel. Berlijn–Neu-Delhi verschilt in de winter 4 uur en 30 minuten en in de zomer 3 uur en 30 minuten. De opdrachten gebruiken hetzelfde referentietijdstip voor de berekening en de stappen in de uitleg. De kernsuite controleert dat Berlijn in beide seizoenen voor elk moeilijkheidsniveau geschikte bestemmingen heeft.

## Controle in het project

- `Tools/test-dino.sh --german-localization` controleert alle 60 minuten over alle 24 uren, de hierboven vastgelegde voorbeelden, geldige en foutieve antwoordstenen, vragen in de 20 oefentypes en zes tijdfamilies, beide uurcycli, middernacht en de referentiestad Berlijn.
- `Tools/test-dino.sh` controleert de Duitse les naast de bestaande Nederlandse en Engelse regressies, spelvoortgang, opslag en Game Center-logica. De UI-tests in [DinoUITests.swift](../Tests/DinoUITests.swift) leggen de overstap tussen Duits, Nederlands en Engels, herstart, exacte minuten, foutfeedback en de Duitse 24-uursles vast.
- De verificatie slaagde met 14.111 gerichte Duitse controles en 2.501.919 controles in de volledige kernsuite. Op de iPhone 17 Pro en iPad Air slaagden samen tien UI-testruns. Daarbij zijn ook de Nederlandse en Engelse rekentitels, tijdzoneles, taalkeuze en portret- en landschaproute gecontroleerd. De gebouwde appbundel bevat de drie talen, de Duitse meervoudsvormen en de Duitse iOS-appnaam *Dino-Zeit*.
- De review op een fysiek toestel dekt de klank van de Duitse systeemstem, VoiceOver en de langste getalwoorden op kleine schermen. Laat een Duitstalige basisschoolreviewer de standaardvormen, regionale varianten en de uitleg bij de langste samenstellingen bekijken. Bij de ouderschermen vraagt vooral de gebruikelijke Duitse terminologie van Apple om een laatste vergelijking op een Duits ingesteld toestel.

## App Store-tekst voor Duitsland

De naam en ondertitel passen binnen 30 tekens. De zoekwoorden passen binnen 100 UTF-8-bytes. De winkelpagina en Game Center-teksten zijn concepten voor de appbeheerder. [Apple over naam en ondertitel](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-compliance-information/) · [Apple over versievelden en zoekwoorden](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

| Veld | Duitse tekst |
| --- | --- |
| Appnaam | Uhr lesen lernen mit Dino |
| Ondertitel | Analoge und digitale Uhren |
| Promotietekst | Lerne mit Dino die Uhr zu lesen. Entdecke zehn Welten, stelle eigene Uhren und übe in deinem Tempo. |
| Zoekwoorden | uhrzeit,grundschule,analoguhr,digitaluhr,mathe,stunden,minuten,lernspiel,zeitrechnen |
| Versietekst | Dino-Zeit gibt es jetzt auf Deutsch. Die Aufgaben, Beispiele und Wortsteine verwenden deutsche Uhrzeitangaben. |

**Beschreibung**

Wie spät ist es, wenn jemand „halb acht“ sagt? Begleite Dino durch zehn Welten mit hundert Leveln und lerne, analoge und digitale Uhren zu lesen.

Fang mit vollen Stunden, halben Stunden und Viertelstunden an. Stelle die Zeiger selbst ein, lege Uhrzeiten mit Wortsteinen und finde heraus, wie viele Minuten zwischen zwei Uhrzeiten liegen. Später rechnest du mit Fahrplänen, Flügen und Zeitzonen.

Beispiele zeigen dir, wie du auf die Lösung kommst. Im Übungsmodus wählst du die Aufgabentypen und Uhrzeiten, die du üben möchtest. Gib deinem Dino deine Lieblingsfarben und gestalte deine eigenen Uhren.

**Screenshotteksten**

| Scherm | Duitse tekst |
| --- | --- |
| Tijd lezen | Uhrzeiten auf einen Blick |
| Spreekvraag met woordstenen | Warum heißt 7:30 „halb acht“? |
| Analoge klok zetten | Stell die Uhr selbst ein |
| Wereldkaart | Zehn Welten mit Dino entdecken |
| Oefenmenu | Übe in deinem Tempo |
| Tijdzonekaart | Wie spät ist es anderswo? |

De project-URL’s voor ondersteuning en privacy reageren met HTTP 200 en bieden Nederlands en Engels. De in-app privacytekst is Duits. De link vanuit de Duitse app opent de bestaande Engelse versie. Voor de Duitse productpagina staan de screenshots van de releasebuild op iPhone en iPad en een eventuele Duitse versie van de twee webpagina’s nog open. [Supportpagina](https://www.hakketjak.com/dino-time/contact/) · [Privacyverklaring](https://www.hakketjak.com/dino-time/privacy/)

De 16 bestaande achievements en 12 ranglijsten hebben Duitse conceptteksten onder hun bestaande ID’s. Zie [achievements](GameCenterAchievements.json) en [ranglijsten](GameCenterLeaderboards.json). [Apple over Game Center-achievements](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-achievements/) · [Apple over ranglijsten](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/)
