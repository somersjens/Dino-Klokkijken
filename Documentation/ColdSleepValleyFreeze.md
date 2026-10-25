# De koude vastloper in de slaapvallei

23 oktober 2026. Vervolg op de [eerste kaartoptimalisatie](MapScrollPreparation.md).

De gemelde meersecondenpauze bleef bestaan na de verbetering van het geheugengebruik. Een afzonderlijke eerste passage heeft een maximale onderbreking van **8.016,6 ms** op de hoofdthread gereproduceerd.

De log meet daarvan **7.428,4 ms** aan meeuwenvoorbereiding op de hoofdthread.

De meeuwen van de piratenwereld waren een aparte laag buiten de eerder begrensde landschapsanimaties. Hun eerste `poses`-aanroep maakte synchroon een complete vliegcyclus aan: 68 seconden aan trajecten, botsingsvermijding en meerdere stabilisatierondes. Ook een gepauzeerde timeline voerde die eerste aanroep uit. Wereld 9 wordt ruim vooruit opgebouwd, terwijl de speler nog door wereld 7 scrolt. Daardoor verschijnt de pauze op een andere plek dan de wereld die het werk veroorzaakt.

De volledige voorbereiding van de kustgeometrie, landingsplekken en vliegsimulatie draait nu op een aparte actor. De tekenfunctie bemonstert uitsluitend een al voorbereide reeks. Zij kan geen nieuwe simulatie meer starten. Eén actor berekent de trajecten na elkaar, bewaart maximaal zes schermmaten en breekt achterhaalde verzoeken bij verdwijnen of roteren tussen simulatiestappen af. De voorbereiding begint nog steeds buiten beeld.

Een tweede, kleinere piek kwam bij het vooruit laden van de kasteelwereld vandaan: één rasterpass kostte 358,9 ms. De oever-, trap-, wandelpad- en heggeometrie van die wereld wordt nu gedeeld en op de achtergrond voorbereid voordat het landschap wordt getekend.

De rekenstappen van de vliegsimulatie zijn behouden; alleen controles op annulering zijn toegevoegd. De gedeelde animatietijd blijft leidend. Water, begroeiing, klokken en andere kaartlagen wachten niet op de meeuwenberekening.

De nieuwe `testColdSleepValleyScrollKeepsMainThreadResponsive` gebruikt geen performance-opwarmronde en kiest per run een lege landschapcache. Een uitsluitend in Debug ingeschakelde displaylink meet vanaf het einde van de kaartopening de langste pauze tussen hoofdthreadcallbacks. De test doorloopt de eerste passage door levels 57, 61, 65, 68, 71, 75, 81 en 85, verlangt een maximum onder 500 ms en controleert dat de volledige vogelvoorbereiding daadwerkelijk op de achtergrond is geleverd. De test faalt met de eerdere code op de gemeten 8.016,6 ms.

Dit is een controle van een lange hoofdthreadblokkade, geen garantie van een bepaalde framerate op ieder fysiek toestel.
