# Instellingen — verificatie

De vier schakelaars zijn gekoppeld aan opgeslagen voorkeuren: geluidseffecten, trillingen bij antwoorden, hoog contrast en optionele iCloud-sync.

- `Tools/test-dino.sh`: 112.207 controles geslaagd. Nieuwe controles dekken voorkeuren na herstart, eenmalige antwoordfeedback, opt-in/uitschakelen, cloudmerges, vertraagde eerste downloads, offline opslag, resets en ongeldige cloudgegevens.
- `testSettingsPreferencesPersist`: geslaagd op iPhone SE (3e generatie) en iPad Air 13-inch (M4), met iOS 27. Controleert alle schakelaars, herstart, taalwisseling, schermrotatie en antwoordfeedback met hoog contrast.
- `testCustomClockAndSettings`: geslaagd op iPhone 18 Pro en iPad Air. De bestaande klokinstellingen blijven bereikbaar.
- `testFourChoicesAndPersistentWrongAnswer`: alle assertions geslaagd op iPhone SE met geluid en trillingen standaard aan. Xcode bleef daarna hangen bij het afronden van het verslag; het aanvullende testproces is beëindigd. De menutest op deze simulator leverde wel een volledig geslaagd verslag op.

[Instellingen op iPad](Screenshots/settings-menu-ipad.png), [hoog contrast op iPhone](Screenshots/settings-contrast-iphone.png) en [antwoordfeedback op iPad](Screenshots/settings-answers-ipad.png) zijn visueel gecontroleerd.

De cloudtests gebruiken een nagebootste opslag. De iCloud-entitlement en Xcode-capability zijn toegevoegd. Echte uitwisseling via Apple moet nog worden getest op twee apparaten met hetzelfde iCloud-account en een passend provisioningprofiel. Fysieke trillingen kunnen niet op de simulator worden gecontroleerd.
