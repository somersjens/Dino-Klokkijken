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

## Kortere hurkpose, 28 oktober 2026

Het experiment met extra tussenbeelden en aangepaste snelheidsopbouw is na visuele feedback teruggedraaid. De huidige versie gebruikt weer de acht oorspronkelijke beelden, een vlucht met constante voortgang en de oorspronkelijke totale duur van 0,94 seconde. Alleen de diepe hurkpose is verkort van 105 naar 50 milliseconden. Zie [timing en controle](WelcomeJumpSmoothness.md).

## Analyse van de vluchtbeelden, 28 oktober 2026

De grote opening gebruikt nu vijf van de acht oorspronkelijke tekeningen: staan, hurken, één vaste vliegpose, contact en herstel. De wissels naar vliegbeelden 04, 05 en 06 zijn alleen voor de grote opening verwijderd; de éénstersprong blijft de volledige reeks gebruiken. De onderliggende kaart staat vóór vertrek al zichtbaar onder de ondoorzichtige opening en de decorvervaging wordt vooraf ingepland. Daardoor hoeft de kaart niet tijdens de vlucht naar zichtbaar om te schakelen. De native verplaatsingsanimatie vraagt expliciet 60 fps aan. Zie [metingen en beperkingen van de simulatoropname](WelcomeJumpSmoothness.md).

Op 29 oktober is ook de decorvervaging van SwiftUI naar native Core Animation verplaatst. De achterste compositie en de voorste titel vervagen op dezelfde klok als de Dino; de titel blijft op zijn plaats staan. De decorlagen dekken de veilige schermranden mee af. Hiermee vervalt de in de laatste opname zichtbare half-doorzichtige stilstand van het decor. De klok behoudt zijn schaal tijdens de vervaging.

## Gevolgde hoofdbeweging bij vertrek, 29 oktober 2026

De bijna gelijke sprongtekening 01 vervalt uit de opening. De exacte rustafbeelding begint een doorlopende bukbeweging van 0,22 seconde, gevolgd door 0,24 seconde opveren. Ogen en neus zijn gemeten en geregistreerd, zodat de twee beeldwissels de hoofdpositie niet meer laten verspringen. De totale welkomsprong duurt nu 1,26 seconde; de eerder verbeterde vlucht en decorvervaging blijven behouden. Zie [registratie, timing en controles](WelcomeHeadTracking.md).

De buk is daarna op verzoek verdiept: het oogmiddelpunt zakt van bronhoogte 470 naar 550, vrijwel de diepte van de oorspronkelijke buktekening. De kin bereikt daarmee weer de bovenrand van het bord. De neerwaartse beweging duurt nu 0,28 seconde en het opveren 0,34 seconde, zodat de grotere afstand de vloeiende hoofdbeweging behoudt. De totale duur is 1,42 seconde. De build en 273.792 gerichte timing- en assetcontroles slagen; de diepere buk is ook in een nieuwe native iPhone-opname gecontroleerd.

De resterende knik bij het opveren is vervolgens aangepakt door niet alleen de gezichtspunten, maar ook hun werkelijke snelheid in schermcoördinaten te laten aansluiten op de vlucht. Deze aansluiting loopt tot 0,10 seconde na de afzet en compenseert ook schaal en draaiing van de vlieglaag. De diepe buk en de totale duur blijven gelijk. De kaart wordt tijdens de rustfase alvast mee gecomposeerd en alle spronglagen vragen dezelfde 60 fps aan. De build, 274.405 gerichte controles en de bestaande openingstest op iPhone en iPad-landschap slagen. Zie [hoofdtracking en snelheidsaansluiting](WelcomeHeadTracking.md).

Na goedkeuring van de vloeiendheid is de afzet iets feller gemaakt: de opvering vóór vertrek duurt 0,28 in plaats van 0,34 seconde. De neerwaartse buk, diepte en snelheidsaansluiting blijven gelijk. De totale welkomsprong duurt daarmee 1,36 seconde. De build en 274.366 gerichte controles slagen.
