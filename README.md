# Dino Tijdavontuur

Native SwiftUI-klokkijkgame voor iPhone en iPad. **Dino Jungle** bevat negen levels met vijf vragen en een direct toegankelijke boss met tien vragen. De app gebruikt uitsluitend Nederlands en Engels, lokale opslag en de aangeleverde dino-assets.

## Starten

Open `Dino Klokkijken.xcodeproj`, kies het gedeelde schema **Dino Klokkijken** en start op een iPhone- of iPad-simulator met iOS 26 of hoger. Voor een eigen apparaat kies je de gebruikelijke signing-instellingen in Xcode. Er zijn geen externe packages of accounts nodig.

De eerste start opent direct bij **Hoe heet jij?**. De Verder-knop blijft bereikbaar boven het toetsenbord. Daarna kun je de klokken aanpassen of direct de standaardklok kiezen. Bestaande Dino-profielen behouden hun naam, klokken, sterren en bossvoortgang.

## Vormgeving en feedback

- Het junglelandschap bestaat volledig uit SwiftUI-paden en shapes: boomkruinen, palmen, lianen, varens, bloemen, mosrotsen, een waterval en lagune. Alles scrolt samen met het slingerende zandpad.
- De vaste header toont het dinoportret met daaronder de naam, het huidige level, alleen het totale aantal verdiende sterren en de pauzeknop. Zachte golven en licht gedraaide badges sluiten aan op de jungle. Via pauze blijven instellingen bereikbaar.
- Na level 10 loopt het pad door naar een nevelige horizon. WorldLandscapePalette houdt het huidige en het volgende kleurenpalet apart; de laatste 560 punten mengen geleidelijk, zodat het volgende blok van tien levels een ander thema kan krijgen. De speelbare volgende wereld blijft een toekomstige uitbreiding.
- De primaire themakleur is **#81D349**, ook voor sterren, voortgang, correcte keuzes en beloningen. De achtergrond heeft zachte groentinten; groene knoppen hebben donkere tekst.
- Dino begint op een blanco beginpunt. Zodra een level minstens één ster heeft, staat hij bij het hoogste behaalde level; een gewonnen boss brengt hem naar level 10. Zijn kaartfiguur is groter en verschijnt bij terugkomst in beeld.
- De levelstartkaart bevat geen vragenaantal of instructiesubtitel.
- Verlaten opent een eigen afgeronde kaart met een groene knop om verder te spelen en een duidelijk rode knop om te verlaten.
- Antwoorden staan in twee kolommen: twee opties op één rij of vier op twee volledige rijen.
- De grotere transparante dino staat in een vaste overlay naast de iets kleinere vraagklok. Klok en titel blijven exact gecentreerd, ook tijdens feedback.
- Na elk goed antwoord speelt de dino de acht beelden `dino-thumbs-up-01` t/m `dino-thumbs-up-08`. Zonder extra tekst volgt na 0,72 seconde de volgende vraag.
- Na een fout antwoord blijven de geselecteerde en correcte optie zichtbaar. **Verder** staat onderaan; er is geen automatische overgang. Op kleine schermen schuiven de antwoordkaarten in beeld.
- Bij **5/5** of **10/10** speelt de dino één backflip op het uitslagscherm, met de acht aangeleverde beelden `dino-backflip-01` t/m `dino-backflip-08`. Omdat de poses grote hoekverschillen hebben, worden ze uitgelijnd rond één draaipunt en gecombineerd met een doorlopende rotatie, sprongbaan, korte pose-overgangen en landing, op maximaal 60 frames per seconde. Bij Minder beweging verschijnt de feestelijke eindpose.

## Project en opslag

`Dino/Core` bevat klokberekening, thema's, levelconfiguraties, vraaggeneratie, scoring en de injecteerbare `UserDefaults`-opslag. `DinoGameModel.swift` verbindt die met SwiftUI. `Dino/Views` bevat de schermen, klokcomponenten, personalisatie, dino en animatie. `DinoRootView` regelt navigatie.

Het bestaande SwiftUI-project, de opslaggrens en runtime-taalwisseling zijn behouden. De oude gamecode, oude assets, audio, winkel, advertenties, promobestanden, vertaalhulpmiddelen en het tweede Xcode-project zijn verwijderd. `Localizable.xcstrings` bevat uitsluitend de Dino-teksten in Nederlands en Engels. De bestaande voorkeurssleutel voor de taal blijft werken.

Het spelersprofiel staat onder `dino.profile.v1`. Reset wist sterren en bossvoortgang na bevestiging; naam, klokken en taal blijven bewaard.

Alle klokken gebruiken één `ClockTheme`. De urenwijzer volgt `30 × uur + 0,5 × minuten`, de minutenwijzer `6 × minuten`. Wereld 1 gebruikt uitsluitend 01:00–12:00. Wereldconfiguraties, dino-states en klokstijlen zijn uitbreidbaar.

## Spelregels

- 0–2/5 = geen ster, 3/5 = één, 4/5 = twee, 5/5 = drie. Een ster ontgrendelt het volgende gewone level.
- Alleen volledige pogingen worden opgeslagen. Een slechtere herhaling verlaagt de beste score niet. Elke vraag accepteert één definitief antwoord.
- Boss: 10/10 voltooit de wereld direct en ontgrendelt alle levels. Anders is minimaal 5/10 nodig én een ster op elk van de negen gewone levels.
- Wereld 2 is een gesloten preview.

## Verificatie

`Tools/test-dino.sh` voert **110.542 controles** uit, inclusief 3.000 gegenereerde pogingen, alle klokminuten, unieke keuzes, volledige antwoordrijen, scoregrenzen, beide boss-routes, dubbele taps en opslag/herstart.

Via **Product → Test** voert `DinoUITests` de scherminteracties uit. De tests gebruiken een eigen spelersopslag en vaste random seed, uitsluitend in debug-builds. Zie [het acceptatieverslag](Documentation/Acceptance.md) en [de screenshots](Documentation/Screenshots).

## Vrienden via Game Center

De kaart heeft een optionele vriendenfunctie met Apple-uitnodigingen, avatars, beschikbare levelresultaten en profielen. Delen staat standaard uit; lokaal spelen blijft mogelijk. Voor werkende online resultaten moeten twaalf klassieke leaderboards in App Store Connect worden aangemaakt. Zie [configuratie, privacy en beperkingen](Documentation/GameCenter.md) en [verificatie](Documentation/GameCenterVerification.md).
