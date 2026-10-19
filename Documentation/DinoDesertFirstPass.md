# Wereld 2 — Dino-Desert, eerste verbeterslag

18 oktober 2026. Wereld 2 is omgebouwd van het dag-en-nachtbos naar een verlaten woestijn. Het aangeleverde woestijnbeeld bepaalt de richting; de jungle en Kristalgrot zijn de referentie voor een doorlopend, gedetailleerd landschap. Dit is de eerste ontwerpronde.

## Landschap

- Gouden zand met brede, overlappende duinen, lichte kammen en fijne windribbels. De hellingen vervagen in de ondergrond, zonder rechte onderranden.
- Drie lagen verre zandsteenformaties achter het titelbord. Verschillende hoogtes, breedtes en lichte nevel maken de verte zachter dan de voorgrond.
- Zes grotere plekken: een natuurlijke rotsboog, een omheinde fossielopgraving, een ruïne met ontbrekende boogsteen, een droge waterput met resterende dakbalken, een rotsgroep met ribben en een oude zonnewijzer.
- De opgraving heeft ribben, wervels, een schedel met oogkas en tanden, losse botten, palen met doorhangende touwen en achtergelaten gereedschap. De waterput heeft een donkere droge opening, houten balken, een hangend touw en een lege emmer.
- Geribde cactussen met stekels, droge vertakte struiken, stenen met lichte bovenvlakken, breuklijnen en kleine losse botten. Zandsteen heeft lagen, donkere zijvlakken en zachte contactschaduwen.
- De grote vormen worden naast de daadwerkelijke Bézierbochten geplaatst en samen op grondcontact gesorteerd. De zonnewijzer staat naast de ruimere bocht bij level 17, zodat hij ook op 320 punten zichtbaar blijft.
- Op brede iPads vullen aanvullende rotsgroepen en cactussen de buitenste delen van het landschap. Hun plaatsing verschilt links en rechts.

## Wereldidentiteit

Het bord toont **Dino-Desert** in Nederlands en Engels. Zandsteen, warme houten randen, verweerde doeken, touwbevestigingen en voetafdrukken vervangen de bosornamenten. De levelstenen hebben een warme stenen rand, kleine barstjes en een koele minerale bovenkant. De HUD neemt het zandkleurige palet over.

**Zandstaart de Woestijnwachter** vervangt de bosuil. Deze vriendelijke gepantserde dino heeft zandstenen rugplaten, een verbleekte sjaal en een klok die zichtbaar aan twee banden hangt. De klok en het kleine klokje in de wereldbanner tonen **07:30**. De wereldbeloning gebruikt dezelfde woestijnillustraties. Het uitslagscherm krijgt een rustige woestijnomgeving met duinen, verre rotsen, een cactus en een ruïne.

De bestaande wereld-ID's, levels 11–20, halfuurleerlijn, ontgrendeling en opgeslagen voortgang blijven behouden. Wereld 2 gebruikt het al bestaande visuele thema-ID 7; Slaapvallei blijft wereld 7 met thema-ID 2. De ondergrond sluit aan op de jungle en loopt naar het bestaande lava-inlaatpunt van Vulkaanland.

Alle nieuwe illustraties zijn native SwiftUI/Canvas-geometrie in `Dino/Views/DinoDesert.swift`. Er zijn geen nieuwe bitmap-assets of continu draaiende animaties toegevoegd. De bestaande viewportbegrenzing van de kaart blijft van toepassing.

## Beelden

- Volledige native composities: [320](Screenshots/DinoDesertFirstPass/native-320.png), [393](Screenshots/DinoDesertFirstPass/native-393.png), [834](Screenshots/DinoDesertFirstPass/native-834.png) en [1194](Screenshots/DinoDesertFirstPass/native-1194.png) punten. De genummerde stenen in deze auditbeelden markeren de bestaande levelposities; Dino, HUD en sterren staan in de appbeelden.
- App-entree op [iPhone](Screenshots/DinoDesertFirstPass/entrance-iphone.png) en [iPad](Screenshots/DinoDesertFirstPass/entrance-ipad.png).
- Halfuurvraag op [iPhone](Screenshots/DinoDesertFirstPass/question-iphone.png) en [iPad](Screenshots/DinoDesertFirstPass/question-ipad.png).
- Woestijnwachter en aansluiting naar wereld 3 op [iPhone](Screenshots/DinoDesertFirstPass/boss-iphone.png) en [iPad](Screenshots/DinoDesertFirstPass/boss-ipad.png).
- [Zes bestemmingen](Screenshots/DinoDesertFirstPass/landmarks.png), [wachter](Screenshots/DinoDesertFirstPass/guardian-and-reward.png) en [daadwerkelijk uitslagscherm](Screenshots/DinoDesertFirstPass/result-iphone.png).

De screenshotmappen worden zoals in de rest van dit project lokaal bewaard en door `.gitignore` uitgesloten.

## Controle

- De simulatorbuild slaagt.
- `Tools/test-dino.sh`: **803.558 geslaagde controles** voor gameplay, opslag en voortgang.
- De bestaande `testNativeWorldChaptersAndMinuteQuestions` en `testWorldBossSceneryRemainsPlayable` zijn met `TEST_RUNNER_DINO_TEST_WORLD_IDS=2,3` uitgevoerd op iPhone 17 en iPad Pro 11-inch: **vier geslaagde schermtests, nul fouten**. Ze controleren de ontgrendeling, tikgebieden, halfuurvraag, HUD-wereld en het openen van beide eindbazen.
- Alle vier native breedtes en de appbeelden zijn visueel gecontroleerd. De decoraties blijven naast de speelroute; de grote tekst past ook op de smalle breedte.
- Het uitslagscherm van level 12 is afzonderlijk geopend en visueel gecontroleerd met een geïsoleerd Debug-profiel.
- `git diff --check` is schoon. Alle speltests gebruiken aparte Debug-opslag.

Logs: [kerncontroles](WorldTestLogs/DinoDesertFirstPass/core-tests.log), [iPhone](WorldTestLogs/DinoDesertFirstPass/iphone-tests.log), [iPad](WorldTestLogs/DinoDesertFirstPass/ipad-tests.log).

Een eerste iPhone-run had de wereldfilter nog zonder de vereiste `TEST_RUNNER_`-prefix en bezocht daardoor alle werelden. Die run stopte in wereld 8: de bestaande test wacht op `question.option.0`, terwijl level 71 begint met `setAnalog`. De levelconfiguratie was vóór deze redesignronde al zo. Alle tien eindbazen openden in die brede run wel succesvol. De gerichte controles voor deze wijziging zijn daarna correct gefilterd en geslaagd.

Een volgende ontwerpronde kan de steencontouren en erosie verder variëren, meer verhaal in de ruïnes aanbrengen en rustige zandbeweging toevoegen. De basiscompositie en alle wereldspecifieke oppervlakken zijn nu beschikbaar om daarop voort te bouwen.
