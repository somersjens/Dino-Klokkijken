# Game Center-vrienden — implementatie en configuratie

## Wat is toegevoegd

De knop **Vrienden** staat op de bestaande kaart. Het vriendenscherm biedt de officiële Apple-uitnodiging, beschikbare Game Center-vrienden, profielen, privacy-uitleg en optioneel publiceren van eigen resultaten. Op de kaart staan maximaal drie avatars bij het eerste aantoonbaar nog te voltooien level, met `+N` voor overige vrienden. Een levelstartkaart toont de vrienden die dat level daadwerkelijk voltooid hebben, met hun foto, naam, beste sterren en de gemeten tijd bij dat resultaat. Avatars en levelresultaten openen het profiel. Gedetailleerde Game Center-resultaten en tijden zijn beschikbaar voor de eerste wereld; level en totaalsterren omvatten het hele avontuur.

Er worden uitsluitend door `GKLocalPlayer.loadFriends()` toegestane vrienden getoond. Apple beheert uitnodigingen, namen, foto's en vriendschappen. Beide accounts moeten deze game vriendentoegang toestaan. Een vriend die nog geen resultaten gepubliceerd heeft blijft zichtbaar, met **Niet beschikbaar** voor onbekende gegevens. Afwezige scores worden nooit als nul gedecodeerd. Alleen een expliciet gepubliceerde nulcode vanuit een echte lokale save bevestigt dat een level nog niet gespeeld is.

De game heeft tien werelden met elk negen gewone levels en één baas: honderd levels en maximaal driehonderd sterren. Ook bazen kunnen drie sterren verdienen. De hoogste bekende voltooiing en het eerste onafgeronde level zijn verschillende gegevens: een directe perfecte boss kan bijvoorbeeld level 10 als hoogste voltooiing hebben terwijl level 1 nog sterren mist. Totaalsterren en percentages worden alleen berekend wanneer alle benodigde resultaten beschikbaar zijn. Een percentage wordt alleen getoond als alle benodigde levelgegevens bekend zijn. Een los totaalsterren-record wordt nooit vergeleken met alleen de eerste wereld.

## Architectuur en behoud van opgeslagen voortgang

`dino.profile.v1` blijft de enige lokale bron voor de eigen voortgang. Er is geen alternatieve vrienden-save of eigen backend. De afzonderlijke iCloud-sync verzorgt de eigen voortgang tussen apparaten voor alle werelden. `SocialProgress` projecteert bestaande records naar twaalf Game Center-leaderboards. `ProgressSyncService` leest de eigen beschikbare Apple-resultaten en voegt per uniek level het beste resultaat samen. Daarna worden uitsluitend ontbrekende of verbeterde scores verstuurd.

De originele afrondingscontrole, scoregrenzen en bossregels zijn behouden. Slechtere herhalingen verlagen geen sterren of beste antwoordscore. Een afgebroken poging wordt niet verstuurd. Het optionele nieuwe veld `nameChangedAt` decodeert bij oude saves als `nil`; de profielversie en opslagkey veranderen niet. Naam, klokthema en bestaande bosshistorie worden niet uit een leaderboard overschreven. Bij import betekent de lokale pogingenteller minimaal één bekende volledige poging; exacte aantallen en datums worden niet uit scores gereconstrueerd.

De bestaande save vormt tevens de duurzame offline uploadwachtrij. Mislukte verzoeken laten die save intact; retries gebruiken 5, 10, 20… seconden tot maximaal vijf minuten. Veranderingen tijdens een upload worden opnieuw gesynchroniseerd. Ongewijzigde resultaten worden niet opnieuw ingediend. Bij terugkeer naar de app wordt ook voortgang van een ander apparaat gelezen; daarnaast vindt maximaal iedere vijf minuten een achtergrondcontrole plaats terwijl de app actief is.

De eerste keer dat een volwassene Game Center aanzet, gaan vriendentoegang en publiceren samen aan. Score delen kan daarna uit zonder nieuwe som; opnieuw aanzetten vraagt de som weer. Afmelden stopt de lokale Game Center-koppeling. Publiceren blijft gekoppeld aan het lokale `gamePlayerID`. De eerste publicatie koppelt de lokale save aan dat account. Een ander account mag die save niet automatisch uploaden of mengen; de speler krijgt een uitleg en kan terugkeren naar het oorspronkelijke account of bewust lokaal resetten. Reset stopt eerst de uploads en wist vervolgens uitsluitend de bestaande lokale voortgang. Game Center behoudt eerder gepubliceerde beste scores: opnieuw delen kan die herstellen. De app claimt geen mogelijkheid om Apples servergegevens te verwijderen.

## Xcode en App Store Connect

De inrichting in App Store Connect is op 11 november 2026 opgeslagen: 25 ranglijsten (inclusief twee verborgen kleurrecords) en 16 achievements met Nederlands en English (U.K.). Alle 41 onderdelen staan op Ready for Review in hetzelfde iOS-reviewconcept. De standaardranglijst is `dino.progress.stars.v1`; Game Center staat aan voor versie 1.1. Zie `GameCenterVerification.md` voor de reviewstatus en uitgevoerde controles.

In de app-target zijn de Game Center-capability, `Dino.entitlements`, `NSGKFriendListUsageDescription` en een Nederlands/Engelse `InfoPlist.xcstrings` toegevoegd. `PrivacyInfo.xcprivacy` beschrijft de app-eigen UserDefaults-toegang (`CA92.1`) en geen tracking. Kies voor fysieke apparaten de juiste signing-identiteit en een provisioningprofiel waarin Game Center voor `Hakketjak.Dino-Klokkijken` is toegestaan.

Maak in App Store Connect voor deze bundle ID de onderstaande **twaalf klassieke resultaat- en samenvattingsranglijsten** aan. Gebruik **Best Score**, **High to Low**, **Integer** en **Descending**. Gebruik geen recurring leaderboards of most-recent-score-beleid. Lokaliseer titels in Nederlands en Engels en voeg ze toe aan de juiste appversie. De code vereist dat alle twaalf boards bestaan; ontbrekende configuratie geeft een nette synchronisatiemelding en laat lokale opslag intact. De exacte configuratiereferentie staat in `GameCenterLeaderboards.json`.

| Leaderboard-ID | Bereik | Inhoud |
| --- | --- | --- |
| `dino.level.1.result.v1` t/m `dino.level.9.result.v1` | 0–30 | Beste gewone levelresultaat |
| `dino.level.10.result.v1` | 0–251 | Beste bossresultaat en behaalde overwinning |
| `dino.progress.highest.v1` | 0–100 | Hoogste behaalde level |
| `dino.progress.stars.v1` | 0–300 | Som van beste sterren over alle honderd levels |

De resultaatscore is een monotone integercodering: gewone levels gebruiken `1 + 8 × beste sterren + beste aantal goede antwoorden`; nul betekent een bevestigde ontbrekende poging. De boss gebruikt `1 + beste antwoorden + 16 × overwinning + 32 × perfect + 64 × sterren`. Hierdoor verbetert een normale bossoverwinning altijd een eerdere mislukte poging met negen goede antwoorden. In de app worden de echte sterren en antwoorden getoond. De Apple-dashboardweergave van het resultaatsleaderboard toont de gecodeerde resultaatpunten; geef dat board daarom een passende titel, zoals **Level 1 — resultaatpunten**, en noem het geen sterrenscore. Context `1` is uitsluitend de versie van dit scoreformaat. De code decodeert alleen geldige combinaties uit dit schema. Scores/context worden niet gebruikt om namen of willekeurige profielgegevens te verbergen.

In totaal zijn er 23 klassieke ranglijsten: twaalf resultaten/samenvattingen, tien tijden en één verborgen zichtbaarheidsrecord. De gedetailleerde resultaat- en tijdsranglijsten blijven beperkt tot de eerste wereld. Het totale sterrenaantal en hoogste level omvatten alle honderd levels; nieuwe werelden synchroniseren hun volledige eigen voortgang via iCloud. Er is geen private CloudKit-sharing met vrienden toegevoegd.

Apple-documentatie: [vriendentoegang en uitnodigingen](https://developer.apple.com/documentation/gamekit/connecting-players-with-their-friends-in-your-game), [leaderboards en limieten](https://developer.apple.com/documentation/gamekit/encourage-progress-and-competition-with-leaderboards), [App Store Connect-configuratie](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/), [scoped identifiers](https://developer.apple.com/documentation/gamekit/protecting-the-player-s-privacy-using-scoped-identifiers).

## Speeltijd per poging

Elke beantwoorde vraag meet met Swift `ContinuousClock` de tijd vanaf het verschijnen tot het eerste definitieve antwoord. Kalender- en tijdzonewijzigingen veranderen deze klok niet. Feedback, wachten op Verder en dubbele taps voegen geen tijd toe. Voor de opgeslagen score wordt elke vraag naar boven afgerond en begrensd op 1–60 seconden. Spelen zelf heeft geen tijdslimiet. Elke volledige poging bewaart lokaal de afzonderlijke vraagtijden, score en datum; afgebroken pogingen tellen niet mee. iCloud deelt alleen de beste gemeten resultaten, niet de pogingengeschiedenis.

Voeg voor online tijden **tien extra klassieke leaderboards** toe: `dino.level.1.timed.v1` t/m `dino.level.10.timed.v1`. Gebruik Best Score, High to Low, Integer en Descending. De referentie staat onder `timingLeaderboards` in `GameCenterLeaderboards.json`. De twaalf resultaat- en samenvattingsboards blijven bestaan. Gewone tijdsranglijsten hebben bereik 1.000–30.596; het baaslevel heeft bereik 1.000–251.591. De extra boards worden gebruikt zodra ze beschikbaar zijn; ontbrekende timingboards blokkeren de bestaande voortgangssync niet.

De timingcode is `resultaatpunten × 1000 + 601 − seconden`. Een beter resultaat wint altijd; binnen hetzelfde resultaat wint de kortste tijd. Zo wordt een snellere herhaling ook door een Best Score-board opgeslagen. Vriendenresultaten worden uit beide boardtypes samengevoegd. Een oudere beste score zonder passende meting toont **—** voor tijd: de app verzint geen tijd en combineert geen snelle mislukte poging met oude sterren. Accounttoestemming en privacycontroles gelden ook voor deze extra uploads.

De levelkaart toont een melding voor de eerste voltooier wanneer alle beschikbare vriendenresultaten voor dat level bekend zijn en geen vriend het heeft voltooid. Onbekende gegevens geven geen aanspraak op een eerste plaats. Zonder beschikbare verbinding opent **Verbind met Game Center** de bestaande vriendenflow.

## Scorezichtbaarheid en delen van alleen het level

**Toon mijn score / Show my score** staat in één kaart met Game Center beheren en afmelden. De infoknop legt uit dat vrienden bij uitzetten alleen het huidige level zien. Het scherm bevat geen online-statusoptie.

De nieuwe klassieke ranglijst **dino.progress.visibility.v1** bewaart het level, avontuurvoltooiing en de keuze voor scorezichtbaarheid. Configureer **Integer**, **Best Score**, **High to Low**, **Hidden: Yes** en laat minimum en maximum leeg. Voeg Engelse en Nederlandse namen toe. De exacte configuratie staat onder `visibilityLeaderboard` in `GameCenterLeaderboards.json`. Deze ranglijst komt naast de twaalf resultaat- en tien tijdsranglijsten. De zichtbaarheidranglijst moet beschikbaar zijn in de sandbox voor ontwikkeltests en door Apple worden goedgekeurd voor de publieke app.

Het scoregetal bevat een monotone voorkeursversie, het level en een bit voor verbergen. Een nieuwere voorkeursversie wint altijd van voortgang onder een oudere keuze. Bij dezelfde versie krijgt verbergen voorrang. Een expliciete lokale wijziging wordt na het lezen van de serverversie opnieuw genummerd als dat nodig is. Een ander apparaat zonder nieuwe lokale wijziging neemt de nieuwste serverkeuze over.

Wanneer scoreweergave uitstaat, verstuurt de app alleen het level, de zichtbaarheidskeuze, behaalde baasprestaties en de gekozen dinokleuren. Er worden geen nieuwe sterrenprestaties gepubliceerd. Er worden geen resultaat- of tijdsranglijsten gelezen of bijgewerkt voor deze speler. Bij opnieuw aanzetten worden eerst de eigen beste resultaten gesynchroniseerd en daarna wordt de zichtbare keuze gepubliceerd. Een mislukte upload laat de verborgen keuze staan. Offline wijzigingen blijven lokaal als wachtende keuze opgeslagen en worden opnieuw geprobeerd.

Vrienden starten met verborgen resultaten. De app controleert hun zichtbaarheid vóór het lezen van scores en opnieuw na het laden. Verborgen resultaten worden volledig uit het geheugenmodel verwijderd, zodat profiel, kaart en levelranglijst geen sterren, antwoordscore of tijden tonen. Bij ontbrekende, ongeldige of onbereikbare zichtbaarheidsgegevens blijft scoreweergave uit. Voor oude spelers kan het laatst bekende level uit de bestaande voortgangsranglijst worden gebruikt.

Dit beheert de weergave in deze bijgewerkte app. Eerder gepubliceerde scores en achievements blijven bij Apple en oudere appversies kunnen scores nog lezen. De infotekst vermeldt dit. De wijziging bereikt vrienden nadat Game Center is gesynchroniseerd en hun lijst opnieuw is ingelezen. Game Center-accountbeperkingen en de bestaande oudercontrole bij opnieuw aanzetten blijven van toepassing.

## Achievements

`GameCenterAchievements.json` bevat de exacte zestien identifiers, punten, afbeeldingen en Engelse en Nederlandse teksten. De zes sterrenmijlpalen zijn 50, 100, 150, 200, 250 en 300 sterren, met respectievelijk 10, 20, 30, 40, 50 en 100 Game Center-punten. Iedere verslagen baas krijgt een eigen verborgen, niet-herhaalbare achievement van 50 punten. Het totaal is 750 punten. De 1024×1024 PNG-afbeeldingen staan in `GameCenterAchievementImages`: sterrenbadges voor mijlpalen en de bestaande juiste baasafbeelding voor iedere wereld. De wereldvolgorde volgt `DinoWorldCatalog`, inclusief woestijn als wereld 2 en slaapvallei als wereld 7.

Configureer alle zestien achievements met beide talen en dezelfde afbeelding per taal. Sterrenmijlpalen zijn vooraf zichtbaar; baasprestaties blijven verborgen tot ze behaald zijn. `DinoAchievements` projecteert de bestaande save. `AchievementSyncService` leest eerder gerapporteerde percentages en verstuurt alleen verbeteringen. Bestaande voortgang verdient de prestaties dus ook na een app-update; opnieuw verbinden veroorzaakt geen dubbele voltooide meldingen. Sterrenpercentages worden alleen verstuurd als score delen aanstaat. Baasprestaties volgen de zichtbare levelvoortgang. Afmelden of accountbeperkingen stoppen alle achievement-uploads. Eerder verdiende prestaties worden nooit via een reset verwijderd.

De versie moet de nieuwe Game Center-componenten bevatten en door Apple worden goedgekeurd voor publieke beschikbaarheid. Configuratie in Prepare for Submission is geen bevestiging van een publieke release. Sandbox-tests met echte accounts blijven noodzakelijk naast de transporttests.

## Gedeelde dinokleuren

`dino.appearance.primary.v1` en `dino.appearance.secondary.v1` bewaren de gekozen bandana-, stekel-, lijf- en buikkleuren als vier exacte 24-bit RGB-waarden in de Game Center-context. Beide zijn verborgen klassieke Integer / Best Score / High to Low-ranglijsten zonder scorebereik. Samen met de bestaande 23 boards zijn er 25 ranglijsten. De score is een monotone paletversie. Beide records moeten dezelfde versie hebben; eerst wordt secondary verstuurd, daarna primary als bevestiging. Een gedeeltelijke upload wordt niet als nieuw palet getoond. De uploadkeuze wordt vóór de eerste request per account lokaal opgeslagen, zodat retries na een herstart dezelfde versie kunnen afmaken.

Een expliciete kleurwijziging of opnieuw inschakelen van Game Center publiceert de lokale selectie. Een ongewijzigd apparaat overschrijft geen nieuwere online kleuren. De eigen personalisatie blijft lokaal opgeslagen; gedeelde kleuren worden alleen in het vluchtige vriendenmodel geladen. Vrienden zien de gekleurde dino in lijst, profiel en levelresultaten. Zonder bevestigd palet blijft de bestaande avatarfallback beschikbaar. Scoreweergave uitzetten stopt deze kleurenupdates niet; afmelden en accountbeperkingen wel.

## Reset na de rekensom

Instellingen voert `resetAllData` alleen uit na het juiste antwoord op de moeilijke som. Een leeg of fout antwoord houdt de resetknop uitgeschakeld. Eerst stopt de Game Center-koppeling en worden lopende requests geannuleerd. Daarna wordt een lege iCloud-save met een resetdatum geschreven en worden lokale resultaten, tijden, oefenrecords, leerhistorie, kleuren en voorkeuren gewist. Die resetdatum voorkomt dat een oudere iCloud-save voortgang opnieuw terugzet.

De bestaande klassieke Best Score-ranglijsten bewaren historische beste scores bij Apple. De app kan daar geen lagere score overheen schrijven. De in-app reset verwijdert die records en reeds verdiende Game Center-achievements daarom niet. Game Center blijft na de reset uitgeschakeld. Als de gebruiker later expliciet weer resultaten gaat delen, kan de bestaande beste voortgang uit Game Center worden hersteld. Deze beperking staat vóór bevestigen in de Nederlandse en Engelse resetuitleg. De reset gebruikt geen testdata-verwijdering of beheerdersactie bij Apple.

## Privacy, kinderaccounts en moderatie

Game Center-leaderboards bieden geen app-afgedwongen opslag die uitsluitend voor vrienden leesbaar is. De app leest zelf alleen resultaten voor beschikbare vrienden, maar dat beperkt niet de zichtbaarheid van gepubliceerde scores via Apple. Het ouderscherm legt dit uit vóór publicatie. Gebruik deze implementatie niet als bewijs dat resultaten privé zijn. Als uitsluitend privé delen een harde releasevoorwaarde is, laat publiceren uit en ontwerp eerst een expliciete private Apple-sharingflow.

Vriendengegevens en foto's staan alleen in het geheugen. Ze worden direct verwijderd bij achtergrondgang, afmelden, accountwisseling, uitschakelen en gedetecteerde weigering/beperking. Elke asynchrone vriendenrequest draagt een generatie en accountcontrole, zodat late responses oude gegevens niet terugzetten. De app controleert toegang bij elke refresh, bij terugkeer naar de app en maximaal iedere minuut terwijl ze actief is. Apple biedt hier geen garantie op een onmiddellijke pushmelding van alle vriendschapswijzigingen. Foto's laden in batches van zes; levelresultaten alleen voor expliciete vrienden in batches van vijftig.

Uitnodigingen worden niet aangeboden wanneer multiplayer of gepersonaliseerde communicatie beperkt is. Publiceren is ook uitgeschakeld voor `isUnderage`-accounts. Daardoor kunnen minderjarige accounts via deze implementatie geen eigen resultaten aan vrienden publiceren, ook wanneer zij wel vrienden mogen bekijken. Dit is een bewuste veilige beperking, geen omzeiling van ouderlijk toezicht. De rekenvraag is een toegangsdrempel voor sociale acties en geen juridisch geverifieerde ouderlijke toestemming.

Er is geen chat, app-eigen berichtensysteem, locatie, contactboektoegang, geboortedatumopslag, tracking of externe SDK. De app verstuurt geen zelfgekozen namen; sociale namen komen ongewijzigd van Apple. Een Apple-profiel kan via `GKAccessPoint` worden geopend. Voor **Meld gebruiker** en **Verwijder vriend** verwijst het scherm naar Apple Games. Er wordt geen niet-bestaande GameKit-blokkeer-API geclaimd. Zie [Apples meld- en vriendenbeheer](https://support.apple.com/en-us/101638).

De zichtbare spelersnaam komt uitsluitend uit `GKLocalPlayer.local.displayName`. Onboarding en dino-personalisatie bevatten geen naamvelden; de HUD bevat geen naam. De naam staat als alleen-lezen tekst in Instellingen en, bij een Game Center-koppeling, naast je eigen score en tijd in de levelstartkaart. Bij afmelding wordt de naam verwijderd uit de weergave; er is geen lokale fallback. Oude naamvelden blijven uitsluitend bewaard voor compatibiliteit met bestaande opslag en worden nergens weergegeven.

Vóór publicatie moet de eigenaar een echt veiligheidscontact opgeven via de app-target build setting **DINO_SAFETY_CONTACT** (Info-key `DinoSafetyContact`), een HTTPS-URL instellen via **DINO_PRIVACY_POLICY_URL** (Info-key `DinoPrivacyPolicyURL`), een extern privacybeleid publiceren en de App Store-privacyvragen beantwoorden voor de daadwerkelijke verwerking. De in-app privacytekst is bereikbaar via Instellingen; ontbrekende contactgegevens worden eerlijk aangegeven. Juridische beoordeling van Kids Category, AVG/AVG-K en eventueel COPPA blijft nodig voor de gekozen doelgroep en landen. Deze code is geen verklaring van juridische compliance. Zie [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) en [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

## Gewijzigde en toegevoegde bestanden

| Bestand | Wijziging |
| --- | --- |
| `Dino/Core/SocialProgress.swift` | Scorecodering, beschikbare gegevens, statistieken, kaartgroepen en max-merge |
| `Dino/Core/ProgressSyncService.swift` | Injecteerbare synchronisatie met toestemmingcontrole na await |
| `Dino/Social/FriendsManager.swift` | GameKit-authenticatie, vrienden, foto's, uitnodigingen, privacy en retries |
| `Dino/Views/Friends.swift` | Vriendenlijst, profiel, avatars, ouderscherm, levelresultaten en privacy |
| `DinoTimeAdventureApp.swift`, `Dino/DinoRootView.swift` | Manager, native presentatie-anker, scene lifecycle, vriendenscherm |
| `Dino/Views/WorldMap.swift` | Vriendenknop, maximaal drie avatars plus extra aantal, profielnavigatie en levelkaart |
| `Dino/DinoGameModel.swift`, `Dino/Core/PlayerProfile.swift` | Voortgang-hooks, behoudende remote merge, compatibele legacy-opslag zonder naam als onboardingvoorwaarde |
| `Dino/Views/OnboardingFlow.swift`, `Dino/Views/Settings.swift` | Dino-kleurkeuze bij eerste start, Game Center-naam en privacytoegang |
| `Dino.entitlements`, `DinoInfo.plist`, `InfoPlist.xcstrings`, `PrivacyInfo.xcprivacy`, `Localizable.xcstrings`, Xcode-project | Capability, privacybeschrijving, manifest, vertalingen en targetlidmaatschap |
| `Tests/DinoSocialTests.swift`, `Tests/DinoCoreTests.swift`, `Tests/DinoUITests.swift`, `Tools/test-dino.sh` | Synchronisatie-, migratie-, Unicode-, kaart- en schermtests |

De map bevatte reeds andere wijzigingen aan assets, kaart, header en menu. Deze zijn niet teruggedraaid; dit verslag beschrijft uitsluitend de sociale uitbreiding.

## Verificatie

`Tools/test-dino.sh` voert de bestaande spelcontroles plus nieuwe controles uit: scorecodering/bossgrenzen, beste sterren, onbekende gegevens, nul/volledige voortgang, grote kaartgroepen, opslagmigratie, onboarding zonder naam, offline/partiële uploads, retries, idempotentie, samengevoegde voortgang tussen apparaten en ingetrokken toestemming tijdens een request. Transportmocks staan uitsluitend in de tests. UI-fixtures zijn alleen in Debug beschikbaar met zowel een geïsoleerde `DINO_TEST_SUITE` als `DINO_TEST_SOCIAL=fixtures`; normale builds en Release krijgen nooit fictieve vrienden.

Zie `GameCenterVerification.md` voor de uitgevoerde builds/simulatorchecks en resultaten.

Nog uit te voeren met fysieke apparaten en echte accounts na App Store Connect-configuratie:

1. Login bestaand account, uitloggen, accountwisseling en geweigerde login.
2. Beschikbare vrienden met wederzijdse toestemming; weigeren en intrekken; verwijderen terwijl de app actief is.
3. Officiële uitnodiging versturen, accepteren en na refresh daadwerkelijk verschijnen.
4. Apple-avatars, namen, scoped-ID-koppeling tussen alle resultaatsboards.
5. Twee apparaten met hetzelfde account: offline verbeteren, upload, herstel, gemengde levelverbeteringen en reset/re-opt-in.
6. Echte kinderaccounts en Screen Time-beperkingen; controleren dat delen/uitnodigen niet omzeild worden.
7. Fouten bij ontbrekende configuratie, serveruitval en gedeeltelijke resultaatsrequests.
8. VoiceOver, grotere tekst, iPhone/iPad-landschap en profielblokkeren/melden via Apples actuele interface.

Er zijn hier geen echte uitnodigingen verstuurd, geen accounts aangemaakt en geen App Store Connect-leaderboards gepubliceerd. De daadwerkelijke Apple-netwerkfunctionaliteit en reviewgoedkeuring zijn daarom nog niet bevestigd.
