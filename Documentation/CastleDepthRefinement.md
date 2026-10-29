# Wereld 10 — aansluitingen en perspectief

28 oktober 2026. De referentie is gebruikt om de bestaande native kasteeltekeningen te verfijnen. Na de eerste visuele beoordeling zijn de te brede zijplaten en de gebogen leuningverbindingen vervangen door aansluitingen met gedeelde geometrie.

## Geometrie

De trap heeft een loopvlak van 44 punten en twee stenen wangen van elk negen punten. Het bordes is daardoor precies even breed als de complete trap: 62 punten. De plaat steekt niet zijdelings uit. De tussenbordessen zijn 30 punten diep; de voorrand van de plaat is vier punten dik.

`landingPoint` projecteert alle vloerhoeken, bestratingsvoegen en pijlerblokken op dezelfde manier. De begin- en eindpunten van de trapvluchten komen uit diezelfde bordesranden. De pijlers hebben afzonderlijke boven-, voor- en zijvlakken. Leuningen hebben een eigen bovenvlak en verticale zijrand, in plaats van over elkaar gelegde dikke lijnen.

De schuine trapleuningen eindigen bij de hoekpijlers. De leuning over het tussenbordes blijft recht en vlak. De gebogen verbindingen en losse korte uiteinden bij de zijtuin zijn verwijderd. Ook het poortje, de zijdelingse doorgang en de lamp buiten het bordes zijn verwijderd; de tuin ligt zelfstandig naast de trap. Dit houdt de trapvorm rustig en voorkomt zwevende onderdelen.

## Bruggen en tekenvolgorde

De bruggen eindigen op dezelfde zijdelingse positie als de trapleuningen. Hun pijlers vormen de gedeelde hoeken bij het boven- en onderbordes, zodat daar geen dubbele kolommen nodig zijn.

Een bovenste brug werd deels bedekt doordat de volledige trappartij later werd getekend. Bij deze bruggen worden nu twee lagen geplaatst: het metselwerk blijft achter de trappen; het dek en de balustrades komen vóór het voorplein. Het bovenbordes kan daardoor de aansluitende brugpijlers niet meer uitwissen. De watermaskers gebruiken dezelfde lagen.

![Eerdere versie, vorige poging en gecorrigeerde aansluiting](Screenshots/CastlePerspectiveCorrection/comparison.jpg)

## Verificatie

De [appbuild](WorldTestLogs/CastlePerspectiveCorrection/app-build.log) en de [testbuild](WorldTestLogs/CastlePerspectiveCorrection/ios-build-current.log) slagen. De bestaande tests voor level 91 en de bereikbaarheid van de eindbaas zijn op [iPad](WorldTestLogs/CastlePerspectiveCorrection/ipad.log) geslaagd. Op iPhone slaagt de [eindbaascontrole](WorldTestLogs/CastlePerspectiveCorrection/iphone.log); de eerste levelcontrole werd door een SIGKILL van de testomgeving onderbroken. Dezelfde [levelcontrole is op een eigen tijdelijke simulator geslaagd](WorldTestLogs/CastlePerspectiveCorrection/iphone-isolated.log). Beide controles slagen daarmee op beide apparaattypen. De tijdelijke simulator is na afloop verwijderd.

[Scherm op iPhone](Screenshots/CastlePerspectiveCorrection/entrance-iphone.png) · [Scherm op iPad](Screenshots/CastlePerspectiveCorrection/entrance-ipad.png).

De native Swift-renderer compileert. De volledige kaart en de drie tussenbordessen zijn op 320, 393, 834 en 1194 punten bekeken. Een tijdelijke geometriecontrole bekijkt 49.410 punten op tien breedtes, van 320 tot 1194 punten: de geprojecteerde bordesvloeren en trapranden blijven buiten de waterloop. [Geometrie en renders](WorldTestLogs/CastlePerspectiveCorrection/final-correction.log).

De bewegende waterlaag is op 393 en 834 punten op twee tijdstippen vergeleken. Binnen de geteste ondoorzichtige brug- en trapvlakken veranderen nul pixels. Fonteinoppervlakken die vóór de steen liggen zijn uitgesloten, omdat daar bewust water beweegt. [Watercontrole](WorldTestLogs/CastlePerspectiveCorrection/water-check.log).

De wijziging blijft in `CastleKingdomLayout` en `CastleWorldPainter`. Er zijn geen bitmap-assets aan de game toegevoegd.
