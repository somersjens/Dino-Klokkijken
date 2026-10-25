# Dorpspaden, volle stadsranden en tijdmachinevoorgrond

23 oktober 2026.

De dorpsbankjes zijn opnieuw getekend met een smal zitvlak, een verhoogde rugleuning en gebogen metalen armleuningen. Hun lange zijde staat langs de kade en volgt licht de richting van het kanaal. De gedraaide voetafdruk wordt bij de plaatsing meegenomen.

De doorgaande kadepaden en huispaadjes worden in twee gezamenlijke stappen geschilderd: eerst alle randen, dan alle bestrating. Afgeronde uitlopers verbinden de zijpaden met het werkelijke midden van hun kade. Zo blijft er geen losse eindrand of afwijkende kleur over het andere pad liggen.

De stad heeft dichter op elkaar geplaatste gevelrijen en meer huizen op de binnenpromenades. Rond de grotopening staan op 393 punten breedte 24 gevelplots. De oorspronkelijke grotstenen liggen achter die gevels. Het linker tunnelportaal ligt achter een nieuwe gevelgroep. De onderste rechter spoorbocht loopt naar de rechterzijde van de stad; het rechterportaal ligt volledig buiten beeld. De verborgen spoorbocht reserveert geen lege straatgrond. Open sporen, levelstenen en speelpad blijven vrij.

De stenen tijdmachinevoet en de putkragen worden vóór de bruine kanaalrand getekend. De ronde putten en de wateropening blijven volledig zichtbaar. Metselwerkvoegen en de lijntjes van de putrand worden binnen hun eigen materiaal begrensd. De tandwielen staan in een aparte voorgrond boven het zandpad; de levelstenen en hun knoppen blijven daarboven. Klokwijzers, machines en water behouden hun eigen laagvolgorde.

[Vier details](Screenshots/WorldVillageCityMachinery/preview.png) · [Volledige telefoonkaarten](Screenshots/WorldVillageCityMachinery/overview-393.png) · [Volledige iPad-kaarten](Screenshots/WorldVillageCityMachinery/overview-834.png).

De native auditbeelden gebruiken vereenvoudigde levelstenen. De afzonderlijke appbeelden in dezelfde map komen uit de iPhone- en iPad-schermtests.

- 24 aansluitingsbeelden en twaalf volledige kaarten op 320, 393, 834 en 1194 punten beoordeeld. [Renders](WorldTestLogs/WorldVillageCityMachinery/native-renders.log).
- 80.657 geometriecontroles op zes breedtes slagen: vrije spoorfunderingen en speelroute, unieke plot-ID’s, rechterportaal buiten beeld, gevels voor het linkerportaal, aansluitende tunneldoorsneden, verticale bankjes, aansluitpunten binnen de kadebestrating en volledige tandwielassemblages. [Log](WorldTestLogs/WorldVillageCityMachinery/geometry.log) en [audit](WorldTestLogs/WorldVillageCityMachinery/geometry-audit.swift).
- De bestaande tests voor metro, tijdmachine en de gewijzigde wereldborden slagen op iPhone 17 en iPad Pro 11-inch. [Metro en tijdmachine](WorldTestLogs/WorldVillageCityMachinery/city-time-machine-ui.log). De definitieve afgeronde dorpspaden slagen daarna opnieuw op beide apparaten. [Dorp](WorldTestLogs/WorldVillageCityMachinery/village-final-ui.log).
- De definitieve iOS-build en de schermtests compileren. [Build](WorldTestLogs/WorldVillageCityMachinery/ios-build.log).
