# Overgang tussen vragen met meer of minder antwoorden

## Oorzaak

Bij een volgende vraag kreeg alleen `QuestionRenderer` een nieuwe identiteit. De titel en de scrollcontainer bleven bestaan; een aparte `onChange` scrolde daarna terug naar de titel. Een hogere antwoordgroep kon daardoor eerst op de oude scrollpositie verschijnen en vervolgens opnieuw worden uitgelijnd.

Op iPad bewaarde `questionContentHeight` bovendien de gemeten hoogte van de vorige vraag. Na de eerste indeling van de nieuwe vraag werd die waarde via een geometriecallback vervangen. De gecentreerde combinatie van HUD, vraag en onderknop kreeg hierdoor een tweede indeling, vooral zichtbaar bij de overgang van twee naar vier opties of terug.

## Aanpassing

`DinoQuestionViewportLayout` vraagt tijdens de indeling de ideale hoogte van de actuele scrollinhoud op. Op iPad begrenst deze layout de vraaghoogte direct tot de beschikbare ruimte; op iPhone gebruikt hij de vaste beschikbare hoogte. Er is geen opgeslagen vraaghoogte of volgende geometriecallback meer nodig.

De volledige vraagviewport, inclusief titel en scrollcontainer, krijgt de identiteit van de vraag. Nieuwe vragen beginnen daardoor meteen op hun eigen beginpositie; de aparte scrollopdracht na de vraagwissel is verwijderd. De wissel gebruikt een identity-transition. Korte vragen blijven gecentreerd en lange vragen blijven scrollbaar. Scrollanimaties bij antwoordfeedback en uitleg blijven binnen de actuele vraag werken.

De hoogte van een vraag met vier opties mag verschillen van die van een vraag met twee opties. Deze wijziging voorkomt de tussentijdse indeling met de positie of hoogte van de vorige vraag; hij reserveert geen lege antwoordvakken.

## Controle

`testQuestionTransitionWhenAnswerChoicesIncrease` doorloopt analoge antwoordklokken, digitale antwoordkaarten en de uitgebreide klokkeuzevragen. Per type controleert hij twee → vier → twee opties, bereikbaarheid en begrenzing van alle antwoorden, stabiele posities na de wissel en de beginpositie van de teruggekeerde vraag. `testQuestionTransitionWhenAnswerChoicesIncreaseInLandscape` herhaalt dit op iPad in landschap.

Daarnaast bewaakt `testClockAnswerFeedbackKeepsItsStageAndTargetInPlace` de bestaande feedback bij digitaal instellen, analoog instellen en vooruitzetten.

Op 28 oktober 2026 slagen de Debug-simulatorbuild en alle vijf geselecteerde schermtests: twee op iPhone 17 en drie op iPad (A16), beide met iOS 27. De eerste gerichte overgangscontrole slaagt ook op iPhone 18 Pro. De simulatoropnamen zijn rond de vraagwissel op intervallen van 50 milliseconden visueel gecontroleerd: de nieuwe vraag verschijnt direct in haar definitieve indeling, zonder een tweede zichtbare verplaatsing.

De volledige kernsuite slaagt met **1.294.329 controles**. Deze run gebruikt een lokale bronkopie, zodat gelijktijdige wijzigingen in andere werkzaamheden de compilerinvoer niet kunnen veranderen. Ook de whitespacecontrole slaagt.

Na de twee geslaagde iPhone-tests bleef Xcode hangen bij het afsluiten van de resultaatbundel. Dat proces is na de complete testuitslag gestopt; de iPhone-uitslag is gebaseerd op de volledige XCTest-uitvoer. De iPad-run en zijn resultaatbundel zijn normaal afgerond.

Lokale beelden: [iPhone met twee opties](Screenshots/QuestionTransitions/iphone-two-options.png), [vier opties](Screenshots/QuestionTransitions/iphone-four-options.png), [iPad met twee opties](Screenshots/QuestionTransitions/ipad-two-options.png), [vier opties](Screenshots/QuestionTransitions/ipad-four-options.png) en [iPad in landschap](Screenshots/QuestionTransitions/ipad-landscape-four-options.png). De [iPhone-overgang](Screenshots/QuestionTransitions/iphone-transition-50ms.jpg) en [iPad-overgang](Screenshots/QuestionTransitions/ipad-transition-50ms.jpg) staan ook als beeldreeks opgeslagen. Deze screenshotmap is lokaal en wordt door Git genegeerd.
