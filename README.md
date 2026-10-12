# Dino Tijdavontuur

Native SwiftUI-klokkijkgame voor iPhone en iPad. **Dino Jungle** bevat negen levels met vijf vragen en een direct toegankelijke boss met tien vragen. De app gebruikt uitsluitend Nederlands en Engels, lokale opslag met optionele iCloud-sync en de aangeleverde dino-assets.

## Starten

Open `Dino Klokkijken.xcodeproj`, kies het gedeelde schema **Dino Klokkijken** en start op een iPhone- of iPad-simulator met iOS 26 of hoger. Voor een eigen apparaat kies je de gebruikelijke signing-instellingen in Xcode. Er zijn geen externe packages of accounts nodig.

De eerste start opent bij **Maak jouw dino** met vier kleurkeuzes en een vast voorbeeld. **Verder** blijft zichtbaar tijdens scrollen. Daarna kun je de klokken aanpassen of de standaardklok kiezen. Er is geen naamveld of verplichte Game Center-aanmelding. Bestaande profielen behouden hun dinokleuren, klokken, sterren en bossvoortgang.

## Vormgeving en feedback

- Het junglelandschap bestaat volledig uit SwiftUI-paden en shapes: asymmetrische boomkruinen op vertakte stammen, gebogen palmbladeren, lianen, varens, lage struiken en onregelmatige mosrotsen. De waterval stroomt over een rotswand naar een poel. Alles scrolt samen met het slingerende zandpad.
- De vaste header toont het grotere dinoportret zonder naam of kwastje, met volledig zichtbare bovenste stekels, het huidige level en de ster boven het totale aantal verdiende sterren. Gelijke, rechte badges houden de HUD rustig. Op de kaart opent het tandwiel direct de instellingen; tijdens een level staat hier de pauzeknop.
- Tik op het portret linksboven om **Mijn dino** te openen, ook tijdens een level. Kies afzonderlijk kleuren voor de bandana, stekels, het lichaam en buikje/tenen via kleurbolletjes of de vrije systeemkleurkiezer. Het vaste voorbeeld blijft zichtbaar tijdens het kiezen. De standaardkleuren tonen exact de oorspronkelijke afbeelding; **Oorspronkelijke kleuren** zet ze terug. Kleuren worden direct lokaal bewaard. Alleen het headerfiguurtje gebruikt deze kleuren.
- Na level 10 loopt het pad door naar een nevelige horizon. WorldLandscapePalette houdt het huidige en het volgende kleurenpalet apart; de laatste 560 punten mengen geleidelijk, zodat het volgende blok van tien levels een ander thema kan krijgen. De speelbare volgende wereld blijft een toekomstige uitbreiding.
- De primaire themakleur is **#81D349**, ook voor sterren, voortgang, correcte keuzes en beloningen. De achtergrond heeft zachte groentinten; groene knoppen hebben donkere tekst.
- Dino begint op een blanco beginpunt. Zodra een level minstens één ster heeft, staat hij bij het hoogste behaalde level; een gewonnen boss brengt hem naar level 10. Zijn kaartfiguur is 15% kleiner, staat met de voeten midden op de huidige levelknop en heeft een zachte grondschaduw, zonder naamlabel, en verschijnt bij terugkomst in beeld.
- Het centrale startpunt heeft een gelaagde groene cirkel en een startlabel. De levelstartkaart opent vlak onder de HUD en toont vrienden met foto, naam, sterren en gemeten tijd, of de Game Center-verbindingsknop. Bij een Game Center-koppeling toont deze kaart ook je eigen Game Center-naam, score en tijd. Je naam staat verder alleen in **Instellingen** en komt rechtstreeks van Apple; er is geen lokale naamkeuze of vervangende naam.
- Voorbeelden openen uitsluitend via het vraagteken. De voorbeeldkaart houdt de klok gecentreerd en bevat geen dino.
- Spelen wisselt de startkaart direct voor het level met een korte overgang. De Dino bij de laatste vraag blijft zichtbaar en springt bij maximale punten met zijn salto naar zijn plek op het resultaat.
- Verlaten opent een eigen afgeronde kaart met een groene knop om verder te spelen en een duidelijk rode knop om te verlaten.
- Antwoorden staan in twee kolommen: twee opties op één rij of vier op twee volledige rijen.
- De grotere transparante dino staat in een vaste overlay naast de iets kleinere vraagklok. Klok en titel blijven exact gecentreerd, ook tijdens feedback.
- Na elk goed antwoord toont Dino één duidelijke duimenpose (`dino-thumbs-up-08`) met een kleine beweging. Zonder extra tekst volgt na 0,72 seconde de volgende vraag.
- Na een fout ingestelde analoge of digitale klok verschijnen het eigen antwoord en de juiste klok naast elkaar met rood/groen. De analoge invoer verkleint en schuift soepel naar links. De rode feedbackbalk is verwijderd.
- Na een fout antwoord toont Dino een rustige verbaasde reactie (`dino-wrong-answer-04`), die blijft staan. De geselecteerde en correcte optie blijven zichtbaar. **Verder** staat onderaan; er is geen automatische overgang. Op kleine schermen schuiven de antwoordkaarten in beeld.
- Bij **5/5** of **10/10** speelt de dino één backflip op het uitslagscherm, met vier gekozen poses voor afzet, draai, landing en eindpose. Tijdens de hele draai blijft dezelfde ingetrokken pose zichtbaar, met een doorlopende rotatie en sprongbaan op maximaal 60 frames per seconde. Er worden geen afbeeldingen over elkaar heen getoond. Bij Minder beweging verschijnt de feestelijke eindpose.

## Project en opslag

`Dino/Core` bevat klokberekening, thema's, levelconfiguraties, vraaggeneratie, scoring en de injecteerbare `UserDefaults`-opslag. `DinoGameModel.swift` verbindt die met SwiftUI. `Dino/Views` bevat de schermen, klokcomponenten, personalisatie, dino en animatie. `DinoRootView` regelt navigatie.

Het bestaande SwiftUI-project, de opslaggrens en runtime-taalwisseling zijn behouden. De oude gamecode, oude assets, oude audio, winkel, advertenties, promobestanden, vertaalhulpmiddelen en het tweede Xcode-project zijn verwijderd. `Localizable.xcstrings` bevat uitsluitend de Dino-teksten in Nederlands en Engels. De bestaande voorkeurssleutel voor de taal blijft werken.

Het spelersprofiel staat onder `dino.profile.v1`. Reset wist sterren en bossvoortgang na bevestiging; dinokleuren, klokken, taal en instellingen blijven bewaard.

Het instellingenmenu bevat **Geluidseffecten**, **Trillingen bij antwoorden**, **Hoog contrast** en **iCloud-sync**. Geluid en trillingen staan standaard aan; hoog contrast en iCloud-sync staan standaard uit. Deze voorkeuren worden lokaal bewaard. De korte antwoordtonen respecteren de stille modus. Trillingen gebruiken de beschikbare iPhone-hardware. Hoog contrast maakt kaart- en knopranden, klokmarkeringen en antwoordfeedback duidelijker en respecteert ook de systeeminstelling voor verhoogd contrast.

iCloud-sync deelt alleen levelresultaten, sterren en spelvoortgang tussen apparaten met hetzelfde iCloud-account. Zet de optie op beide apparaten aan. Dinokleuren, klokthema's en instellingen blijven lokaal. De zichtbare naam komt uit Game Center. Elk apparaat schrijft een eigen cloudkopie, zodat een eerste start geen bestaande voortgang kan overschrijven. Beste resultaten worden samengevoegd; offline voortgang wordt bij een volgende synchronisatie meegenomen. Een reset krijgt een bewaard tijdstip, zodat oude cloudresultaten geen gewiste voortgang terugzetten. Bij ingeschakelde sync wordt de reset ook gedeeld. Uitschakelen stopt cloudtoegang op dat apparaat en verwijdert de cloudkopie niet.

De app gebruikt Apples [iCloud Key-Value Storage](https://developer.apple.com/documentation/foundation/synchronizing-app-preferences-with-icloud). De entitlement en Xcode-capability zijn opgenomen. Voor echte apparaten moet iCloud Key-Value Storage ook beschikbaar zijn voor de App ID en het provisioningprofiel van het gekozen Apple Developer-team. Simulator-UI-tests gebruiken een eigen opslag en krijgen geen toegang tot echte iCloud-voortgang. Controleer de uiteindelijke uitwisseling op twee ingelogde apparaten; cloudupdates kunnen vertraagd zijn.

Alle klokken gebruiken één `ClockTheme`. De urenwijzer volgt `30 × uur + 0,5 × minuten`, de minutenwijzer `6 × minuten`. Wereld 1 gebruikt uitsluitend 01:00–12:00. Wereldconfiguraties, dino-states en klokstijlen zijn uitbreidbaar.

## Spelregels

- 0–2/5 = geen ster, 3/5 = één, 4/5 = twee, 5/5 = drie. Een ster ontgrendelt het volgende gewone level.
- Per volledige poging worden ook de vraagtijden verzameld. Alleen de tijd vóór het antwoord telt; de score rekent 1–60 seconden per vraag zonder een tijdslimiet voor de speler. Een monotone klok voorkomt invloed van tijdzone- of kalenderwijzigingen.
- Alleen volledige pogingen worden opgeslagen. Een slechtere herhaling verlaagt de beste score niet. Elke vraag accepteert één definitief antwoord.
- Boss: 10/10 voltooit de wereld direct en ontgrendelt alle levels. Anders is minimaal 5/10 nodig én een ster op elk van de negen gewone levels.
- Wereld 2 is een gesloten preview.

## Verificatie

`Tools/test-dino.sh` voert **112.640 controles** uit, inclusief 3.000 gegenereerde pogingen, alle klokminuten, unieke keuzes, volledige antwoordrijen, scoregrenzen, beide boss-routes, dubbele taps, opslag/herstart, voorkeuren en iCloud-merge/reset/offline-gedrag.

Via **Product → Test** voert `DinoUITests` de scherminteracties uit. De tests gebruiken een eigen spelersopslag en vaste random seed, uitsluitend in debug-builds. Zie [het acceptatieverslag](Documentation/Acceptance.md) en [de screenshots](Documentation/Screenshots).

Het instellingenmenu is gecontroleerd op een iPhone SE en een iPad Air: alle schakelaars, bewaren na herstart, Nederlands/Engels, landschapstand en antwoordfeedback met hoog contrast. [Menu op iPad](Documentation/Screenshots/settings-menu-ipad.png), [hoog contrast op iPhone](Documentation/Screenshots/settings-contrast-iphone.png) en [antwoordfeedback op iPad](Documentation/Screenshots/settings-answers-ipad.png). De cloudtests gebruiken een nagebootste opslag; echte iCloud-uitwisseling en fysieke trillingen moeten op apparaten worden gecontroleerd.

## Vrienden via Game Center

De kaart heeft een optionele vriendenfunctie met Apple-uitnodigingen, avatars, beschikbare levelresultaten en profielen. Delen staat standaard uit; lokaal spelen blijft mogelijk. Voor werkende online resultaten moeten twaalf klassieke resultaatleaderboards en voor tijden tien aanvullende leaderboards in App Store Connect worden aangemaakt. Zie [configuratie, privacy en beperkingen](Documentation/GameCenter.md) en [verificatie](Documentation/GameCenterVerification.md).
