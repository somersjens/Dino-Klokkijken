# Klokstad — aansluitingen en dichtere straten

De metro-inrit gebruikt één doorlopende spoorvloer. De breedte en hoogte van de zijwanden groeien vanuit de bestaande spoorrand; er staat geen dwarsvlak meer op het begin van de afdaling. De linker tak draait bij de laatste wijk naar buiten en verdwijnt achter de buitenste gevels uit beeld. Een gereserveerde gevel voor die uitgang blijft onderdeel van dezelfde stadsindeling.

De bebouwing zoekt nu ook bouwruimte tussen het spoor en de levelstraat. Smalle herenhuizen, lage hoekwinkels en extra gevelrijen vullen de eerder lege stroken. Op 393 punten breed staan er 71 gebouwen; de uitgangssituatie had er 22. Grotere schermen krijgen aanvullende buitenstraten en enkele kleine zitplekken met bomen. Volledige gevels blijven vrij van de levelstraat en funderingen blijven buiten het open spoor, de perrons en het eindbaasplein.

De klokken aan de zijkant van het wereldbord zijn verplaatst naar de stadsbebouwing onder de grotgrens. Kloktorens beginnen onder die rotsafwerking. Gewone gevels vormen de bovenste skyline; de donkere grotgrond blijft tussen en achter deze huizen zichtbaar. Twee lage winkels sluiten de eerste stadsgrond direct onder het bord af.

Straten, gebouwterrassen en perronpleinen delen hetzelfde bestratingsmateriaal in kaartcoördinaten. Daardoor ontstaan er geen afzonderlijk gekleurde vlakken onder elk huis. De ondergrens naar de slaapvallei volgt een rustige boog rond complete gebouwvoeten. Losse straatstenen en kleine mosplanten verbinden die rand met het park.

## Controle

De iOS-build slaagt. De bestaande tests `testCityMetroRouteRemainsPlayable` en `testWorldBannersHaveBalancedClearance` slagen op afzonderlijke iPhone 17- en iPad Pro 11-inch M5-simulators. Level 51 opent en start, de route langs 54 en 57 blijft bereikbaar en de eindbaas bij 60 opent. De controles voor de borden zijn uitgevoerd voor werelden 6 en 7. [Apparaatresultaten](WorldTestLogs/CitySeamRefinement/devices.log).

De native controle slaagt met 169.991 geometriecontroles op negen breedtes van 320 tot 1194 punten. Die onderzoekt de afstand van complete gevels tot de bochten, vrije funderingen, perrons, het eindbaasplein, kloktorens onder de grot, aansluitende spoorprofielen en de volledige gebouwvoeten langs de parkgrens. [Geometrie](WorldTestLogs/CitySeamRefinement/geometry.log).

De entree, metro, onderste wijk en beide wereldgrenzen zijn visueel bekeken in native renders en in de appbeelden. Native renders gebruiken eenvoudige genummerde levelcirkels; de simulatorbeelden tonen de echte interface. `git diff --check` is schoon. Een eerdere iPhone-poging kon de gedeelde simulator niet starten omdat deze bezet was; de volledige eindcontrole slaagt op de twee afzonderlijke testtoestellen. Die tijdelijke toestellen zijn daarna verwijderd.

## Beelden

- [Appoverzicht iPhone](Screenshots/CitySeamRefinement/app-overview-iphone.jpg)
- [Appoverzicht iPad](Screenshots/CitySeamRefinement/app-overview-ipad.jpg)
- [Grot naar stad, native 393 punten](Screenshots/CitySeamRefinement/join-5-393.png)
- [Stad naar slaapvallei, native 393 punten](Screenshots/CitySeamRefinement/join-6-393.png)
- [Volledige stad, native 834 punten](Screenshots/CitySeamRefinement/native-834.png)
