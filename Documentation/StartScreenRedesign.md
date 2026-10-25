# Nieuw startscherm

23 oktober 2026.

De opening toont één gecentreerde compositie: een standaardklok met een dinogroene buitenrand, de persoonlijke Dino ervoor en een houten laag rondom de spelnaam op de voorgrond. Achtergrond, klok, houtnerf, bladeren en sterren worden native getekend. De titel wordt uit de vertaalde tekst als vectorlettercontouren opgebouwd, met kleurverloop en diepte. Alleen de bestaande, gepersonaliseerde Dino gebruikt een afbeelding.

`dino.launch.title.firstLine` en `dino.launch.title.secondLine` bepalen de twee titelregels. Nederlands toont **Dino / Klokkijken**, Engels **Dino / Time**. Vertalers kunnen beide regels aanpassen. Elke regel past binnen het bord, ook bij langere namen; er hoeft geen afbeelding per taal te worden gemaakt.

De bruine vorm is afgeleid van de werkelijke letteromtrekken, met een buitenrand, een lichtere binnenlaag, houtnerf en een onderste schaduwlaag. Punten, rondingen en de onderkant van de `j` bepalen de omtrek. Binnenruimtes en kleine ingesloten openingen blijven gevuld met hout. De vorm verandert dus ook mee tussen **Dino Time** en **Dino Klokkijken**. De tweede titelregel en beide klokranden gebruiken dinogroen.

De bladeren vormen twee aangesloten waaiers. Ieder blad heeft een eigen vorm, kleurverloop, vouw, middennerf, vertakte fijne nerven, randlicht en schaduw. De bladeren komen aan een gezamenlijke steel achter de letters vandaan.

De klok staat direct in beeld voordat de dinokleur en kaart klaar zijn. De wijzers gebruiken Core Animation zodat ze tijdens de voorbereiding van de kaart blijven draaien. Zodra de opgeslagen dinokleuren zijn voorbereid, begint Dino volledig verborgen met zijn bovenste stekel net onder de lokale bovenrand van het hout. Een gemeten contourmasker laat hem van achter de letters omhoogkomen. De beginpose wordt eerst vastgelegd; daarna beweegt zijn eigen afbeeldingslaag in 0,82 seconde omhoog. Daardoor slaat kaartvoorbereiding de eerste helft van zijn verschijnanimatie niet meer over. De klok staat achter hem; het hout bedekt zijn onderlichaam.

De grote openings-Dino gebruikt de volledige oorspronkelijke **1254 × 1254 pixels**, ook na het toepassen van persoonlijke kleuren. De gewone kaartfiguren en reacties houden hun compacte variant van maximaal 768 pixels. Beide resoluties hebben afzonderlijke cachesleutels. De nieuwste acht afbeeldingen (aangeleverd om 16:14) vervangen de eerdere sprongreeks onder de namen `dino-opening-jump-01` t/m `dino-opening-jump-08`, zonder wijziging van hun PNG-inhoud. Deze reeks heeft een diepere afzet en meer beweging in armen en benen.

Na de onthulling en kaartvoorbereiding blijft de complete compositie minstens één seconde staan. Dan volgt de nieuwe achtposesprong: staan, doorzakken, afzetten, knieën optrekken, dalen, voeten uitstrekken, landen en herstellen. De complete beweging duurt **0,94 seconde**; de afzet begint na 0,14 seconde en de landing ligt op 0,76 seconde. De voorbereiding duurt dus 0,14 seconde en het landingsherstel 0,18 seconde, in plaats van de eerdere 0,32 en 0,40 seconde. De vlucht, schaal, korte vering, posewissels en het vrijgeven van het houtrandmasker worden één keer als Core Animation-keyframes klaargezet. De iOS-renderer speelt ze vervolgens op dezelfde klok af, zonder een SwiftUI-update voor ieder beeld. Daarmee kan het zichtbaar maken van de kaart de Dino niet meer tijdelijk stilzetten. De verplaatsing behoudt haar snelheid tot contact met de steen; de verticale boog vertraagt rond het hoogste punt en versnelt naar de landing. Er is geen ease-in/ease-out meer die de afzet laat zweven of de Dino vóór de steen laat afremmen. De poses volgen één doorgaande boog naar het gemeten kaartanker. De vlieghoogte houdt rekening met de beschikbare ruimte boven Dino. De geplante poses hebben dezelfde gemeten voetenlijn als de kaartfiguur.

De achtergrond, klok, bladeren en titel vervagen vanaf de afzet in 0,38 seconde; het bord schuift iets naar beneden. Dino blijft tijdens de afzet achter het bord totdat hij vanzelf boven de rand uitkomt. Pas na zijn landingsherstel neemt de kaartfiguur het over. De grote openingsbeelden worden vervolgens uit de eigen cache en kaartstatus vrijgegeven.

Alle acht poses worden vooraf buiten de hoofdthread voorbereid met maximaal twee gelijktijdige taken. De gezichtsmaskers en kleurmetingen zijn opnieuw afgestemd op de nieuwste illustraties. Elke pose heeft eigen gezichtsmaskers, een afgebakende bedrukking van de bandana en gemeten kleur-/lichtwaarden. Ogen, mond en de gekozen lichaamskleuren blijven daardoor bij alle posewissels behouden, inclusief zwarte bedrukking bij een witte bandana.

Bij **Verminder beweging** blijven klok en decor stil en gebruikt de overgang een korte vervaging. De klok pauzeert wanneer de app niet actief is. De bestaande onderliggende kaartvoorbereiding, positieherstel en persoonlijke kleuren blijven behouden. De opening wordt niet herhaald na het sluiten van een levelkaart of terugkeer uit het spel.

Het statische iOS-launchscreen gebruikt dezelfde basiskleur. De verouderde losse launch-klok is uit de launchconfiguratie gehaald; de bewegende compositie wordt volledig door de app getekend.

## Controle

- Simulatorbuild met `build-for-testing` geslaagd.
- De volledige coretestsuite is geslaagd: **822.227 controles**.
- **6.094 gerichte controles** geslaagd voor animaties, bronresolutie, persoonlijke kleuren, gezichtsmaskers en bandanabedrukking. Deze controleren ook alle acht posegrenzen voor native playback, doorlopende vlucht, echte voetenlijnen, verminderde beweging en behoud van de snelheid tot aan de landing.
- Bestaande koude-herstarttest geslaagd op iPhone 18 Pro en iPad (A16), iOS 27: level 1, 4 en 91, bewaarde blauwe/paarse dinokleuren en stabiele kaart-/HUD-posities.
- Definitieve build opnieuw gecontroleerd op iPhone. De extra iPad-test voor een Engelstalige start in landschapstand, landing bij level 4 en sluiten van de levelkaart zonder herhaalde introductie is geslaagd.
- Nederlandse en Engelse openingen als video opgenomen en in afzonderlijke frames bekeken: kleuronthulling, titel, volgorde van de lagen, afzet en landing.
- De onafhankelijk draaiende klokwijzers zijn in opeenvolgende simulatorbeelden bevestigd, ook tijdens kaartvoorbereiding.
- Na de verfijning is de onthulling op 20 beelden per seconde gecontroleerd: eerst alleen de bovenste stekel/bandana bij de houtrand, daarna ogen, snuit en bovenlichaam. De complete pose verschijnt geleidelijk vanaf de rand.
- De nieuwe achtposesprong is op iPhone en iPad gecontroleerd, inclusief opgeslagen levels en persoonlijke kleuren. De originele PNG-inhoud is per bestand met de aangeleverde Git-hash vergeleken: alleen namen en assetmetadata zijn gewijzigd.
- Een afzonderlijk oranje testprofiel met paarse bandana, gele stekels en groene buik controleert de hoge resolutie en kleurvastheid tijdens de complete sprong. De korte video behoudt de volledige opgenomen resolutie.

Lokale beelden staan onder `Documentation/Screenshots/StartScreen`; de opnames en build-/testlogs staan in `/tmp/dino-opening-*`.

## Verfijning van de sprong met de nieuwste beelden

De eerste opname van de snellere sprong liet tijdens de kaartonthulling nog twee korte stilstaande vluchtbeelden zien. Na het verplaatsen van de volledige choreografie naar Core Animation toont de gecontroleerde reeks op 20 beelden per seconde voortgaande beweging in ieder vluchtbeeld. De korte stilstand tijdens de geplante afzet en na contact blijft bewust behouden. De definitieve iPad-test voor landschapstand, opgeslagen level 4 en terugkeer uit een level en de iPhone-test voor koude herstarts bij levels 1, 4 en 91 zijn opnieuw geslaagd.

De definitieve preview staat in `Documentation/Screenshots/StartScreen/startscreen-smooth-native-jump.mov` en behoudt de oorspronkelijke videoresolutie.
