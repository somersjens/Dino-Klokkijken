# Tijdpiraten — lossere meeuwengroepen

22 oktober 2026.

De meeuwen bewegen met overlappende gebeurtenissen: de bovenste groep verplaatst en landt, terwijl de volgende pluk van links door het beeld vliegt. Halverwege die passage vertrekt de derde groep naar nieuwe rustplekken. Tijdens het landen vliegt een vierde pluk vanaf rechts door het beeld. Lager op de kaart loopt hetzelfde gedrag met een andere fase; iedere vogel heeft eigen vertrekvertragingen. Ze volgen gebogen trajecten door de open ruimte tussen de levelstenen, met eigen hoogteverschillen, onregelmatige vertrekvolgordes en kleine tempowisselingen. Ook de vleugelslag verschilt per vogel; rustige glijmomenten wisselen met fladderen af.

Onderlinge afstand wordt met snelheid, traagheid en vroeg uitwijken berekend. De ruimte voor vleugels die bijna opengaan telt al mee vóór het opstijgen. Kleine contactcorrecties voorkomen dat vleugels bij elkaar komen. De beweging wordt vooraf voor een ronde doorgerekend en per kaartformaat gecachet. De animatie leest het resultaat met interpolatie uit; vogels worden tijdens het vliegen niet plotseling opzij geplaatst.

Rustplekken op zand liggen onregelmatig verspreid. Palmbladeren zijn uitgesloten als rustplek en vogels op het kraampje staan op de lage voorrand. Op kraamranden, palen en rotsen houden de vogels meer ruimte, ook tussen aangrenzende groepjes. Ze vliegen schuin op de rustplek af, klappen hun vleugels in, rusten en vertrekken weer. Het speelpad tussen de levelstenen blijft bruikbaar; de volledige vogels houden afstand tot de stenen.

[Bewegende preview](Screenshots/PirateEighthPass/loose-flocks.gif) · [smalle kaart](Screenshots/PirateEighthPass/native-393.png) · [brede kaart](Screenshots/PirateEighthPass/native-834.png).

[Buildlog](WorldTestLogs/PirateEighthPass/build.log) · [geometrie- en bewegingscontrole](WorldTestLogs/PirateEighthPass/native-check.log) · [renderlog](WorldTestLogs/PirateEighthPass/native-render.log).

Gecontroleerd op tien kaartbreedtes van 320 tot 1194 punten: steeds 49 vogels, 650 bewegingsmomenten per formaat, ruim twee miljoen controles van vogelruimte bij levelstenen en gerenderde maskers van de krapste passages. De vluchtbeweging blijft vloeiend over de volledige ronde. De native preview bevat 30 seconden beweging.

De iOS-simulatorbuild slaagt. De 240 previewframes bevatten allemaal beweging en de twee renders met Minder beweging zijn pixelgelijk.
