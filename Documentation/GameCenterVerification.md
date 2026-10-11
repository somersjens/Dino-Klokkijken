# Verificatie vriendenfunctie — 11 oktober 2026

| Controle | Resultaat |
| --- | --- |
| `Tools/test-dino.sh` | **110.542 controles geslaagd**, inclusief de oorspronkelijke gameplaytests |
| Debug iOS Simulator-build | Geslaagd voor arm64 en x86_64 |
| Release iOS-device-build | Geslaagd, zonder signing; echte provisioning nog te controleren |
| iPhone 18 Pro / iOS 27 | Twee definitieve vriendenschermtests geslaagd: profiel/kaart/levelresultaten/ontbrekende gegevens en ouderscherm/offline speelroute |
| iPhone SE (3e generatie) / iOS 26.1 | Dezelfde twee tests geslaagd; screenshotcontrole van kleine schermen |
| Bestaande directe perfecte boss | Simulator-test geslaagd: 10/10, wereldvoltooiing en behoud van opslag |
| Bestaande nul sterren / herhaling | Simulator-test geslaagd: ontgrendeling, beste sterren en herstart |
| Project, entitlements en privacy-manifest | Plist-validatie geslaagd; gelokaliseerde Game Center-toestemmingstekst aanwezig in de build |
| `git diff --check` | Geslaagd |

De twee nieuwe schermtests hadden in de eerste runs onjuiste selectors voor het type toegankelijkheidselement, de vertaling van Annuleren en de vernieuwde sterrenteller. Deze selectors zijn gecorrigeerd. De definitieve runs eindigen met `TEST SUCCEEDED` en nul fouten. Xcode bleef bij de eerste runs met een expliciet resultBundlePath hangen nadat de testcases afgerond waren; die eigen processen zijn afgesloten. De definitieve runs gebruiken seriële simulatoruitvoering en de standaardresultaatbundel.

De UI-tests gebruiken uitsluitend geïsoleerde Debug-fixtures. De onderstaande screenshots demonstreren de interface met testdata, en bevestigen geen echte Game Center-vriendschappen:

- [Kaart met drie avatars en +2](Screenshots/Social/friends-map-iphone-se.png)
- [Profiel en beste sterren](Screenshots/Social/friends-profile-iphone-se.png)
- [Sterren van vrienden op de levelstartkaart](Screenshots/Social/friends-level-results-iphone-se.png)
- [Onbekende resultaten](Screenshots/Social/friends-unavailable-results-iphone-se.png)
- [Veilige standaardinstelling](Screenshots/Social/friends-private-default-iphone-se.png)

Logs van deze sessie staan in `/tmp/dino-social-ui-final.log`, `/tmp/dino-social-ui-small.log`, `/tmp/dino-social-release.log` en de standaard Xcode-resultaatbundels onder `/tmp/dino-social-build/Logs/Test`. Tijdelijke bestanden zijn geen duurzame releaseartefacten.

Niet uitgevoerd: echte Game Center-authenticatie met gebruikersaccounts, daadwerkelijk versturen/accepteren van uitnodigingen, netwerkherstel op twee fysieke apparaten, Apple-avatarrequests, echte privacy-intrekking/kinderaccounts, handmatige VoiceOver-bediening en App Store Connect-publicatie. De releasevoorwaarden, leaderboardinstellingen, contactvelden en beperkingen staan in [GameCenter.md](GameCenter.md).
