# Wereld 5 — Kristalgrot verfijnd, 14 oktober 2026

## Analyse en richting

De bestaande kaart had een lichte blauwe ondergrond, losse kristallen en eenvoudige rotsgroepen. Het bestaande conceptbeeld toont juist een omsloten grot: een rotsgewelf, licht door een opening, watervallen, gelaagde stenen oevers en kristallen die hun omgeving verlichten. Dat beeld is vertaald naar native SwiftUI/Canvas-paden.

Het zandpad, de levelposities en de bestaande schermindeling blijven de basis. Het grootste detail staat langs de buitenkant van de bochten. Het midden blijft helder genoeg voor levels 41–50 en Dino.

## Uitwerking

- Een grotgewelf met ongelijke rotsvlakken, stalactieten en hangende kristallen. Het midden heeft een heldere opening, zachte transparante lichtbanen, verre rotsformaties, watervallen en kleine lichtdeeltjes. De watervallen zijn boven het titelbord geplaatst en de bovenrand van het gewelf loopt geleidelijk over uit de vorige wereld. De verre formaties vervagen in de nevel. Boven de titel is 118 punten extra ruimte toegevoegd.
- Doorlopende gelaagde rotswanden langs de randen, met steenbreuken, schaduwkanten en lichte bovenvlakken. Beekjes, watervallen en schuim verbinden de stenen terrassen; kleine stenen bruggen hebben voegen, palen en kristallen op de uiteinden.
- Kristallen in cyaan, amethist en zachtroze. De afzonderlijke vlakken hebben kleurverloop, doorsnijdende facetten, scherpe lichtranden, glasreflecties en een rustige gloed op de ondergrond. Grote groepen wisselen af met kleine scherven en hangende exemplaren.
- Geodes met een donkere binnenkant en kleine kristallen, warme lantaarns, groene planten en kleine paarse bloemen. Water en randdecoratie staan achter de grotere bestemmingen.
- Digitale klokstenen tonen **02:17** en **08:43**, passend bij exacte minuten. De schermpjes liggen voor de omringende kristalgroepen; de cijfers blijven leesbaar.
- Een rotsboog met kristallen vormt de achtergrond van de bestaande grotbaas.
- Eigen levelstenen met een koele mineraalrand, kleine kristalfacetten en een lichte mintgroene bovenkant. De steen onder Dino krijgt een bleke laag en een rustige lichtkring. Hoog contrast behoudt duidelijke cijfers en randen; tikgebieden en voetpositie blijven gelijk.

`CrystalCavePainter` geldt uitsluitend voor de kaart van wereld 5 en de wereld-5-preview op boss- en beloningskaarten. `CrystalLevelStone` geldt uitsluitend voor levels 41–50. De bronvergelijking vergelijkt de illustraties met de bestanden van vlak vóór deze opdracht. Tijdens het werk zijn in de gedeelde checkout ook onafhankelijke aanpassingen aan Dino’s vrije ruimte en de titelgrootte bij liggend gebruik binnengekomen. Die bestaande schermwerkzaamheden zijn behouden; het bronlog benoemt ze afzonderlijk. Andere landschap-painters, levelstenen en gedeelde scenecode buiten de wereld-5-preview blijven gelijk.

## Beelden

| Controle | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree en eerste level | [Screenshot](Screenshots/CrystalCaveRefinement/entrance-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/entrance-ipad.png) |
| Exacte minuten spelen | [Screenshot](Screenshots/CrystalCaveRefinement/exact-minute-question-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/exact-minute-question-ipad.png) |
| Dino op de behaalde steen | [Screenshot](Screenshots/CrystalCaveRefinement/occupied-stone-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/occupied-stone-ipad.png) |
| Onderste grotdeel en boss | [Screenshot](Screenshots/CrystalCaveRefinement/lower-cave-iphone.png) | [Screenshot](Screenshots/CrystalCaveRefinement/lower-cave-ipad.png) |

## Verificatie

De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testDinoStandsOnCompletedLevel` zijn gericht op wereld 5 uitgevoerd met `DINO_TEST_WORLD_IDS=5`. De hoofdstuktest controleert de ontgrendeling en het tikgebied van level 41, opent de startkaart en beantwoordt een vraag. De plaatsingstest speelt level 41 volledig en controleert Dino's voeten op de behaalde steen. Beide gebruiken afzonderlijke Debug-testopslag.

[Definitieve build](WorldTestLogs/CrystalCaveRefinement/final-build.log) · [Definitieve iPhone-controle](WorldTestLogs/CrystalCaveRefinement/final-iphone.log) · [Definitieve iPad-controle](WorldTestLogs/CrystalCaveRefinement/final-ipad.log) · [Bronvergelijking](WorldTestLogs/CrystalCaveRefinement/scope-check.log).

De definitieve versie slaagt met twee tests per apparaat: **vier geslaagde schermtestuitvoeringen, nul fouten**. De entree, de behaalde levelsteen, de exacte-minutenvraag en het onderste grotdeel zijn visueel gecontroleerd op iPhone en iPad. De digitale klokstenen zijn leesbaar en de rotsboog bedekt de grotbaas niet. `git diff --check` is schoon.

Alle illustraties blijven native getekend. Er zijn geen bitmap-assets toegevoegd en echte spelersvoortgang wordt niet gewijzigd.

## Doorlopende grot en vloeiende wereldgrenzen — 15 oktober 2026

De grotwanden beginnen in de laatste bocht van Dino Dorp, lopen door achter de Kristalgrot-banner en wijken pas voorbij de Dino Stad-banner weer naar de zijkanten. De brede luchtstroken tussen deze werelden zijn verwijderd. Elke kaart tekent zijn deel van dezelfde doorgang; positie, materiaal en raaklijn sluiten aan op de wereldgrens. Horizontale materiaalverlopen houden de rotskleur daar gelijk. De grot verdwijnt niet via een transparante laag.

De rivieroevers bij het dorp en de stad gebruiken ruime Bézierbochten. De instroom sluit aan op de verticale raaklijn bij het eerste level; de uitstroom begint bij de verticale raaklijn van het voorlaatste level. Zo schiet de oever niet voorbij zijn aansluiting om vervolgens scherp terug te draaien. Kleine stadsplateaus beginnen na de grotuitgang, zodat ze niet los boven een afgedekte rivier verschijnen.

Rotslagen, overhangende richels en vastgegroeide stalactieten omsluiten het pad. Hangende kristallen zitten met hun voet achter een rotslip. Zes grotere bestemmingen delen een richel: twee asymmetrische kristalgroepen, twee klokstenen, een geode en een waterval met aangesloten poel en boogbrug. De kristallen hebben verschillende groeirichtingen, doorschijnende facetten, reflectiebanden en kleine lichtaccenten. De klokgroepen staan bij ruimere bochten en tonen **02:17** en **08:43**.

De complete grot en de overgangen **4 → 5** en **5 → 6** zijn visueel gecontroleerd op breedtes van 320, 393, 834 en 1194 punten. De rivierbochten zijn daarnaast afzonderlijk zonder grotwanden bekeken. De simulatorbuild slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` controleren met `DINO_TEST_WORLD_IDS=5,6` de levels, speelvragen en bannerruimte op iPhone 17 en iPad Pro 11-inch: **vier geslaagde testuitvoeringen, nul fouten**. `git diff --check` is schoon.

Actuele appbeelden: [ingang iPhone](Screenshots/CrystalContinuity/entrance-iphone.png), [ingang iPad](Screenshots/CrystalContinuity/entrance-ipad.png), [uitgang iPhone](Screenshots/CrystalContinuity/exit-iphone.png) en [uitgang iPad](Screenshots/CrystalContinuity/exit-ipad.png). De eerdere afwerking van Vulkaanland en de kristalgroepen, klokken en grotbaas zijn behouden.

## Grotboog na wereld 4 — 16 oktober 2026

De nieuwe entree vervangt de vroege instroom van grotwanden in de laatste dorpsbocht. In het aangeleverde voorbeeld ligt het groene buitengebied boven een omhoog gewelfde rotsboog en loopt de donkere grot onder die boog verder. Warm licht aan houten palen contrasteert met de koele kristallen. Deze opbouw is nu naar native Canvas-tekeningen vertaald.

Level 40 en de dorpsbaas blijven volledig buiten. De dorpsgrond en oevers behouden hun groene tint tot aan de wereldgrens. Wereld 5 begint met een eigen entree van 176 punten vóór het titelbord: een omhoog gewelfde rotsboog met afzonderlijke steenfacetten, breuklijnen, lichte bovenvlakken, een warme onderrand en planten en ranken. De grotvloer en zijwanden beginnen onder de boog. De extra hoogte schuift het wereldbord en alle grotlevels samen op, met behoud van de bestaande afstand tussen bord en eerste level.

Twee houten lantaarnpalen flankeren de ingang. Verder in de grot staan vier extra lantaarnpalen, twee houten mijnplatforms met kruisverbanden, touwleuningen en planknaden, en twee opslagplekken met gestapeld mijnhout, zichtbare jaarringen en kisten met kristallen. Langs de wanden groeien 24 extra kristalgroepen uit rotsrichels; bij de ingang staan nog twee groepen. De bestaande klokstenen, geodes, waterval en grotbaas zijn behouden. Het nieuwe donkerblauwe diepteverloop loopt vóór de laatste grotbocht terug naar de bestaande vloerkleur.

De overgang **5 → 6** is in deze ronde niet herontworpen. De stadspainter en de bestaande vertrekdoorgang zijn ongewijzigd. Ook de overige wereldpainters, levelknoppen, vragen en voortgangsregels blijven gelijk. Er zijn geen bitmap-assets voor de kaart toegevoegd.

De native tekeningen zijn visueel gecontroleerd op breedtes van 320, 393, 834 en 1194 punten. De definitieve simulatorbuild slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` zijn met `DINO_TEST_WORLD_IDS=5` op iPhone 17 en iPad Pro 11-inch uitgevoerd: **vier geslaagde schermtests, nul fouten**. Ze controleren de toegang en het tikgebied van level 41, de eerste exacte-minutenvraag en de bordafstand met de extra entree. `git diff --check` is schoon.

[Actuele ingang op iPhone](Screenshots/CaveEntrance/entrance-iphone.png) · [Actuele ingang op iPad](Screenshots/CaveEntrance/entrance-ipad.png) · [Buildlog](WorldTestLogs/CaveEntrance/build.log) · [iPhone-tests](WorldTestLogs/CaveEntrance/iphone.log) · [iPad-tests](WorldTestLogs/CaveEntrance/ipad.log).

## Tweede verfijning: de rotsrand vóór de weg — 16 oktober 2026

Het voorbeeld laat de weg achter de dikke grotrand verdwijnen en binnen de grot weer tevoorschijn komen. De eerste versie tekende de weg nog over de rotsrand. Een aparte, korte voorgrondlaag tekent nu het gewelf, de zijrotsen, de hangplanten en de ingangslampen na het pad. De levelknoppen en het titelbord blijven ervoor liggen. De weg en stippellijn zijn volledig afgedekt waar de stenen boog eroverheen loopt.

De entree heeft nu 260 punten ruimte vóór het wereldbord. Bemoste rotsbanken, varens, lage planten en bloemen sluiten over de wereldgrens op elkaar aan. Ze beginnen ná het laatste buitenlevel. De rotsboog bestaat uit grotere, onregelmatige stenen met brede facetten, breuklijnen, een diepe onderrand en gereflecteerd lantaarnlicht. Dikke zijrotsen dragen de ranken. Achter de opening geven een kleiner houten mijnplatform, kristallen, lichtdeeltjes en een waterval met aansluitende poel meer diepte.

De grot bevat nu 40 aanvullende kristalgroepen langs de wanden, naast 20 ingebedde aders met elk drie gerichte kristalscherven. Helder cyaan, amethist en roze wisselen af met de bestaande zachte mineraalkleuren. Drie grotere mijnwerkplaatsen hebben houten stutten, schoren, een gevulde plank, mijnhout, opslagkisten en een hanglamp. Ze staan aan de ruime kant van de bochten, zodat hun houtwerk ook op een telefoon zichtbaar blijft. De bestaande mijnplatforms en klokstenen zijn hierop afgestemd; de levels zelf blijven op dezelfde bochten staan.

Native renders op 320, 393, 834 en 1194 punten zijn visueel gecontroleerd. Een pixelcontrole bevestigt op elk formaat dat de zandweg boven de boog zichtbaar is, bij de boog door steen wordt afgedekt en eronder opnieuw zichtbaar wordt. De bestaande vertrekdoorgang en de stadspainter zijn ongewijzigd; de overgang **5 → 6** blijft buiten deze verfijning.

De definitieve build slaagt. `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` zijn opnieuw gericht op wereld 5 uitgevoerd op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. De entreebeelden en het mijnhout zijn met geïsoleerde Debug-testvoortgang vastgelegd. `git diff --check` is schoon.

[Volledige ingang op iPad](Screenshots/CaveRefinement/entrance-ipad.png) · [Eerste grotlevels op iPhone](Screenshots/CaveRefinement/entrance-iphone.png) · [Mijnwerkplaatsen op iPhone](Screenshots/CaveRefinement/mine-workshops-iphone.png) · [Buildlog](WorldTestLogs/CaveRefinement/build.log) · [iPhone-tests](WorldTestLogs/CaveRefinement/iphone.log) · [iPad-tests](WorldTestLogs/CaveRefinement/ipad.log).

## Vaste bordafstand en kleinere grotuitgang — 16 oktober 2026

De aparte entreestroken van 260 en 250 punten vóór wereld 5 en 6 zijn verwijderd. Alle hoofdstukken gebruiken weer dezelfde afstand van bosssteen tot wereldbord en dezelfde vrije ruimte onder het bord. De grotpoorten tekenen in de bestaande tussenruimte, met een korte voorgrondlaag die over de hoofdstukgrens loopt. Hun hoogte houdt rekening met de bossaanduiding op smalle schermen. Het titelbord blijft vóór de rotsen liggen.

De uitgang heeft een lagere, smallere stenen boog met afzonderlijke wigstenen, lichte afgeschuinde randen, mineraalbreuken en een kristal in de sluitsteen. Kleine lantaarns, ranken, mos en bloemen maken de pijlers af. Beide pijlers staan op een stenen voet en een doorlopende droge aanloop. De grot opent langs dezelfde gebogen contour naar de stadsgrond. De waterbanen blijven buiten de poortvoeten en behouden hun bestaande verloop.

De ingang en uitgang zijn native gerenderd en visueel gecontroleerd op breedtes van 320, 393, 834 en 1194 punten. De definitieve simulatorbuild slaagt. De bestaande tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` slagen voor werelden 4, 5 en 6 op iPhone 17 en iPad Pro 11-inch. De afstandstest heeft geen uitzondering meer voor de grot. Een extra afstandscontrole op de definitieve iPhone-build slaagt eveneens: vijf geslaagde testuitvoeringen, nul fouten. `git diff --check` is schoon.

[Ingang iPhone](Screenshots/CaveSpacing/entrance-iphone.png) · [Uitgang iPhone](Screenshots/CaveSpacing/exit-iphone.png) · [Ingang iPad](Screenshots/CaveSpacing/entrance-ipad.png) · [Uitgang iPad](Screenshots/CaveSpacing/exit-ipad.png) · [Buildlog](WorldTestLogs/CaveSpacing/build.log) · [iPhone-tests](WorldTestLogs/CaveSpacing/iphone.log) · [Definitieve iPhone-afstandscontrole](WorldTestLogs/CaveSpacing/iphone-final.log) · [iPad-tests](WorldTestLogs/CaveSpacing/ipad.log).

## Oorspronkelijke poortvorm en dieptevolgorde — 16 oktober 2026

De afgeplatte uitgang is vervangen door de oorspronkelijke boog, pijlers en ornamenten. Alle oorspronkelijke paden en controlepunten zijn teruggezet. Eén uniforme schaalfactor verkleint de complete poort binnen de beschikbare ruimte; breedte en hoogte behouden hun verhouding. De vaste bordafstand en droge aanloop blijven behouden.

De grotscène sorteert kristalgroepen, hangende rotsen, mijnpalen, platforms, opslag, werkplaatsen, watervallen en de baas gezamenlijk op hun grondcontact. Lager geplaatste objecten worden later getekend en bedekken hogere objecten. Gelijke grondcontacten behouden een vaste volgorde. Ook de kristalscherven binnen groepen en de stapels mijnhout volgen deze regel. De ingangsonderdelen doen mee in dezelfde sortering. De sierboog bij de baas staat 37 punten hoger, zodat de baas logisch ervoor staat en zijn gezicht zichtbaar blijft.

Het pad wordt in het bestaande grot-Canvas getekend vóór de gesorteerde decoratie. Daardoor kan de grotrand over de weg vallen terwijl lager geplaatste decorstukken ervoor blijven staan, zonder een extra Canvas over de volledige hoofdstukhoogte. Alleen de overhang boven de hoofdstukgrens gebruikt de korte aparte voorgrondlaag. Levelknoppen, Dino en het wereldbord blijven hun eigen UI-laag gebruiken.

De bronvergelijking bevestigt dat de oorspronkelijke poortgeometrie en ornamenten exact overeenkomen. Native renders zijn visueel gecontroleerd op 320, 393, 834 en 1194 punten breed. De zandkleur bij de hoofdstukaansluiting blijft op alle vier breedtes pixelgelijk. De build slaagt. `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` slagen voor wereld 5 en 6 op iPhone 17 en iPad Pro 11-inch: vier geslaagde testuitvoeringen, nul fouten. `git diff --check` is schoon.

[Ingang iPhone](Screenshots/CaveDepth/entrance-iphone.png) · [Uitgang iPhone](Screenshots/CaveDepth/exit-iphone.png) · [Ingang iPad](Screenshots/CaveDepth/entrance-ipad.png) · [Uitgang iPad](Screenshots/CaveDepth/exit-ipad.png) · [Buildlog](WorldTestLogs/CaveDepth/build.log) · [iPhone-tests](WorldTestLogs/CaveDepth/iphone.log) · [iPad-tests](WorldTestLogs/CaveDepth/ipad.log).

## Alle werelden op grondcontact en een rotsachtige uitgang — 16 oktober 2026

De aangeleverde beelden tonen twee verschillen: een boom die achter de junglebaas staat maar hem toch bedekt, en een losse poort op een kale, bolle overgang naar de stad. De bestaande wijzigingen aan bordafstand, poortverhoudingen en grotindeling zijn als uitgangspunt behouden.

**Eerste verfijningsronde.** De gezamenlijke `WorldSceneryDepth` sorteert alle tien werelden op het geplaatste grondcontact. Bomen, decorstukken en eindbazen delen dezelfde volgorde; de jungle gebruikt hiervoor kleine statische tegels. Bewegende slangen, bladeren en water gebruiken dezelfde objectposities voor hun afdekking. Het dag-en-nachtbos bleek de sorteerlijst al te ontvangen zonder die te gebruiken: dat is hersteld, met behoud van de lokale nachtkleuren. De grotuitgang krijgt onregelmatige, asymmetrische rotsterrassen en een mineraalrand die de boog met de zijrotsen verbindt. Hangende vertrek-kristallen worden niet meer door het vloermasker afgesneden; volledige kristalgroepen staan op eigen rotsrichels.

**Tweede verfijningsronde.** Verschillende rotscontouren, breuklijnen, mineraaladers, kleine scherven, losse voetstenen, mos, varens en ranken verfijnen de overgang. De boog krijgt een verdiepte binnenrand, een kleine kristalinleg en lichte steenranden. De nabije rotsen laten beide aan de pijlers bevestigde lantaarns vrij, ook op de brede iPad. Het pad loopt door de opening en de vaste titelplaat ligt vóór de aflopende rotsbanken.

De native compositie is op 320, 393, 834 en 1194 punten breed gerenderd. Per breedte zijn alle tien bossomgevingen en de overgangen 4→5 en 5→6 vastgelegd. Alleen voor deze statische native beelden is de uitgestelde voorbereiding van jungletegels overgeslagen; de app blijft de bestaande voorbereiding tijdens scrollen gebruiken. De cirkels en onvertaalde titels in deze native controlebeelden zijn hulpaanduidingen van de renderer. De echte interface wordt afzonderlijk in de simulator gecontroleerd.

[Bossomgevingen van alle tien werelden](Screenshots/SceneryDepthAndExit/native-ten-world-bosses.png) · [Uitgang op 320 punten](Screenshots/SceneryDepthAndExit/native-transition-5-6-320.png) · [Uitgang op 393 punten](Screenshots/SceneryDepthAndExit/native-transition-5-6-393.png) · [Uitgang op 834 punten](Screenshots/SceneryDepthAndExit/native-transition-5-6-834.png) · [Uitgang op 1194 punten](Screenshots/SceneryDepthAndExit/native-transition-5-6-1194.png).

De iPad-controle van de tweede ronde liet zien dat ook de nieuwe rotskap in de beschikbare hoogte moet worden meegerekend. De uniforme schaal gebruikt daarom de volledige silhouethoogte van 246 punten in plaats van alleen de oorspronkelijke 222 punten van de poort. Daardoor begint de rotskap minstens 85 punten onder het midden van de bosssteen, na het volledige onderschrift. De hoofdstukafstand blijft gelijk.

De build slaagt. `Tools/test-dino.sh` slaagt met **557.693 controles**. De nieuwe `testWorldBossSceneryRemainsPlayable` slaagt op iPhone en opent alle tien eindbazen via hun kaartknop. Op iPad slagen `testNativeWorldChaptersAndMinuteQuestions` voor werelden 2–10 en `testWorldBannersHaveBalancedClearance` voor werelden 2, 4, 5, 6, 9 en 10. Na de laatste silhouetcorrectie slaagt de afzonderlijke afstandstest voor wereld 6 op zowel iPhone als iPad. De definitieve screenshots laten het volledige BOSS-onderschrift vrij boven de rotskap. `git diff --check` is schoon.

[Buildlog](WorldTestLogs/SceneryDepthAndExit/build.log) · [Spelcontroles](WorldTestLogs/SceneryDepthAndExit/core-tests.log) · [Tien eindbazen op iPhone](WorldTestLogs/SceneryDepthAndExit/ten-bosses-iphone.log) · [Werelden en bordafstanden op iPad](WorldTestLogs/SceneryDepthAndExit/worlds-and-spacing-ipad.log).

[Definitieve uitgang op iPhone](Screenshots/SceneryDepthAndExit/exit-iphone.png) · [Definitieve uitgang op iPad](Screenshots/SceneryDepthAndExit/exit-ipad.png) · [Laatste iPhone-controle](WorldTestLogs/SceneryDepthAndExit/final-fit-iphone.log) · [Laatste iPad-controle](WorldTestLogs/SceneryDepthAndExit/final-fit-ipad.log).


## Herbouw als doorlopende grotwand — 16 oktober 2026

De vorige uitgang bestond nog uit herhaalde rotsgroepen langs een naar buiten aflopende contour. Dat gaf twee versierde randen, terwijl het voorbeeld een doorlopende grotwand met een vrijwel horizontale voet toont. Die opzet is vervangen.

De onderste grotrand blijft nu over de volle breedte ongeveer op dezelfde hoogte. Boven die voet staan onregelmatige, in elkaar grijpende steenlagen. Links en rechts hebben een eigen profiel en eigen steenverdeling. De grotere uitstekende blokken staan voor de kleinere achterste voegen en hebben verschillende hoogtes en contouren. Kristallen, ranken, varens en bloemen staan in afzonderlijke voegen en richels; de complete rots-met-kristallen-groep wordt niet meer langs de rand gekopieerd.

De boog heeft bredere rotsschouders die op de zijwand aansluiten, met afzonderlijke blokken rondom de pijlers. Een donkere binnenbekleding onder de gemetselde boog geeft de opening meer diepte. De doorgang, het BOSS-onderschrift en de bestaande titelbordafstand behouden hun vrije ruimte. De hoge wand wordt als terrein achter de bestaande baas getekend; de korte poortvoorgrond bedekt de weg bij het gewelf.

De native uitwerking is opnieuw op 320, 393, 834 en 1194 punten breed gerenderd, inclusief een geoptimaliseerde Swift-build. De eerdere beelden in het verslag hierboven horen bij de vervangen versie.

De definitieve simulatorbuild slaagt. `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` zijn gericht voor wereld 6 uitgevoerd op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. De nieuwe stadsentree opent en de eerste klokvraag kan worden beantwoord. De definitieve beelden zijn gecontroleerd op de horizontale voetlijn, de hoge steenlagen, de volledige kristalgroepen en de ruimte bij de bosssteen. `git diff --check` is schoon.

[Vorige en nieuwe opbouw](Screenshots/HorizontalCaveExit/before-after.png) · [Nieuwe uitgang op iPhone](Screenshots/HorizontalCaveExit/exit-iphone.png) · [Nieuwe uitgang op iPad](Screenshots/HorizontalCaveExit/exit-ipad.png) · [Native op 320 punten](Screenshots/HorizontalCaveExit/native-exit-320.png) · [Native op 1194 punten](Screenshots/HorizontalCaveExit/native-exit-1194.png) · [Buildlog](WorldTestLogs/HorizontalCaveExit/build.log) · [iPhone-tests](WorldTestLogs/HorizontalCaveExit/iphone.log) · [iPad-tests](WorldTestLogs/HorizontalCaveExit/ipad.log).


## Overlappende steenlagen, riviermond en bestrate aanloop — 16 oktober 2026

De hoge rotswand en de bijna horizontale voetlijn blijven de basis. De steenverdeling geeft nu alleen de achterste posities aan: afzonderlijke rotsen steken onregelmatig over de aangrenzende vakken heen. Ze worden van hoog naar laag getekend en werpen een korte contactschaduw over de lagen erachter. De onderste rotsvlakken krijgen een subtiele warme reflectie van de grond buiten.

De riviermond van de stad ligt verder buiten de grot, met ruimte voor de volledige stenen oever en kade. Water, oevers en kadebestrating gebruiken dezelfde ingangscurve. De controlepunten lopen in één richting naar de eerste verticale raaklijn van de route, zodat de rivier niet terugbuigt of een extra lus maakt. De riviermond van het dorp behoudt zijn bestaande geometrie.

De losse tegels na de poort zijn vervangen door één doorlopend terras met verspringende tegelrijen in perspectief, smalle voegen, lichtranden en een complete zijkant. De bestrating begint in de doorgang en wordt naar voren breder. De tegels dicht bij de grot hebben een koelere kleur; verder naar buiten worden ze warmer.

Een zachte lichtvlek rond de uitgang, blauwgroene grond direct langs de wand en een geleidelijke overgang naar de warmere stadsgrond verminderen de abrupte kleursprong. De koele ingangskleur loopt over beide hoofdstukhelften door. De native beelden zijn op 320, 393, 834 en 1194 punten breed gecontroleerd; de geoptimaliseerde native render en de iOS-testbuild slagen.

De gerichte tests `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBannersHaveBalancedClearance` slagen voor wereld 6 op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. De eerste stadslevel is geopend en de eerste klokvraag is beantwoord. De definitieve beelden bevestigen de overlappende steenranden, de vrijliggende riviermond, de bestrating en de kleurverloopzone. `git diff --check` is schoon.

[Detail van de verfijnde uitgang](Screenshots/CaveExitPolish/exit-detail.png) · [iPhone](Screenshots/CaveExitPolish/exit-iphone.png) · [iPad](Screenshots/CaveExitPolish/exit-ipad.png) · [Native op 320 punten](Screenshots/CaveExitPolish/native-exit-320.png) · [Native op 1194 punten](Screenshots/CaveExitPolish/native-exit-1194.png) · [Build](WorldTestLogs/CaveExitPolish/build.log) · [iPhone-tests](WorldTestLogs/CaveExitPolish/iphone.log) · [iPad-tests](WorldTestLogs/CaveExitPolish/ipad.log).
