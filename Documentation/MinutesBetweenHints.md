# Vraagtype 16 — uitklappende tijdlijn

Het Van/Tot-gedeelte blijft staan. Bij het openen van een vraag loopt één pijl door de capsule met de onbekende totale tijd. Na het eerste foute antwoord zakt diezelfde lijn in 0,55 seconde omlaag tot een tijdlijn. Een afgeronde bovenste verbinding koppelt beide uiteinden aan het totaal. De tussenliggende punten verschijnen op de lijn, met hun tijden eronder. Onder elke tijdstap verzamelt een soepele krul het interval naar zijn minuutblok. Er komt geen tweede kaart of extra parallelle tijdlijn bij. Verminder beweging toont de uitgeklapte toestand direct.

Alle hulpblokken tonen meteen hun aantal minuten, ook tijdens een herkansing. De totale tijd blijft `? min` zolang het antwoord nog openstaat. Bij het tonen van het antwoord wordt het totaal boven de tijdlijn ingevuld. Onder de minuutblokken staat geen aparte optelregel. Een volgende vraag begint weer met alleen de pijl.

Gelijke aantallen minuten krijgen dezelfde kleur binnen de opgave. De grootste tijdstappen zijn lichtblauw, de volgende verschillende duur is groen. Zo toont `08:00 → 09:00 → 10:00 → 10:30` twee lichtblauwe blokken met `60 min` en een groen blok met `30 min`. Bij meer verschillende duren worden daarnaast zachtoranje en lila gebruikt.

De tussenstappen volgen het tijdsverschil:

- Via de hele uren die tussen beide tijden liggen, bijvoorbeeld `13:30 → 14:00 → 15:00`, met `30 min` en `60 min`.
- Drie of vier kwartieren bij een interval van 45 of 60 minuten zonder tussenliggend heel uur.
- Twee gelijke delen bij een korter even aantal minuten, bijvoorbeeld `08:10 → 08:25 → 08:40`.
- Een nabije vijfminutenstap of een afgerond midden bij een oneven aantal minuten. Eén minuut krijgt één hulpblok.

De voorbeeldkaart gebruikt dezelfde uitklapbeweging, krullen, ingevulde minuutblokken en kleuren, zonder aparte optelregel. De tijdlabels volgen de ingestelde 12-/24-uursnotatie. De eindpunten staan naar binnen zodat ieder label centraal onder zijn punt past. De segmentbreedtes volgen de tijdsduur, met voldoende breedte voor korte stappen op smalle schermen. Hoog contrast voegt donkere randen toe.

## Verificatie

De gerichte kernsuite is beschikbaar via `./Tools/test-dino.sh --minute-intervals`. Deze slaagt met **13.323 controles**, inclusief de referentie met twee stappen van 60 minuten en één van 30 minuten, gelijke kleuren voor gelijke duren en verschillende kleuren voor verschillende duren.

De gerichte schermtests controleren de eerste fout, ingevulde hulpblokken, tijden onder het totaal, ruimte voor de krullen, de volledige uitleg, voorbeeld vernieuwen en het wissen van de hulp bij de volgende vraag.

De simulatorbuild en gerichte schermtests slagen op iPhone 18 Pro en iPad mini (A17 Pro), beide met iOS 27. Gecontroleerd: volledig ingevulde hulpblokken direct na de eerste fout, het nog onbekende totaal tijdens herkansingen, bereikbare vier antwoordkeuzes, het tonen van het totaal, vernieuwen van het voorbeeld en een volgende vraag zonder tijdlijn. Nederlandse hele uren en Engelse kwartieren zijn meegenomen. De definitieve herkansingscontrole slaagt op beide apparaten na het verwijderen van de dubbele hoogtemeting rond deze kaart.

De overgang is tevens op video gecontroleerd, inclusief opeenvolgende beelden tijdens het zakken van de lijn. De kaart verplaatst vloeiend mee en springt niet meer kort omhoog en terug. De krullen, kleurverdeling en labels zijn visueel gecontroleerd. `git diff --check` slaagt.

Beelden: [hint op iPhone](Screenshots/MinutesBetweenRedesign/iphone-timeline-hint.png), [uitgewerkt antwoord op iPhone](Screenshots/MinutesBetweenRedesign/iphone-timeline-answer.png), [voorbeeld op iPhone](Screenshots/MinutesBetweenRedesign/iphone-timeline-example.png) en [hint op iPad](Screenshots/MinutesBetweenRedesign/ipad-timeline-hint.png).

## Compactere uitleg en doorlopende pijlpunt

De pijlpunt wordt als een eigen lijnpad getekend, met exact dezelfde groene kleur en lijndikte als de aanvankelijke tijdlijn. De kaart heeft kleinere marges, compactere klokken en een kortere tijdlijn met kleinere hulpblokken. Alleen bij vraagtype 16 is ook de verticale ruimte rond de vraag en tussen de kaart en de antwoorden verkleind.

De schermcontrole bewaakt nu de volledige boven- en onderkant van alle vier antwoordknoppen, zowel tijdens de hint als na het tonen van het antwoord. De controle slaagt op de kleinere iPhone 17e met iOS 27; de compactere kaart slaagt eveneens op iPad mini (A17 Pro). De geometriemetingen houden een halve punt tolerantie voor afgeronde schermcoördinaten. De beelden zijn visueel gecontroleerd en `git diff --check` slaagt.

Beelden: [compact antwoord op iPhone](Screenshots/MinutesBetweenRedesign/iphone-compact-answer.png) en [compacte hint op iPad](Screenshots/MinutesBetweenRedesign/ipad-compact-hint.png).

## Optelregel verwijderd — 2 november 2026

De afzonderlijke optelling onder de minuutblokken is verwijderd uit zowel de uitleg als het voorbeeld. De tijdlijn, krullen, kleuren, minuutblokken en totale tijd erboven blijven behouden. De bestaande schermcontrole verwacht dat de optelregel afwezig is, ook na het tonen van het antwoord.
