# Doorlopend materiaal en natuurlijke lagen — 24 oktober 2026

Het mos en de bladranken zijn op 25 oktober opnieuw getekend met fijnere begroeiing en aangesloten bladstelen. De laatste afwerking en controle staan in [Mos en verbonden bladwerk](ResultBotanicalFinish.md).

De sterren staan rechtstreeks op het materiaal van het wereldpodium. De resterende vervaging en uitsparingen achter de beloningen zijn volledig verwijderd voor alle tien werelden. Facetten, zandsteenlagen, voegen en metaal lopen over het hele object door. De compacte podiumvorm en grotere sterren blijven behouden; er is geen afzonderlijk stervlak of materiaalbeschermingsmasker meer.

## Afwerking

- **Laagvolgorde:** hoge junglebladeren groeien achter de steen; brede voorgrondbladeren en hangende ranken overlappen de zijvlakken. Ook de vallei heeft bladeren vóór de steen. De planten staan op de buitenste zijvlakken en de beloningen worden als laatste getekend.
- **Mos:** de kappen bij jungle, dorp en vallei hebben een volledige, gebogen contour met afgeronde uiteinden en onregelmatige overhang. De schaduwen en interne kleurverschillen volgen die contour. Extra tekenruimte rondom de logische podiumgrenzen voorkomt afgekapte zijkanten.
- **Grondcontact:** de dubbele mosmat en brede onderstrook zijn verwijderd. Afzonderlijke graspollen verbinden de junglesteen met het bestaande landschap. De overige werelden gebruiken een elliptische contactschaduw die naar alle kanten volledig transparant uitloopt. Extra contourlijnen direct onder de steen zijn verwijderd.
- **Gedeelde positie:** podium, decor en grondverbinding gebruiken dezelfde schaal en ankerpositie. De grotere tekenruimte verplaatst het object, Dino's voetlijn of de sterren niet.

De native tekeningen staan in `Dino/Views/ResultWorldPodium.swift`, `Dino/Views/LevelResult.swift` en `Dino/Views/ResultWorldScenery.swift`. De wereldmaterialen blijven gekoppeld aan `themeID`, ook voor de omgewisselde woestijn en Slaapvallei.

## Controle

- Debug-testbuild: geslaagd.
- `testAllWorldResultScenery`: geslaagd op eigen iPhone 17 en iPad Pro 11-inch (M5), iOS 26.5. Alle twintig wereldbeelden zijn ook visueel beoordeeld op doorlopend materiaal, vrije sterpunten, mosranden, voorgrondlagen en grondcontact.
- `testResultRewardStatesAndNavigation`: geslaagd op iPad, inclusief nul tot drie sterren, opnieuw spelen, verdergaan, kaart, eindbaasresultaten en Engelse tekst.
- Eigen iPhone SE (3e generatie, iOS 26.1): wereld 1, 5, 6, 9 en het resultaat van level 100 met extra uitleg visueel gecontroleerd. Sterren en mos zijn niet afgesneden; de bediening blijft bereikbaar.
- Drie UI-testuitvoeringen, nul fouten. De oude materiaalbeschermingscode, steruitsparingen en mosmat zijn niet meer aanwezig. `git diff --check` is schoon.

[Build](WorldTestLogs/ResultNaturalLayers/build.log) · [iPhone](WorldTestLogs/ResultNaturalLayers/iphone.log) · [iPad](WorldTestLogs/ResultNaturalLayers/ipad.log) · [Kleine iPhone](WorldTestLogs/ResultNaturalLayers/compact.log).

## Beelden

[Jungle voor en na](Screenshots/ResultNaturalLayers/jungle-voor-na.jpg) · [Alle tien werelden op iPhone](Screenshots/ResultNaturalLayers/alle-werelden-iphone.jpg) · [Alle tien werelden op iPad](Screenshots/ResultNaturalLayers/alle-werelden-ipad.jpg) · [Nul tot drie sterren](Screenshots/ResultNaturalLayers/beloningsstaten.jpg) · [Kleine iPhone](Screenshots/ResultNaturalLayers/compact/overzicht.jpg).

De vergelijking gebruikt links het aangeleverde voorbeeld en rechts een nieuwe simulatoropname van hetzelfde level. Beide uitsneden hebben dezelfde schaal en verhouding.
