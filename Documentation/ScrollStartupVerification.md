# Startanimatie en voorbereid kaartlandschap

20 oktober 2026.

## Gedrag

Het native iOS-startbeeld toont dezelfde basiskleur als de app. Sinds 23 oktober bestaat de opening uit een draaiende standaardklok en een native houten bord met de vertaalbare spelnaam op twee regels. De opgeslagen Dino-kleuren worden buiten de hoofdthread voorbereid. Dino komt achter het bord omhoog; daarna wordt de kaart achter deze compositie klaargezet. Zodra de echte levelrij, de HUD en de naburige landschappen klaarstaan, blijft de complete compositie één seconde zichtbaar. Dan vervagen bord en decor en springt dezelfde Dino met een boog naar de gemeten positie op zijn levelsteen. Na de landing neemt de kaart-Dino het op exact die plek over. Bij Minder beweging gebruikt de overgang een korte vervaging. Na terugkeer uit een level wordt de openingsanimatie niet herhaald. Zie [het nieuwe startscherm](StartScreenRedesign.md).

De eerste layout gebruikt meteen de echte HUD-schaal en schermbreedte. Herstel van de opgeslagen scrollpositie gebeurt vóór de kaart zichtbaar wordt. De vriendenrij behoudt haar ruimte tijdens Game Center-authenticatie.

## Rendering en voorbereiding

- Het scrollen pauzeert of herstart geen animatieklok. Animaties gebruiken één vaste begintijd en lopen onafhankelijk van scrollgebaren door.
- De asynchrone landschapcanvassen die een flits konden veroorzaken zijn verwijderd. De jungle gebruikt voorbereide stroken; een themalandschap wordt eenmaal gerasterd en vervolgens als een vaste afbeelding getoond; de lichte animaties blijven aparte native lagen. Bij een andere schermmaat blijft de bestaande afbeelding staan totdat de nieuwe klaarstaat.
- De actuele wereld en maximaal twee werelden erboven en eronder worden tijdens de opening voorbereid. Vervolgens geldt een voorbereidingszone van drie schermhoogten, met minimaal 1.800 punten aan beide kanten. Verre viewlagen worden vrijgegeven, terwijl voorbereide afbeeldingen herbruikbaar blijven.
- Een geheugen-cache met een richtwaarde van 96 MiB bewaart de landschapafbeeldingen. Een lokale schijfcache voorkomt dat een volledige procesherstart dezelfde tekenopdrachten opnieuw moet uitvoeren. Deze cache staat los van spelvoortgang en wordt per appbuild onderscheiden. Decor wordt op maximaal 2× schermschaal opgeslagen; tekst, HUD en levelbediening blijven native op de schermschaal.
- De kostbare perceelindeling en dicht bemonsterde vaarroutes van het dorp worden per kaartmaat één keer berekend en gedeeld tussen terrein, animaties en maskers. De geometrie wordt op een achtergrondtaak voorbereid vóór de rasterpass.
- Kleine effecten en bewegende dieren beginnen al 256 punten buiten beeld te tekenen. Hun voorbereidingsband verandert niet voor iedere scrollpixel. Daardoor komen ze bewegend binnen, zonder op de schermrand geïnitialiseerd te worden.
- De bootroutes beginnen en eindigen ruim buiten de wereldgrens. Beide boten hebben een eigen vertrekmoment; de lusovergang gebeurt buiten beeld. Bruggen en brugwachters gebruiken dezelfde bewaarde route en hetzelfde tijdstip.
- Op de kaart wordt alleen Dino's staande pose voorbereid. De overige animatieposes worden bij de startkaart/game geladen.

## Verificatie

`testColdLaunchMapKeepsItsFirstVisiblePosition` sluit het appproces volledig af en opent opnieuw bij level 1, 4 en 91, inclusief opgeslagen blauwe/paarse Dino-kleuren. Na de openingsanimatie moeten het opgeslagen level en de HUD direct bedienbaar zijn en op dezelfde positie blijven.

`testPreparedMapArtworkStaysStableDuringScrolling` opent het dorp en controleert tijdens herhaalde scrollgebaren dat het aantal rasterisaties niet toeneemt. Deze teller bestaat alleen in een geïsoleerde Debug-testomgeving.

De coretests controleren dat voorbereide animatiebanden de gehele zichtbare kaart omvatten, acteurs vóór de schermrand voorbereiden, kleine scrollverplaatsingen samenvoegen en verre animaties uitschakelen.

De koude start is daarnaast opgenomen en in afzonderlijke frames gecontroleerd op de aansluiting met het native startbeeld, kaartopbouw, vlucht en landing. Ook herhaald scrollen door het dorp is opgenomen en visueel gecontroleerd. Opnames en contactbeelden staan lokaal in `/tmp`.

De vergelijkende scrolltest gebruikt dezelfde iPhone 18 Pro-simulator, iOS 27, Debug-configuratie en drie gemeten herhalingen van vier snelle vegen omhoog en vier omlaag. CPU-, geheugen- en intervalmetingen zijn simulatorindicaties; ze zijn geen FPS-meting op een fysiek toestel. De oudere eerste optimalisatie is vervangen na de gemelde flitsen en verspringingen.

## Geslaagde controles

Zowel de Debug-testbuild als de geoptimaliseerde Release-simulatorbuild slaagt.

- **805.848 corecontroles**: spelregels, opslag, geometrie, voorbereiding buiten beeld en bestaande regressies.
- **iPhone 18 Pro, iOS 27**: koude herstart bij level 1, 4 en 91; eigen Dino-kleuren; herhaald scrollen door het dorp met ongewijzigd aantal rasterisaties.
- **iPad (A16), iOS 27**: dezelfde koude herstarts; kaartrotatie en HUD-verhoudingen; doorlopende vraag bij rotatie en pauzeren/hervatten; herhaald dorpscrollen met ongewijzigd aantal rasterisaties.
- De overgang van gepersonaliseerde Dino via de startkaart naar het spel, een volledige uitslag en terugkeer naar de kaart slaagt eveneens.

De bestaande rotatietest is aangepast aan de actuele adaptieve twee- of vierkeuzevragen en directe foutfeedback bij twee keuzes. Alle positiecontroles wachten expliciet tot de gevraagde landingsanimatie is afgerond.

## Afzonderlijke scrollmeting

| Metriek, gemiddelde van drie herhalingen | Nulmeting | Definitieve versie | Verschil |
| --- | ---: | ---: | ---: |
| CPU-tijd van de app | 10,900 s | 6,551 s | −39,9% |
| Gemiddeld fysiek appgeheugen | 176,95 MB | 129,55 MB | −26,8% |
| Piek fysiek appgeheugen | 180,65 MB | 131,26 MB | −27,3% |
| CPU-instructies | 99,61 miljard | 73,69 miljard | −26,0% |
| Volledige gemeten testbewerking | 35,795 s | 23,102 s | −35,5% |
| Scroll-/uitloopinterval | 2,545 s | 2,581 s | +1,4% |

De definitieve meting is afzonderlijk uitgevoerd, nadat andere schermtests en videoverwerking waren afgerond. Het scroll-/uitloopinterval beschrijft dezelfde gebaren en is geen FPS-meting. De volledige testbewerking bevat ook automatiseringswachttijd. De relevante verbetering is minder appwerk en lager geheugenverbruik; de animaties zijn niet versneld. Ruwe meetreeksen staan in [ScrollStartupMeasurements.json](ScrollStartupMeasurements.json).
