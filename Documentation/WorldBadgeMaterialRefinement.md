# Wereldbadges: zachtere materialen en laagvolgorde

De volgende verfijning volgt op het [redesign naar de beeldreferentie](WorldBadgeReferenceRedesign.md). De kleuren van de badges zijn dichter bij de bestaande landschappen gebracht. De grote verschillen tussen lichte en donkere materiaalvlakken zijn kleiner, de randen zijn dunner en de donkere letterschaduwen zijn teruggebracht.

Het oerwoud en klokdorp gebruiken warm, vergrijsd hout. De woestijn heeft lichte zandsteen. De kristalgrot krijgt leisteenblauw met koele kristallen; de stad blauwgroen metaal; de slaapvallei zacht paars met blauwgroen bladwerk. Het tijdmachinebord krijgt vergrijsd metaal en zacht messing, passend bij het landschap. De piraten behouden een houtkleur en het kasteel ivoor met gedempt goud en blauw.

De ornamenten krijgen een lichte omgevingskleur uit hun eigen wereld. Daarmee sluiten ook bladnerven, rotsfacetten, buizen, kristallen en kleine bevestigingen aan op het materiaal van het bord. De grote ondertitels blijven op een rustig leesvlak staan. De optie voor hoog contrast houdt een duidelijke, donkere tekstcontour.

Bij de tijdmachine is de constructie opnieuw geordend. Alleen de dragende leidingen en achterste rail staan achter het bord. Klokranden, lagerblokken, assen, gekoppelde tandwielen en voetblokken worden na de twee tekstplaten getekend. Ze vallen daardoor vóór de bordranden. Kleine contactschaduwen, afgeschuinde randen, een ingewerkte metaalnaad en boutjes maken hun bevestiging zichtbaar. De voorgrond blijft buiten de letters en het klokje van de ondertitel.

[Alle badges, Nederlands](Screenshots/WorldBadgeMaterialRefinement/ten-worlds-nl.png) · [Engels](Screenshots/WorldBadgeMaterialRefinement/ten-worlds-en.png) · [Tijdmachine, smal](Screenshots/WorldBadgeMaterialRefinement/world-8-284-nl.png) · [Tijdmachine, breed](Screenshots/WorldBadgeMaterialRefinement/world-8-564-nl.png).

## Controle

De native renders omvatten alle tien werelden in Nederlands en Engels, op 284, 354 en 564 punten, plus hoog contrast op 284 punten. Vooral de leesbaarheid van de lichtere titelvlakken en de overlap van de tijdmachineblokken met de randen zijn visueel beoordeeld.

[Simulatorbuild](WorldTestLogs/WorldBadgeMaterialRefinement/build.log).

De bestaande afstandscontrole is geslaagd in een aparte iPhone 17-simulator voor de kristalgrot, slaapvallei en tijdmachine: 33,167 seconden, nul fouten ([testlog](WorldTestLogs/WorldBadgeMaterialRefinement/isolated-iphone.log)). De [tijdmachine in de app](Screenshots/WorldBadgeMaterialRefinement/world-8-iphone.png) is ook visueel beoordeeld op de overlap van blokken, tandwielen en klokranden. De brede native renders zijn op dezelfde details gecontroleerd.

De geometrische iPad-controle van de tijdmachine is geslaagd: 17,860 seconden, nul fouten ([testlog](WorldTestLogs/WorldBadgeMaterialRefinement/ipad.log)). Een eerste run op de gedeelde iPhone-simulator gaf afwijkende metingen tijdens een ander scherm; de herhaling op de aparte simulator is de gebruikte iPhone-verificatie. De opgeslagen beelden komen rechtstreeks uit het bijbehorende testresultaat.
