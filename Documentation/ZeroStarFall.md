# Diepe val en weer opstaan bij nul sterren

Bij nul sterren kiest het resultaat `DinoAnimation.Clip.stumble`, ook bij een verloren eindbaas. Dino valt vanuit het portret naar de resultaatsteen. Zijn handen raken eerst de steen; daarna geven de armen mee, zakken de snuit en kin door tot het oppervlak en komt ook het achterlijf laag. Vanuit die volledige val drukt hij zich vlot weer overeind. De kleine getekende duizelsterren horen bij de impact; het resultaat blijft nul verdiende sterren en toont geen confetti.

## Bronbeelden en aanvullingen

De acht bestanden van 26 oktober met namen `15_20_13-1` t/m `15_20_19-8` zijn hernoemd naar `dino-stumble-deep-01` t/m `08`. Hun PNG-inhoud is byte voor byte vergeleken met de door de gebruiker gestagede bronbestanden. De bestanden van de eerdere val blijven bewaard.

Twee ontbrekende overgangen zijn gemaakt met de ingebouwde **image_gen**-tool en opgeslagen in de assetcatalogus:

- `dino-stumble-deep-03a`: de palmen raken de steen terwijl de snuit er nog boven zit, vóór het doorzakken.
- `dino-stumble-deep-06a`: knieën gebogen, romp half opgericht en handen net los, tussen de lage opdrukpose en staan.

De oorspronkelijke namen, SHA-256-controles en volledige prompts staan in [DeepZeroStarFallPrompts.json](DeepZeroStarFallPrompts.json).

## Beweging en uitlijning

De tekening blijft exact `dino-idle` tot het vertrek. De bijna gelijke nieuwe rustpose `01` wordt niet vooraf in het portret verwisseld. Dat bewaart het bestaande gezicht en de gekozen kleuren tijdens de schermovergang.

| Houding | Tijd na de schermfade |
| --- | ---: |
| Exact rustbeeld; vertrek | 0,120 s |
| Evenwicht verliezen (`02`) | 0,260 s |
| Naar voren vallen (`03`) | 0,460 s |
| Eerste handcontact (`03a`) | 0,640 s |
| Armen geven mee; snuit bij de steen (`04`) | 0,720 s |
| Ook het achterlijf komt laag (`05`) | 0,800 s |
| Opdrukken (`06`) | 0,875 s |
| Handen los (`06a`) | 0,945 s |
| Vrijwel rechtop (`07`) | 1,025 s |
| Eindhouding (`08`) | 1,080 s |

De schermfade duurt 0,24 seconde. De gedeelde verplaatsing stopt bij het eerste handcontact, op 0,88 seconde vanaf het begin. Het lichaam beweegt daarna verder naar beneden op de steen. Zo is het diepste punt een echte fase na de landing en blijft het niet bij een hangende opdrukpose. Vanaf de volledig lage houding staat Dino in 0,225 seconde vrijwel rechtop; 55 ms brengt hem rustig naar de eindhouding. De hele clip duurt 1,32 seconde.

Een mesh volgt overeenkomstige punten van gezicht, nek, romp, heupen, achterpoot, staart en bandana met doorlopende kubische banen. Vijf vaste grondpunten houden de contactlijn op de steen. De verschillende uitsneden van de bronbeelden zijn vooraf in schaal geregistreerd: vooral de lage opdrukpose zou anders een veel groter hoofd hebben. De tekeningen worden tijdens de beweging scherp afgewisseld; er staat steeds één volledig dekkend beeld op het scherm. Er zijn geen lange doorschijnende overgangen met dubbele gezichten of handen.

## Kleuren en toegankelijkheid

Iedere pose heeft eigen contouren voor ogen, mond, hoofdpieken en bandana. De gele duizelsterren blijven hun geschilderde kleur houden, ook met een andere buikkleur. De bestaande kalibratie meet tint, verzadiging, schaduwen, middentonen en hooglichten van de werkelijke bitmap en stemt ze af op de gewone Dino. De twee gegenereerde beelden gebruiken dezelfde afstemming. Op lichte bandana’s blijft `12:34` donker en leesbaar.

Bij **Minder beweging** verschijnt direct de stilstaande eindpose `dino-stumble-deep-08` op de steen.

## Controle

De gerichte animatiecontroles bewaken het exacte portret vóór vertrek, het verdere zakken van snuit en heupen ná handcontact, het vlotte herstel, doorlopende banen en snelheid, alle houdingen op 30 en 60 Hz, vaste grondpunten, scherpe beeldwissels, niet-omgeklapte zichtbare meshvlakken en Minder beweging. De volledige kernsuite controleert daarnaast kleuren en transparantie op 384 en 768 pixels en leesbare opdruk op lichte bandana’s.

De native UI-controle speelt echte levels uit met de gewone groene Dino en een gepersonaliseerde roze Dino, en controleert één figuur, nul sterren, de eindpositie en opnieuw spelen.

De volledige kernsuite slaagt met **1.043.487 controles**; de gerichte animatierun met **167.010 controles**. De simulatorbuild en beide iPhone-routes slagen. De echte opname is rond handcontact, het diepe doorzakken en het herstel per 1/30 seconde gecontroleerd. De snuit komt bij het oppervlak van de steen, het achterlijf zakt daarna verder, het herstel blijft kort en er staan geen doorschijnende dubbele figuren over elkaar.

[Nieuwste opname](Animations/zero-star-deep-fall-iphone.mp4) · [Beeldreeks](Screenshots/ZeroStarFall/sequence-deep.png) · [Diepste hand-/snuitcontact](Screenshots/ZeroStarFall/deep-impact.png) · [Groene Dino](Screenshots/ZeroStarFall/iphone-deep-standard.png) · [Eigen kleuren](Screenshots/ZeroStarFall/iphone-deep-custom.png). Bouw- en testlogs: `Documentation/ZeroStarFallTestLogs/*-deep.log`.
