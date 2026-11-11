# Verificatie vriendenfunctie — 11 oktober 2026

| Controle | Resultaat |
| --- | --- |
| `Tools/test-dino.sh` | **110.542 controles geslaagd**, inclusief de oorspronkelijke gameplaytests |
| Debug iOS Simulator-build | Geslaagd voor arm64 en x86_64 |
| Release iOS-device-build | Geslaagd, zonder signing; echte provisioning nog te controleren |
| iPhone 18 Pro / iOS 27 | Twee definitieve vriendenschermtests geslaagd: profiel/kaart/levelresultaten/ontbrekende gegevens en ouderscherm/offline speelroute |
| iPhone SE (3e generatie) / iOS 26.1 | Dezelfde twee tests geslaagd; screenshotcontrole van kleine schermen |
| Bestaande directe perfecte boss | Simulator-test geslaagd: 10/10, wereldvoltooiing en behoud van opslag |
| Bestaande nul sterren / herhaling | Simulator-test geslaagd: ontgrendeling, beste sterren en herstart |
| Project, entitlements en privacy-manifest | Plist-validatie geslaagd; gelokaliseerde Game Center-toestemmingstekst aanwezig in de build |
| `git diff --check` | Geslaagd |

De twee nieuwe schermtests hadden in de eerste runs onjuiste selectors voor het type toegankelijkheidselement, de vertaling van Annuleren en de vernieuwde sterrenteller. Deze selectors zijn gecorrigeerd. De definitieve runs eindigen met `TEST SUCCEEDED` en nul fouten. Xcode bleef bij de eerste runs met een expliciet resultBundlePath hangen nadat de testcases afgerond waren; die eigen processen zijn afgesloten. De definitieve runs gebruiken seriële simulatoruitvoering en de standaardresultaatbundel.

De UI-tests gebruiken uitsluitend geïsoleerde Debug-fixtures. De onderstaande screenshots demonstreren de interface met testdata, en bevestigen geen echte Game Center-vriendschappen:

- [Kaart met drie avatars en +2](Screenshots/Social/friends-map-iphone-se.png)
- [Profiel en beste sterren](Screenshots/Social/friends-profile-iphone-se.png)
- [Sterren van vrienden op de levelstartkaart](Screenshots/Social/friends-level-results-iphone-se.png)
- [Onbekende resultaten](Screenshots/Social/friends-unavailable-results-iphone-se.png)
- [Veilige standaardinstelling](Screenshots/Social/friends-private-default-iphone-se.png)

Logs van deze sessie staan in `/tmp/dino-social-ui-final.log`, `/tmp/dino-social-ui-small.log`, `/tmp/dino-social-release.log` en de standaard Xcode-resultaatbundels onder `/tmp/dino-social-build/Logs/Test`. Tijdelijke bestanden zijn geen duurzame releaseartefacten.

Niet uitgevoerd: echte Game Center-authenticatie met gebruikersaccounts, daadwerkelijk versturen/accepteren van uitnodigingen, netwerkherstel op twee fysieke apparaten, Apple-avatarrequests, echte privacy-intrekking/kinderaccounts, handmatige VoiceOver-bediening en App Store Connect-publicatie. De releasevoorwaarden, leaderboardinstellingen, contactvelden en beperkingen staan in [GameCenter.md](GameCenter.md).

## 11 november 2026 — scorezichtbaarheid en achievements

- Gerichte sociale tests: **4.091 controles geslaagd**. Dit omvat zichtbaarheidsversies, uitschakelen zonder resultaat-uploads, voorkeuren tussen apparaten, ontbrekende gegevens, late score- en totaalsterrenresponses, bestaande saves en idempotente achievements. De losse macOS-testharness gebruikt een tijdelijke audiostub voor `DinoAnswerFeedback`, omdat de bestaande CLI-testopdracht deze UIKit-afhankelijkheid niet meeneemt.
- Definitieve generieke iOS-build: **BUILD SUCCEEDED**, zonder codesigning, met DerivedData in `/tmp/dino-apple-configuration` en log `/tmp/dino-apple-configuration-build.log`.
- Configuratiereferenties gecontroleerd: 23 unieke leaderboard-ID's, 16 unieke achievement-ID's, 32 achievementvertalingen, 750 punten en zestien PNG-afbeeldingen van 1024×1024. Achievementtitels passen binnen 30 tekens; omschrijvingen binnen 120 tekens.
- Echte vriendenuitnodigingen en end-to-end synchronisatie tussen twee Game Center-accounts zijn in deze controle niet uitgevoerd. Draft-configuratie is geen publieke reviewgoedkeuring.

De fysieke iPhone-schermtest van 7 november slaagde voor de vernieuwde Friends-flow. Die gebruikte geïsoleerde testdata en bevestigt geen echte Game Center-netwerkuitwisseling. Resultaatbundel: `/tmp/dino-friends-device.V8tg8d/Results.xcresult`.

### Definitieve controle — 11 november 2026

- **1.698.470 core- en sociale controles geslaagd**, waaronder scorecodering, beste resultaten per level, iCloud-resetmarkeringen, offline retries, voortgang tussen apparaten en exacte RGB-kleuren.
- **4.360 gerichte sociale controles geslaagd** voor dezelfde broncode. Exacte kleurwaarden, halve uploads, herstart/retry, oudere apparaten, ingetrokken toestemming en resetopslag zijn afzonderlijk afgedekt.
- Generieke iOS-build: **BUILD SUCCEEDED**, log `/tmp/dino-apple-configuration-build.log`.
- QA iPhone 17 Pro-simulator: `testFriendsScreenShowsListAndOpensProfile` geslaagd (64,499 s). De lijst toont verschillende dino's in opgeslagen kleurpaletten. Screenshot met uitsluitend testvrienden: `/tmp/DinoScreenshots/iphone/friends-list.png`.
- `testFullResetClosesAndRestartsWelcome` geslaagd (128,172 s). De test controleert dat een leeg en fout antwoord de resetknop uitgeschakeld houden. Alleen het juiste antwoord wist de voortgang; na herstart verschijnen onboarding, nul sterren en level 1. De eerste run kreeg geen toetsenbordfocus door de AX-tik; na aanpassen naar de zichtbare veldcoördinaten slaagde de definitieve run. Resultaat: `/tmp/dino-avatar-reset-ui-retry.xcresult`.
- De volledige core-run staat in `/tmp/dino-core-avatar.log`; de eerste UI-run in `/tmp/dino-avatar-reset-ui.log`. De losse CLI-harness gebruikt een tijdelijke audiostub omdat de bestaande CLI-opdracht de UIKit-audiolaag niet meeneemt.

### App Store Connect — alle onderdelen Ready for Review

- **25 klassieke ranglijsten** opgeslagen, elk met Nederlands en English (U.K.): twaalf resultaten/samenvattingen, tien tijdsranglijsten, één verborgen zichtbaarheidsrecord en twee verborgen kleurrecords.
- **16 achievements** opgeslagen met beide talen, pre-earned en earned omschrijvingen en de juiste afbeelding in beide talen: zes sterrenmijlpalen en tien bazen.
- Punten: 10/20/30/40/50/100 voor 50/100/150/200/250/300 sterren en 50 voor elke baas, samen **750 punten**. Sterrenmijlpalen: Hidden No; bazen: Hidden Yes. Alle prestaties zijn niet herhaalbaar.
- De twee kleurrecords gebruiken **Best Score**, **High to Low**, **Integer**, **Hidden Yes** en geen scorebereik. Hun IDs zijn `dino.appearance.primary.v1` en `dino.appearance.secondary.v1`.
- Het complete overzicht is na alle toevoegingen uitgelezen: **41 componenten, 25 ranglijsten, 16 achievements, 41 Ready for Review, geen afwijkende status**. Alle onderdelen staan in hetzelfde bestaande iOS-reviewconcept. Er is **geen Submit for Review** uitgevoerd.
- **Verzamelde sterren** (`dino.progress.stars.v1`) is opnieuw bevestigd als standaardranglijst.
- Versie **1.1 Prepare for Submission** heeft Game Center ingeschakeld. Er is nog geen build gekoppeld. Apple vereist voor de eerste Game Center-onderdelen een Game Center-enabled appversie in dezelfde inzending; het concept is daarom nog niet indienbaar.

### Praktische grenzen

De reset wist lokale en opgeslagen iCloud-voortgang, inclusief tijden, geschiedenis, oefenrecords, instellingen en kleuren. Een resetdatum voorkomt terugkeer van een oudere iCloud-save. Game Center wordt eerst losgekoppeld. Klassieke Best Score-records en verdiende achievements blijven bij Apple; de app-reset wist die niet. Expliciet opnieuw delen kan die eerdere beste resultaten herstellen. Dit staat vóór de resetsom in Nederlands en Engels.

Totaalsterren, hoogste level en achievements omvatten alle honderd levels. De gedetailleerde Game Center-resultaat- en tijdsranglijsten zijn momenteel voor wereld 1; volledige eigen voortgang van alle werelden synchroniseert via iCloud. De gekozen dino wordt wel onafhankelijk van scorezichtbaarheid met vrienden gedeeld. Een echte uitwisseling met twee Game Center-accounts is niet uitgevoerd; sandbox-/productiebeschikbaarheid moet na configuratie en Apple-review met echte accounts bevestigd worden.
