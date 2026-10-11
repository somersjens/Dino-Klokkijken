# Dino Tijdavontuur

Een volledig native SwiftUI-klokkijkgame voor iPhone en iPad, gebouwd in het bestaande Hungry Frog-project. Wereld 1, **Dino Jungle**, bevat negen levels met vijf vragen en een direct toegankelijke boss met tien vragen. De aangeleverde `1_dino`-afbeelding wordt ongewijzigd gebruikt.

## Starten

Open `Dino Klokkijken.xcodeproj`, kies het gedeelde schema **Dino Klokkijken** en start op een iPhone- of iPad-simulator met iOS 26 of hoger. Voor een eigen apparaat kies je de gebruikelijke signing-instellingen in Xcode. Er zijn geen externe packages, accounts, netwerkaanvragen of betaalde functies nodig.

## Hergebruik en integratie

- **Behouden:** SwiftUI, het bestaande Xcode-project en bundle-ID, `LanguageManager`, `LanguagePicker`, runtime-taalwissel, rechts-naar-links-layout en `gameEnvironment()` voor sheets. Alle bestaande taalkeuzes blijven beschikbaar. De nieuwe strings zijn aan `Localizable.xcstrings` toegevoegd in Nederlands en Engels; overige talen gebruiken het bestaande Engelse fallbackmechanisme.
- **Opslag:** dezelfde injecteerbare `KeyValueStore`/`UserDefaults`-architectuur en test-double. Het bestaande spelersnaamveld wordt overgenomen. Dino bewaart een versioneerbaar profiel onder `dino.profile.v1`; oude rekenresultaten worden niet als klokresultaten gebruikt. Bestaande taal- en overige voorkeurssleutels worden niet gewist.
- **Navigatie en instellingen:** de bestaande SwiftUI-schermwissels, sheets, `NavigationStack`, scrollbare instellingenkaarten en responsive inhoudsbreedtes. De bestaande losse gameplayknoppen zijn gekoppeld aan rekenonderwerpen, dieren en valuta; nieuwe afgeronde button styles gebruiken dezelfde native SwiftUI-aanpak.
- **Vervangen in de actieve target:** oude rekenvragen, vliegen, levens, winkel/premium, herinneringen, iCloud-sync, audio en promotievideo's. De oorspronkelijke Swift-bestanden blijven als referentie en worden niet gecompileerd; losse audio- en promobestanden worden niet verpakt. De bestaande assetcatalogus blijft behouden. Er is geen audio- of spraakinitialisatie in de nieuwe app.
- **Mobiel:** de oude verplichte landschapstand is verwijderd. Portret en landschap worden ondersteund; kleine schermen kunnen verticaal scrollen. De build is beperkt tot iPhone/iPad, de gevraagde platformen.

## Modules

`Dino/Core` bevat tijdsberekening, klokthema's, declaratieve levelconfiguraties, vraaggeneratie, antwoordvalidatie, scoring en opslag. `DinoGameModel.swift` verbindt deze met SwiftUI. `Dino/Views` bevat losse klokcomponenten, personalisatie, onboarding, junglekaart, vraagrenderer, demonstraties, resultaten en instellingen. `DinoRootView` verzorgt de centrale navigatie.

Alle klokken gebruiken één `ClockTheme`. De urenwijzer volgt `30 × uur + 0,5 × minuten`, de minutenwijzer `6 × minuten`. De engine gebruikt nu uitsluitend 01:00–12:00. Nieuwe werelden, minuten en boss-recepten kunnen via configuraties worden toegevoegd. `DinoCharacter.State` reserveert idle, happy, thinking, sad, celebrating en boss voor toekomstige assets.

## Spelregels

- 0–2/5 = geen ster, 3/5 = één, 4/5 = twee, 5/5 = drie. Een ster ontgrendelt het volgende gewone level.
- Scores worden uitsluitend na een volledige poging opgeslagen. Een slechtere herhaling verlaagt de beste score niet. Een vraag accepteert één definitief antwoord.
- Boss: 10/10 voltooit de wereld direct en ontgrendelt alle levels. Anders is minimaal 5/10 nodig én een ster op elk van de negen gewone levels.
- Bossresultaten en pogingen blijven bewaard. Wereld 2 is een gesloten preview.
- Reset wist sterren en bossvoortgang na bevestiging; naam, klokken en taal blijven bewaard.

## Verificatie

Voer `Tools/test-dino.sh` uit voor de zelfstandige kernlogica-tests: ruim 97.000 controles, inclusief 3.000 gegenereerde pogingen, alle klokminuten, unieke opties, antwoordposities, scoregrenzen, beide boss-routes, dubbele taps en echte `UserDefaults`-herstart.

Het gedeelde Xcode-schema bevat `DinoUITests`. Via **Product → Test** worden echte schermen en aanraakinteracties doorgelopen: onboarding, alle negen levels, analoge en digitale bediening, beide soorten bosswinst, onvoldoende sterren, herhaling, personalisatie en herstart. De tests gebruiken een afzonderlijke opslagruimte en een vaste random seed, uitsluitend in debug-builds; productie blijft willekeurig en gebruikt de normale lokale opslag.

De uitgevoerde controles en platformen staan in [het acceptatieverslag](Documentation/Acceptance.md). [Voorbeeldscreenshots](Documentation/Screenshots) tonen alle vraagtypen en de iPad-layout. Debug- en Release-build zijn gecontroleerd; de interface is getest op iPhone 18 Pro, iPhone SE en iPad A16.
