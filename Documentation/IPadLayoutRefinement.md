# iPad-indeling en kaartfocus — 28 oktober 2026

De oude indeling gebruikte vooral schermbreedte om klokken groter te maken. In landschap bleven de bovenbalk, verbindingskaarten, woordvragen en instelklokken samen te hoog. Het leveloverzicht tekende ondertussen een steeds breder landschap rond vrijwel even grote levelstenen.

## Aanpassingen

- De vraagkolom blijft begrensd op 680 punten in portret en maximaal 900 in breed landschap. Tijdzones mogen in portret 760 punten gebruiken; tijdzinnen blijven in beide richtingen maximaal 760 punten breed. Klokgroottes en verbindingsrijen houden rekening met de beschikbare hoogte; bossvragen reserveren ook ruimte voor hun kristallen.
- Tijdens spelen schaalt de bovenbalk tot maximaal 1,20 keer zijn telefoonontwerp. Op iPad vormen bovenbalk, oefening en actieknop één samen gecentreerde groep. Het scrollgebied gebruikt de gemeten inhoudshoogte, tot de beschikbare schermhoogte. De groene knop staat vlak onder de oefening, buiten het afgeknipte scrollgebied. De iPhone houdt zijn vaste onderknop en volledige vraagviewport.
- In breed landschap staan vier antwoordklokken, digitale tijden, leesantwoorden, dagdelen en sorteerklokken op één rij. Verbindingskolommen blijven even breed en passen hun klokgrootte aan de beschikbare hoogte aan; de digitale kaarten gebruiken hun eigen compacte hoogte.
- Vervolg op de gebruikersfeedback: rekenvragen, tijdreeksen, minutenverschillen, treinreizen, tijdzones en vliegtickets staan in één gecentreerde kolom, met in breed landschap de vier antwoorden eronder op één rij. Alleen de vraagillustratie schaalt zo nodig kleiner. Tijdzinnen staan eveneens boven de woordstenen.
- Bij alle drie instelvragen staat op ruime schermen de referentie links en de invoerklok rechts, met de bediening onder die rechterklok. Na een fout verschijnt de juiste vergelijking op de linkerplek. De telefoonindeling blijft verticaal. De grens volgt de beschikbare inhoudsbreedte van 600 punten, zodat smalle iPad-vensters ook de telefoonindeling behouden.
- De analoge antwoordklokken staan verticaal midden in hun witte kaart. Alleen een fout gekozen klok schuift omhoog om zijn digitale uitleg te tonen; de andere kaarten blijven op hun plaats. Verborgen tijdzone- en dagdeeluitleg neemt vooraf geen lege ruimte meer in.
- Het scrollgebied is expliciet afgeknipt boven de actiezone. Ook antwoordranden en feedback kunnen daardoor niet achter **Controleer**, **Toon antwoord** of **Verder** tekenen. De actiezone behoudt zijn gereserveerde hoogte bij feedback. Op iPad staat de knop los op de achtergrond; de brede materiaalstrook is daar vervallen. Kleinere vensters kunnen blijven scrollen.
- Op iPad vergroot het leveloverzicht de complete scène met 1,20 tot 1,55 keer. Dino, stenen, pad en decor houden dezelfde verhoudingen. Het landschap wordt op een smallere logische breedte getekend; er zijn geen extra decorstukken toegevoegd om ruimte te vullen. Ook het eerste level opent op iPad met Dino in focus.
- Scrollankers, openingssprongen en wereldsprongen gebruiken de vergrote scène. Zichtbaarheidsberekeningen van dieren, bruggen, metro en meeuwen rekenen schermcoördinaten terug naar de lokale schaal, zodat kaartanimaties tijdens scrollen correct blijven verschijnen.

## Verificatie

De nieuwe UI-matrix opent geïsoleerde testprofielen met losse minuten, seed 42 en de hoogste moeilijkheidsstap. Zo worden vier antwoordstenen en langere vragen gecontroleerd. De fixture is uitsluitend beschikbaar in DEBUG met `DINO_TEST_SUITE`; gewone spelersprofielen worden niet gebruikt.

| Controle | Simulator | Resultaat |
| --- | --- | --- |
| Alle 20 vraagtypen in de nieuwe éénkolomsindeling, titel en antwoorden binnen de vraagviewport, portret en landschap | iPad mini, iPadOS 27 | Geslaagd |
| Acht gewijzigde varianten: antwoordklokken, alle drie instelvragen, rekenen, treinreis, tijdzones en vliegticket | iPad Pro 13-inch, iPadOS 27 | Geslaagd |
| Definitieve analoge indeling en bediening, beide oriëntaties | iPad Pro, A16 en mini | Geslaagd |
| Foutfeedback en groene onderknop bij 8 vraagtypen, inclusief alle drie instelvragen en hun linker vergelijking | iPad mini, nieuwe build, portret en landschap | Geslaagd |
| Ingezoomde kaart bij een later level en beide draairichtingen | iPad Pro, A16 en mini | Geslaagd |
| Eerste kaartopening, aanwijzer en opnieuw openen | iPad mini | Geslaagd |
| Wereldsprongen na werelden 1, 4 en 9, en terugkeer na wereld 10 | iPad A16 | Geslaagd |
| Bestaande HUD- en rotatietest | iPad A16 en iPhone 18 Pro | Geslaagd |
| Bestaande koppel- en sorteertest uit de basisronde | iPhone 18 Pro | Geslaagd |
| Bestaande verticale klokbediening en foutvergelijking; digitale vergelijking in 12- en 24-uursnotatie | iPhone 18 Pro, nieuwe build | Geslaagd |
| Release-build voor iOS Simulator | Xcode | Geslaagd |
| Kernsuite, inclusief 6 nieuwe controles voor ingezoomde animatiegebieden | `Tools/test-dino.sh` | 1.159.241 controles geslaagd |

Enkele eerdere iPadOS 27-rondes bleven na hun testuitslag hangen bij het finaliseren van het Xcode-rapport. De geslaagde eindrondes sluiten normaal af. De gemeten schermen zijn ook visueel gecontroleerd.

## Beelden

- [Nieuw overzicht van alle twintig vraagtypen op iPad mini](Screenshots/IPadSingleColumn/all-question-types-mini.png)
- [Eén kolom met antwoorden eronder](Screenshots/IPadSingleColumn/one-column-flight-landscape-ipad.png) en [tijdzones](Screenshots/IPadSingleColumn/one-column-timezone-ipad.png)
- [Gecentreerde antwoordklokken](Screenshots/IPadSingleColumn/centered-answer-clocks-ipad.png)
- [Analoog instellen](Screenshots/IPadSingleColumn/analog-setting-ipad.png), [digitaal instellen](Screenshots/IPadSingleColumn/digital-setting-ipad.png) en [wijzers vooruitzetten](Screenshots/IPadSingleColumn/advance-setting-ipad.png)
- [Kaart in portret](Screenshots/IPadRefinement/map-portrait-ipad.png) en [landschap](Screenshots/IPadRefinement/map-landscape-ipad.png)

- [Antwoordklokken na een foute keuze](Screenshots/IPadSingleColumn/answer-clocks-after-wrong-ipad.png) en [de juiste vergelijking links](Screenshots/IPadSingleColumn/analog-comparison-left-ipad.png)

## Compacte witvlakken en horizontale tijdreeks

Vraagtype 6 gebruikt op ruime tablets vaste woordstenen van 48 punten met grotere letters, een klokletter van 46 punten en een begrensde bordbreedte. Bij weinig verticale ruimte, zoals de mini in landschap, worden de stenen 40 punten hoog en de tussenruimtes compacter.

Bij type 11 blijven in portret de analoge klokken links en de digitale tijden rechts, op dezelfde middenpunten. De klokvlakken kunnen daar tot 164 punten groeien. In breed landschap staan de drie klokken op één rij met de digitale tijden eronder. Daarmee kunnen de klokvlakken tot 184 punten groeien en blijven ze ook op de mini veel beter leesbaar. Digitale kaarten blijven maximaal 88 punten hoog. De verbindingspunten zitten aan de naar elkaar gerichte kaartranden; getekende lijnen en sleepdoelen gebruiken dezelfde kaartgeometrie, ook na roteren.

Type 17 gebruikt op brede iPads in landschap een horizontale rij tijden met pijlen naar rechts. De klokletters groeien mee tot 48 punten, de antwoordtekst tot 24 punten en de antwoordstenen hebben een minimale hoogte van 88 punten. Bij foutuitleg lopen de tijdverschilbogen boven de klokken; de tekst blijft rechtop en de pijlpunt komt bij de volgende klok uit. Terugdraaien naar portret herstelt de verticale reeks met de bogen rechts.

De gerichte schermmatrix voor typen 6, 11 en 17 slaagt op iPad mini en iPad Pro in portret en landschap, en op iPhone in portret. De tijdreekscontrole slaagt op beide iPads, inclusief draaien naar beide landschapsrichtingen en terug naar portret met zichtbare foutuitleg. De definitieve debug-build compileert.

Een aanvullende bestaande sleeptest voor type 11 blijft open: de drie verbindingen, hun eindpunten en de opgeslagen goede score kloppen, maar na bevestigen verdwijnt het oefenspel en wordt vraag 2 niet zichtbaar. De oorzaak is nog niet vastgesteld; deze controle wordt niet als geslaagd gerekend. Tijdelijke pogingen aan de presentatie van het oefenscherm zijn teruggedraaid.

- [Compacte tijdzin in landschap](Screenshots/IPadCompactSequence/compact-word-tiles-landscape.png) en [portret](Screenshots/IPadCompactSequence/compact-word-tiles-portrait.png)
- [Compacte verbindingskaarten in landschap](Screenshots/IPadCompactSequence/compact-matching-landscape.png) en [portret](Screenshots/IPadCompactSequence/compact-matching-portrait.png)
- [Horizontale tijdreeks](Screenshots/IPadCompactSequence/sequence-horizontal-before-answer.png), [met verschilpijlen](Screenshots/IPadCompactSequence/sequence-horizontal-difference-arrows.png) en [verticale foutuitleg in portret](Screenshots/IPadCompactSequence/sequence-portrait-difference-arrows.png)

## Nieuwe samenhang en schaal

De eerste compacte versie liet de bovenbalk bovenaan staan, centreerde de kleine oefening in een hoge viewport en zette de knop onderaan. Daardoor ontstonden grote gaten tussen de drie onderdelen. De nieuwe iPad-compositie centreert die onderdelen samen en laat de leestekst en leerklokken zwaarder wegen dan de bovenbalk. De witruimte zit rondom de oefening in plaats van tussen de vraag en de knop.

De schermcontroles bewaken nu ook dat er geen groot leeg vlak boven de titel binnen het scrollgebied ontstaat, dat de actieknop dichtbij de oefening blijft en dat de grotere stenen vaste hoogtegrenzen houden.

De nieuwe compositie is gecontroleerd met alle twintig vraagtypen op mini, in beide richtingen; typen 6, 11 en 17 op Pro; beide landschapsrichtingen en portret met tijdreeksuitleg; de drie voorbeeldtypen in iPhone-portret; en acht soorten foutuitleg op iPad A16. Deze controles slagen. De verandering van de verbindingsgeometrie wordt daarnaast afzonderlijk gecontroleerd met slepen naar kaartranden, tikken en draaiende bestaande verbindingen.

De nieuwe sleepcontrole slaagt op mini en Pro. Hij verbindt vanaf beide kanten, landt dichtbij de kaartranden, vult de derde verbinding met tikken en draait vervolgens naar portret en beide landschapsrichtingen. Alle drie de verbindingen blijven behouden en hun lijnen blijven tussen de juiste aansluitpunten liggen. De maatcontrole op Pro telt de buiten de kaart getekende aansluitpunten mee.

- [Nieuwe tijdzin op Pro](Screenshots/IPadLessonComposition/ipad-fit-sayTime-landscape.png)
- [Nieuwe tijdreeks met uitleg](Screenshots/IPadLessonComposition/sequence-horizontal-difference-arrows.png)
- [Verbindingen over de breedte op Pro](Screenshots/IPadLessonComposition/matching-landscape-connected-pro.png) en [mini](Screenshots/IPadLessonComposition/mini/matching-connected-4.png)
- [Tijdzin op mini](Screenshots/IPadLessonComposition/mini/ipad-fit-sayTime-landscape.png)
- [Alle twintig typen op mini](Screenshots/IPadLessonComposition/mini/)
