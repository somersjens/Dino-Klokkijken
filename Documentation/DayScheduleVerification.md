# Vraagtype 20 — twee activiteiten met pauze

In Oefenen staat vraagtype 20 als **Twee activiteiten met pauze**. Iedere vraag bevat een begintijd, twee verschillende activiteiten en precies één pauze ertussen. De leerling kiest uit vier eindtijden. De planning blijft binnen dezelfde dag, tussen 08:00 en 20:00.

De kaart gebruikt de afgeronde vormen, rustige kleuren en pictogrammen van de app. De drie blokken op de tijdlijn zijn evenredig aan hun duur. De activiteiten en pauze hebben ieder een eigen regel met de duur in minuten. De eindtijd blijft een vraagteken tijdens de vraag en bij een herkansing; na het tonen van het antwoord wordt deze ingevuld.

Het voorbeeld toont dezelfde kaart, één uitgewerkt antwoord en de volledige optelsom. Een ander voorbeeld vervangt alleen het voorbeeld. De nieuwe oefening werkt met alle minutenfamilies, de oplopende volgorde, de mixmodus en de bestaande opslag van oefenrecords. De bestaande vraagtypenummers blijven gelijk.

## Controles

- De kernsuite slaagt met **661.540 controles**. De aanvullende planningscontroles doorlopen 200 vragen per minutenfamilie en controleren de twee verschillende activiteiten, positieve duren, tijdstappen, dezelfde dag, vier unieke antwoorden en veelgemaakte rekenfouten.
- `testDayScheduleHasTwoActivitiesAndBreak` slaagt op iPhone 18 Pro en iPad Air 13-inch (M4), beide met iOS 27. De test controleert beide activiteiten, pauze, begintijd, antwoordkeuzes, voorbeeld, verversen, behoud van de echte vraag, herkansing en antwoordweergave.
- De vraag en het voorbeeld zijn op beide apparaten visueel gecontroleerd; de kaart en antwoordkeuzes passen volledig op het scherm.
- Alle elf nieuwe teksten zijn in het Nederlands en Engels beschikbaar. `git diff --check` slaagt.

Lokale screenshots staan in `Documentation/Screenshots/iphone/day-schedule-*.png` en `Documentation/Screenshots/ipad/day-schedule-*.png` en worden door de bestaande Git-instellingen uitgesloten.
