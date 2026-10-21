# Navigeren via de levelknop

20 oktober 2026.

De levelknop animeerde iedere afstand in 0,55 seconde. Bij een verre bestemming passeerde de kaart meerdere werelden en activeerde onderweg hun landschaplagen en voorbereiding. De aanwijzer verscheen na een vaste wachttijd, onafhankelijk van de werkelijke aankomst.

De bestaande native viewportmeting verzorgt nu ook het navigeren:

- Tot één schermhoogte blijft de kaart met een native scrollanimatie naar het level bewegen.
- Grotere afstanden worden direct overbrugd onder een momentopname van het huidige kaartbeeld. De tussenliggende werelden worden daardoor niet doorgescrolld.
- Zodra de positie stabiel is en het landschap van de bestemming klaarstaat, verdwijnt de momentopname in 0,22 seconde. De HUD blijft bedienbaar. Een landschap dat uit de kaartboom is verwijderd, geldt pas weer als klaar na zijn nieuwe voorbereidingsmelding.
- De levelaanwijzer of voltooiingsconfetti verschijnt na aankomst en blijft vijf seconden staan. Een nieuwe tik vervangt het vorige verzoek. Een handmatige veeg kan een korte scroll onderbreken.
- Bij Minder beweging gebeurt de verplaatsing zonder scrollanimatie of overvloeien. De viewportmeting stopt na aankomst en bij het verlaten van de kaart.

## Verificatie

Zowel de eerste als de uiteindelijke Debug-testbuild uit de werkmap slagen, evenals de bestaande **805.848 kerncontroles**. Tijdens de verificatie veranderde de vraaglogica gelijktijdig. Voor de nieuwe schermtest is daarom ook een vaste tijdelijke projectkopie gebruikt met de oorspronkelijke kernlogica uit `2dddf22`; de gewijzigde `WorldMap.swift` is bytegelijk aan die in de werkmap. De wijzigingen aan de vraaglogica in de werkmap zijn ongemoeid gelaten. De uiteindelijke testbuild uit de werkmap slaagt ook samen met de bijgewerkte vraaglogica; de uitvoer staat in `/tmp/dino-level-navigation-final-build.log`.

Geslaagde schermcontroles op iOS 27:

| Apparaat | Controles |
| --- | --- |
| iPhone 18 Pro | Koude herstart bij level 1, 4 en 91; tijdelijke aanwijzer en opnieuw aantikken; aanwijzer bij wereld 10; voltooiingsconfetti; verre verplaatsingen naar level 35 vanuit eerdere en latere werelden; dubbel tikken; stabiele aankomst en level openen. |
| iPad (A16) | Eerste levelaanwijzer en de korte verplaatsing na rotatie; aanwijzer bij wereld 10; verre verplaatsingen in beide richtingen; dubbel tikken; stabiele aankomst, landschapstand, terugdraaien en level openen. |

Dit zijn acht geslaagde schermtestgevallen. Een eerste iPad-run liep vast op een dubbel toegankelijkheidselement voor het wereldbord; de test gebruikt nu expliciet de eerste overeenkomst. De herhaling slaagt.

De nieuwe regressietest heet `testLevelHeaderReturnsAcrossSeveralWorlds`. De opname en afzonderlijke tussenbeelden van de iPhone-controle staan lokaal onder `/tmp/dino-level-navigation-*`. Ze tonen een stilstaand vertrekbeeld en een korte overgang naar het gereedstaande level, zonder de tussenliggende werelden of een tweede verschuiving na aankomst. Deze controle is geen FPS-meting op een fysiek toestel.

De gerichte testuitvoer staat lokaal in `/tmp/dino-level-navigation-iphone-existing.log`, `/tmp/dino-level-navigation-iphone-long.log`, `/tmp/dino-level-navigation-ipad.log` en `/tmp/dino-level-navigation-ipad-first-level.log`.
