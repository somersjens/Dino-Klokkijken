# Tijdpiraten — meeuwengroepen en bewegende zee

21 oktober 2026. Deze ronde werkt de kustbeweging en de plaatsing van de decoratie uit.

- Zes groepen van drie tot vijf kleinere meeuwen volgen de kust boven zee. Hun snelheid is verhoogd van circa 16–22 naar 37–43 punten per seconde. Kleine verschillen in vleugelfase en een losse V-formatie houden de groepjes levendig.
- Beide vleugels hebben dezelfde witte basiskleur en dezelfde spanwijdte. De voorste vleugel wordt na het lichaam getekend. Een ruimer tekenvlak voorkomt afgesneden vleugelpunten tijdens draaien en fladderen.
- De vliegroutes volgen de werkelijke zeecontour. Het volledige tekenvlak van de vogels houdt afstand tot het strand en de levelstenen.
- Bloemen staan op het zand naast of onder de rotsgroepen. Bloemen bij de palmvoeten zijn vervangen door laag groen en de losse begroeiing boven op de stenen is verwijderd.
- De grote zandloper staat rechtstreeks op het strand. Zijn hoge rotsvoet en de stilstaande waterval/fontein langs de route zijn verwijderd.
- Vanaf beide zeekanten schuiven zachte golfaccenten naar het land. De schepen bewegen zacht op en neer en kantelen licht volgens dezelfde golfperiode.
- De losse water- en schuimvlakken onder boten en steigers zijn helemaal verwijderd. Overal blijft dezelfde doorlopende zee zichtbaar, met dezelfde bewegende accenten.

## Opbouw

`PirateSeaGeometry` bereidt de kustpaden voor. `PirateSeaMotion` deelt de golfperiode tussen het water en de schepen. `PirateCoastLife` tekent water in stroken van maximaal 320 punten hoog en schepen in kleine afzonderlijke tekenvlakken. Statische decoraties vormen een apart dieptemasker, zodat de beweging achter voorliggende bomen, stenen en steigers blijft.

`PirateGullFlocks` plaatst de groepen boven het water en `PirateGullPainter` tekent de nieuwe vleugels. Alleen zichtbare animatievlakken verversen, maximaal twintig keer per seconde. De animaties pauzeren buiten beeld, wanneer de app niet actief is en bij **Minder beweging**. In die laatste stand blijven water, boten en vogels op vaste tijdstippen staan.

Implementatie: [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift).

## Beelden

[Opname in de iPhone-app](Screenshots/PirateFourthPass/sea-motion-iphone.mp4) · [bewegend native voorbeeld](Screenshots/PirateFourthPass/sea-motion.gif) · [voor en na](Screenshots/PirateFourthPass/before-after.jpg) · [vleugelposes](Screenshots/PirateFourthPass/gull-wing-poses.png) · [actuele kust op iPhone](Screenshots/PirateFourthPass/pirate-route-83-iphone.png).

Native composities op [320](Screenshots/PirateFourthPass/native-320.png), [393](Screenshots/PirateFourthPass/native-393.png), [834](Screenshots/PirateFourthPass/native-834.png) en [1194](Screenshots/PirateFourthPass/native-1194.png) punten zijn visueel gecontroleerd. De cirkels in de native composities zijn controlemarkeringen. De simulatorbeelden tonen de echte interface.

## Controles

De [iOS-verificatiebuild](WorldTestLogs/PirateFourthPass/verification-build.log) en [native renderbuild](WorldTestLogs/PirateFourthPass/native-build.log) slagen.

Op tien breedtes van 320 tot 1194 punten zijn zestien animatiemomenten gecontroleerd. 31.680 meetpunten rond de meeuwentekenvlakken liggen in zee; de vogels behouden bovendien extra afstand tot alle tien levelstenen. Alle 74.240 meetpunten binnen de wiegende scheepsrompen blijven in het water. De 25.520 bestaande controles voor statische rompen, droge schatverbindingen en steigerinstappen slagen eveneens. [Geometrie- en renderlog](WorldTestLogs/PirateFourthPass/native-render.log).

Vier bewegingsbeelden verschillen; twee beelden met **Minder beweging** zijn pixelgelijk. Er zijn 48 beelden gerenderd voor het bewegende voorbeeld. [Pixelcontrole](WorldTestLogs/PirateFourthPass/visual-checks.json).

De gerichte kaart-, level- en eindbaascontrole slaagt op [iPhone](WorldTestLogs/PirateFourthPass/iphone-verified.log) en [iPad](WorldTestLogs/PirateFourthPass/ipad-verified.log): vier geslaagde testuitvoeringen, nul fouten. Hiervoor is dezelfde afzonderlijke controlekopie gebruikt als in de eerdere rondes; de tests in de werkmap zijn niet aangepast. De gecontroleerde piratenbroncode komt overeen met de werkmap; `git diff --check` is schoon.

Een opname in de draaiende iPhone-app gebruikt uitsluitend een afzonderlijk Debug-profiel. Twee beelden zonder scrollen of aanraken tonen verandering in beide zeestroken en in de boot: respectievelijk 846, 3.483 en 10.704 pixels veranderen met meer dan 18 RGB-niveaus. [Meetresultaten](WorldTestLogs/PirateFourthPass/app-motion-checks.json). De tijdelijke simulators zijn na de controle verwijderd.
