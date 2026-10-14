# Dino Time — de werelden 2 t/m 10

Dit document bevat negen uitgewerkte ontwerpen en negen zelfstandige beeldprompts. Elke wereld heeft negen gewone levels en één groter eindbaaslevel. De omgeving vertelt het thema; levelpunten en interface staan in een aparte laag.

De negen beelden zijn gegenereerd met de ingebouwde ImageGen-tool en opgeslagen in [WorldConcepts](WorldConcepts). Ze dienen uitsluitend als inspiratie. De speelbare kaarten en hun eindbazen worden volledig met SwiftUI-shapes, paden en Canvas getekend, net als Wereld 1. Ook de previews gebruiken die getekende vormen. De beelden zijn niet opgenomen in de runtime-assets. [WorldImageManifest.json](WorldImageManifest.json) bewaart de werkelijk gebruikte prompts, bronbestanden en conceptbestanden.

## Referenties uit het project

- Compositie: [junglekaart](Screenshots/jungle-map-iphone-se.png), [waterval](Screenshots/jungle-waterfall-ipad.png) en [wereld-overgang](Screenshots/jungle-transition-iphone-se.png).
- Exacte hoofddino en 3D-materialen: [originele dino](../Assets.xcassets/dino-idle.imageset/dino-idle.png).
- Bestaande kaartopbouw: [WorldMap.swift](../Dino/Views/WorldMap.swift) en [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift).

De jungleachtergrond bestaat uit SwiftUI-vormen. De junglebeelden dienen als referentie voor compositie, schaal, zachte kleuren en padplaatsing; de dino dient als referentie voor de 3D-materialen van de conceptbeelden. De productiekaarten volgen juist de bestaande getekende stijl. Screenshots zijn uitsluitend referenties: hun knoppen, tekst en levelpunten worden niet in de conceptbeelden overgenomen.

## Overzicht

| Wereld | Levels | Naam | Klokvaardigheid | Eindbaas |
| --- | --- | --- | --- | --- |
| 1 | 1–10 | Dino Jungle | Hele uren | De klokpoort — bestaand |
| 2 | 11–20 | Slaapvallei | Halve uren | Dommel de Droomsaurus |
| 3 | 21–30 | Vulkaanland | Kwartieren | Magma de Vuurtriceratops |
| 4 | 31–40 | Dino Dorp | Stappen van 5 minuten | Burgemeester Tik-Tak |
| 5 | 41–50 | Kristalgrot | Exacte minuten | Prisma de Kristalbewaker |
| 6 | 51–60 | Dino Stad | Digitale klok | Neon de Klokrobot |
| 7 | 61–70 | Dag-en-nachtbos | 12- en 24-uursklok | Tweelicht de Bosuil |
| 8 | 71–80 | Tijdmachine | Analoog en digitaal combineren | Professor Pendel |
| 9 | 81–90 | Tijdpiraten | Tijdsduur | Kapitein Zandloper |
| 10 | 91–100 | Dinokasteel | Alle vaardigheden | Koning Chronos |

## Vaste compositie en productie

- Eén wereld per beeld, 9:16; bij voorkeur 1080 × 1920 of een hogere resolutie met dezelfde verhouding.
- Dezelfde licht verhoogde isometrische camera, vergelijkbare schaal, afgeronde volumes, fijne oppervlaktetextuur en zachte schaduwen naar rechtsonder. De kleur van het invullicht mag met het thema veranderen.
- Een brede, lichte route van boven naar beneden met precies tien vrije zones: negen voor gewone ronde levelpunten, één grotere voor de eindbaas. Er worden geen levelpunten in de achtergrond getekend.
- De baas staat naast de laatste zone. De originele hoofddino wordt later als bestaande sprite toegevoegd, zodat zijn uiterlijk en positie exact behouden blijven. Een concept met dino gebruikt steeds de originele referentie.
- Obstakels zijn omgevingsdecor in deze ontwerpbrief. Ze bedekken het pad en de levelzones niet; water of lava onderbreekt de route alleen bij een duidelijke brede brug.
- Fysieke omgevingsklokken mogen tijden tonen. Knoppen, levelnummers, sterren, slotjes, HUD, wereldtitel, logo's en watermerken ontbreken.
- Bovenste circa 12% rustig voor de latere interface; onderste circa 6% geschikt voor de wereld-overgang.

Voor een vaste 9:16-ontwerpserie kunnen deze centra worden gebruikt. Coördinaten zijn percentages vanaf de linkerbovenhoek, geen cijfers om in het beeld te tekenen. Een normale vrije zone is circa 10% van de beeldbreedte; de eindbaaszone circa 15%.

| Plaats | x | y |
| --- | --- | --- |
| 1 | 28% | 18% |
| 2 | 50% | 26% |
| 3 | 72% | 34% |
| 4 | 50% | 42% |
| 5 | 28% | 50% |
| 6 | 50% | 58% |
| 7 | 72% | 66% |
| 8 | 50% | 74% |
| 9 | 28% | 82% |
| Eindbaas | 50% | 90% |

De app gebruikt een veel langere scrollkaart. Deze 9:16-compositie is een ontwerpformaat. De shapes zijn uitgewerkt op de daadwerkelijke scrollhoogte met dezelfde afstand tussen levelpunten als in de jungle. De conceptbeelden worden niet uitgerekt of als achtergronden geladen.

## Wereld 2 — Slaapvallei

**Levels:** 11–20 · **Klokvaardigheid:** Halve uren.

**Kleurenpalet:** Lavendel #DCD6F7, nachtblauw #596A99, saliegroen #9CCBB8, maanlicht #FFF1B8, parelcrème voor het pad #F6EAD5.

**Omgeving:** Een schemervallei met afgeronde heuvels, hangende wilgen, zachte mist, slapende bloemen, lichtgevende paddenstoelen en een smal beekje. De ingang is een bloemenweide; halverwege ligt een houten brug; de baas wacht bij een maanvormig nest.

**Obstakels:** Een omgevallen wilgenstam naast de route, dichtgevouwen bloemen en een beekje onder een brede houten brug.

**Eindbaas — Dommel de Droomsaurus:** Een vriendelijke lichtblauwe langnekdino met maanvormige vlekken, slaperige ogen en een grote ronde wekker naast zijn nest. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Kleine nestwekkers met de minutenwijzer op de 6, bijvoorbeeld 03:30 en 07:30. In het Nederlands betekent 03:30 ‘half vier’.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Slaapvallei uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp een dromerige schemervallei in lavendel, zacht nachtblauw en saliegroen met warm maanlicht. Een brede parelcrèmekleurige route kronkelt langs ronde heuvels, wilgen, slapende bloemen, nevel en subtiel gloeiende paddenstoelen. Een stevige houten brug passeert een smal beekje. Bouw diepte op met verre heuvels, een heldere middengrond en grotere planten langs de buitenranden. Laat ondergrond en pad helder genoeg om gemakkelijk te lezen. Zet een omgevallen wilgenstam en grote gesloten bloemen buiten de doorgang. Plaats Dommel de Droomsaurus naast de laatste vrije zone bij een maanvormig nest: een vriendelijke lichtblauwe langnek met maanvlekken en slaperige ogen. Voeg kleine fysieke wekkerklokken toe met correct weergegeven halve uren, zoals 03:30 en 07:30; hun minutenwijzers staan op de 6 en hun urenwijzers halverwege twee uurmarkeringen. Laat onderaan een warme perzikkleurige gloed vooruitwijzen naar Vulkaanland.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 3 — Vulkaanland

**Levels:** 21–30 · **Klokvaardigheid:** Kwartieren.

**Kleurenpalet:** Perzik #FFD1A1, koraal #F47C65, amber #FFC857, warm basalt #706778, licht zand voor het pad #F8DFB5.

**Omgeving:** Ronde vulkanen, warme rotsplateaus, afgekoelde lavavelden en zacht gloeiende lavastromen. Een lavabrug en een open kraterplein zijn de herkenningspunten.

**Obstakels:** Afgeronde basaltblokken, kleine stoompluimen naast het pad en lavageulen met brede stenen bruggen.

**Eindbaas — Magma de Vuurtriceratops:** Een terracottakleurige triceratops met stompe hoorns, amberkleurige rugaccenten en een ronde kraag met vier subtiele kloksegmenten. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Rotsklokken met de minutenwijzer op de 3 of de 9 en de urenwijzer op de juiste tussenpositie. 04:15 is kwart over vier; 04:45 is kwart voor vijf.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Vulkaanland uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Bouw een uitnodigend vulkaanlandschap in perzik, koraal, amber en warm paarsgrijs basalt. Een brede lichte zandroute kronkelt tussen ronde rotsplateaus. Gebruik afgeronde vulkanen in de verte, zacht gloeiende oranje lavastromen aan de zijkanten, gekoelde rotsen, kleine stoompluimen en twee stevige stenen bruggen. Laat lava voor warm invullicht zorgen, terwijl de zachte hoofdverlichting en de heldere route behouden blijven. Er zijn geen gevaarlijke uitbarstingen of explosies. Plaats Magma de Vuurtriceratops naast het laatste open kraterplein: een vriendelijke terracottakleurige triceratops met stompe hoorns, amberaccenten en een ronde kraag met vier subtiele segmenten. Verwerk kleine analoge klokken in basaltrotsen, met correcte kwartieren zoals 04:15 en 04:45, minutenwijzers op de 3 of de 9 en passend verschoven urenwijzers. Houd de bruggen vrij van rotsblokken. Laat onderaan de basaltstenen overgaan in groen gras en de terracotta van Dino Dorp.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 4 — Dino Dorp

**Levels:** 31–40 · **Klokvaardigheid:** Stappen van 5 minuten.

**Kleurenpalet:** Mint #C7E8BE, terracotta #D98663, honing #F6CC73, luchtblauw #AAD9EB, warm crème voor het pad #F5E6C7.

**Omgeving:** Eivormige huizen met ronde deuren, moestuinen, een marktplein, een beek met bruggetjes en een ronde klokkentoren.

**Obstakels:** Fruitkratten, een stilstaande handkar en een waterrad langs de dorpsbeek; alles buiten de doorgang.

**Eindbaas — Burgemeester Tik-Tak:** Een vriendelijke goudbruine ankylosaurus met een klein blauw burgemeestersjasje en een ronde klokstaf. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Een dorpsklok met twaalf duidelijke markeringen en tuinwekkers op bijvoorbeeld 02:05, 05:20 en 09:55.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Dino Dorp uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp een gezellig dinodorp in mintgroen, terracotta, honinggeel en lichtblauw. Een brede warmcrèmekleurige dorpsroute kronkelt langs eivormige huizen met ronde deuren, moestuinen, fruitkraampjes en kleine bruggen over een beek. Plaats huizen in afwisselende clusters aan beide randen, met een herkenbare ronde klokkentoren in de verte. Voeg een stilstaande houten kar, fruitkratten en een waterrad toe als decoratieve obstakels buiten de vrije route. De laatste grotere vrije zone ligt op een open dorpsplein. Burgemeester Tik-Tak wacht ernaast: een vriendelijke goudbruine ankylosaurus met een klein blauw jasje en een ronde klokstaf. Integreer fysieke klokken met vijfminutenstanden zoals 02:05, 05:20 en 09:55; teken beide wijzers correct. Gebruik twaalf markeringen als terugkerend motief in de klokkentoren, zonder onderwijslabels. Scheid voorgrond, huizen en verre heuvels duidelijk in diepte. Laat onderaan kleine turquoise kristallen tussen de dorpsstenen verschijnen als overgang naar Kristalgrot.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 5 — Kristalgrot

**Levels:** 41–50 · **Klokvaardigheid:** Exacte minuten.

**Kleurenpalet:** Aquamarijn #79D8D0, violet #A493D7, roze kwarts #F1BCD9, blauwgroen #427D89, lichte steen voor het pad #D8EEF0.

**Omgeving:** Een ruime lichte grot met afgeronde rotsbogen, kristaltuinen, ondergrondse meertjes en een brede stenen brug. Grote kristalclusters vormen herkenningspunten.

**Obstakels:** Lage kristalgroepen, ronde stalagmieten en ondiepe watergeulen. Kristallen staan buiten de speelroute.

**Eindbaas — Prisma de Kristalbewaker:** Een ronde blauwgrijze rotsreus met zachte turquoise en roze schouderkristallen, een vriendelijk gezicht en een klein kristallen klokamulet. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Fijn gemarkeerde fysieke wijzerplaten op bijvoorbeeld 02:17 en 08:43. De zestig minuutstreepjes zijn decor; leesbare oefenklokken worden later door de game getekend.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Kristalgrot uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Maak een ruime, goed verlichte grot in aquamarijn, violet, roze kwarts en blauwgroen. Een brede lichte stenen route kronkelt door de grot naar een monumentale ronde kristalboog bij de laatste vrije zone. Zet doorschijnende kristalclusters langs de buitenranden, ronde stalagmieten bij de rotswanden en kleine rustige meertjes in de zijkanten. Een brede stenen brug overspant een watergeul. Gebruik zachte verre rotsbogen en grotere kristallen op de voorgrond voor diepte. Houd de kristalgloed subtiel: de route blijft helder, zonder harde neonkleuren of donkere tunnel. Plaats Prisma de Kristalbewaker naast de laatste vrije zone: een vriendelijke ronde blauwgrijze rotsreus met turquoise en roze schouderkristallen en een klein klokamulet. Voeg fysieke analoge klokken in kristalnissen toe, met fijne minuutmarkeringen en correcte wijzerstanden voor 02:17 en 08:43. Houd deze klokken klein en ondergeschikt aan het landschap. Laat de onderste rotsrand overgaan naar lichte stadsstenen met een kleine warme lamp, als overgang naar Dino Stad.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 6 — Dino Stad

**Levels:** 51–60 · **Klokvaardigheid:** Digitale klok.

**Kleurenpalet:** Luchtblauw #B8E4F5, turquoise #54BCC5, zonnig geel #FFE08A, mandarijn #F6A168, lichte straatsteen voor het pad #EBE4D7.

**Omgeving:** Een compacte stad met afgeronde gebouwen, daktuinen, een station, een tram en een open digitaal klokplein. Hout en terracotta verbinden de stad met Dino Dorp.

**Obstakels:** Stilstaande trams, lage bloembakken en kleine plassen langs een duidelijk herkenbare wandelroute.

**Eindbaas — Neon de Klokrobot:** Een vriendelijke turquoise robot met een rond geel gezichtsscherm, korte armen en een klein fysiek digitaal buikdisplay. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Stations- en geveldisplays in consequent HH:MM, bijvoorbeeld 08:05, 10:30 en 12:45. De expliciete dagdeel- en 24-uurskoppeling volgt in Wereld 7.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Dino Stad uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp een lichte compacte dinostad in luchtblauw, turquoise, zonnig geel en mandarijnoranje. Een brede wandelroute van lichte straatstenen kronkelt langs ronde gebouwen, groene daktuinen, een klein tramstation en een open klokplein. Zet hogere gebouwen aan de randen en verlaag hun dichtheid rond het pad. Integreer enkele warme houten en terracotta onderdelen, zodat de stad bij de jungle en het dorp past. Stilstaande trams, lage bloembakken en kleine plassen vormen herkenbaar decor buiten de doorgang. Plaats Neon de Klokrobot naast de laatste open plek: een vriendelijke turquoise robot met een rond geel gezichtsscherm, korte armen en een klein digitaal buikdisplay. Voeg op fysieke stationsklokken en gevelklokken subtiele digitale tijden toe, zoals 08:05, 10:30 en 12:45, steeds in HH:MM-formaat. Displays zijn onderdeel van gebouwen. Geef de straten, gebouwen en verre stadsrand duidelijke diepte en houd de route visueel rustig. Laat onderaan de stadsstenen overgaan in bomen met warm avondlicht voor Dag-en-nachtbos.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 7 — Dag-en-nachtbos

**Levels:** 61–70 · **Klokvaardigheid:** 12- en 24-uursklok.

**Kleurenpalet:** Ochtendgoud #FFD98C, bosgroen #8CC68C, schemerpaars #AA99CC, nachtblauw #526894, maancrème voor het pad #F1E7C7.

**Omgeving:** Eén doorlopend bos dat langs de route van ochtend naar middag, avond en zachte nacht verandert. Glimwormen en een maanvijver markeren het laatste deel.

**Obstakels:** Afgeronde boomwortels, een houten brug over een beek en grote paddenstoelen naast de route.

**Eindbaas — Tweelicht de Bosuil:** Een vriendelijke grote uil met één goudkleurige en één indigo vleugel, ronde ogen en twee kleine klokhangertjes. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Een analoge klok op drie uur naast 15:00 in het middagdeel; een analoge klok op acht uur naast 20:00 bij een maanmotief. De omgeving maakt het dagdeel zichtbaar.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Dag-en-nachtbos uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp één doorlopend bos dat langs de route van warm ochtendgoud en fris groen via middaglicht naar schemerpaars en zachte nachtblauwen overgaat. Een brede maancrèmekleurige route kronkelt naar een maanvijver bij de laatste vrije zone. Laat dezelfde ronde bomen en paddenstoelen door het hele landschap terugkomen. Voeg in het avonddeel glimwormen en subtiele natuurlijke sterren aan de verre hemel toe. Een houten brug passeert een beek; wortels liggen naast het pad. Ook het nachtdeel blijft licht genoeg om gemakkelijk te lezen. Behoud de hoofdlichtrichting en verander geleidelijk de kleurtemperatuur en het invullicht. Plaats Tweelicht de Bosuil naast de laatste vrije zone: een vriendelijke grote uil met een gouden en een indigo vleugel, ronde ogen en twee kleine klokhangertjes. Integreer fysieke dubbele klokken: een analoge klok op drie uur naast 15:00 in het middagdeel en een analoge klok op acht uur naast 20:00 onder een maanmotief in het avonddeel. De context toont het dagdeel zonder labels. Voeg onderaan de subtiele turquoise gloed van een machinepoort toe voor Tijdmachine. Maak geen splitscreen.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 8 — Tijdmachine

**Levels:** 71–80 · **Klokvaardigheid:** Analoog en digitaal combineren.

**Kleurenpalet:** Turquoise #7EDDD0, zacht violet #B5A6E6, messing #D9B46C, koraal #EF9A85, lichte werkplaatsvloer voor het pad #E8E9DA.

**Omgeving:** Een open fantasiewerkplaats met ronde portalen, messing tandwielen, een centrale tijdmachine, zacht gloeiende buizen en kleine observatieplatforms.

**Obstakels:** Stilstaande tandwielen langs de rand, kabelbogen boven zijgangen en een korte brede brug tussen twee zichtbaar gedragen platforms.

**Eindbaas — Professor Pendel:** Een vriendelijke violette pterosaurus met ronde bril, kort crème vest en een messing slingerinstrument. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Twee fysieke apparaten met dezelfde tijd analoog en digitaal, bijvoorbeeld 06:25 en 10:40.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Tijdmachine uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp een open fantasiewerkplaats in turquoise, zacht violet, warm messing en kleine koraalaccenten. Een brede lichte route kronkelt langs ronde portalen, grote tandwielen, zacht gloeiende buizen en observatieplatforms naar de centrale tijdmachine. Laat alle platforms zichtbaar rusten op afgeronde constructies. Een korte brede brug verbindt twee vloerdelen; stilstaande tandwielen en kabelbogen staan buiten de route. Gebruik kleine plantenbakken om de machinewereld met de eerdere omgevingen te verbinden. Combineer mat gelakt materiaal en zacht glanzend messing; gloed blijft subtiel. Plaats Professor Pendel naast de laatste vrije zone: een vriendelijke violette pterosaurus met ronde bril, crème vest en een messing slingerinstrument. Integreer twee fysieke apparaten die analoog en digitaal dezelfde tijd tonen: 06:25 en 10:40. Teken de minutenwijzers en tussenstanden van de urenwijzers correct. De displays zitten in het apparaat en zweven niet boven de route. Maak de werkplaats ruim en toon duidelijke diepte. Laat onderaan een portaal zacht zicht geven op turquoise water en zand van Tijdpiraten.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 9 — Tijdpiraten

**Levels:** 81–90 · **Klokvaardigheid:** Tijdsduur.

**Kleurenpalet:** Zeeturquoise #63C7CB, zand #F5D698, koraal #EF927B, warm hout #A47757, zeilcrème #FFF1D3.

**Omgeving:** Een zonnige archipel met eilanden, houten loopbruggen, palmen, een kleine haven en een vrolijk piratenschip bij de laatste baai.

**Obstakels:** Touwrollen, tonnen, getijdenpoeltjes en een aangespoelde boomstam buiten de doorgang. Alle eilanden worden zichtbaar met brede bruggen verbonden.

**Eindbaas — Kapitein Zandloper:** Een vriendelijke donkerblauwe spinosaurus met zeilvormige rug, koraalkleurige kapiteinshoed met zandlopermotief en een grote zandloper naast zijn schip. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Kleine havenklokken op 09:00, 09:30 en 10:00 en fysieke zandlopers. Geen berekening of antwoord in de achtergrond.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Tijdpiraten uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Bouw een vrolijke archipel in zeeturquoise, goudzand, zacht koraal en warm hout. Een brede zandroute met stevige houten loopbruggen kronkelt over kleine eilanden naar een beschutte havenbaai. Gebruik palmen, ronde rotsen, rustige getijdenpoeltjes en crème zeilen voor diepte. Zet touwrollen, tonnen en een aangespoelde stam langs de route zonder de doorgang te bedekken. Laat de eilanden één leesbare reis vormen met zichtbaar verbonden bruggen en rustig water. Plaats Kapitein Zandloper naast de laatste vrije zone bij een vrolijk piratenschip: een vriendelijke donkerblauwe spinosaurus met een zeilrug en een koraalkleurige hoed met zandlopermotief. Zet een grote zandloper bij de haven en kleine fysieke havenklokken op 09:00, 09:30 en 10:00. Verstreken-tijdmotieven blijven decor, zonder berekeningen of opdrachten in het beeld. Gebruik dezelfde zachte materialen met fijne hout- en zandtextuur als in de stijlreferentie. Laat onderaan een lichte stenen kasteelbrug opdoemen. Geen wapens, schedelvlaggen of dreigende zee; de hoofddino krijgt geen piratenkostuum.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Wereld 10 — Dinokasteel

**Levels:** 91–100 · **Klokvaardigheid:** Alle vaardigheden.

**Kleurenpalet:** Lichte kalksteen #E8DFCC, koningsblauw #789BCF, warm goud #E8C66D, tuinmunt #A8D5AA, bandanakoraal #EB7D72.

**Omgeving:** Een uitnodigend kasteel met ronde torens, tuin, brede ophaalbrug, binnenplaats en grote klokpoort. Bloemen, kristallen, messing tandwielen en een zandloperfontein herinneren aan eerdere werelden.

**Obstakels:** Lage tuinmuren, een slotgracht onder de brede brug en ronde tandwielornamenten naast de poort.

**Eindbaas — Koning Chronos:** Een vriendelijke grote goudbruine tyrannosaurus met afgeronde kroon, korte koningsblauwe mantel en een rond klokmedaillon. Dit is een zelfstandig personage; de hoofddino verandert niet.

**Klokdetails:** Analoge klokken, fysieke digitale displays en zandlopers verdeeld over torens en tuinen. Een prominent duo toont 10:25 in beide klokvormen.

**Volledige generatieprompt:**

> Maak één verticale mobiele wereldkaartachtergrond in 9:16 voor Dinokasteel uit Dino Time. Premium 3D-cartoon game art voor kinderen van 5–9 jaar: vrolijk, zorgvuldig afgewerkt, speels zonder babyachtig te worden. Gebruik de meegestuurde Wereld 1-junglekaart als compositiereferentie en de originele groene dino als exacte karakter- en materiaalreferentie. Behoud dezelfde licht verhoogde isometrische camera, objectgrootte, afgeronde vormtaal, fijne oppervlaktetextuur en zachte hoofdverlichting van linksboven met schaduwen naar rechtsonder. Scheid voorgrond, middengrond en achtergrond voor duidelijke diepte. De hoofddino behoudt exact zijn groene huid, donkere stekels, crèmekleurige buik en tenen, grote bruine ogen, ronde snuit en rode bandana met witte 12:34. Houd hem als bestaande losse sprite buiten deze productieachtergrond; verander zijn uiterlijk niet.
>
> Ontwerp een feestelijk en uitnodigend kasteel in lichte kalksteen, koningsblauw, warm goud, tuinmunt en kleine koraalaccenten. Een brede lichte stenen route kronkelt door de tuin, over een brede ophaalbrug en via de binnenplaats naar een grote ronde klokpoort. Geef de laatste vrije eindbaaszone extra nadruk door een open plein en ruime omlijsting. Gebruik ronde torens langs de randen en houd het centrale pad open. Voeg subtiele herinneringen aan de vorige werelden toe: junglebladeren, dorpsbloemen, enkele kristallen, messing tandwielen en een kleine zandloperfontein. Lage tuinmuren en de gracht liggen buiten de vrije zones. Plaats Koning Chronos naast de laatste open plek: een vriendelijke grote goudbruine tyrannosaurus met afgeronde kroon, korte koningsblauwe mantel en een rond klokmedaillon. Verwerk kleine analoge klokken, fysieke digitale displays en zandlopers in torens en tuinornamenten; een analoge klok op 10:25 staat naast een display met 10:25. Houd alle klokdetails ondergeschikt aan het landschap. Gebruik zachte steen- en stoftexturen. Rond de wereld onderaan af met een zonnige tuin en zachte gouden gloed, passend bij de voltooiing van het avontuur.
>
> De brede route loopt zoals in Wereld 1 van boven naar beneden in een duidelijke slinger. Reserveer precies tien vrije plaatsingszones op de route voor later toe te voegen ronde levelpunten: negen normale zones en één grotere laatste zone voor de eindbaas. Teken de levelpunten zelf niet, ook niet als lege ronde knoppen. De baas staat naast de laatste zone. Decor en obstakels staan langs de randen of onder een brede brug en bedekken geen plaatsingszones. Houd de bovenste circa 12% rustig voor de latere interface. Klokken zijn subtiele fysieke objecten in de omgeving. Geen knoppen, levelnummers, voortgangssterren, slotjes, HUD, wereldtitel, overige tekst, logo of watermerk. Alleen tijden op fysieke digitale klokdisplays zijn toegestaan. Eén doorlopende omgeving, geen collage.

## Controle bij het genereren

1. Stuur bij elke generatie opnieuw de Wereld 1-referentie en de originele dinoafbeelding mee. Een tekstverwijzing naar een niet meegestuurd beeld is onvoldoende.
2. Genereer de werelden afzonderlijk en vergelijk met dezelfde goedgekeurde referentie. Gebruik steeds Wereld 1, zodat stijlverschuiving niet van wereld naar wereld opstapelt.
3. Controleer beeldverhouding, camerahoek, leesbaarheid van het pad, tien vrije zones, grotere laatste zone en de positie van de baas.
4. Controleer dat geen interface is ingebakken. Voeg de bestaande dino als losse sprite toe voor de definitieve game.
5. Controleer fysieke klokstanden handmatig. Beeldgeneratie kan wijzers of displaytekens verkeerd tekenen; corrigeer die vóór gebruik. De programmatisch getekende klokken blijven leidend voor de onderwijsvragen.
6. Vergelijk de negen ontwerpen naast elkaar op schaal, materiaalgebruik, schaduwrichting, detaildichtheid en aansluiting op Wereld 1.

**Status:** negen conceptbeelden gegenereerd; negen speelbare werelden toegevoegd met native shapes. De game bevat levels 1–100 en toont daarna Coming soon.
