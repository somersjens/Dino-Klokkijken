# Jungle-entree — 15 oktober 2026

De eerste wereldbanner staat 48 punten hoger in portret. De ruimte onder het bord, tussen de vriendenknop en baasuitnodiging en vóór de route is verkleind. Daardoor schuift het beginpunt in totaal 88 punten omhoog ten opzichte van de oorspronkelijke entree. De vriendenknop krijgt aan beide kanten een kleine tak met dezelfde gevouwen bladeren en nerven als het wereldbord. De drie doorschijnende rijen struiken en bijbehorende nevelheuvels achter Dino zijn verwijderd; de open plek en de scherpe voorgrondbomen blijven over.

De lucht loopt minimaal 900 punten boven de scrollinhoud door, op grotere schermen anderhalve schermhoogte. Eén doorlopend statisch Canvas tekent lucht, zonnegloed, wolken en bladcontouren aan beide kanten van de oorspronkelijke bovenrand. De eerdere losse verlenging miste de over de rand vallende zonnegloed en liet daardoor bij doortrekken nog een horizontale kleurstap zien. De jungleoevers komen geleidelijk in de open plek op; ze tekenen geen rechte kleurvlakken meer over de bovenste lucht.

Alle drie junglewatervallen hebben bewegende waterstrepen, uitzettende rimpels en spatwater. Het landschap, de rotsen, planten en basiswaterval blijven in het statische Canvas. Elke bewegende laag beslaat slechts 144 × 346 ontwerppunten vóór schaling en werkt maximaal 30 keer per seconde bij. De eigen zichtbaarheid pauzeert elke laag buiten het scherm; een inactieve app en Minder beweging pauzeren de timeline ook. Bij Minder beweging blijft de bestaande statische waterval zichtbaar. Dezelfde watercontour wordt voor de basisillustratie en de animatiemaskering gebruikt.

Negen vogels vervangen de drie statische silhouetten. Ze verplaatsen horizontaal, deinen en slaan met verschillende ritmes hun vleugels. Eén kleine transparante tekenlaag van maximaal 530 × 64 punten werkt maximaal 24 keer per seconde bij. Ook deze laag pauzeert buiten beeld en bij een inactieve app; Minder beweging toont stilstaande vogels. Er zijn geen bitmapreeksen, deeltjessystemen of nieuwe assets nodig.

## Controle

- De definitieve Debug-simulatorbuild slaagt: [buildlog](WorldTestLogs/EntranceRevision/build.log).
- `testStartPointCleanCardAndExitCancel` slaagt op iPhone 17 en iPad Pro 11-inch met iOS 26.5: [iPhone](WorldTestLogs/EntranceRevision/iphone.log), [iPad](WorldTestLogs/EntranceRevision/ipad.log). De test controleert het beginpunt, levelstart, spelen, pauzeren, hervatten en verlaten.
- De bestaande `testMapScrollPerformance` slaagt met actieve water- en vogelanimaties, drie gemeten herhalingen van snelle vegen. De uitvoer staat in hetzelfde iPhone-log. Dit is een functionele scrollcontrole met indicatieve simulatorcijfers, geen bewijs van een bepaalde framerate op fysieke apparaten.
- De entree is visueel bekeken op [iPhone](Screenshots/EntranceRevision/entrance-iphone.png) en [iPad](Screenshots/EntranceRevision/entrance-ipad.png).
- Een tijdelijke controlebuild verschuift de volledige scrollinhoud met [60](Screenshots/EntranceRevision/sky-pull-60.png), [140](Screenshots/EntranceRevision/sky-pull-140.png) en [240 punten](Screenshots/EntranceRevision/sky-pull-240.png). Bij 60 punten ligt de voormalige aansluiting boven de HUD, zoals op het aangeleverde screenshot; bij de grotere afstanden worden andere delen van de doorlopende lucht zichtbaar. In alle drie beelden is de harde kleurstap weg. De tijdelijke verschuivingscode is verwijderd en de normale definitieve app staat weer op de controlesimulator.
- Een lokale opname en [opeenvolgende vogelbeelden](Screenshots/EntranceRevision/flying-birds.gif) bevestigen verplaatsing en veranderende vleugelstanden. Waterstrepen, spatwater en rimpels blijven bewegen.
- De eerdere kerncontrole had **437.244 geslaagde controles**; deze vervolgwijziging raakt uitsluitend kaartlayout en tekenviews.
- `git diff --check` is schoon. Screenshots blijven lokaal in de genegeerde screenshotmap.
