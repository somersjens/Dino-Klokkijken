# Jungle — plaatsing, begroeiing en dieren

15 oktober 2026.

De eerste bomen staan 135–185 punten hoger dan voor deze herindeling. Hun kronen zijn van het pad af gedraaid en vormen een scherp groen kader naast Dino. De voorste begroeiing overlapt de onderkant van de bovenste watervallen. De open route blijft zichtbaar; er is geen terugkeer van de doorschijnende struikenband.

De waterval langs de route staat op de linkeroever bij level 3, verder naar de rand en 22% lager. Een gespiegelde bovenloop komt zichtbaar van links en stroomt naar de lip. Basisillustratie en stromend water delen dezelfde positie, spiegeling en hoogtefactor. De overige bomen, palmen en lage begroeiing vormen losse groepen bij de bochten en de bosrand. Nieuwe details zijn brede bladplanten, bloemen, mosrotsen, paddenstoelen en vier gevallen boomstammen met schorslijnen, houtringen en jonge bladeren. Beide uiteinden van de gevallen stammen hebben een afgeronde doorsnede met houtringen; de schorslijnen blijven binnen de stam.

De tekenvolgorde is grond met paddenstoelen en gevallen stammen, stromend water, slangen, voorste bomen en bosjes, en dwarrelende bladeren. Zo liggen paddenstoelen achter de stammen en kruipen slangen achter de bosjes.

## Een vrije route

`JungleMapLayout` deelt de vaste levelafstanden en bochtposities met de getekende route. Het berekent de werkelijke kubische bochten en controleert de volledige omtrek van ieder object: brede kronen, smallere stammen, hangende lianen en watervalpoelen hebben afzonderlijke banden. De vrije strook bevat ook de schuine padrand, levelstenen en sterrenrijen. Objecten schuiven zo nodig verder de oever op. Er wordt geen vegetatie door een padmasker afgesneden en geen boom door het pad heen getekend.

De plaatsing is onafhankelijk van de tekenvolgorde. De oevers worden in een kolom van maximaal 720 punten ingericht, zodat de begroeiing ook op brede iPads naast het speelgebied blijft staan.

## Kleine bewegende scènes

- Vijf bomen laten elk vier bladeren langzaam dwarrelen en draaien. De volledige drift blijft in een berekende vrije strook langs de oever.
- Drie kleine slangen bewegen over de grond in rustige bochten, met een taps lichaam, schubvlekjes, contactschaduw en af en toe een tongbeweging. Hun hele bewegingsruimte valt onder dezelfde padcontrole.
- Slangen en vallende bladeren gebruiken kleine afzonderlijke Canvas-lagen, maximaal twintig updates per seconde; vogels en water maximaal 24. Ze pauzeren buiten beeld, bij een inactieve app, bij Minder beweging en tijdens slepen en uitrollen van de kaart. Ze hervatten zodra de kaart stilstaat. Het landschap, de begroeiing en de overige details blijven statisch.

## Scrollwerk beperken

De volledige plaatsing wordt eenmaal per schermbreedte opgelost en als onveranderlijke scène bewaard in een cache voor maximaal acht breedtes. Achtergrond, waterval en dieren delen die scène. Viewupdates en animatieticks lossen de omtrekken dus niet opnieuw op. Een lokale geoptimaliseerde meting van drie plaatsingsrondes kostte vóór deze wijziging mediaan 10,75 ms; een koude nieuwe scène 1,79 ms en drie hergebruikte rondes minder dan 0,001 ms. Dit meet alleen de gedeelde geometriecode op de Mac, geen scrollframerate.

De statische voorste begroeiing wordt asynchroon getekend in tegels van 512 punten hoog. Alleen nabije tegels blijven opgebouwd, met minimaal 768 punten voorbereiding. Slangen bewegen erachter zonder dat die bomen en bosjes voor elke animatiestap opnieuw getekend worden. De doorlopende lucht behoudt zijn bestaande naadloze Canvas. Watervalcurves worden eenmaal opgebouwd en gedeeld tussen de animatiestappen.

De bestaande `testMapScrollPerformance` is vóór en na deze verfijning uitgevoerd op dezelfde iPhone 17-simulator met iOS 26.5, in Debug, met drie meetrondes van vier snelle vegen omhoog en vier omlaag. [Voor](WorldTestLogs/JungleRedesign/scroll-before.log) en [na](WorldTestLogs/JungleRedesign/scroll-after.log) bevatten de ruwe waarden.

| Gemiddelde per ronde | Voor | Na |
| --- | ---: | ---: |
| App-CPU-tijd | 14,054 s | 10,491 s (−25,4%) |
| Uitgevoerde CPU-instructies | 162,52 miljard | 145,83 miljard (−10,3%) |
| Totale testhandeling, inclusief automatisering | 30,110 s | 27,148 s |
| Scroll- en uitrolinterval | 2,594 s | 2,590 s |
| Absoluut fysiek appgeheugen | 135,5 MB | 140,2 MB |
| Piek fysiek appgeheugen | 141,1 MB | 142,0 MB |

De afzonderlijke statische lagen gebruiken hier ongeveer 4,6 MB meer appgeheugen en verminderen het CPU-werk. De CPU-tijd varieerde vóór de wijziging sterker (18,5% relatieve standaardafwijking) dan erna (6,2%); het instructieaantal is stabieler (1,2% en 0,3%). Deze beperkte simulatorsessie ondersteunt minder scrollwerk, maar meet geen constante framerate op een fysiek toestel.

## Verificatie

- De definitieve Debug-simulatorbuild en de scrolltest slagen: [build- en testlog](WorldTestLogs/JungleRedesign/scroll-after.log).
- **546.312 kern- en geometriecontroles slagen**: [log](WorldTestLogs/JungleRedesign/core-polish.log). De controles bekijken de hele oeverbegroeiing en bewegingsruimtes op elf schermbreedtes, van 320 tot 1.366 punten. Ze controleren elke verticale puntpositie, dichter dan de plaatsingsberekening zelf. Extra controles bewaken de hergebruikte scène, de voorgrondtegels en de gewijzigde waterval.
- De uitgebreide junglecontrole slaagt op [iPhone](WorldTestLogs/JungleRedesign/route-polish.log): scrollen door wereld 1, instellingen openen, een level spelen en terugkeren naar Dino op de behaalde steen. De bestaande kaart-, speel-, pauzeer-, hervat- en verlaatcontrole slaagt op [iPad](WorldTestLogs/JungleRedesign/ipad-polish.log).
- Een verouderde verwachting voor Dino's voeten is gelijkgetrokken met de bestaande gedeelde positie (`node.midY + 12`), zoals al gecontroleerd door `testDinoStandsOnCompletedLevel`; de kaartfiguur zelf is niet verplaatst.
- De entree, waterval en het middenstuk zijn na deze verfijning apart bekeken met geïsoleerde testvoortgang: [entree](Screenshots/JungleRedesign/polish-entrance-iphone.png), [level 3](Screenshots/JungleRedesign/polish-level-3-iphone.png), [middenstuk](Screenshots/JungleRedesign/polish-middle-iphone.png), [iPad](Screenshots/JungleRedesign/polish-entrance-ipad.png). De uitgebreide routecontrole bewaart ook de overige secties en de wereldovergang.
- `git diff --check` is schoon. Screenshots en korte animatievoorbeelden blijven in de lokaal genegeerde screenshotmap.
