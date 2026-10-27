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

| Fase | Tijd na de schermfade |
| --- | ---: |
| Vertrek uit het exacte rustbeeld | 0,120 s |
| Evenwicht verliezen | 0,260 s |
| Naar voren vallen | 0,460 s |
| Eerste handcontact | 0,640 s |
| Snuit raakt de steen | 0,720 s |
| Volledig neergevallen | 0,820 s |
| Einde van 0,30 seconde volledige stilstand | 1,120 s |
| Handen opnieuw geplaatst; armen nemen het gewicht over | 1,190 s |
| Armen gestrekt; handen mogen loskomen | 1,380 s |
| Handen los, knieën nog gebogen | 1,480 s |
| Vrijwel rechtop | 1,560 s |
| Eindhouding | 1,620 s |

De schermfade duurt 0,24 seconde. De hele clip duurt **1,86 seconde**. De gedeelde verplaatsing stopt bij het eerste handcontact. Hoofd en achterlijf zakken daarna verder tot de lage houding. Van 0,82 tot 1,12 seconde zijn de tekening én alle vervormingspunten exact gelijk: Dino ligt echt stil.

Het volledige opstaan na de rust duurt **0,50 seconde**, teruggebracht van 0,88 seconde. Alleen deze opwaartse fase is versneld; de val en de volledige stilstand behouden hun timing. Na die rust verplaatst hij zijn handen en bereidt hij het opdrukken voor. Tijdens de daaropvolgende **0,19 seconde** gebruikt de beweging één opdruktekening. De schouders en het hoofd bewegen doorlopend omhoog terwijl beide palmen exact dezelfde positie houden. De palmen worden als afzonderlijke delen uit hetzelfde gekleurde bronbeeld getekend; hun vingers rekken daardoor niet mee met het lichaam. Het lichaam wordt achter de handen vervormd en overlapt bij de polsen. Pas na deze steunfase komen de handen los en volgt het verder oprichten.

De sleuteltijden voor de gewrichten staan los van de keuze van de tekening. Daardoor vraagt een nieuw punt in de bewegingsbaan geen nieuwe PNG midden in het gewicht dragende deel. Vrij bewegende handen sturen de benen niet mee; dat voorkomt uitgerekte voeten tijdens de overgang naar staan. De laatste overgangen gebruiken nog de bestaande geschilderde houdingen. De aangeleverde PNG’s hebben verschillende gezichtsverhoudingen en perspectief; de mesh en registratie beperken die verschillen, maar vervangen geen volledig opnieuw opgebouwde karakterrig.

## Kleuren en toegankelijkheid

Iedere pose heeft eigen contouren voor ogen, mond, hoofdpieken en bandana. De gele duizelsterren blijven hun geschilderde kleur houden, ook met een andere buikkleur. De bestaande kalibratie meet tint, verzadiging, schaduwen, middentonen en hooglichten van de werkelijke bitmap en stemt ze af op de gewone Dino. De twee gegenereerde beelden gebruiken dezelfde afstemming. Op lichte bandana’s blijft `12:34` donker en leesbaar.

Bij **Minder beweging** verschijnt direct de stilstaande eindpose `dino-stumble-deep-08` op de steen.

## Controle

De gerichte animatiecontroles vergelijken de volledige stilstaande houding, bewaken dat de palmen tijdens het dragen van het gewicht niet verschuiven, controleren dat het hoofd en de schouders boven die handen omhoogkomen en dat dezelfde tekening de hele steunfase draagt. Ook de doorlopende banen, vaste grondpunten, contactlijn, niet-omgeklapte meshvlakken op 30 en 60 Hz, alle overige cliptypes en Minder beweging worden gecontroleerd.

De native UI-controle speelt echte levels uit met de gewone groene Dino en een gepersonaliseerde roze Dino, en controleert één figuur, nul sterren, de eindpositie en opnieuw spelen. De wachttijd in de UI-test omvat de volledige nieuwe clip.

Na de timingwijziging slaagt de gerichte suite met **255.261 animatiecontroles**. De simulatorbuild en de echte nulsterrenroute met de groene Dino op iPhone 18 Pro met iOS 27.0 slagen. De nieuwe opname controleert de val, de volledige rust en het kortere opstaan. De eindpositie en opnieuw spelen worden via de native UI-test gecontroleerd.

[Nieuwste opname met sneller opstaan](Animations/zero-star-rise-halfsecond-iphone.mp4) · [Beeldreeks](Screenshots/ZeroStarFall/sequence-halfsecond.png). Logs: `Documentation/ZeroStarFallTestLogs/*-brisk.log`. De [eerdere opname](Animations/zero-star-supported-rise-iphone.mp4) toont dezelfde val met het langzamere opstaan.
