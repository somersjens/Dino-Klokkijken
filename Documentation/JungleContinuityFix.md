# Jungle — doorlopende animatie, stammen en bandana

16 oktober 2026.

De scrollpauze uit de vorige junglewijziging is verwijderd. De kaart publiceert geen scrollfasestatus meer naar alle decorlagen. Water, vogels, slangen en vallende bladeren blijven ook tijdens slepen en uitrollen bewegen. De bestaande limieten van 20/24 updates per seconde blijven gelden, evenals pauzeren buiten beeld, bij een inactieve app en bij Minder beweging.

De vaste begroeiing wordt vooraf per tegel opgebouwd. Een voorbereide tegel blijft behouden zolang het hoofdstuk binnen het bestaande venster voor nabije werelden staat. Terugscrollen vervangt die laag dus niet door transparantie. De statische Canvas-lagen tekenen zonder asynchrone vervanging; de scèneberekening blijft gecachet. Bij het ver weg verlaten van het hoofdstuk kan de bestaande kaartbegrenzing het volledige landschap nog steeds vrijgeven.

Gevallen stammen hebben één licht zaagvlak, gericht naar het pad. De achterkant toont geen tweede doorsnede en verdwijnt achter een bosje dat aan de berekende stampositie gekoppeld is. De nieuwe bosjes volgen dezelfde controle op vrije ruimte langs het pad.

De eerder toegevoegde donkere letters op lichte bandana's gebruiken antraciet (`#3D3D3D`). De bestaande dekking van de print blijft behouden, inclusief de overgang naar de stof bij de randen. De normale rode bandana behoudt witte letters.

## Controle

- De actuele simulatorbuild slaagt: [buildlog](WorldTestLogs/JungleRedesign/continuous-build.log).
- **557.561 kerncontroles slagen**: [log](WorldTestLogs/JungleRedesign/continuous-core.log). Dit omvat vrijhouden van het pad op elf schermbreedtes, oriënteren en afdekken van alle vier de stammen, en de daadwerkelijke antracietkleur in alle zeven poses op witte en lichte crème stof.
- De nieuwe gerichte scrolltest sleept zesmaal langzaam heen en terug rond level 3. Deze slaagt op [iPhone](WorldTestLogs/JungleRedesign/continuous-iphone.log) en [iPad](WorldTestLogs/JungleRedesign/continuous-ipad.log), met behoud van het bedienbare HUD en de spelerpositie in level 3.
- Een iPhone-simulatoropname bevat 1.064 gedecodeerde beelden. Het gecontroleerde kaartvenster bevat 634 beelden over 25,5 seconden, zonder zichtbare lichtflitsen in de bekeken reeks. De grootste gemiddelde helderheidstoename tussen opeenvolgende kaartbeelden is 0,00223 op een schaal van 0–1: [meetgegevens](WorldTestLogs/JungleRedesign/continuous-frame-review.json). Deze steekproef van het onderste kaartvlak ondersteunt de visuele controle; dit is geen algemene flitsdetector of FPS-meting.
- Het [contactblad](Screenshots/JungleRedesign/continuous-scroll-contact.png) toont ook het voorafgaande starten van de testapp. De witte startschermen vóór de kaart vallen buiten het gecontroleerde kaartvenster. [Watervalbeelden tijdens de beweging](Screenshots/JungleRedesign/continuous-water-motion.png) tonen veranderende stroomstrepen.
- Beeldcontrole: [stammen rond level 3](Screenshots/JungleRedesign/continuous-level-3-iphone.png), [terugscrollen op iPad](Screenshots/JungleRedesign/continuous-return-ipad.png), [antraciet op wit en crème](Screenshots/JungleRedesign/bandana-charcoal.png).
- `git diff --check` is schoon. De oudere CPU-percentages uit de variant met scrollpauze zijn geen meting van deze herstelde versie.
