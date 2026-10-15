# Schermverhoudingen — 14 oktober 2026

De iPhone blijft in portret, ook wanneer het toestel wordt gedraaid. iPad ondersteunt portret, omgekeerd portret en beide landschapstanden. De configuratie geldt voor Debug en Release; de appdelegate past dezelfde apparaatkeuze toe op gepresenteerde schermen.

De HUD wordt als één compositie vergroot. Het dinoportret, de tekst, tellers, iconen, bladeren, omlijsting, recordbadges en oefensubtitel behouden hun verhoudingen. Op korte schermen begrenst de beschikbare hoogte de vergroting. Lange Nederlandse koppen delen een kleinere lettergrootte, zodat ze binnen hun vak passen.

Het landschap en de kaartviewport lopen door tot beide zijranden. De decoratie staat aan de echte schermranden, ook bij brede iPads. Dino op de kaart is groter en krijgt extra ruimte onder de wereldtitel en boven het beginpunt.

Tijdens een vraag staat Dino altijd gecentreerd in een eigen rij onder de vraag. Zijn grootte volgt de resterende ruimte onder de gemeten vraaginhoud; bij lange vragen en lagere schermen wordt hij kleiner. De vraagviewport blijft over de volle breedte gecentreerd. Vier antwoordklokken staan in landschap naast elkaar. Kortere telefoons gebruiken minder verticale witruimte en kleinere antwoordklokken. Langere vragen blijven scrollbaar; foutfeedback brengt de antwoorden in beeld. De analoge koppelklokken groeien op een normale iPad van maximaal 94 naar circa 151 punten, en tot 180 punten op brede schermen. Analoge en digitale kaarten hebben dezelfde breedte en hoogte. De twee instructiezinnen staan op aparte, gecentreerde regels; tekst bij andere uitgebreide vragen gebruikt ook een begrensde, gecentreerde kolom. Oefenklokken voor sorteren en gesproken tijden zijn eveneens groter op tablets.

## Controles

| Controle | Simulator | Resultaat |
| --- | --- | --- |
| Portret, beide draairichtingen, HUD-verhoudingen, randvulling en behoud van de vraag | iPhone 17 / iOS 26.5, iPhone SE / iOS 26.1, iPad Pro 11-inch / iPadOS 26.5, iPad A16 / iPadOS 27 | Geslaagd |
| Dino blijft onderaan bij scrollen, foutfeedback en lange koppelvragen | iPhone 17 en iPad Pro | Geslaagd |
| Eén Dino bij starten, voltooien en terugkeer naar de kaart | iPhone 17 en iPad Pro | Geslaagd |
| Vier antwoordkeuzes en blijvende foutfeedback | iPhone 17 en iPhone SE | Geslaagd |
| Pauzeren, hervatten en taalwisseling | iPhone 17 | Geslaagd |
| Grotere Dino staat op het gespeelde level in wereld 4 | iPad A16 | Geslaagd |
| Bestaande kernsuite | `Tools/test-dino.sh` | 437.231 controles geslaagd |
| Release-build voor iOS Simulator | `xcodebuild build -configuration Release` | Geslaagd |

Op twee bestaande iPadOS 26.5-simulatoren bleef de app in de eerder bewaarde portretstand staan. Dezelfde build doorloopt beide rotaties op een nieuwe, lege iPadOS 26.5-simulator en op iPadOS 27. De gerichte tests gebruiken geïsoleerde spelersprofielen. De definitieve iPadOS 27-suite meldt twee geslaagde tests en nul fouten, maar bleef daarna hangen bij het finaliseren van het Xcode-rapport; alleen dat eigen testproces is gestopt. De iPadOS 26.5-, iPhone- en iPhone SE-runs sluiten normaal af met `TEST SUCCEEDED` of `TEST EXECUTE SUCCEEDED`.

## Aanvullende vraagindeling — 15 oktober

- `testResponsiveOrientationsAndProportionalHUD` controleert nu ook dat titel, doelklok, antwoordrij en Dino hetzelfde schermmidden gebruiken, en dat alle antwoorden boven Dino blijven.
- `testCenteredPracticeClocksAndCompanionBelowQuestions` controleert grotere oefenkaarten, gelijke kaartafmetingen, gecentreerde tekst en Dino onder de vraagviewport in beide iPad-oriëntaties en op iPhone SE.
- `testMatchingSupportsDragsAlongsideTaps` controleert verbinden, overnemen en losmaken van verbindingen. De dropzone beslaat de hele vergrote tijdkaart. Op korte schermen scrolt de test de kaarten via de lege verbindingsruimte eerst in beeld. De aanvullende controles slagen op iPad A16 / iPadOS 27 en iPhone SE / iOS 26.1; de definitieve sleeprun op iPhone SE sluit af met `TEST SUCCEEDED`.

## Beelden

- [Kaart in portret](Screenshots/ResponsiveLayout/map-portrait-ipad.png)
- [Kaart in landschap](Screenshots/ResponsiveLayout/map-landscape-ipad.png)
- [Vraag in portret](Screenshots/ResponsiveLayout/game-portrait-ipad.png)
- [Vraag in landschap](Screenshots/ResponsiveLayout/game-landscape-ipad.png)
- [Lange oefenvraag met grotere Dino](Screenshots/ResponsiveLayout/practice-large-question-ipad.png)
- [iPhone](Screenshots/ResponsiveLayout/game-portrait-iphone.png)
- [Kleine iPhone SE](Screenshots/ResponsiveLayout/responsive-game-portrait-iphone-se.png)
