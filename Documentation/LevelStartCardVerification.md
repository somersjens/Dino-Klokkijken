# Levelstartkaart — 20 oktober 2026

De levelheader is de uitklapknop voor de vraagtypen. Het pijltje wijst dichtgeklapt naar rechts en draait open naar beneden. De omlijsting groeit in 0,34 seconde mee; de inhoud blijft binnen de afgeronde kaart geknipt en krijgt geen losse fade- of schuiftransitie. Bij inklappen blijft de tekst in de weergave totdat de hoogteanimatie klaar is, zodat de regels met de omlijsting verdwijnen. Snel opnieuw openen annuleert het opruimen van die inhoud. Bij Minder beweging wordt de stand direct gewijzigd. Opnieuw openen begint dichtgeklapt.

Elke vraagregel opent het oefenmenu met het bijbehorende vraagtype en de tijdsoort voorgeselecteerd. De gegevens komen rechtstreeks uit de eigen levelreceptuur van die regel, zodat hetzelfde vraagtype met verschillende tijdsoorten correct blijft werken. Het menu brengt de geselecteerde vraag in beeld; de vaste knop **Start oefenen** begint de oefening. De keuze blijft daarna ook beschikbaar bij gewoon openen van het oefenmenu.

De startkaart volgt de wereld van het geselecteerde level, ook bij het opnieuw spelen van een eerder level. Achtergrond, headericoon, bord, vraagaccenten, eigen score en speelknop delen het wereldpalet. De woestijn heeft zandkleuren, duinen en cactussen; de jungledecoratie blijft bij wereld 1.

## Verificatie

- Debug-build en `git diff --check` geslaagd.
- **805.838 kerncontroles** geslaagd, inclusief de oefenconfiguratie van iedere vraagregel in alle honderd levels.
- `testLevelOutlineOpensExactPracticeCombination` geslaagd op iPhone 17 Pro en iPad Pro 11-inch (M5), beide iOS 26.5: level 11 opent hetzelfde vraagtype met respectievelijk halve en hele uren, en level 18 opent tijdzonevragen met hele uren. Controleert zichtbare selectie, direct starten, het vraagnummer en de tijdsoort in de gestarte oefening, terugkeren en inklappen/opnieuw openen.
- `testLevelStartHeaderExpansionAndWorldThemes` geslaagd op iPhone 17 Pro en iPad Pro 11-inch (M5), beide iOS 26.5. Controleert verborgen vraagtypen, uitklappen binnen het bord, meeschuivende bediening, inklappen, opnieuw openen en starten. Alle tien wereldkaarten zijn op iPhone bekeken; woestijn, kristalgrot en kasteel ook op iPad.
- `testLevelStartBossOutlineScrollsInEnglish` geslaagd op beide apparaten: tien vraagtypen bij level 20, scrollen naar de laatste rij en starten.
- De opname van de iPad-test is beeld voor beeld bekeken rond het uitklappen: tekst blijft binnen de groeiende omlijsting.
- Ook het inklappen is beeld voor beeld bekeken: tekst wordt met de afnemende hoogte afgeknipt en verdwijnt pas na de animatie uit de weergave.

[Woestijnkaart dicht en open](Screenshots/LevelStart/desert-startkaart.png) · [Uitgeklapt op iPhone](Screenshots/LevelStart/desert-expanded-iphone.png)

[Inklapbeweging](Screenshots/LevelStart/collapse-motion.png) · [Tijdzonevraag voorgeselecteerd op iPhone](Screenshots/LevelStart/level-practice-preselected-timeZone-whole-iphone.png) · [Op iPad](Screenshots/LevelStart/level-practice-preselected-timeZone-whole-ipad.png)
