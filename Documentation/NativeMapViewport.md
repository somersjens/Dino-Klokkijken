# Native viewport voor de wereldkaart

**Afgewezen experiment; volledig teruggedraaid.** De centrale native waarnemer kostte in de koude toestelproef meer CPU en gaf meer haperingen. De productiecode gebruikt weer de eerdere SwiftUI-positieobservaties.

2 november 2026. De gebruiker ervaart nog veel haperingen bij grote vegen door meerdere werelden, ook in de gewone Release-app. De eerdere geometriecaches verbeterden één automatische proef maar hebben het ervaren probleem niet opgelost.

## Nieuwe opname van echte vegen

Een afzonderlijke Time Profiler-opname van circa 26 seconden in de gewone Release-app is geslaagd. Anders dan de eerdere gecombineerde opname kon deze worden opgeslagen en geëxporteerd. De gebruiker veegde ongeveer twintig seconden zelf door meerdere werelden.

Er zijn 13.668 CPU-steekproeven van 1 ms, waarvan 11.228 op de hoofdthread. De inclusieve stacks bevatten 7.274 ms in SwiftUI-renderupdates, 4.523 ms in AttributeGraph-updates en 3.366 ms in Core Animation-transacties. Deze aantallen overlappen en worden niet bij elkaar opgeteld. De grootste bladkosten zitten in graphupdates, het doorgeven van gewijzigde attributen en laagverwerking. Losse geometrie- en tekenfuncties vormen een veel kleiner deel. Log en opname: `.build/iphone-manual-cpu-only.log` en `.build/iphone-manual-cpu-only.trace`.

De werkhypothese is dat de vele afzonderlijke SwiftUI-positieobservaties de weergaveboom te vaak laten meelopen met de native scrolloffset. Dat is een interpretatie van de stacks, nog geen afzonderlijk bewezen oorzaak voor iedere pauze.

## Aanpak

De kaart krijgt één eigen `MapViewportDriver`. De kaartachtergrond levert een native referentievlak op dezelfde plek als de bestaande benoemde SwiftUI-coördinatenruimte. Decorlagen registreren transparante native meetviews. Hun rechthoeken worden met `UIView.convert` in dat referentievlak gemeten, inclusief de kaartvergroting op iPad.

De driver observeert één native `UIScrollView.contentOffset`. Tijdens beweging worden de registraties maximaal twintig keer per seconde bemonsterd. Alleen een gewijzigde boolean of afgeronde voorbereidingsrechthoek wordt aan SwiftUI doorgegeven. De gewone scrollbeweging en de bestaande animatietimelines behouden hun eigen frequentie. De displaylink stopt na de laatste meetpassages zodra de kaart stilstaat. De driver bewaart meetviews zwak en stopt zijn observatie als de kaart verdwijnt.

Er zijn 26 aanroepplekken omgezet: wereldgrenzen voor het HUD, terreinvoorbereiding en zichtbaarheid/voorbereiding van decorlagen. Groottewaarneming voor layout en de native levelankers voor herstel en wereldsprongen blijven bestaan. Buiten een kaart met eigen driver gebruikt de helper zijn bestaande SwiftUI-variant; losse illustraties en resultaatdecor blijven daardoor zelfstandig bruikbaar.

Een zichtbaarheidsovergang kan ongeveer één meetinterval later worden doorgegeven. De bestaande voorbereidingsmarges en hysterese blijven behouden. De extra native meetviews kosten ook geheugen en laagadministratie; de koude toestelproef moet aantonen of de totale afweging positief is.

## Functionele tussencontrole

Op de aangesloten iPhone met de geoptimaliseerde testbuild slagen:

- `testHUDThemeFollowsScrollInsteadOfPlayerLevel` (35,971 s).
- `testMapLevelCircleKeepsItsFullHitArea` (13,251 s).
- `testWorldJumpStillLandsOnNextWorld` (11,482 s).

De gerichte coreproef slaagt met 97 viewportcontroles. Deze test de zichtbaarheid en voorbereidingsgrenzen; de daadwerkelijke native coördinaten en bediening worden door de toesteltests gecontroleerd.

De koude performanceproef en controle van de vergrote kaart volgen hieronder zodra die werkelijk zijn afgerond. Er wordt nog geen frameratewinst voor deze aanpak geclaimd.

## Koude toestelproef

De native waarnemer mat 63 scrollhaperingen, 419,1 ms/s hitchratio en 50,650 s CPU. De voorafgaande versie met alleen geometriecaches mat 25 haperingen, 142,5 ms/s en 39,834 s CPU. De grootste callbackpauze bleef ongeveer gelijk: 267,8 tegenover 260,5 ms. Dit zijn afzonderlijke koude vergelijkingsruns met dezelfde route; één gemeten iteratie per variant.

De extra native meetviews en hun laag-/layoutadministratie leveren in deze uitvoering dus geen aangetoonde winst op. De volledige nieuwe driver en alle 26 helpervervangingen zijn teruggedraaid. De geslaagde functionele tests zijn geen reden om een tragere uitvoering te behouden. Log: `.build/iphone-native-viewport-cold.log`.
