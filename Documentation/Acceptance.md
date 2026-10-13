# MVP-acceptatie — 11 oktober 2026

De app is in het bestaande native SwiftUI-project gebouwd, met de originele dino-asset. De kernlogica en de echte scherminteracties worden afzonderlijk gecontroleerd.

| Scenario's uit de opdracht | Controle |
| --- | --- |
| 1–3 Naam, eigen klok, standaardklok | UI-tests: lege naam blokkeert Verder; naam invoeren; eigen kleur; standaardklok overslaan. |
| 4–7 Kaart, startpositie, eerste level, ontgrendeling | Kerncontrole van 10 configuraties en initiële levels `[1, 10]`; UI doorloopt alle 9 gewone levels. |
| 8–11 Sterren bij 2/5, 3/5, 4/5 en 5/5 | Alle scoregrenzen automatisch getest; UI speelt 2/5, 3/5 en de volledige normale route met 5/5. |
| 12–13 Hoogste sterren behouden en Dino verplaatsen | Kerncontrole van hoogste score, blanco beginpunt en hoogste behaalde level; UI controleert 3/5 → 0/5, behoud van ontgrendeling en herstart. |
| 14–18 Directe boss, 10/10, normale 5/10, onvoldoende 9/10 en 4/10 | Volledige kernmatrix 0–10 met/zonder normale route; UI speelt directe 10/10, normale route met 5/10 en directe 9/10. |
| 19–20 Analoge en digitale klok | Alle 24 × 60 tijden mathematisch gecontroleerd; 03:00, 03:30, 03:45, 12:00, voorloopnullen, aanraak-snapping en plus/min-omslag. UI gebruikt beide klokken in alle vraagtypen. |
| 21–23 Thema's, later wijzigen, herstart | Kerncontrole van alle profielvelden en echte UserDefaults-opslag; UI test klok aanpassen in onboarding en instellingen, beëindigen en opnieuw openen. |
| 24 Geen geluid of spraak | Actieve target bevat geen audio-, speech- of StoreKit-code; geen audioresources verpakt of initialisatie aangeroepen. |
| 25 Telefoon en tablet | Echte speelroute op iPhone 18 Pro; personalisatie en boss op iPad A16; aanvullende controle van portret/landschap en bereikbare knoppen. Screenshots visueel nagekeken. |
| 26 Bestaande taalfunctionaliteit | Bestaande voorkeurssleutel en live taalwissel behouden; uitsluitend Nederlands en Engels. UI controleert de twee taalkeuzes, Engelse schermen en taalbehoud na herstart. |

## Uitgevoerde tests

- `Tools/test-dino.sh`: **110.415 geslaagde controles**, waaronder 3.000 gegenereerde levelpogingen, alle vraagtypen, unieke antwoorden, wisselende antwoordposities, dubbele taps, onvolledige pogingen en resetgedrag.
- iPhone 18 Pro / iOS 27: volledige normale wereld en boss, 0 sterren/herhaling/herstart, directe perfecte boss en klokpersonalisatie.
- iPad A16 / iPadOS 27: boss 9/10 zonder voorgaande levels, klokpersonalisatie en herstart, landschapstand en live taalwissel.
- iPhone SE (3e generatie) / iOS 26.1: onboarding, portret/landschap, bereikbare bediening en live taalwissel. Een achterblijvende navigatietitel bij taalwissel op iOS 26 is hersteld en opnieuw getest.
- Zowel Debug- als Release-build slagen.

De onafhankelijke testopslag en vaste random seed zijn uitsluitend beschikbaar in debug-builds. Productie vraagt geen account, speelt willekeurige vragen en bewaart het spelersprofiel lokaal. De testresultaten gebruiken simulatoren; er is geen fysiek apparaat getest.

Alle spelteksten zijn vertaald in Nederlands en Engels. De overige talen en oude spelonderdelen zijn verwijderd. Wereld 2 is bewust gesloten, met het label Binnenkort.

## Aanpassingen na de eerste versie

| Verzoek | Controle |
| --- | --- |
| Direct starten met naam | De eerste zichtbare invoer is `onboarding.name`; geen losse Start-stap. Lege naam blokkeert Verder. De knop blijft op iPhone SE bereikbaar met toetsenbord. |
| Geen 2/1-antwoordrasters | De generator maakt uitsluitend twee of vier opties. Alle 3.000 pogingen controleren dit. UI controleert twee volledige rijen van twee. |
| Foute antwoorden zelf bekijken | UI wacht drie seconden na een fout en controleert dat vraag 1/10 blijft staan. Alle vier de klokken blijven zichtbaar; Verder opent pas daarna vraag 2/10. |
| Transparante dino, vaste titel | De originele PNG is ongewijzigd hernoemd naar `dino-idle`; geen wit kader. De dino staat bij de klok, buiten de titel. Screenshots controleren de plaatsing. |
| Backflip bij maximale punten | Alle acht poses zijn ongewijzigd hernoemd en gekoppeld. UI controleert dat de backflip alleen verschijnt bij 5/5 of 10/10, ook bij herhaling. |
| Nieuwe themakleur | Primaire kleur en AccentColor zijn #81D349; tekst op groene knoppen is donker. |
| Oude game en talen weg | Bronbestanden, resourcecatalogus en projectverwijzingen opgeschoond; een nieuwe build verpakt alleen en.lproj en nl.lproj. |

## Tweede verfijning

- Sterren, voortgang, correcte antwoorden, kristallen en trofeeën gebruiken groen.
- De klok staat los van Dino in het midden; op iPhone SE en iPad wordt het midden vóór/na feedback automatisch vergeleken.
- De nieuwe duimenbeelden zijn hernoemd en spelen bij ieder correct antwoord; door naar de volgende vraag na 0,72 seconde, zonder tekstbanner.
- De salto gebruikt een doorlopende rotatie en sprongbaan, gecorrigeerde beeldoriëntaties en uitgelijnde draaipunten. De bewegingscurve wordt op 120 tijdstappen per seconde gecontroleerd op onderbroken rotatie en hoogte.
- Een nieuw profiel heeft kaartpositie 0 (blanco beginpunt, geen speelbaar level). De positie volgt het hoogste behaalde level en blijft na een slechtere herhaling bewaard.
- Startkaarten tonen geen vragenaantal of instructiesubtitel. De eigen verlaten-kaart is visueel bekeken in portret en landschap; annuleren houdt dezelfde vraag vast, verlaten keert terug naar de kaart.
- Nieuwe UI-runs: drie controles op iPhone SE en drie op iPad geslaagd; volledige normale wereld, directe perfecte boss en herhaling/herstart op iPhone 18 Pro geslaagd.
- Na de visuele kaartcontrole zijn de scrollankers vervangen door vaste rijen. Aanvullende UI-tests controleren Dino volledig in het scherm bij level 1 en 10, inclusief herstart; geslaagd op iPhone 18 Pro en iPhone SE. De definitieve Release-build slaagt.


## Junglelandschap en speelse header

- Alle landschapselementen zijn uit shapes opgebouwd in één statische Canvas. Het decor loopt achter de titel en over de hele scrollroute door; de sierlijke vormen onderscheppen geen aanrakingen.
- De ingang heeft boomkruinen en lianen, de middenroute een rotswaterval en lagune, en de boss een open plek met mosstenen. Het zandpad blijft vrij voor levelknoppen en Dino.
- De laatste 560 punten mengen het junglepalet met een apart horizonpalet. Begroeiing maakt plaats voor lage silhouetten en nevel. De preview van wereld 2 blijft gesloten.
- De header heeft een dinoportret met naam, een levelbadge, de ster boven het verdiende sterrentotaal zonder maximum en een instellingenknop op de kaart. De badges zijn recht uitgelijnd en hebben beperkte breedte op tablets; de onderrand is licht gebogen. Tijdens een level blijft pauzeren beschikbaar.
- UI-controle op iPhone 18 Pro / iOS 27 en iPad A16 / iPadOS 27: vaste positie van de header tijdens scrollen, juiste volgorde van de onderdelen, direct openen van instellingen, en verandering van 0 naar 3 sterren na een voltooid level. Op beide apparaten geslaagd.
- De bestaande UI-controle voor vier antwoordkeuzes en blijvende foutfeedback slaagt op iPhone. Landschapstand en taalwisseling worden gecontroleerd via de kaartinstellingen; pauzeren blijft beschikbaar tijdens een level.
- Op iPhone SE (3e generatie) / iOS 26.1 zijn ook de foutfeedback en portret/landschapindeling gecontroleerd. De eerdere kernsuite slaagde met 110.536 controles.

## Verfijning van landschap en HUD

- Bomen hebben een vertakte, taps toelopende stam en asymmetrische kruinen. Palmen gebruiken gebogen, hangende bladeren; struiken hebben lage, overlappende silhouetten en varens een herkenbare bladstructuur.
- Rotsen hebben onregelmatige contouren, schaduwvlakken en kleine mosplekken. Steenclusters liggen op de grond. De waterval heeft een zichtbare aanvoer, een getrapte rotswand, een verbredende waterstroom, schuim en een poel.
- Dino staat met zijn voeten op de huidige levelknop, horizontaal gecentreerd, zonder naamlabel. De figuur onderschept geen aanrakingen. Het blanco beginpunt en de bestaande voortgangsregels blijven behouden.
- De HUD staat recht, met gelijke level- en sterrentegels. De ster staat boven het verdiende totaal. Het tandwiel opent vanuit de kaart direct de instellingen; het hoofdmenu heeft geen pauzeknop.
- De definitieve UI-controle slaagt op iPad A16 / iPadOS 27 en iPhone SE / iOS 26.1: header tijdens scrollen, direct openen van instellingen, horizonovergang, verdiende sterren en Dino op de levelknop. De previews zijn visueel nagekeken en opgeslagen in `Documentation/Screenshots`. De level-10-positie, portret/landschap en taalwisseling zijn daarnaast gecontroleerd op iPhone 18 Pro. De definitieve Release-build slaagt.

## Rustigere reacties

De duimen gebruiken één geselecteerde afbeelding met een kleine vergroting; de foutreactie gebruikt één geselecteerde afbeelding met een lichte kanteling en blijft daarna stil staan. De nieuwe foutbeelden zijn ongewijzigd hernoemd. De salto gebruikt vier gekozen poses, met één vaste afbeelding gedurende de volledige draai; geen pose-overvloeiingen of dubbele contouren.

Kerncontrole: **112.169 geslaagde controles**, inclusief stabiele reactiebeelden, stille eindposes en Minder beweging. De directe perfecte boss en de foutfeedback zijn via UI getest op iPhone 18 Pro. De foutreactie is na visuele controle naar de vaste feedbackbalk verplaatst; op iPhone SE blijven alle vier de antwoorden, Dino en Verder zichtbaar. De afzonderlijke Dino-reactie is toegankelijk en verdwijnt pas bij de volgende vraag. De native schermopname is per frame beoordeeld op de duimen en salto.

## Doorlopende start en voltooiing

- De startkaart staat in dezelfde scène als de kaart en het level. Spelen bereidt de sessie direct voor; de kaart verdwijnt tegelijk met het verschijnen van het level. Sluiten via de knop, buiten de kaart tikken en de greep omlaag slepen blijven beschikbaar.
- Eén gedeelde Dino wordt bij vragen, foutfeedback en resultaat gebruikt. Bij maximale punten begint de salto bij de laatste vraag en eindigt hij op de resultaatplek. De resultaatweergave maakt geen tweede Dino aan. De figuur onderschept geen knoppen en blijft tijdens scrollen op zijn plek in de inhoud.
- UI-controles slagen op iPhone SE / iOS 26.1 en iPad A16 / iPadOS 27: startkaart verdwenen zodra het level opent, één Dino voor/na voltooiing en correcte landingspositie. De directe perfecte boss en blijvende foutfeedback slagen op iPhone SE; verlaten/annuleren, landschap en taalwisseling zijn ook gecontroleerd. De iPad-opname is per tiende seconde visueel nagekeken.

## Dinoportret en personalisatie — 12 oktober 2026

- Het headerportret is vergroot van 44 naar 62 punten (36 naar 46 in compacte weergave). De bovenste stekels blijven volledig zichtbaar. Portret en naam openen **Mijn dino**, zowel op de kaart als tijdens een level.
- Bandana, stekels, lichaam en buikje/tenen hebben elk kleurbolletjes en een vrije systeemkleurkiezer. Het vaste voorbeeld blijft zichtbaar tijdens scrollen. De oorspronkelijke kleuren gebruiken de originele afbeelding; kleurwijzigingen behouden textuur, schaduwen, ogen, mond en bandanatekst. Alleen het headerportret en het voorbeeld gebruiken de personalisatie.
- De vier kleuren worden direct lokaal opgeslagen. Oude profielen zonder kleurvelden behouden hun naam, klokthema en voortgang. Herstel naar de oorspronkelijke kleuren, voortgang resetten en cloudmerge zijn gecontroleerd. Cloudvoortgang bevat geen dinokleuren.
- Naamwijzigingen zijn op elk moment mogelijk; de bestaande Unicode-validatie blijft gelden. Bewaren en afsluiten met een aangepaste naam zijn getest, inclusief twee opeenvolgende wijzigingen en herstart.
- `Tools/test-dino.sh`: **112.204 geslaagde controles**. `testPersonalizeHeaderColorsAndName` slaagt op iPhone 17 / iOS 26.5 en iPad Air 13-inch (M4) / iPadOS 27, inclusief portret/landschap en personalisatie tijdens een level. `testFreeAvatarColorPicker` slaagt op iPhone: een vrije RGB-kleur via de systeemschuifbalken blijft na herstart bewaard.
- De Debug-build slaagt. Screenshots van header en personalisatie zijn visueel nagekeken en opgeslagen als `personalize-header-*` en `personalize-colors-*` in `Documentation/Screenshots`.
- Maskercorrectie: gebogen contouren rond ogen en mond vervangen de rechte uitsparingen. De lichte voorkant van de bovenste stekels gebruikt ook de stekelkleur. Elf regressiecontroles beschermen deze plekken en de oorspronkelijke ogen en tong. `Tools/test-dino.sh` slaagt met **112.640 controles**; `testAvatarColorMaskContours` slaagt op iPhone 17 / iOS 26.5. De bijgewerkte iPhone-screenshots en `personalize-mask-closeup.png` zijn visueel gecontroleerd.

## Welkom, HUD en Game Center-naam — 12 oktober 2026

- De HUD-dino is 82 punten groot (60 in compacte weergave), zonder kwastje of naam. Tikken opent nog steeds de kleurkeuze, ook tijdens een level.
- De eerste welkomststap is **Maak jouw dino**, met dezelfde vier direct bewaarde kleurkeuzes als de HUD-editor. Daarna volgt de klokkeuze. Verder blijft bereikbaar tijdens scrollen; er is geen naamveld of verplichte Game Center-aanmelding. Een afgeronde onboarding blijft zonder lokale naam afgerond na herstart.
- Instellingen toont de Game Center-displaynaam als alleen-lezen tekst. De naam wordt bij authenticatiewijzigingen en terugkeer naar de app vernieuwd. Er is geen lokale fallback. Bestaande lokale naamvelden blijven uitsluitend ongebruikt in de legacy-opslag staan.
- Bij een Game Center-koppeling bevat de levelstartkaart een eigen regel met diezelfde Apple-naam, sterren, score en de gemeten tijd bij het resultaat. Niet gespeelde levels en ontbrekende tijden krijgen geen verzonnen resultaat. De naam staat niet in de welkomsflow, HUD of dino-editor.
- `Tools/test-dino.sh`: **112.636 geslaagde controles**, inclusief onboarding zonder naam, herstart, legacy-migratie en behoud van voortgang en dinokleuren. `testWelcomeDinoAndGameCenterIdentity` slaagt op iPhone 17 / iOS 26.5 en iPad Air 13-inch (M4) / iPadOS 27. `testPersonalizeHeaderColors` slaagt op iPhone, inclusief reset, herstart, een lopend level en landschap. De bestaande controle van optionele vrienden en het ouderscherm slaagt ook.
- Game Center-identiteit en vrienden worden in de schermtests geleverd door de bestaande geïsoleerde Debug-fixtures; de Apple-aanmelding met een echt account is hier niet opnieuw doorlopen. De screenshots `welcome-dino-colors-*`, `hud-dino-no-name-*`, `settings-game-center-name-*` en `level-own-game-center-result-*` zijn visueel gecontroleerd. Op iPad meldde de test en gehele geselecteerde suite nul fouten; Xcode bleef daarna hangen in `Finalize test log`. Alleen dat eigen testproces is beëindigd. Het iPhone-testrapport rondde normaal af met `TEST SUCCEEDED`.


## Dinoportret, HUD-balans en resultaatvolgorde — 12 oktober 2026

- De HUD en de eigen resultaatregel gebruiken hetzelfde ronde dinoportret met de gekozen kleuren. Een aparte hoofduitsnede volgt de kin en achterste stekels, verwijdert handen en torso en geeft ruimte boven de bovenste punten. Er is geen rechte afsnijding van de nek of zichtbaar stukje duim.
- De HUD-dino is 84 punten groot (62 compact). Level en Sterren hebben identieke tekstkoppen en kleinere kaarten van 66 punten (52 compact), met cijfers van 22 punten (20 compact). De instellingen-/pauzeknop is 58 punten groot (52 compact). De sterafbeelding in de HUD is vervangen door **Sterren**.
- De eigen regel in de levelstartkaart toont het gekozen portret links van de Game Center-naam en sterren. Alleen het stericoon met aantal en de tijd rechts blijven als resultaat staan; de fractie goede antwoorden en het stopwatchicoon zijn verwijderd. Een ontbrekende tijd blijft **—**.
- Eigen en vriendenresultaten staan samen onder **Resultaten**, eerst op sterren aflopend en bij gelijk aantal op gemeten tijd oplopend. Ontbrekende tijden komen na gemeten tijden met hetzelfde aantal sterren; volledige gelijke resultaten krijgen een stabiele volgorde op naam en ID. De eigen regel blijft herkenbaar aan **Jij** en de gekleurde kaart.
- `Tools/test-dino.sh`: **112.639 geslaagde controles**, met regressiecontrole voor sterren vóór tijd, ontbrekende tijden en gelijke sterren zonder voorrang voor goede antwoorden. De Game Center-opslag en voortgangsberekening zijn niet aangepast.
- `testLevelFriendsRowsWithTimings` en `testWelcomeDinoAndGameCenterIdentity` slagen op iPhone 17 / iOS 26.5 en iPad (A16) / iPadOS 26.5; beide testrapporten sluiten af met **TEST SUCCEEDED**. Ze controleren de volgorde inclusief de eigen regel, dino links van naam/sterren, uitsluitend sterren zonder 5/5, tijd rechts, kleinere kaarten en grotere instellingenknop. `testPersonalizeHeaderColors` slaagt op iPhone inclusief herstart en landschap. De screenshots `hud-dino-portrait-*`, `level-ranked-dino-result-*` en `level-ranked-friends-*` zijn visueel gecontroleerd. Game Center-identiteit en vrienden gebruiken geïsoleerde Debug-fixtures.


## Contextuele HUD, direct oefenen en volledige reset — 12 oktober 2026

- Het leveloverzicht heeft **dino | Level | Sterren | Oefenen | Instellingen**. De laatste vier kaarten delen een hoogte van 64 punten (52 compact), dezelfde afgeronde hoeken en achtergrond. De tekstkoppen zijn 12 punten (11 compact); de cijfers blijven 22 punten (20 compact). De HUD-dino heeft geen cirkel; de hoofduitsnede volgt de onderkant van de kin nauwkeuriger en houdt de handen buiten beeld.
- Tijdens een level vervangt **Vragen** het totale aantal sterren, met bijvoorbeeld **1/5** of **1/10**. De teller onder de HUD is verwijderd. De voorbeeldknop staat tussen de teller en pauze en is tijdens antwoordfeedback uitgeschakeld. Oefenen heeft ook een voorbeeldknop in de eigen header.
- Pauze verlaat vraag 1 direct, ook tijdens feedback op die eerste vraag. Vanaf vraag 2 blijft de bevestiging voor verlaten/blijven spelen aanwezig. Afgebroken pogingen schrijven geen resultaat.
- **Levels oefenen** opent rechtstreeks vanuit de HUD in een eigen scherm met een sluitknop. De ingang in instellingen is verwijderd. Oefensessies blijven los van de reguliere levelvoortgang.
- **Voortgang resetten** vraagt een bevestiging en wist alle oude lokale opslagvelden, inclusief naamlegacy, kleuren, klokthema, voorkeuren, geschiedenis, tijdmetingen en onboarding. Vrienden en delen worden uitgezet; iCloud-snapshots van deze app worden verwijderd. Alleen een lege resetmarkering blijft staan om vertraagde oude cloudgegevens te blokkeren. Er wordt een nieuwe installatie-ID gemaakt en de hele SwiftUI-root wordt opnieuw opgebouwd, zodat geen open scherm of sessie terugkomt.
- De Debug-build sluit na 700 ms, nadat de lokale reset naar opslag is weggeschreven. Een koude herstart begint met de eerste dino-welkomststap. De release-build start deze stap direct in de app; zelf afsluiten wordt door Apple afgeraden (https://developer.apple.com/library/archive/qa/qa1561/_index.html). De resetdialoog meldt dat gepubliceerde Game Center-scores bij Apple blijven.
- `Tools/test-dino.sh`: **313.492 geslaagde controles**, inclusief alle herstel- en cloudtests. De gerichte resetcontrole slaagt met **46 controles**, inclusief offline wissen, oude onbekende voorkeuren verwijderen en blokkeren van een vertraagde oude cloudsnapshot. De release-build sluit af met **BUILD SUCCEEDED**.
- `testContextualHUDAndFirstQuestionExit` slaagt op iPhone 17, de kleine iPhone SE en iPad (A16). `testFullResetClosesAndRestartsWelcome` slaagt op iPhone 17 en iPad (A16), inclusief werkelijk afsluiten, koude herstart, standaardkleuren/klok en reset van alle voorkeuren. `testPracticeSelectionAndEndlessDigitalMinutes`, `testStartPointCleanCardAndExitCancel` en de landschaps-/taalcontrole slagen op iPhone. De definitieve iPhone-, iPhone SE- en iPad-rapporten eindigen met **TEST SUCCEEDED**. De screenshots `hud-map-practice-*`, `hud-game-questions-*` en `reset-fresh-welcome-*` zijn visueel gecontroleerd.


## Personalisatie van de hele dino — 12 oktober 2026

- De eigen dino op de levelkaart en de duimen-, salto- en foutreacties gebruiken dezelfde vier opgeslagen kleuren als de HUD. Alle zeven gebruikte afbeeldingen lopen door dezelfde renderer. De standaardkleuren laten elk origineel volledig intact; de uitsnede van het HUD-hoofd blijft behouden.
- De zes animatiehoudingen hebben eigen maskers voor bandana, lichte stekelranden, ogen en mond. Ook bij de gedraaide saltohouding blijft de tong los van de bandana en blijven ogen en mond behouden. De cache bevat nu de afbeeldingsnaam, zodat houdingen elkaar niet overschrijven; de ingekleurde beelden worden vooraf voorbereid buiten de UI-thread.
- Het label **Oefenen / Practice** staat boven het boek en gebruikt dezelfde hoogte, lettergrootte en tekststijl als **Level** en **Sterren**.
- De bestaande UI-controles `testContextualHUDAndFirstQuestionExit` en `testPlayCardAndContinuousResultDino` slagen op iPhone 17 (**TEST SUCCEEDED**). De animatiecontrole kiest eerst vier afwijkende kleuren en bewaart beelden van het beginpunt, de landing en het voltooide level. De zeven native rendertests bevestigen ongewijzigde standaardafbeeldingen en aparte gecachte beelden per houding. Alle beelden in `Screenshots/PersonalizedCompanion` zijn visueel gecontroleerd.
- De gerichte bestaande kerncontroles voor animatie, opgeslagen kleuren en het oorspronkelijke contourmasker slagen met **2.538 controles**. De volledige kernsuite slaagt na de afzonderlijke uitbreiding van de leveltests met **361.179 controles**. De definitieve release-build eindigt met **BUILD SUCCEEDED**.


## Gekozen kleuren vanaf het eerste beeld — 13 oktober 2026

- Bij een koude start bereidt `DinoAvatar` de gekozen afbeelding voor voordat deze wordt getoond. De oorspronkelijke groene dino dient alleen nog als afbeelding wanneer de speler daadwerkelijk de standaardkleuren gebruikt. Latere wijzigingen met de kleurkiezer behouden de asynchrone verwerking.
- Het portret en de dino op de kaart delen de eenmaal ingekleurde volledige afbeelding. Ook een nog niet voorbereide animatiehouding krijgt meteen de gekozen kleuren.
- De native controle van de echte beeldselectie met een lege cache bevestigt dat het eerste beeld al de blauwe bandana en paarse bovenste stekel heeft, dat hoofd en lichaam dezelfde cache delen, dat alle zeven houdingen hun gekozen kleuren krijgen en dat de standaardafbeelding behouden blijft.
- `testPersonalizeHeaderColors` slaagt op iPhone 17, inclusief afsluiten, opnieuw starten, opgeslagen kleuren, terugzetten naar standaard en personaliseren tijdens een level (**TEST SUCCEEDED**). Het beeld direct na herstart is visueel gecontroleerd en bewaard als `Screenshots/PersonalizedCompanion/personalize-cold-start-iphone.png`.
