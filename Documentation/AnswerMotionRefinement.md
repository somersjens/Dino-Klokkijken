# Antwoordbeweging en digitale vergelijking

Vraagtype 7 verbergt de instelchevrons zodra de antwoordweergave verschijnt. De overlay behoudt zijn ruimte en verwijdert de verborgen knoppen ook uit de toegankelijkheidsboom. Op iPad vervagen de instelknoppen onder de klokken binnen hun bestaande ruimte.

De digitale hulppijlen staan acht punten hoger en houden afstand van de oranje en groene antwoordrand. De telefoonbediening reserveert die ruimte vooraf: de hulppijlen gebruiken de plaats van de bovenste chevrons. De ingevoerde en juiste klok delen dezelfde boven- en onderruimte, zodat hun displays op dezelfde hoogte staan. Ook de digitale doelklok bij analoog instellen reserveert de hulpruimte vooraf.

Antwoordkeuzes starten hun feedback in één expliciete animatietransactie van 0,3 seconde. Daardoor bewegen de gekozen knop, de overige antwoorden en de omringende indeling samen. De gedeelde knopstijl gebruikt alleen een lichte transparantieverandering bij indrukken; een tweede schaaltransformatie beïnvloedt de antwoordanimatie niet meer. Bij Minder beweging vervalt de animatie.

`testWrongAnswerLayoutAcrossQuestionTypes` doorloopt een fout antwoord en het tonen van de oplossing bij alle twintig oefenvraagtypen. Hij bewaakt de bereikbaarheid van Verder, antwoordgrenzen, verdwenen digitale chevrons en stabiele eindposities. Bestaande controles voor klokposities meten de onderrand van een digitale klok: hulppijlen vergroten de toegankelijkheidsgrenzen naar boven, zonder het display te verplaatsen.

De type-2-overgang is in een simulatoropname op intervallen van 25 milliseconden gemeten. De bovenranden van het gekozen en het naastliggende digitale display volgen hetzelfde neerwaartse pad; het onderlinge verschil is maximaal één pixel in de halve-resolutie-opname. De eerdere sprong omhoog en afwijkende beweging van het gekozen antwoord zijn verdwenen.
