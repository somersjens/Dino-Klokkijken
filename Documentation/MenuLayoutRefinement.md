# Welkom, oefenen en instellingen — 16 oktober 2026

Het welkomstscherm gebruikt op brede vensters een inhoudskolom van maximaal 740 punten, voorbeelden van 270 punten en grotere tekst, kleurstalen en knoppen. In een breed, lager venster staan het voorbeeld en de opties naast elkaar. Smalle vensters behouden de compacte indeling. De gedeelde klokeditors gebruiken dezelfde maten.

Oefenen opent op iPad als een hoge, afgeronde sheet met een zichtbare strook van de kaart erboven. De klokvoorbeelden en vraagregels zijn groter. De start- en terugknop blijven onderaan bereikbaar terwijl de opties scrollen.

Instellingen gebruikt op iPhone en iPad een gecentreerde titel, zachte groentinten en witte kaarten met een extra binnenlaag. Nederlands en Engels staan direct naast elkaar; een taalkeuze wordt meteen toegepast. De enige klaar-knop staat onderaan. Omlaag vegen sluit de sheet eveneens. De schakelaarlabels hebben een eigen ruim tikvlak en behouden de native switch en toegankelijkheid.

## Controle

- `build-for-testing` slaagt voor iOS Simulator.
- `testAdaptiveWelcomePracticeAndSettingsPresentation` slaagt op iPhone 17 en iPad A16 met iOS/iPadOS 26.5. De test controleert de grotere voorbeelden en bediening, iPad-landschap, hoge oefensheet, scrollen en kiezen, de vaste onderste knop, directe taalwisseling, Mijn klokken en beide manieren om instellingen te sluiten.
- `testSettingsPreferencesPersist` slaagt op iPhone 17 en iPad A16 met iOS/iPadOS 26.5, inclusief voorkeuren na herstart, hoog contrast en Nederlandse/Engelse labels.
- `git diff --check` meldt geen problemen.

## Schermbeelden

- [Welkom op iPad](Screenshots/MenuLayout/ipad/adaptive-welcome-dino.png)
- [Welkom op iPad in landschap](Screenshots/MenuLayout/ipad/adaptive-welcome-landscape.png)
- [Analoge klok op iPad](Screenshots/MenuLayout/ipad/adaptive-welcome-analog.png)
- [Oefenen op iPad](Screenshots/MenuLayout/ipad/adaptive-practice-sheet.png)
- [Instellingen op iPad](Screenshots/MenuLayout/ipad/adaptive-settings-dutch.png)
- [Instellingen op iPhone](Screenshots/MenuLayout/iphone/adaptive-settings-dutch.png)
- [Engelse instellingen op iPhone](Screenshots/MenuLayout/iphone/adaptive-settings-english.png)

De PNG-bestanden worden lokaal bewaard en vallen onder de bestaande screenshotuitsluiting in `.gitignore`.
