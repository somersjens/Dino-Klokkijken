# Adaptieve spelindeling

De game gebruikt de safe-area-geometrie van zijn venster. HUD en antwoordactie krijgen eigen ruimte; de resterende GeometryReader levert het werkelijke speelgebied. De vraagtitel gebruikt 23 punten, of 21 in korte vensters, en vormt samen met de vraag en antwoorden één verticaal gecentreerde les.

`DinoGameLayout` beschrijft de indeling op basis van beschikbare breedte, hoogte, vraagsoort en aantal antwoorden. Er zijn geen toestelmodellen of idiom-controles in deze beslissingen. Korte, brede vensters zetten de HUD verticaal links van de volledige les. De presentatie ondersteunt portrait en beide landscape-standen op iPhone en iPad.

`DinoQuestionComposition` houdt dezelfde context- en antwoordviews aan bij herindeling via `AnyLayout`. Context en antwoorden staan altijd onder elkaar. De context krijgt maximaal de hoogte die na het meten van de antwoordstenen overblijft. Een eigen SwiftUI `Layout` meet de natuurlijke inhoudshoogte in dezelfde layoutpass: kleine inhoud reserveert geen onzichtbare extra hoogte. Daardoor blijft vrije ruimte rondom de complete les, in plaats van tussen klok en antwoordstenen. In landscape schaalt zo nodig ook de volledige les evenredig naar de beschikbare hoogte. Extra uitleg wordt opnieuw gemeten. Een scrollgebied blijft beschikbaar. Zie [het landscape-redesign van 4 november](LandscapeRedesign.md) voor de nieuwe kaart-, HUD- en menuverhoudingen.

Vier antwoordstenen gebruiken twee rijen of één rij wanneer de cellen breed genoeg zijn. Een tijdreeks verandert van verticale naar horizontale volgorde op basis van zijn beschikbare verhouding. Bij instelvragen staat de referentie boven de gecentreerde invoer. Een fout antwoord blijft als vergelijking naast de juiste klok zichtbaar. In korte vensters kunnen de analoge handselectie en draaiknoppen één horizontaal paneel vormen.

## Verificatie

- `Tools/test-dino.sh --game-layout`: 60.761 controles, met een doorlopende reeks vensterbreedtes en -hoogtes.
- Gerichte bestaande kerncontroles voor tijdlezen en klokhelpers: 17.504 respectievelijk 110.208 controles.
- `testAllQuestionTypesFitTabletViewport` is uitgebreid naar alle devices, inclusief landscape, foutfeedback en terugrotatie. De naam is behouden zodat bestaande testselecties blijven werken. `DINO_LAYOUT_TYPES` kan de matrix beperken tot specifieke vraagtypen.
- Voor de verfijning van 3 november is de gerichte kerncontrole voor de layout uitgevoerd; de volledige kernsuite is niet opnieuw gedraaid.

De gedeelde context gebruikt vanaf iOS 17 een geometrisch visueel effect, zonder de gemeten natuurlijke hoogte terug te schrijven naar de layout. Dat voorkomt een vastlopende rotatie tijdens zichtbare Goed/Fout-feedback. iOS 16 behoudt de bestaande gemeten fallback. Voorbeelden houden hun natuurlijke inhoudshoogte en vaste actieknoppen.

De simulatorverificatie omvat brede matrices en gerichte hercontroles na correcties:

- Alle twintig oefenvraagtypen op iPhone, telkens portrait, landscape, landscape met foutfeedback en terug naar portrait met foutfeedback.
- Alle twintig oefenvraagtypen op iPad, met aparte hercontroles van leesklok, klokbediening, dagdelen, sorteren, tijdreeks, vooruitzetten en Goed/Fout.
- Negen ruimtegevoelige vraagtypen op iPhone SE, inclusief Goed/Fout en hercontrole van de uiteindelijke klokvergelijking en verbindingslayout.
- Goed/Fout-feedback met terugrotatie op iOS 26.5 en iOS 27.
- De bestaande sleepverbindingstest na rotatie en de vier compacte voorbeeldschermen slagen.

De laatste simulatorbuild en de gerichte kerncontroles slagen. De lokale simulatorinventaris bevat geen iPhone Duo; de doorlopende geometriecontrole bestrijkt ook tussenliggende vensterformaten, maar vervangt geen fysieke Duo-controle.

## Normalisatie van type 2, 3 en 4 — 3 november 2026

Leesklokken hebben een voorkeursmaat van 210 punten, vergelijkbaar met de oorspronkelijke telefoonverhoudingen. Breder beschikbare vraagruimte laat deze maat geleidelijk maximaal 20% groeien; hoogte en breedte mogen de klok nog steeds verkleinen wanneer nodig. Uitleg krijgt een eigen passend kader rond deze wijzerplaat, zodat extra labels ruimte mogen gebruiken zonder de gewone klok op te blazen.

De titel wordt onafhankelijk van de vraaginhoud gemeten. Die hoogte wordt eerst van het speelbudget afgetrokken, waarna titel, vraag en antwoorden als één natuurlijk hoog blok worden gecentreerd. De bestaande onderste verankering voor brede interactieve klokvragen en de vaste actieknoppen blijven behouden. Voorbeelden behouden hun natuurlijke hoogte.

De gerichte regressietests controleren ook de bovengrens van de leesklok, de centrering van het complete blok en de afstand tussen klok en antwoorden, vóór en na foutfeedback en bij rotatie.

De build, 60.761 maatcontroles en de gerichte UI-matrices slagen: typen 2 en 3 op een schone iPhone 17 Pro-simulator (portrait/landscape, vóór/na foutfeedback) en zes vraagtypen op iPad (inclusief rekenen, tijdreeks en analoge bediening). Op de bestaande telefoonsimulators reageerde rotatie niet betrouwbaar; daarom is de iPhone-rotatie op een geïsoleerde simulator gecontroleerd.

## Foutfeedback zonder overlappende klokbeelden

De wijzerplaat en wijzers van `AnalogClock` worden nu in een vast tekenstelsel van 240 punten opgebouwd, zoals de bestaande soepele type-1-klokken. Grootteveranderingen schalen die bestaande tekening. De cijfertypografie blijft tijdens de beweging constant, zodat SwiftUI geen oude en nieuwe lettergroottes over elkaar hoeft te mengen. De aanraakcoördinaten blijven gekoppeld aan de werkelijke zichtbare wijzerplaat.

Type 3 gebruikt ook vóór en na een fout dezelfde klokview. Alleen het passende kader en de leeshelpers veranderen. `DinoQuestionFeedbackTiming` legt een gedeelde volgorde vast: bestaande inhoud beweegt gedurende 0,30 seconde; nieuwe uitleg verschijnt vanaf 0,32 seconde in 0,18 seconde. Dat geldt ook voor de uitleg onder antwoordstenen en de spreekhelpers bij type 5. De bestaande type-1-overgang blijft behouden.

Waar een referentie echt verandert van kloksoort of tijd (instellen en vooruitzetten), gebruikt `DinoFeedbackReplacement` dezelfde volgorde. De oude referentie verdwijnt eerst in 0,10 seconde; de correctie verschijnt pas na de beweging. Bij Verminder beweging worden de nieuwe toestand en helpers direct getoond.

De gerichte iPhone-test laat het eerste foute antwoord bij typen 1 t/m 5 staan, controleert de leesklok en gecentreerde groep, en bewaakt dat één vraagklok in de toegankelijkheidsboom overblijft. De tussenframes van typen 2, 3 en 4 zijn daarnaast uit een simulatoropname bekeken:

- [Type 2: stabiele wijzerplaat, daarna leeshelpers](Screenshots/FeedbackMotion/type-2-frames.png)
- [Type 3: één klok tijdens de correctie](Screenshots/FeedbackMotion/type-3-frames.png)
- [Type 4: genormaliseerde maat en spreekuitleg](Screenshots/FeedbackMotion/type-4-frames.png)

Verificatie van deze aanpassing: simulatorbuild geslaagd; 60.761 layout- en timingcontroles, 110.208 controles voor klokhelpers en 17.504 tijdleescontroles geslaagd. De gerichte iPhone-test voor de eerste fout bij typen 1–5 slaagt. De iPad-matrix voor tien vraagtypen (lezen, instellen, vooruitzetten, 24 uur, minutenverschil en tijdreeks) slaagt in portrait en landscape, inclusief foutfeedback en terugrotatie.

## Strakkere uitleg en vloeiendere digitale invoer — 3 november 2026

Bij typen 3 en 4 reserveert de spreekschaal nu zijn werkelijke verticale omvang, berekend door `SpokenClockGuideLayout.verticalBounds`. Ook het verborgen Canvas gebruikt die rechthoek; de oude vierkante tekenbuffer vergrootte de toegankelijkheidsgrenzen en leidde tot een onnodig vierkant om de volledige klok. Type 4 houdt dezelfde kleine binnenmarge voor en na feedback. De wijzerplaat behoudt de bestaande genormaliseerde maat; extra labels bepalen alleen de benodigde buitenruimte.

Type 7 animeert ook het kleiner worden van de analoge referentie wanneer de nummerhelpers verschijnen. De instelpijlen blijven tijdens hun korte fade dezelfde views; ze verdwijnen in 0,10 seconde voordat de ingevoerde digitale tijd in 0,30 seconde opzij schuift. Nieuwe digitale helpers, antwoordranden en de vergelijking verschijnen vanaf 0,42 seconde. `DinoFeedbackReveal` verzorgt de uitgestelde introductie zonder dubbele klokbeelden. Verminder beweging toont de eindtoestand direct.

Verificatie: de simulatorbuild, 60.762 layout- en timingcontroles en 110.208 klokhelpercontroles slagen. De gerichte iPhone-tests controleren de eerste fout bij type 7 en de compacte hulpkaders van typen 3 en 4 voor hele uren en exacte minuten. De iPad-matrix voor typen 2, 3, 4, 5 en 7 slaagt met portrait, landscape, foutfeedback en terugrotatie; type 7 is na de laatste animatieaanpassing opnieuw gecontroleerd. De tussenframes van type 7 zijn uit een simulatoropname bekeken.

- [Type 3: passend kader rond de spreeklabels](Screenshots/FeedbackMotion/type-3-tight-guide.png)
- [Type 4: passende hoogte tussen titel en antwoordstenen](Screenshots/FeedbackMotion/type-4-tight-guide.png)
- [Type 7: vloeiende schaal en vergelijking](Screenshots/FeedbackMotion/type-7-frames.png)

## Ongeldige tijdelijke leesklokmaten

De waarschuwing `Invalid frame dimension (negative or non-finite)` in `DinoTimeReadingClock` had nog een geldig foutpad: een tijdelijke breedte onder 52 punten werd na aftrek van de marge een negatieve diameter en soms een negatieve framehoogte. `DinoTimeReadingClockLayout` berekent nu de maten voor zowel vraagklok als voorbeeld, inclusief veilige positieve marges bij nulbreedte en niet-eindige invoer. Ook labelposities en labelkaders gebruiken diezelfde geldige breedte. Geldige schermmaten behouden de bestaande verhoudingen en de strakke hoogte voor spreekhulp.

De gerichte layoutcontrole slaagt met 66.523 controles, inclusief tijdelijke breedtes rondom 0, 16 en 52 punten, ongeldige invoermaten, alle klokvormen en beide talen. De simulatorbuild slaagt.

De bestaande iPhone-UI-test voor het tijdlezen slaagt voor hele uren en exacte minuten, inclusief foutfeedback en voorbeeldschermen. Tijdens deze run zijn geen nieuwe `Invalid frame dimension`-meldingen in de simulatorlog waargenomen.
