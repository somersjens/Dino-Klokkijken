# Vraagselectie en verborgen moeilijkheid — 25 oktober 2026

Alle twintig vraagtypen gebruiken in oefenen en avontuur dezelfde selectieregels. De zes tijdsoorten behouden hun eigen invoerstap; iedere combinatie heeft drie verborgen moeilijkheidsniveaus. De moeilijkheid bepaalt antwoordondersteuning en rekencomplexiteit. Na de eerste binnenkomer is steeds de volledige gekozen tijdsoort beschikbaar.

## Tijdkeuze en variatie

| Tijdsoort | Beschikbare minuten | Eerste kennismakingsvraag |
| --- | --- | --- |
| Hele uren | :00 | Duidelijke uurstand |
| Halve uren | :00, :30 | Half uur |
| Kwartieren | :00, :15, :30, :45 | Kwart over of kwart voor |
| Tien minuten | :00, :10, :20, :30, :40, :50 | Tien over of tien voor |
| Vijf minuten | Alle veelvouden van vijf | Vijf over of vijf voor |
| Minuten | :00–:59 | Eén/twee minuten over of voor |

Alleen de eerste introductievraag per combinatie in een sessie geeft voorkeur aan herkenbare uurstanden (3, 6, 9 of 12). Daarna worden alle toegestane minuten en uren gebruikt, ook als de speler door fouten op introductie blijft. Een fout vergroot de ondersteuning en vermindert de rekenlast zonder de speler weer vast te zetten op :05 en :10.

De generator bewaart per vraagtype en tijdsoort maximaal 12 recente vragen, of 60 voor losse minuten. Hij kiest eerst de minst gebruikte minuut, vervolgens een minst gebruikt deel van de wijzerplaat en daarna een minder gebruikt uur. Waar mogelijk verschilt het uur van de direct voorafgaande vraag. Gelijke kandidaten worden willekeurig gekozen. Zo komen vijf over, vijf voor, kwartieren en tijden rond half snel afwisselend voorbij, zonder een vaste oplopende reeks.

De geschiedenis blijft afzonderlijk per vraagtype werken in Oplopend en Mix. Het avontuur gebruikt dezelfde afweging bij het vooraf maken en bij het aanpassen van vervolgvragen. Een sessie bewaart een begrensd aantal vragen; er ontstaat geen onbeperkte geschiedenis in de speleropslag.

Analoge aflees-/woordvragen gebruiken een 12-uurswijzerplaat. Vragen met expliciete 24-uursnotatie en rekencontext kunnen alle dagdelen gebruiken. Dagdeelvragen verdelen hun antwoorden over de vier dagdelen; de bestaande ingestelde dagdeelgrenzen blijven gelden. Goed/fout verdeelt ware en onware beweringen. Tijdzonevragen wisselen recente bestemmingen af. Rekenvragen wisselen toegestane tijdsduren af.

## Drie niveaus

- **Kennismaken:** twee keuzes waar passend, één eenvoudige rekenstap en een rustige eerste klokstand.
- **Vertrouwd:** vier keuzes, alle klokposities en gevarieerde rekenstappen tot 90 minuten.
- **Uitdagen:** vier plausibele keuzes, uur-/minuutcombinaties en waar passend een overgang over middernacht. Optellen, aftrekken en wijzers vooruit zetten gebruiken stappen tot vier uur; reeksen stappen tot 90 minuten; verschillen maximaal 180 minuten.

Eén goed eerste antwoord verhoogt kennismaken naar vertrouwd. Twee goede eerste antwoorden op vertrouwd verhogen naar uitdagen. Daarmee kan vraag vier de hoogste moeilijkheid hebben. Een fout verlaagt één stap en begrenst ook de direct volgende vraag in een gemengde sessie. Herstel volgt dezelfde korte route. Herkansingen, voorbeelden en het getoonde antwoord tellen niet als nieuwe leerprestaties.

Het avontuur behoudt zijn vaste leerlijn: een onbekende combinatie begint eenvoudig, bekende combinaties volgen het geplande niveau en fouten geven tijdelijke ondersteuning. Alleen een onbeantwoorde vervolgvraag mag worden vervangen. Vraagtype, ID, score en gemeten antwoordtijd blijven behouden.

## Contextregels

**Treinen:** vertrek vanaf 06:00 en aankomst uiterlijk 22:00, met beide ritten en de overstap op dezelfde dag. Iedere rit duurt minstens tien minuten, afgerond naar de gekozen tijdsoort. De maximale ritduur groeit van ongeveer twintig naar negentig en honderdvijftig minuten. Overstappen duren één tot dertig minuten op de gekozen stap; bij hele uren is een uur de kleinste beschikbare stap. Alle tussenklokken, antwoorden en afleiders blijven op het geselecteerde minutenraster.

**Vluchten:** de eerste moeilijkheid oefent vliegtijd zonder tijdzoneverschil; vertrouwd voegt één uur vooruit/achteruit toe. Uitdagen wisselt twee, drie en vier uur vooruit/achteruit af, soms drieënhalf uur. Vliegtijden zijn minstens twee uur en minstens twee uur langer dan het tijdzoneverschil, met gevarieerde extra tijd. Gegeven tijd en antwoord blijven op de gekozen tijdsoort.

**Tijdzones:** verschillen zijn hele uren en soms halve uren. De hoofdsteden gebruiken de echte Foundation/IANA-offset op de huidige lesdatum. New Delhi voegt een echte halfuurzone toe ([CSIR-NPL: UTC +5:30](https://www.nplindia.res.in/clockcode/html/)). Hele-urenvragen gebruiken alleen hele uurverschillen; alle andere tijdsoorten kunnen een halfuurverschil behouden. Er worden geen willekeurige verschillen per vijf of losse minuten gegenereerd. Berekeningen, teksten, kaartlabels en voorbeeldanimaties bewaren het halfuur exact; de animatie telt hele uren en eindigt zo nodig met een halfuur.

## Opslag en verificatie

De bestaande `dino.learning.records.v1` blijft leesbaar. Leerstand blijft per combinatie bewaard en wordt gereset met de gewone voortgangsreset. Oefenrecords, vraagvolgorde, sterren en cloudopslag behouden hun betekenis.

De kernsuite controleert alle 360 categorieën in Nederlands en Engels, de volledige avontuurroute, correcte sommen, unieke antwoorden, tijdsoorten, snel herstel en opslag. Aanvullende variatietests controleren met twee seeds voor ieder type en niveau alle minuten binnen een korte reeks, beide gemengde oefenvolgorden, gevarieerde rekenduren, realistische treinreizen en incidentele halfuurzones. Positieve en negatieve halfuurberekeningen en de laatste halve animatiestap worden apart gecontroleerd.

Uitgevoerd: de volledige kernsuite slaagt met **843.852 controles**. Na een extra controle op aangepaste dagdelen met slechts één uur slaagt de gerichte variatiesuite met **19.563 controles**. De Debug-build voor iOS Simulator slaagt. De schermtest voor de opbouw na één en drie goede antwoorden slaagt op iPhone 17 (iOS 26.5); ook de Engelse referentiekaart met Londen slaagt.
