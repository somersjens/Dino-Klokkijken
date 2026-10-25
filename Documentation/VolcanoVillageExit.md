# Afwerking van de uitgang van wereld 3

21 oktober 2026.

De lava en basaltwanden verlaten Vulkaanland via twee verspringende, vloeiende bochten. Net als bij de entree delen de rotsranden, de statische lava en de bewegende lichtstromen dezelfde geometrie. De bochten beginnen bij de laatste speelbocht en eindigen met een horizontale monding buiten beeld.

Onder het uitgaande basalt verschijnen drie lage, onregelmatige stroken as en groen. Deze sluiten aan op de ondergrond van wereld 4 en vervangen de zichtbare horizontale miststrook. De zandige schouders langs de weg vervagen mee naar het nieuwe terrein. Levelposities, de speelweg en tikgebieden zijn behouden.

## Controle

- De Debug-build voor iOS Simulator slaagt.
- De bestaande iPhone 17-schermtests voor de ruimte rond de wereldborden en de bereikbaarheid van alle tien eindbazen slagen.
- De geometrie is gecontroleerd op 320, 393, 402, 520, 600, 744, 834, 1024 en 1194 punten breed. Alle vijf vulkanen blijven geplaatst. De 109.395 silhouetmetingen vinden geen overlap met de weg of hoofdstromen; de basaltbedding heeft geen gaten. De uitgaande rotsranden hebben nergens een abrupte knik; de grootste gemeten richtingsverandering is 2,59 graden per twee punten.
- Native renders op vier breedtes en de actuele overgang in de app zijn visueel gecontroleerd. In de native renders is de baassteen vereenvoudigd tot een kroonmarkering.

[Actueel appbeeld](Screenshots/VolcanoVillageExit/app-world-3-iphone.png) · [Overgang naar wereld 4](Screenshots/VolcanoVillageExit/app-transition-iphone.png) · [iPhonebreedte](Screenshots/VolcanoVillageExit/join-393.png) · [iPadbreedte](Screenshots/VolcanoVillageExit/join-834.png) · [Brede iPad](Screenshots/VolcanoVillageExit/join-1194.png).

[Geometriecontrole](WorldTestLogs/VolcanoVillageExit/geometry.log) · [Build en schermtests](WorldTestLogs/VolcanoVillageExit/verification.log). De screenshotmap blijft lokaal en is uitgesloten van Git-synchronisatie.
