# Landscape-redesign — 4 november 2026

## Spel

Titel, referentie en antwoordgroep vormen in alle vensters één centrale kolom, met een maximale breedte van 620 punten. `DinoGameLayout` schakelt context-/antwoordkolommen en de eerdere naast-elkaarindeling voor klokinstellen uit. Antwoordstenen, verbindingsborden en tijdreeksen mogen binnen hun eigen groep meerdere items op een rij tonen. Foutfeedback vergelijkt het ingestelde antwoord links met de juiste klok rechts.

In landscape met minder dan 500 punten veilige hoogte krijgt de HUD een verticale strook van 92 punten links. Portret, level/reeks, vraagnummer, voorbeeld en pauze blijven bereikbaar. Op hogere vensters, waaronder iPad mini in landscape, blijft de HUD bovenaan. Dit wordt bepaald door het beschikbare venster, zonder lijst met toestelmodellen.

De titel blijft onderdeel van de les. Een korte landscape-les krijgt een logisch ontwerpbudget van minimaal 360 punten; de bestaande native meet-/schaalcontainer past daarna titel, klok en antwoordgroep samen in de werkelijke hoogte boven de actieknop. Ook grotere landscape-lessen passen zo als geheel. Rotatie behoudt de sessie, invoer en feedback.

De achtergrond van de vaste antwoordactie wordt eenmaal achter de hele breedte getekend, inclusief de horizontale veilige schermranden en de ruimte achter de linker HUD. De knop zelf blijft begrensd en gecentreerd onder de les.

Type 6 staat altijd onder elkaar: titel, digitale tijd, hint/opgebouwde zin en woordstenen. De compacte rijen zijn 36 punten hoog met 7 punten tussenruimte; de witte kaart krijgt een eigen binnenmarge. De stenen worden niet tot aaneengesloten stroken uitgerekt.

## Personalisatie

In landscape staan Dino/Klaar en Analoog/Digitaal als een 2×2-blok links onderaan, met het actuele voorbeeld erboven en de opties rechts. De Dino-kleuren gebruiken compacte rijen met volledige labels die over twee regels mogen lopen. iPhone landscape gebruikt de normale typografische schaal; alleen ruime, hogere vensters krijgen de tabletvergroting. De [vervolgverfijning](LandscapeRefinements.md) beschrijft ook het nieuwe levelpaneel, oefenscherm en eindscherm.

## Kaart en welkomstsprong

De kaartbreedte omvat beide horizontale safe-area-insets, omdat de scrollweergave onder deze schermranden doorloopt. De kaartvergroting volgt de korte vensterzijde. Een brede telefoon kan daardoor niet meer onbedoeld de tabletvergroting activeren. In landscape wordt de Dino-maat begrensd door de beschikbare hoogte; de ruimte boven zijn route en de landingsanchor gebruiken dezelfde maat. De HUD blijft binnen de veilige breedte gecentreerd.

De welkomstsprong is op iPhone SE opgenomen en rondom afzet, vlucht en landing in stappen van 0,08 seconde bekeken. De vlucht landt op de zichtbare levelsteen. Als het venster tijdens de native vlucht verandert, wordt de kaart direct in zijn nieuwe indeling vrijgegeven: eerder ingeplande Core Animation-keyframes kunnen niet alsnog naar een oude schermpositie vliegen.

## Verificatie

- Volledige kernsuite: 1.652.877 geslaagde controles.
- Aanvullende maatmatrix: 77.385 geslaagde controles, inclusief de eis van één vraagkolom.
- Alle twintig vraagtypen op iPhone 17 Pro: portrait, landscape, foutfeedback en terugrotatie. Alleen de oude assertions over het midden van de eerdere klokkolommen moesten aan de nieuwe leskolom worden aangepast; de aparte hercontrole van deze drie vraagtypen slaagt.
- Gerichte spel-, kaart- en menutests op een schone iPhone SE, iPhone 17 Pro en iPad mini. Beide landscape-standen en terugrotatie naar portrait worden daadwerkelijk gecontroleerd.
- De iPad-hercontrole slaagt voor zes ruimtegevoelige vraagtypen, de nieuwe referentie-boven-invoerindeling, foutvergelijkingen en sleepverbindingen na rotatie.

Bestaande simulators reageerden niet betrouwbaar op rotatie. De controles gebruiken daarom aparte, schone simulators. Een echte iPhone Duo is niet beschikbaar; de continue maatmatrix vervangt geen controle op dat fysieke toestel.

Ook de laatste kaartcontroles met centrering van de HUD slagen op [iPhone](WorldTestLogs/LandscapeRedesign/iphone-map-final.log) en [iPad mini](WorldTestLogs/LandscapeRedesign/ipad-map-final.log).

De definitieve [iPhone-controles](WorldTestLogs/LandscapeRedesign/iphone-final.log), [iPhone SE-controle](WorldTestLogs/LandscapeRedesign/iphone-se-final.log) en [iPad-controles](WorldTestLogs/LandscapeRedesign/ipad-final.log) slagen.

## Geïntegreerd portret in de zij-HUD

Het portret is vergroot van 52 naar 64 punten en overlapt de bovenkant van de balk. De verticale balk gebruikt nu dezelfde gelaagde `HUDPlate` als de horizontale variant. De bladeren houden ruimte vrij voor deze verticale aansluiting. Alle vier vakken krijgen dezelfde scheiding, met drie lijnen in de wereldkleur. Het oefenrecord houdt een eigen ruimte onder het portret.

![Geïntegreerde zij-HUD op iPhone SE](Screenshots/LandscapeRedesign/integrated-hud-se.png)

## Beelden

![Spel op iPhone](Screenshots/LandscapeRedesign/iphone-game.png)

![Personalisatie op iPhone](Screenshots/LandscapeRedesign/iphone-menu.png)

![Volledige levelkaart](Screenshots/LandscapeRedesign/iphone-map.png)

![Spel op iPad mini](Screenshots/LandscapeRedesign/ipad-game.png)

![Welkomstsprong in stappen van 0,08 seconde](Screenshots/LandscapeRedesign/welcome-flight.png)
