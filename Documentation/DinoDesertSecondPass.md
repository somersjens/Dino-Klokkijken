# Dino-Desert — tweede verbeterslag

19 oktober 2026. Deze ronde verfijnt de woestijn van wereld 2, met de compositie uit de [eerste ronde](DinoDesertFirstPass.md) als basis.

## Afwerking

- De zandsteen heeft onregelmatige, licht gebogen contouren, afgebroken richels en verschillende overhangende schouders. Gebogen lagen, kleine erosieholtes, vertakte scheuren en fijne korrel geven de rotsen meer reliëf. Zand bedekt delen van hun voet.
- De natuurlijke boog heeft een asymmetrische opening, een donkere binnenrand en lichte afgesleten randen. De verre formaties gebruiken dezelfde vormtaal met minder contrast en detail.
- Ruïnestenen hebben afgeronde, afgebrokkelde hoeken, lichte bovenvlakken, donkere zijvlakken en kleine putjes. De kolommen staan niet perfect recht. Een gevallen sluitsteen, een verweerd reliëf en opgewaaid zand maken de poort ouder.
- De fossielkuil heeft een onregelmatige bodem en een lichte rand van los zand. De ribben verschillen in lengte, met werveluitsteeksels en enkele breuken; de schedel heeft kleine slijtageplekjes.
- De waterput heeft houtnerven, bevestigingen, een gerafeld touw, een gebarsten emmer en dood hout bij de voet. De zonnewijzer heeft korrel, slijtage en een scheur in het voetstuk.
- Drie korte reeksen dinoafdrukken en enkele droge grondscheurtjes liggen naast het pad. De duinkammen hebben meer variatie in afstand en buiging; de fijne ribbels zijn zachter.

## Zandwind

Fijne zandkorrels en korte lage windsluiers bewegen rustig over de open grond. Een apart masker gebruikt dezelfde decorposities en tekenfuncties als het statische landschap. Daardoor blijft de wind achter rotsen, cactussen, fossielen en de wereldbaas. De opening van de rotsboog blijft doorlaatbaar.

De volledige speelroute heeft een extra brede uitsparing voor levelstenen en sterren. Kleine Canvas-vlakken van 280 punten hoog verversen maximaal zestien keer per seconde. Buiten de viewport en als de app niet actief is, pauzeren ze. **Minder beweging** gebruikt een vaste tijd van nul.

De uitwerking staat in `Dino/Views/DinoDesert.swift`. In `JungleLandscape.swift` is alleen de wereldspecifieke windlaag toegevoegd. Levels, routeposities en gameplay zijn in deze ronde niet aangepast.

## Beelden

Volledige native kaarten op [320](Screenshots/DinoDesertSecondPass/native-320.png), [393](Screenshots/DinoDesertSecondPass/native-393.png), [834](Screenshots/DinoDesertSecondPass/native-834.png) en [1194](Screenshots/DinoDesertSecondPass/native-1194.png) punten. De auditbeelden gebruiken genummerde stenen op de echte levelposities. [De zes decorplekken naast elkaar](Screenshots/DinoDesertSecondPass/landmarks.png).

Daadwerkelijke appbeelden: entree op [iPhone](Screenshots/DinoDesertSecondPass/entrance-iphone.png) en [iPad](Screenshots/DinoDesertSecondPass/entrance-ipad.png), en de baasomgeving op [iPhone](Screenshots/DinoDesertSecondPass/boss-iphone.png) en [iPad](Screenshots/DinoDesertSecondPass/boss-ipad.png).

Vier vaste tijdstippen tonen de wind: [1](Screenshots/DinoDesertSecondPass/motion-0.png), [2](Screenshots/DinoDesertSecondPass/motion-1.png), [3](Screenshots/DinoDesertSecondPass/motion-2.png) en [4](Screenshots/DinoDesertSecondPass/motion-3.png). De screenshotmappen blijven zoals gebruikelijk lokaal en staan in `.gitignore`.

## Verificatie

- De definitieve iOS-simulatorbuild slaagt.
- `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn gericht op wereld 2 uitgevoerd op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. Deze controleren onder meer level 11, een halfuurantwoord, de HUD en het openen van de eindbaas.
- De vier animatietijdstippen hebben aantoonbaar verschillende pixels. Twee renders met de stilstandoptie zijn pixelgelijk; deze optie volgt dezelfde tijd-nulroute als Minder beweging.
- **6.720** meetpunten rond de tien levelstenen hebben nul dekking in het windmasker. Een punt binnen de rots van de boog is afgeschermd, terwijl een punt in de opening volledig doorlaatbaar is.
- Alle vier schermbreedtes en de echte appbeelden zijn visueel gecontroleerd. Een fout met los gevulde contoursegmenten werd in de beeldcontrole gevonden en hersteld vóór de definitieve build en tests.
- `git diff --check` is schoon. De schermtests gebruiken aparte Debug-profielen.

[Meetgegevens](WorldTestLogs/DinoDesertSecondPass/visual-checks.json) · [iPhone-tests](WorldTestLogs/DinoDesertSecondPass/iphone-tests.log) · [iPad-tests](WorldTestLogs/DinoDesertSecondPass/ipad-tests.log).
