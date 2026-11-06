# Productiecontrole Dino Time — 2–3 november 2026

**Status: de lokale technische afronding is voltooid. De reset- en instellingenhercontroles slagen. De gecombineerde Release-archive met alle afgeronde layoutwijzigingen is gebouwd, ondertekend, op de fysieke iPhone geïnstalleerd en zonder debugger gestart. De bronhashes komen overeen met deze build.**

## Definitieve build

Archive: `/tmp/dino-production-check-20261102/Dino-Time-production-combined.xcarchive`. Bouwlog: `.build/production-archive-combined.log`. Versie **1.0 (1)**. Uitvoerbare SHA-256: `819794540a8e7e19a765ebcc744e629935b425fc987105c21ab01753b75d713c`.

De bronhashes zijn vóór de bouw vastgelegd en daarna met de werkmap vergeleken: er waren geen wijzigingen tijdens de bouw. De inmiddels afgeronde responsive-layoutwijzigingen zijn opgenomen. Bundelwaarden, bronhashes en teststatus staan lokaal in `.build/production-combined-verification.json`.

De gewone Release-archive slaagt zonder DEBUG-testvoorwaarden of AppIcon-omwegen. `codesign --verify --deep --strict` slaagt. Game Center en iCloud Key-Value Storage gebruiken de juiste teamidentifier. De bundel ondersteunt iPhone en iPad vanaf iOS 16, behoudt de ProMotion-instelling en bevat het privacy-manifest en beide ingevulde webadressen. XCTest-bundels, debugbibliotheek, `DINO_TEST_`-strings, de experimentele viewportdriver en de globale `setKeyboardAppearance:`-aanroep ontbreken in de uitvoerbare app. De enige appbuildwaarschuwing betreft overgeslagen AppIntents-metadata omdat de app AppIntents niet gebruikt.

## Behouden verbeteringen en opschoning

- De grot- en kustgeometriecaches, gedeelde landschapaanvragen en bestaande cachehysterese blijven behouden. Alle aanvullende hoofdstukviewportdrivers, native meetviews, tegelweergave en experimentele schakelaars zijn verwijderd. De gebruiker meldt dat het scrollen aardig goed aanvoelt. De eerdere warme en mislukte benchmarks blijven afgewezen; er wordt geen vaste framerate gegarandeerd.
- De resettest vond een echte toetsenbordcrash via globale `UIAppearance`-instellingen op UIKit’s eigen tekstinvoer. De proxy-aanroepen zijn verwijderd; de ondersteunde directe venster-/controllerstijl, Info.plist en SwiftUI-palet blijven licht. De volledige resettest slaagt daarna, inclusief invoer, reset, herstart, nul sterren, level 1 en standaardvoorkeuren. [Apple UIAppearance](https://developer.apple.com/documentation/uikit/uiappearance). Oorspronkelijke console: `.build/production-reset-crash-console.log`.
- Native instellingenschakelaars behouden hun gesproken label wanneer dat visueel verborgen is. De tijdelijke proef met `fixedSize` is afgewezen en volledig teruggedraaid.
- Privacy en contact gebruiken de opgegeven pagina’s met `#nl` of `#en` volgens de apptaal. Beide externe pagina’s blijven achter de ouderbevestiging. De Nederlandse en Engelse controles slagen op iPhone en iPad, inclusief annuleren. Beide websites zijn op bereikbaarheid en ondersteuning van de taalfragmenten gecontroleerd.
- Het privacy-manifest verklaart lokale bestandsdatumtoegang voor de landschapcache met `NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1`; UserDefaults blijft `CA92.1`. DEBUG-tijdmetingen zitten niet in de gewone Release. [Apple API-redenen](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
- Het ongebruikte promotie-icoon is byte voor byte behouden in `Documentation/PromotionalAssets`, buiten de gecompileerde spelcatalogus. De drie actieve appiconen zijn 1024 × 1024 pixels zonder alfakanaal. Vertaalcatalogi bevatten Nederlands en Engels; plist- en whitespacecontroles slagen.

## Testresultaten

De volledige kernsuite slaagde met **1.642.313 controles** (`.build/production-core-cleaned.log`). Na de gewijzigde junglepadposities slaagt de actuele route-/decorcontrole met **118.784 controles** (`.build/production-jungle-current-layout.log`). De afgeronde responsive-layoutcontrole rapporteert daarnaast **60.756 maatcontroles** en gerichte iPhone/iPad-schermmatrices; zie [AdaptiveGameLayout.md](AdaptiveGameLayout.md). De volledige kernsuite is na die laatste layoutverfijning niet opnieuw uitgevoerd.

Elf unieke gerichte schermcontroles slagen, verspreid over de herstelronden:

| Apparaat | Controle | Bewijs |
| --- | --- | --- |
| iPhone-simulator | Koude route met flinke vegen tot het kasteel | `.build/production-iphone-corrected.log` |
| iPhone-simulator | HUD-thema volgt de zichtbare wereld | `.build/production-iphone-final.log` |
| iPhone-simulator | Volledig rond tikvlak van levelstenen | `.build/production-iphone-final.log` |
| iPhone-simulator | Landschapbeelden worden hergebruikt bij scrollen | `.build/production-iphone-final.log` |
| iPhone-simulator | Wereldsprong landt correct | `.build/production-iphone-final.log` |
| iPhone-simulator | Privacy/contact in Nederlands en Engels, ouderbevestiging en annuleren | `.build/production-iphone-final.log` |
| iPad-simulator | Opgeslagen positie openen in landschapstand en terugkeren uit een level | `.build/production-ipad-final.log` |
| iPad-simulator | Wereldsprong met geschaalde voetafstand | `.build/production-ipad-final.log` |
| iPad-simulator | Privacy/contact in beide talen en ouderbevestiging | `.build/production-ipad-final.log` |
| iPhone-simulator | Volledige reset, herstart, voortgang en standaardvoorkeuren | `.build/production-iphone-verified-final.log` — 103,835 s |
| Schone iPhone 17 Pro-simulator, iOS 26.5 | Instellingen bewaren na herstart, schakelbediening in portrait/landscape, Engelse labels en foutfeedback | `.build/production-settings-completed.xcresult` — **Passed**, 119,134 s, nul fouten en nul runtimewaarschuwingen |

De laatste instellingenproef gebruikt onveranderlijke testbestanden in `/tmp/dino-final-settings-policy-products`. De al gebruikte simulator bleek onbetrouwbare rotatie- en aanraakcoördinaten te rapporteren. De controle is daarom op een afzonderlijk, schoon apparaat uitgevoerd. De standaard schakelaarlayout is behouden.

De testhulpen zijn gecorrigeerd op basis van de werkelijke UI: scrollen binnen `settings.options` in een korte landschapssheet, de zichtbare tellers binnen hun publieke headerknoppen uitlezen, en de actuele feedbackregels controleren. Bij twee antwoordopties verschijnt na een fout meteen de oplossing met `Next`; bij meer opties blijft `Show answer` gecontroleerd. De controles op waarden, taal, foutfeedback en uitgeschakelde antwoordknoppen zijn behouden. Dit is een verzameling gerichte regressies, geen uitvoering van de volledige UI-suite op één binary. Simulator-timing geldt niet als bewijs van fysieke scrollprestaties.

## Fysieke iPhone en opruimen

De eerdere gewone Release met SHA-256 `b080e468c53a6f148cd35be9cdd94290a51dfc179226b97c1f61326b5916c928` is geïnstalleerd en zonder debugger gestart. Een tweede procescontrole bevestigde de nieuwe installatie. Er is geen uninstall of echte reset uitgevoerd; de gegevenscontainer is behouden. Deze versie bevat de scroll- en toetsenbordfix, privacy/contactlinks en de toenmalige layoutstand.

De nieuwere gecombineerde archive hierboven bevat ook de daarna afgeronde responsive-layoutwijzigingen. Na opnieuw aansluiten van de telefoon is de update succesvol geïnstalleerd, met installatie-ID `1C7EBD91-B81F-489D-BD75-3A19D572987C`. De gewone Release is zonder debugger gestart. De installatie is als update uitgevoerd; er is geen uninstall of echte profielreset gebruikt.

Alle eigen testsimulatoren zijn afgesloten. De oude simulator is teruggezet op zijn oorspronkelijke lichte weergave en Device Hub toont weer het oorspronkelijk geselecteerde apparaat. Andere simulatoren en projecten zijn niet afgesloten. Er draaien geen nieuwe fysieke performance-opnamen.

## Distributie buiten deze controle

De archive is lokaal met het ontwikkelprofiel ondertekend. Distributie-export en App Store Connect-uploadvalidatie zijn niet uitgevoerd. Ook een echte iCloud-uitwisseling tussen twee fysieke apparaten is niet uitgevoerd. De App Store-downloadlink is nog niet opgegeven; de bestaande deelactie valt terug op de vertaalde uitnodigingstekst. Er is niets gepubliceerd.
