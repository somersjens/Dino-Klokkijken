# Levelnavigatie en aanwijsvinger — 16 oktober 2026

De kolom **Level** in de kaart-HUD is een knop. Een tik schuift de volgende speelbare steen naar het midden van de ruimte onder de HUD. De huidige positie van Dino blijft gekoppeld aan het laatst behaalde level. De volgende stap volgt de bestaande ontgrendelregels, inclusief de route via perfecte eindbazen en de overgang naar een volgende wereld.

Een crèmekleurige aanwijsvinger met een donkere rand beweegt rustig naar de steen toe. Een gouden ring accentueert het level. Na vijf seconden verdwijnen beide. Opnieuw tikken begint de aanwijzing opnieuw; een level openen annuleert de lopende aanwijzing. Bij een voltooid avontuur schuift de kaart naar level 100 en valt er vijf seconden confetti. Er wordt geen level 101 aangewezen.

Bij de eerste installatie verschijnt de aanwijzing automatisch bij level 1. Deze eerste aanwijzing heeft geen tijdslimiet. Het openen van een speelbaar level of de eindbaassnelkoppeling bewaart lokaal dat de speler een level heeft geselecteerd. Het level hoeft niet gestart, afgerond of gehaald te worden. Sluiten en herstarten tonen de eerste aanwijzing daarna niet opnieuw. Een gewone voortgangsreset bewaart deze keuze; alle appgegevens wissen herstelt de beginsituatie. Bestaande opgeslagen pogingen, ook mislukte, worden bij het laden herkend.

De vinger blijft aan de levelsteen gekoppeld tijdens scrollen en draaien. Decoratieve onderdelen laten aanrakingen door. Verminder beweging geeft een stilstaande aanwijzing en confetti zonder vallende beweging; de kaart springt dan rechtstreeks naar het doel. Animatietijdlijnen pauzeren wanneer de app niet actief is.

## Controles

`Tools/test-dino.sh`: **557.940 controles geslaagd**, inclusief de volgende stap voor alle honderd levels, mislukte pogingen, perfecte eindbaasroutes, voltooide avonturen, bewaren vóór en na de eerste selectie, migratie en beide resetvormen.

De gerichte UI-tests controleren de eerste aanwijzing en herstart, openen en sluiten zonder spelen, terugscrollen via Level, automatisch verdwijnen en opnieuw tonen, de overgang van level 90 naar 91 en herhaalbare confetti na de laatste wereld.

Alle vier scenario's slagen op **iPhone 18 Pro / iOS 27** en **iPad Pro 11-inch (M5) / iPadOS 26.5**. De iPad-test voor de eerste aanwijzing is apart herhaald nadat de test-runner tijdens een rotatiecontrole wegviel; die herhaling slaagt. De bewaarde beelden tonen de portretweergave. De Debug-build en `git diff --check` slagen.

- [Eerste aanwijzing op iPhone](Screenshots/LevelGuidance/iphone/map-first-level-pointer.png)
- [Aanwijzing bij de volgende wereld op iPad](Screenshots/LevelGuidance/ipad/map-next-world-pointer.png)
- [Confetti na de laatste wereld op iPhone](Screenshots/LevelGuidance/iphone/map-adventure-complete-confetti.png)
