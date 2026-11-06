# Gedeelde levelstenen en gespreide rasterisatie

**Teruggedraaid na iPhone-feedback.** De gedeelde steenafbeeldingen en centrale rasterplanner zijn verwijderd. De onderstaande simulatorcijfers beschrijven een eerdere proef en onderbouwen geen verbetering bij kleine bewegingen op de iPhone. Zie [het vervolgonderzoek op iPhone](IPhoneSmallScrollCorrection.md).

1 november 2026. Vervolg na de adaptieve decorfrequentie.

Deze wijziging vermindert het tekenwerk van de kaart zelf. De honderd levelstenen bestonden uit afzonderlijke stapels cirkels, verlopen, paden en schaduwen. Hun decoratieve basis wordt nu één keer per uiterlijk gerenderd en tussen de bijbehorende levels gedeeld.

## Gedrag en implementatie

De sleutel bevat wereld, eindbaasstatus, ontgrendeling, bezetting door Dino, contrast, diameter en renderschaal. Het levelnummer hoort daar niet bij: cijfers, sloten, kroontjes, sterren en de echte Button blijven native en veranderen op de gebruikelijke manier mee met de voortgang. De volledige ronde knop houdt zijn raakvlak.

De afbeeldingen gebruiken de schermschaal maal de kaartvergroting op iPad. Een transparante rand van veertig punten houdt ook de buitenste randen en schaduwen binnen het beeld. Tot een afbeelding beschikbaar is, blijft de oorspronkelijke tekening zichtbaar. Er worden geen nieuwe spelassets toegevoegd.

Een gedeelde cache combineert gelijktijdige verzoeken voor dezelfde stijl. De cache heeft een kostenlimiet van 24 MiB en een limiet van 96 varianten. Views kunnen gebruikte afbeeldingen zelf vasthouden; de cachelimiet is dus geen harde limiet voor het hele appgeheugen.

Nieuwe steenafbeeldingen en landschapcaptures delen nu één rasterplanner. Na iedere synchrone capture wacht die minimaal circa 16,7 ms voordat de volgende capture begint. Het wachten geeft de hoofdthread gelegenheid om aanrakingen en scrollframes af te handelen. Ook de bestaande kasteelstroken gebruiken deze planner, zodat zij niet tegelijk met een andere wereld een reeks captures op dezelfde hoofdthread kunnen vormen.

Een afzonderlijke grote landschapcapture kan nog steeds langer dan een frame duren. De planner is bedoeld om opeenvolgende captures te spreiden; hij maakt een dure afzonderlijke tekening niet automatisch goedkoop en verplaatst ImageRenderer niet naar een ongeschikte achtergrondthread.

## Controle

De Debug-testbuild en de Release-simulatorbuild voor arm64 slagen. De volgende vier UI-tests slagen:

- De bestaande speelbare stadsroute, inclusief openen van level 51 en bereiken van de eindbaas.
- Dezelfde vaste scrollproef als de nulmeting.
- Gedeelde steenafbeeldingen voor honderd levelknoppen, behoud van de levelbediening en het openen van een levelkaart.
- Hergebruik van de voorbereide landschapafbeeldingen bij herhaald heen-en-weer scrollen.

Een aanvullende herhaling van de steentest slaagt ook met een tik op 88% van de knopbreedte, buiten het centrale cijfer. De afbeeldingen en schaduwen zijn op de simulator visueel gecontroleerd.

## Vergelijkende meting

De nulmeting en aangepaste variant zijn achtereenvolgens uitgevoerd op dezelfde iOS 27-simulator met het profiel bij wereld 6. XCTest voert na de opwarming drie gemeten herhalingen uit, ieder met twee snelle vegen door de kaart en twee terug. Er draaien tijdens de meting geen builds van deze taak.

| Gemiddelde van drie herhalingen | Voor | Na |
| --- | ---: | ---: |
| CPU-tijd van de app | 8,832 s | 4,987 s |
| Absoluut fysiek appgeheugen | 194,9 MB | 182,3 MB |
| Piek fysiek appgeheugen | 197,8 MB | 184,8 MB |
| Scroll-/uitloopinterval | 2,671 s | 2,568 s |

De gemeten CPU-tijd is in deze proef ongeveer **43,5% lager**. Het gemiddelde appgeheugen is ongeveer **6,5% lager**, het piekgeheugen **6,6%**. Dit zijn geen percentages voor de framerate. De relatieve spreiding van de CPU-metingen is vóór 2,1% en na 11,2%; de ruwe waarden staan in [SharedMapStonesMeasurements.json](SharedMapStonesMeasurements.json). Het betreft één vergelijkende sessie, geen garantie voor dezelfde winst op elk toestel.

De kortere gemeten intervalduur beschrijft de scrollbeweging en het uitrollen, geen FPS. Een eerste koude wereldcapture kan nog steeds een hapering veroorzaken. De eerdere koude metingen worden daarom niet als opgelost aangemerkt op basis van deze warme scrollproef.

De lokale logs staan in `.build/scroll-stones-baseline.log`, `.build/scroll-stones-verified.log` en `.build/scroll-stones-hit-area.log`. De eerdere beperking van decorupdates tijdens snel scrollen blijft actief; deze wijziging verlaagt de decorfrequentie niet verder.
