# Vraagtype 16 – Verschil in minuten

Vraagtype 16 staat na optellen en aftrekken in Levels oefenen. Het heeft een eigen record per tijdsoort en draait mee in Oplopend en Mix.

De vraag is **Hoeveel minuten zitten ertussen?** Twee digitale klokken gebruiken de persoonlijke klokstijl. Onder Van en Tot verbindt een groene tijdlijn beide tijden; een gestippelde capsule toont `? min`. De afgeronde kaart gebruikt het groene apppalet, een lichte achtergrond en een zachte schaduw. Vier antwoordknoppen tonen uitsluitend minuten, bijvoorbeeld **120 minuten** voor twee uur. De teksten zijn beschikbaar in Nederlands en Engels.

Beide tijden volgen de gekozen minuutfamilie. De eindtijd ligt later op dezelfde dag, met maximaal 180 minuten ertussen. De kaart heeft geen onderschrift over de dag. Afleiders zijn positieve, unieke minuutwaarden in de buurt van de juiste uitkomst.

Bij een fout antwoord blijft het vraagteken staan tijdens herkansingen. Na een juiste keuze of Toon antwoord verschijnt het juiste aantal minuten in de tijdlijn. De ondoorzichtige capsule houdt de verbindingslijn achter de tekst verborgen. Op de kleine iPhone passen alle vier antwoorden tegelijk; antwoordfeedback laat de vraag op dezelfde plek staan. Het voorbeeld toont de uitkomst direct; Een ander voorbeeld laten zien maakt een nieuwe geldige opgave zonder de lopende vraag of oefenvoortgang te wijzigen.

Sinds 1 november 2026 gebruikt het voorbeeld een opgebroken tijdlijn met ingevulde minutendelen. Na één fout verschijnt dezelfde tijdlijn met ingevulde hulpblokken vanuit de bestaande pijl onder Van/Tot. Zie [de actuele uitleg en controles](MinutesBetweenHints.md). De onderstaande testresultaten beschrijven de eerdere aftrekuitleg.

## Controles

- `Tools/test-dino.sh`: geslaagd met 805.872 controles. Kerntests voor alle zes tijdsoorten, exacte minuutverschillen, uurwisselingen, vier unieke keuzes, geldige voorbeelden, Oplopend, Mix, antwoordvalidatie, aftrekken met een geleend uur en bestaande opslag- en spelregels.
- Simulatorbuild met `xcodebuild build-for-testing`: geslaagd.
- Gerichte interfacetest `testMinutesBetweenQuestionAndExample`: geslaagd op iPhone SE (3e generatie) en iPad Pro 11-inch (M5), iOS 26.5. De test kiest vraagtype 21, controleert beide tijden en vier zichtbare minuutantwoorden, vernieuwt het voorbeeld, geeft een fout antwoord, kiest Toon antwoord en gaat door naar vraag 2. De vraag blijft ook tijdens feedback onder de bovenbalk. Op iPad wordt de landschapstand eveneens vastgelegd.
- `testMinutesBetweenEnglishQuarterHours` en `testMinutesBetweenDutchQuarterHours` controleren ook de aftreksom, de resterende uren en minuten, de omzetting naar minuten en het lenen van een uur, voor en na het vernieuwen van het voorbeeld.
- Op 17 oktober 2026 zijn de bijgewerkte kerntests, simulatorbuild en drie gerichte interfacontroles geslaagd: hele uren in het Nederlands en kwartieren in het Engels op iPhone SE, plus kwartieren in het Nederlands op iPad. De voorbeelden zijn visueel gecontroleerd, inclusief de rekenstappen en de knoppen op het kleine scherm.

## Schermbeelden

- [iPhone, vraag](Screenshots/MinutesBetween/iphone-minutes-between-question-nl.png)
- [iPhone, uitgewerkt voorbeeld](Screenshots/MinutesBetween/iphone-minutes-between-example-nl.png)
- [iPad, voorbeeld met een geleend uur](Screenshots/MinutesBetween/ipad-minutes-between-borrowing-nl.png)
- [iPhone, antwoordfeedback](Screenshots/MinutesBetween/iphone-minutes-between-answer-nl.png)
- [iPad, portret](Screenshots/MinutesBetween/ipad-minutes-between-question-nl.png)
- [iPad, landschap](Screenshots/MinutesBetween/ipad-minutes-between-landscape.png)

