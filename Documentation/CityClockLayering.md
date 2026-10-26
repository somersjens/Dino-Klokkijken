# Klokstad — gelijke bewegende klokken en natuurlijke laagvolgorde

Alle gevelklokken delen één tijd vanaf 12:45. De minutenwijzer draait in 24 seconden eenmaal met de klok mee; de uurwijzer beweegt continu met de juiste verhouding van 1:12. Dat is 150 keer normale kloktijd en 48 keer rustiger dan de minutenwijzers in wereld acht. De analoge en digitale stationsklokken gebruiken dezelfde fase.

De klokstand komt uit de gezamenlijke animatietijd van de kaart. Gebouwen die later in beeld komen sluiten direct aan. De wijzers en digitale cijfers volgen een gedeelde klokstand op 30 beelden per seconde; gedetailleerde gevels, stationskappen en tunnelranden behouden hun eigen statische canvassen. De bestaande pauzes bij minder beweging, een inactieve app en een onzichtbaar stadsdeel blijven gelden.

De twee gebouwen boven de tunnel hadden een verhoogde tekenvolgorde om het tunnelportaal te bedekken. Daardoor kwamen ze onterecht vóór het lager gelegen winkeltje. Alle gebouwen worden nu op hun eigen grondcontact gesorteerd. De tunnelrand krijgt een uitsparing achter de twee bestaande gevels, zodat het portaal bedekt blijft zonder hun gebouwen naar voren te trekken. Wijzers delen de diepte van hun eigen gebouw en verdwijnen dus ook achter een dichterbij gelegen gevel.

[Onderste wijk op telefoonformaat](Screenshots/CityClockLayering/lower-city-402-t0.0.png) · [Dezelfde klokken 2,5 seconden later](Screenshots/CityClockLayering/lower-city-402-t2.5.png) · [Onderste wijk op tabletformaat](Screenshots/CityClockLayering/lower-city-834-t6.0.png).

## Controle

De native controle verifieert de gezamenlijke beginstand, de draairichting, de snelheid van beide wijzers, de verhouding van 1:12 en de overgang over middernacht. De gebouwen en funderingen zijn op tien breedtes gecontroleerd, van 320 tot 1194 punten. Alle gebouwposities, begrenzingen en spoorpunten zijn exact gelijk aan het vorige stadsontwerp. Het winkeltje met id 40260 wordt op 393 en 402 punten vóór beide tunnelgebouwen getekend. [Native controle](WorldTestLogs/CityClockLayering/native.log) · [Vergelijking van de indeling](WorldTestLogs/CityClockLayering/placement-comparison.log).

De simulatorbuild en testbuild slagen. [Build](WorldTestLogs/CityClockLayering/build.log) · [Testbuild](WorldTestLogs/CityClockLayering/build-for-testing.log).

De bestaande schermtest `testCityMetroRouteRemainsPlayable` slaagt op iPhone 17 en iPad Pro 11-inch M5 met iOS 26.5: één test per apparaat, nul fouten. Level 51 start, de route langs levels 54 en 57 blijft bereikbaar en de eindbaas bij level 60 opent. [iPhone-test](WorldTestLogs/CityClockLayering/iphone.log) · [iPad-test](WorldTestLogs/CityClockLayering/ipad.log).

[Onderste wijk in de app op iPhone](Screenshots/CityClockLayering/city-metro-route-60-iphone.png) · [Stadsroute in de app op iPad](Screenshots/CityClockLayering/city-metro-route-54-ipad.png) · [Dezelfde route na beweging](Screenshots/CityClockLayering/city-metro-route-54-motion-ipad.png).

De appbeelden zijn visueel gecontroleerd op gelijke klokstanden, zichtbare beweging en de gecorrigeerde laagvolgorde. `git diff --check` is schoon.

De native beelden zijn opnieuw te maken vanuit de projectmap:

```sh
python3 Documentation/WorldTestLogs/CityClockLayering/prepare-native.py /private/tmp/city-clock-layering
xcrun swiftc -parse-as-library -module-cache-path /private/tmp/city-clock-layering/modules /private/tmp/city-clock-layering/native.swift -o /private/tmp/city-clock-layering/render
/private/tmp/city-clock-layering/render "$PWD/Documentation/Screenshots/CityClockLayering"
```
