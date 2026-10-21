# Wereld 8 — eerste redesignronde van het klokkenkoninkrijk

21 oktober 2026. Het nieuwe aangeleverde voorbeeld vormt de basis voor een dichtbebouwde, magische stad. De bestaande uitvindingen staan nu tussen gebouwen en terrassen, in plaats van los op een open vloer.

Vervolg: [stromend water, echte rivieruitmondingen, volledige lantaarns en verfijnde laagvolgorde](TimeMachineWaterConnections.md).

## Eerste uitwerking

- Twee doorlopende stadsflanken volgen de echte bochten van het levelpad. Gemetselde gevels, gewelfde onderbouwen, klokkentorens, blauwe koepels, balkons en verlichte boogramen vullen de zijkanten. Op bredere schermen komen er meer gevelmodules bij.
- Brede stenen terrassen dragen de gebouwen. Trapvluchten wisselen van richting en landen op de boven- en onderbordessen. Messing balustrades hebben stijlen, ringornamenten, handrails en afgewerkte eindknoppen.
- Koningsblauwe vaandels dragen een gouden zandloper als wapenteken. Ze hangen aan gevels, torens en terrassen.
- Gouden lantaarns hebben gefacetteerd glas, een dakje, een donkere voet, metalen stijlen en warm licht. Bloemenranden en bloeiende hangranken groeien langs de gevels en bordessen.
- Twee helderblauwe magische waterlopen volgen de stad. Messing randen, stenen oversteken en bewegende lichtstrepen verbinden ze met de bestaande tanks en watervallen. De drie hoofdportalen hebben een sterker elektrisch blauw energieveld.
- Bij de wereldgrenzen loopt de stadslaag geleidelijk over in de omliggende ondergrond. Het bestaande levelpad, de levelstenen, vragen en voortgang behouden hun werking.

## Tekenen en beweging

De nieuwe architectuur wordt samen met het bestaande terrein gecachet. Metselwerk, balustrades en begroeiing worden per materiaal in samengestelde paden getekend, om de hoeveelheid afzonderlijke tekenopdrachten op tablets te beperken. Er zijn geen nieuwe bitmapassets toegevoegd.

De geometrie van beide waterlopen, de stadsgrenzen en hun voorgrondmaskers wordt per kaartformaat bewaard. Alle animatiestroken gebruiken dezelfde volledige waterpaden; de lichtstrepen sluiten daardoor bij hun grenzen op elkaar aan. Bruggen en apparaten dekken de stroom af. De bestaande zichtbaarheidspauze, maximaal vijftien updates per seconde, inactieve appstatus en **Minder beweging** gelden ook voor deze nieuwe waterlaag.

## Beelden

| Deel van de kaart | iPhone 17 | iPad Pro 11-inch |
| --- | --- | --- |
| Entree | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-entrance-iphone.png) | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-entrance-ipad.png) |
| Levels 72–74 | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-74-iphone.png) | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-74-ipad.png) |
| Levels 75–77 | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-77-iphone.png) | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-77-ipad.png) |
| Eindbaas | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-80-iphone.png) | [Open](Screenshots/TimeMachineKingdomFirstPass/time-machine-route-80-ipad.png) |

Native overzichtsrenders: [320](Screenshots/TimeMachineKingdomFirstPass/native-320.png), [393](Screenshots/TimeMachineKingdomFirstPass/native-393.png), [834](Screenshots/TimeMachineKingdomFirstPass/native-834.png) en [1194](Screenshots/TimeMachineKingdomFirstPass/native-1194.png) punten breed. Deze overzichtsrenders gebruiken eenvoudige genummerde routecirkels; de appbeelden tonen de echte interface.

## Verificatie

De definitieve [simulator-testbuild](WorldTestLogs/TimeMachineKingdomFirstPass/build.log) slaagt. De bestaande test `testTimeMachineWorkshopRouteRemainsPlayable` slaagt op [iPhone 17](WorldTestLogs/TimeMachineKingdomFirstPass/iphone.log) en [iPad Pro 11-inch](WorldTestLogs/TimeMachineKingdomFirstPass/ipad.log): **twee geslaagde testuitvoeringen**. Deze opent level 71, controleert de instelbare klok en bevestigingsknop, scrolt langs levels 74, 77 en 80 en opent de eindbaas. De entree en de drie routebeelden zijn op beide apparaten visueel nagekeken ([beeldoverzicht](Screenshots/TimeMachineKingdomFirstPass/app-overview.png)).

De [native geometriecontrole](WorldTestLogs/TimeMachineKingdomFirstPass/native-render.log) onderzoekt negen breedtes van 320 tot 1194 punten. Alle **30.620 onderzochte punten** in de gereserveerde promenade liggen buiten de nieuwe stadsflanken. De bestaande steekproef van de negen hoofdmachines vindt daarnaast nul routecontacten in 9.477 punten. Dit zijn steekproeven van de geometrie; de stadscontour knipt de nieuwe architectuur ook daadwerkelijk buiten de promenade af.

Vier vaste animatietijdstippen leveren verschillende beelden op. Twee renders met **Minder beweging** zijn identiek ([controlebestand](WorldTestLogs/TimeMachineKingdomFirstPass/visual-checks.json)). `git diff --check` is schoon.

Het [afzonderlijke diff voor wereld 8](WorldTestLogs/TimeMachineKingdomFirstPass/world-8.diff) bevat de implementatie voor deze ronde. Gelijktijdige, onafhankelijke wijzigingen aan de piratenwereld in hetzelfde bronbestand zijn behouden. De uiteindelijke appcontroles gebruiken de gezamenlijke build.

Dit is de eerste ronde van het nieuwe stadsontwerp. Uniekere gebouwen, grotere architectonische blikvangers en verdere verfijning van de verbindingen kunnen hierop voortbouwen.
