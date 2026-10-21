# Game Center-vrienden — implementatie en configuratie

## Wat is toegevoegd

De knop **Vrienden** staat op de bestaande kaart. Het vriendenscherm biedt de officiële Apple-uitnodiging, beschikbare Game Center-vrienden, profielen, privacy-uitleg en optioneel publiceren van eigen resultaten. Op de kaart staan maximaal drie avatars bij het eerste aantoonbaar nog te voltooien level, met `+N` voor overige vrienden. Een levelstartkaart toont de vrienden die dat level daadwerkelijk voltooid hebben, met hun foto, naam, beste sterren en de gemeten tijd bij dat resultaat. Avatars en levelresultaten openen een profiel met alle tien levels.

Er worden uitsluitend door `GKLocalPlayer.loadFriends()` toegestane vrienden getoond. Apple beheert uitnodigingen, namen, foto's en vriendschappen. Beide accounts moeten deze game vriendentoegang toestaan. Een vriend die nog geen resultaten gepubliceerd heeft blijft zichtbaar, met **Niet beschikbaar** voor onbekende gegevens. Afwezige scores worden nooit als nul gedecodeerd. Alleen een expliciet gepubliceerde nulcode vanuit een echte lokale save bevestigt dat een level nog niet gespeeld is.

De bestaande game heeft negen gewone levels en één boss. De boss heeft volgens de bestaande spelregels geen sterren. De hoogste bekende voltooiing en het eerste onafgeronde level zijn verschillende gegevens: een directe perfecte boss kan bijvoorbeeld level 10 als hoogste voltooiing hebben terwijl level 1 nog sterren mist. Totaalsterren en percentages worden alleen berekend wanneer alle benodigde resultaten beschikbaar zijn. Het maximum voor de percentageberekening is drie sterren per voltooid gewoon level; de boss telt niet mee.

## Architectuur en behoud van opgeslagen voortgang

`dino.profile.v1` blijft de enige lokale bron voor de eigen voortgang. Er is geen alternatieve vrienden-save, geen CloudKit-database en geen eigen backend. `SocialProgress` projecteert bestaande records naar twaalf Game Center-leaderboards. `ProgressSyncService` leest de eigen beschikbare Apple-resultaten en voegt per uniek level het beste resultaat samen. Daarna worden uitsluitend ontbrekende of verbeterde scores verstuurd.

De originele afrondingscontrole, scoregrenzen en bossregels zijn behouden. Slechtere herhalingen verlagen geen sterren of beste antwoordscore. Een afgebroken poging wordt niet verstuurd. Het optionele nieuwe veld `nameChangedAt` decodeert bij oude saves als `nil`; de profielversie en opslagkey veranderen niet. Naam, klokthema en bestaande bosshistorie worden niet uit een leaderboard overschreven. Bij import betekent de lokale pogingenteller minimaal één bekende volledige poging; exacte aantallen en datums worden niet uit scores gereconstrueerd.

De bestaande save vormt tevens de duurzame offline uploadwachtrij. Mislukte verzoeken laten die save intact; retries gebruiken 5, 10, 20… seconden tot maximaal vijf minuten. Veranderingen tijdens een upload worden opnieuw gesynchroniseerd. Ongewijzigde resultaten worden niet opnieuw ingediend. Bij terugkeer naar de app en handmatig vernieuwen wordt ook voortgang van een ander apparaat gelezen; daarnaast vindt maximaal iedere vijf minuten een achtergrondcontrole plaats terwijl de app actief is.

De eerste keer dat een volwassene Game Center aanzet, gaan vriendentoegang en publiceren samen aan. Elk schuifje kan daarna uit zonder nieuwe som; opnieuw aanzetten vraagt de som weer. Publiceren blijft gekoppeld aan het lokale `gamePlayerID`. De eerste publicatie koppelt de lokale save aan dat account. Een ander account mag die save niet automatisch uploaden of mengen; de speler krijgt een uitleg en kan terugkeren naar het oorspronkelijke account of bewust lokaal resetten. Reset stopt eerst de uploads en wist vervolgens uitsluitend de bestaande lokale voortgang. Game Center behoudt eerder gepubliceerde beste scores: opnieuw delen kan die herstellen. De app claimt geen mogelijkheid om Apples servergegevens te verwijderen.

## Xcode en App Store Connect

In de app-target zijn de Game Center-capability, `Dino.entitlements`, `NSGKFriendListUsageDescription` en een Nederlands/Engelse `InfoPlist.xcstrings` toegevoegd. `PrivacyInfo.xcprivacy` beschrijft de app-eigen UserDefaults-toegang (`CA92.1`) en geen tracking. Kies voor fysieke apparaten de juiste signing-identiteit en een provisioningprofiel waarin Game Center voor `Hakketjak.Dino-Klokkijken` is toegestaan.

Maak in App Store Connect voor deze bundle ID de onderstaande **twaalf klassieke leaderboards** aan. Gebruik **Best Score**, **High to Low**, **Integer** en **Descending**. Gebruik geen recurring leaderboards of most-recent-score-beleid. Lokaliseer titels in Nederlands en Engels en voeg ze toe aan de juiste appversie. De code vereist dat alle twaalf boards bestaan; ontbrekende configuratie geeft een nette synchronisatiemelding en laat lokale opslag intact. De exacte configuratiereferentie staat in `GameCenterLeaderboards.json`.

| Leaderboard-ID | Bereik | Inhoud |
| --- | --- | --- |
| `dino.level.1.result.v1` t/m `dino.level.9.result.v1` | 0–30 | Beste gewone levelresultaat |
| `dino.level.10.result.v1` | 0–59 | Beste bossresultaat en behaalde overwinning |
| `dino.progress.highest.v1` | 0–10 | Hoogste behaalde level |
| `dino.progress.stars.v1` | 0–27 | Som van beste sterren per gewoon level |

De resultaatscore is een monotone integercodering: gewone levels gebruiken `1 + 8 × beste sterren + beste aantal goede antwoorden`; nul betekent een bevestigde ontbrekende poging. De boss gebruikt `1 + beste antwoorden + 16 × overwinning + 32 × perfect`. Hierdoor verbetert een normale bossoverwinning altijd een eerdere mislukte poging met negen goede antwoorden. In de app worden de echte sterren en antwoorden getoond. De Apple-dashboardweergave van het resultaatsleaderboard toont de gecodeerde resultaatpunten; geef dat board daarom een passende titel, zoals **Level 1 — resultaatpunten**, en noem het geen sterrenscore. Context `1` is uitsluitend de versie van dit scoreformaat. De code decodeert alleen geldige combinaties uit dit schema. Scores/context worden niet gebruikt om namen of willekeurige profielgegevens te verbergen.

Twaalf boards vallen ruim binnen de limiet van honderd zonder leaderboardsets. Apple ondersteunt tot vijfhonderd boards met sets; de twee samenvattingen tellen ook mee. Als de catalogus groeit, reserveer tijdig sets en pas de bestaande wereldopslag aan. Boven die capaciteit is een ander ontwerp nodig. Een mogelijke toekomstige private oplossing is expliciete CloudKit-sharing met toegangsbeheer; een Game Center-vriendschap verleent geen CloudKit-toegang. Er is nu geen CloudKit-configuratie nodig.

Apple-documentatie: [vriendentoegang en uitnodigingen](https://developer.apple.com/documentation/gamekit/connecting-players-with-their-friends-in-your-game), [leaderboards en limieten](https://developer.apple.com/documentation/gamekit/encourage-progress-and-competition-with-leaderboards), [App Store Connect-configuratie](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/), [scoped identifiers](https://developer.apple.com/documentation/gamekit/protecting-the-player-s-privacy-using-scoped-identifiers).

## Speeltijd per poging

Elke beantwoorde vraag meet met Swift `ContinuousClock` de tijd vanaf het verschijnen tot het eerste definitieve antwoord. Kalender- en tijdzonewijzigingen veranderen deze klok niet. Feedback, wachten op Verder en dubbele taps voegen geen tijd toe. Voor de opgeslagen score wordt elke vraag naar boven afgerond en begrensd op 1–60 seconden. Spelen zelf heeft geen tijdslimiet. Elke volledige poging bewaart lokaal de afzonderlijke vraagtijden, score en datum; afgebroken pogingen tellen niet mee. iCloud deelt alleen de beste gemeten resultaten, niet de pogingengeschiedenis.

Voeg voor online tijden **tien extra klassieke leaderboards** toe: `dino.level.1.timed.v1` t/m `dino.level.10.timed.v1`. Gebruik Best Score, High to Low, Integer en Descending. De referentie staat onder `timingLeaderboards` in `GameCenterLeaderboards.json`. De twaalf oorspronkelijke boards en hun codering blijven behouden. De extra boards worden gebruikt zodra ze beschikbaar zijn; ontbrekende timingboards blokkeren de bestaande voortgangssync niet.

De timingcode is `resultaatpunten × 1000 + 601 − seconden`. Een beter resultaat wint altijd; binnen hetzelfde resultaat wint de kortste tijd. Zo wordt een snellere herhaling ook door een Best Score-board opgeslagen. Vriendenresultaten worden uit beide boardtypes samengevoegd. Een oudere beste score zonder passende meting toont **—** voor tijd: de app verzint geen tijd en combineert geen snelle mislukte poging met oude sterren. Accounttoestemming en privacycontroles gelden ook voor deze extra uploads.

De levelkaart toont een melding voor de eerste voltooier wanneer alle beschikbare vriendenresultaten voor dat level bekend zijn en geen vriend het heeft voltooid. Onbekende gegevens geven geen aanspraak op een eerste plaats. Zonder beschikbare verbinding opent **Verbind met Game Center** de bestaande vriendenflow.

## Privacy, kinderaccounts en moderatie

Game Center-leaderboards bieden geen app-afgedwongen opslag die uitsluitend voor vrienden leesbaar is. De app leest zelf alleen resultaten voor beschikbare vrienden, maar dat beperkt niet de zichtbaarheid van gepubliceerde scores via Apple. Het ouderscherm legt dit uit vóór publicatie. Gebruik deze implementatie niet als bewijs dat resultaten privé zijn. Als uitsluitend privé delen een harde releasevoorwaarde is, laat publiceren uit en ontwerp eerst een expliciete private Apple-sharingflow.

Vriendengegevens en foto's staan alleen in het geheugen. Ze worden direct verwijderd bij achtergrondgang, afmelden, accountwisseling, uitschakelen en gedetecteerde weigering/beperking. Elke asynchrone vriendenrequest draagt een generatie en accountcontrole, zodat late responses oude gegevens niet terugzetten. De app controleert toegang bij elke refresh, bij terugkeer naar de app en maximaal iedere minuut terwijl ze actief is. Apple biedt hier geen garantie op een onmiddellijke pushmelding van alle vriendschapswijzigingen. Foto's laden in batches van zes; levelresultaten alleen voor expliciete vrienden in batches van vijftig.

Uitnodigingen worden niet aangeboden wanneer multiplayer of gepersonaliseerde communicatie beperkt is. Publiceren is ook uitgeschakeld voor `isUnderage`-accounts. Daardoor kunnen minderjarige accounts via deze implementatie geen eigen resultaten aan vrienden publiceren, ook wanneer zij wel vrienden mogen bekijken. Dit is een bewuste veilige beperking, geen omzeiling van ouderlijk toezicht. De rekenvraag is een toegangsdrempel voor sociale acties en geen juridisch geverifieerde ouderlijke toestemming.

Er is geen chat, app-eigen berichtensysteem, locatie, contactboektoegang, geboortedatumopslag, tracking of externe SDK. De app verstuurt geen zelfgekozen namen; sociale namen komen ongewijzigd van Apple. Een Apple-profiel kan via `GKAccessPoint` worden geopend. Voor **Meld gebruiker** en **Verwijder vriend** verwijst het scherm naar Apple Games. Er wordt geen niet-bestaande GameKit-blokkeer-API geclaimd. Zie [Apples meld- en vriendenbeheer](https://support.apple.com/en-us/101638).

De zichtbare spelersnaam komt uitsluitend uit `GKLocalPlayer.local.displayName`. Onboarding en dino-personalisatie bevatten geen naamvelden; de HUD bevat geen naam. De naam staat als alleen-lezen tekst in Instellingen en, bij een Game Center-koppeling, naast je eigen score en tijd in de levelstartkaart. Bij afmelding wordt de naam verwijderd uit de weergave; er is geen lokale fallback. Oude naamvelden blijven uitsluitend bewaard voor compatibiliteit met bestaande opslag en worden nergens weergegeven.

Vóór publicatie moet de eigenaar een echt veiligheidscontact opgeven via de app-target build setting **DINO_SAFETY_CONTACT** (Info-key `DinoSafetyContact`), een HTTPS-URL instellen via **DINO_PRIVACY_POLICY_URL** (Info-key `DinoPrivacyPolicyURL`), een extern privacybeleid publiceren en de App Store-privacyvragen beantwoorden voor de daadwerkelijke verwerking. De in-app privacytekst is bereikbaar via Vrienden en Instellingen; ontbrekende contactgegevens worden eerlijk aangegeven. Juridische beoordeling van Kids Category, AVG/AVG-K en eventueel COPPA blijft nodig voor de gekozen doelgroep en landen. Deze code is geen verklaring van juridische compliance. Zie [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) en [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

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
