# Pirouette – tussenbeelden voor de volledige draai

De tweesterrensprong gebruikt achttien beelden: de originele reeks `dino-pirouette-01` t/m `14`, aangevuld met `06a`, `07a`, `08a` en `10a`. Deze vier nieuwe tussenbeelden zijn gemaakt met de ingebouwde imagegen-tool, met telkens de twee aangrenzende originele beelden als referentie. Ze vullen de grote kijkhoekwisselingen rond de achterkant en de overgang naar de landing op. De originele eindafbeelding `dino-pirouette-14`, de offsets (`−0,012`, `−0,029`) en de resultaatsteen blijven behouden.

## Assets in afspeelvolgorde

| Asset | Pose | Duur |
| --- | --- | --- |
| [dino-pirouette-01](../Assets.xcassets/dino-pirouette-01.imageset/dino-pirouette-01.png) | Staan | 320 ms, inclusief schermovergang |
| [dino-pirouette-02](../Assets.xcassets/dino-pirouette-02.imageset/dino-pirouette-02.png) | Inveren voor afzet | 140 ms |
| [dino-pirouette-03](../Assets.xcassets/dino-pirouette-03.imageset/dino-pirouette-03.png) | Afzetten | 80 ms |
| [dino-pirouette-04](../Assets.xcassets/dino-pirouette-04.imageset/dino-pirouette-04.png) | Begin draai | 60 ms |
| [dino-pirouette-05](../Assets.xcassets/dino-pirouette-05.imageset/dino-pirouette-05.png) | Rechterzijaanzicht | 65 ms |
| [dino-pirouette-06](../Assets.xcassets/dino-pirouette-06.imageset/dino-pirouette-06.png) | Draaien naar achteren | 75 ms |
| [dino-pirouette-06a](../Assets.xcassets/dino-pirouette-06a.imageset/dino-pirouette-06a.png) | Achter-rechts, 140° | 75 ms |
| [dino-pirouette-07](../Assets.xcassets/dino-pirouette-07.imageset/dino-pirouette-07.png) | Achteraanzicht | 65 ms |
| [dino-pirouette-07a](../Assets.xcassets/dino-pirouette-07a.imageset/dino-pirouette-07a.png) | Begin achter-links, 202,5°; staart naar camera | 50 ms |
| [dino-pirouette-08](../Assets.xcassets/dino-pirouette-08.imageset/dino-pirouette-08.png) | Achter-links | 50 ms |
| [dino-pirouette-08a](../Assets.xcassets/dino-pirouette-08a.imageset/dino-pirouette-08a.png) | Overgang achter-links naar zijaanzicht, 247,5° | 50 ms |
| [dino-pirouette-09](../Assets.xcassets/dino-pirouette-09.imageset/dino-pirouette-09.png) | Linkerzijaanzicht | 70 ms |
| [dino-pirouette-10](../Assets.xcassets/dino-pirouette-10.imageset/dino-pirouette-10.png) | Draaien naar voren | 55 ms |
| [dino-pirouette-10a](../Assets.xcassets/dino-pirouette-10a.imageset/dino-pirouette-10a.png) | Benen uitstrekken voor landing, 325° | 50 ms |
| [dino-pirouette-11](../Assets.xcassets/dino-pirouette-11.imageset/dino-pirouette-11.png) | Landing opvangen | 130 ms |
| [dino-pirouette-12](../Assets.xcassets/dino-pirouette-12.imageset/dino-pirouette-12.png) | Overeind komen | 150 ms |
| [dino-pirouette-13](../Assets.xcassets/dino-pirouette-13.imageset/dino-pirouette-13.png) | Armen heffen | 170 ms |
| [dino-pirouette-14](../Assets.xcassets/dino-pirouette-14.imageset/dino-pirouette-14.png) | Juichen | Blijft staan |

De gegenereerde PNG’s zijn met hun oorspronkelijke alpha naar de assetcatalogus gekopieerd. De nieuwe beelden hebben eigen contourmaskers en gemeten lichtpaletten voor de gekozen Dino-kleuren. De zichtbare opdruk op `08a` en `10a` heeft ook een eigen gebied voor donkere cijfers op lichte hoofdbanden. De achteraanzichten hebben geen zichtbare opdruk. De originele veertien PNG’s zijn niet gewijzigd.

## Timing

Elke pose heeft een eigen afspeelduur in `DinoAnimation.pirouetteFrames`. De eerdere globale versnelling van 1,7× liet een aantal tussenbeelden maar 31–33 ms zien en hield de getekende landingspose ongeveer 230 ms in de lucht. De actuele tijdlijn versnelt de vlucht van 830 naar 665 ms, ongeveer 25% vlotter. De langste draaiende beelden zijn ingekort en de laatste luchtpose krijgt 50 ms in plaats van 100 ms. De geplante landing behoudt zijn herstelritme.

De schermovergang duurt 0,24 seconde, gevolgd door 0,30 seconde voorbereiding: 80 ms staan, 140 ms inveren en 80 ms afzetten. De sprong duurt 0,665 seconde. Tijdens de vlucht varieert de beeldduur van 50 tot 75 ms; de benen krijgen vlak voor contact 50 ms om uit te strekken. Op 1,205 seconde begint de geplante landingspose. Daarna volgen 130 ms opvangen, 150 ms overeind komen en 170 ms armen heffen. Op 1,655 seconde staat de blijvende eindpose; de tijdlijn stopt direct omdat de beweging dan is afgelopen.

Een monotone kubische interpolatie houdt draaihoek én draaisnelheid doorlopend tussen de beeldwisselingen, ook bij ongelijke beeldduur. De geschilderde hoekstappen blijven maximaal 40°; de kleine perspectiefcorrectie blijft begrensd op 9°. De sprongbaan en de gedeelde reis gebruiken dezelfde afzet- en landingstijden. De eerste ster verschijnt na contact, op ongeveer 1,245 seconde. Alle achttien afbeeldingen en uitlijningen blijven behouden.

[Vlottere draai](Screenshots/PirouetteTimingFaster/pirouette.gif) · [Vorige timing en vlottere draai naast elkaar](Screenshots/PirouetteTimingFaster/timing-comparison.gif).

## Verificatie van de timing

- **6.981 animatiecontroles slagen**, inclusief de exacte beeldgrenzen, contact bij de landing, doorlopende hoeksnelheid en alle achttien beelden bij 30 én 60 fps met vier verschillende verversingsfasen.
- Elke actieve pose heeft 50–170 ms leestijd; de eerste staande pose bevat ook de schermovergang. De benen blijven tot het grondcontact in de luchtpose.
- De iOS-simulatorbuild met de aangepaste timing slaagt (`xcodebuild build`, Debug).
- De voorbeelden zijn op 50 fps gerenderd uit de echte kleurverwerking en tijdsamples. Ze tonen Dino los van de schermreis en de kleine SwiftUI-3D-correctie. Het vergelijkingsvoorbeeld gebruikt dezelfde klok voor beide versies.
- De oude afbeeldings-, kleur- en transparantiecontroles hieronder horen bij het toevoegen van de vier beelden; de timingwijziging wijzigt geen PNG’s of kleurmaskers.

## Verificatie van de tussenbeelden

- De volledige kernsuite slaagt met **822.851 controles**. De gerichte animatie-, transparantie-, kleur- en opdrukcontrole slaagt met **6.710 controles**.
- De animatietest controleert de volledige reeks van achttien poses, vooraf laden, een maximale posewissel van 40°, de doorlopende sprongbaan, de bestaande landing en de statische eindpose bij Minder beweging.
- Alle nieuwe PNG’s zijn 1254 × 1254 RGBA met echte transparantie. De vier assetmanifesten verwijzen naar bestaande bestanden. De originele veertien PNG’s zijn ongewijzigd ten opzichte van Git.
- De Xcode-simulatorbuild (`build-for-testing`, iPhone 17 / iOS 26.5) slaagt. De bestaande UI-test `testTwoStarPirouetteFromQuestionToStone` werd tijdens het personaliseren onderbroken door een onverwachte runner-herstart, vóór het level en de pirouette; daarom is die test niet als geslaagd geteld.
- Het kleurenoverzicht toont de echte kleurverwerking met standaardkleuren en blauw/paars/roze/oranje. Het GIF-voorbeeld gebruikt de actuele poses, offsets, spronghoogte en squash op 50 fps; het toont de sprite los van de schermreis en de kleine SwiftUI-3D-correctie.

[Vorige timing](Screenshots/PirouetteV5/pirouette.gif) · [Alle achttien poses en kleuren](Screenshots/PirouetteV5/colors.png) · [Exacte nieuwe imagegen-prompts](PirouetteV5Prompts.json).

De eerdere simulatoropname blijft beschikbaar als historisch voorbeeld: [versie 4](Animations/pirouette-two-stars-v4-iphone.mp4).

## Nieuwe imagegen-prompts

De ingebouwde imagegen-tool is gebruikt, met `transparent_background: true`, één aanroep per nieuw beeld. De volledige prompts staan in [PirouetteV5Prompts.json](PirouetteV5Prompts.json), met sleutels voor de aangrenzende originele beelden. De nieuwe bestanden staan rechtstreeks in de vier hierboven gelinkte `.imageset`-mappen in `Assets.xcassets`.

## Exacte prompts

### 02 — Afzet voorbereiden

Use case: identity-preserve. Asset type: single transparent full-body dinosaur game animation sprite.
Input images: image 1 is the starting animation keyframe reference, image 2 is the following ending keyframe reference. Generate ONE new in-between sprite only.
Primary request: Create the anticipation pose, 25% of the way from standing reference 1 to airborne reference 2. Keep the front-right three-quarter viewing angle of reference 1. Both feet are planted at the same ground baseline and almost same horizontal positions as reference 1. Bend both knees and lower the hips slightly, torso leans just a little forward. Hands draw slightly down/back near hips, preparing to push off. Do not lift a knee yet. This must be a small motion step after reference 1, not an airborne pose.
Identity and style: preserve this exact cute green dinosaur character, round oversized head, large brown eyes, cheek shapes, smiling open mouth with pink tongue, cream muzzle/belly/toes, dark forest-green back spikes and spots, red cloth bandana with white printed "12:34". Match the references' polished soft 3D children's-game rendering, proportions, texture and lighting. Keep body color/illumination consistent; the game recolors these sprites.
Composition: single character fully visible on a square transparent canvas, centered horizontally, similar apparent size and margins to reference 2. No cropped head, toes, tail or bandana tips.
Text (verbatim): "12:34" on front of bandana.
Constraints: transparent background with real alpha. No ground, no cast shadow, no stone, no motion trail, no particles, no glow, no extra character, no objects, no labels, no frame or border. Only the new in-between pose.

### 03 — Eerste afzet

Use case: identity-preserve. Asset type: single transparent full-body dinosaur game animation sprite.
Input images: image 1 is the starting animation keyframe reference, image 2 is the following ending keyframe reference. Generate ONE new in-between sprite only.
Primary request: Create the early takeoff pose, 60% of the way from standing reference 1 to airborne reference 2. The body has rotated only halfway toward the right-facing orientation of reference 2. Extend the legs to push off: heels lifted, toes still point down close to the ground, one knee only slightly beginning to rise. The feet must not yet be tucked up as much as reference 2. Arms are halfway between the low bent arms of reference 1 and the outstretched arms of reference 2. This is a small early launch, not the already airborne pose of reference 2.
Identity and style: preserve this exact cute green dinosaur character, round oversized head, large brown eyes, cheek shapes, smiling open mouth with pink tongue, cream muzzle/belly/toes, dark forest-green back spikes and spots, red cloth bandana with white printed "12:34". Match the references' polished soft 3D children's-game rendering, proportions, texture and lighting. Keep body color/illumination consistent; the game recolors these sprites.
Composition: single character fully visible on a square transparent canvas, centered horizontally, similar apparent size and margins to reference 2. No cropped head, toes, tail or bandana tips.
Text (verbatim): "12:34" on front of bandana.
Constraints: transparent background with real alpha. No ground, no cast shadow, no stone, no motion trail, no particles, no glow, no extra character, no objects, no labels, no frame or border. Only the new in-between pose.

### 12 — Overeind komen

Use case: identity-preserve. Asset type: single transparent full-body dinosaur game animation sprite.
Input images: image 1 is the starting animation keyframe reference, image 2 is the following ending keyframe reference. Generate ONE new in-between sprite only.
Primary request: Create the first intermediate landing-recovery pose between reference 1 crouched landing facing slightly LEFT and reference 2 final celebration facing slightly RIGHT. Finish the turn so the head and chest now face almost STRAIGHT toward camera, with only a tiny lean to the left. Both feet planted and knees still slightly bent. Both hands remain low near the waist, elbows loosely bent. Do not raise arms in celebration yet. Keep the sole baseline and body size like reference 2; tail curves behind on viewer's LEFT, becoming only partially visible as it swings behind the torso. This is one natural body, no duplicate limbs or ghosting.
Identity and style: preserve this exact cute green dinosaur character, round oversized head, large brown eyes, cheek shapes, smiling open mouth with pink tongue, cream muzzle/belly/toes, dark forest-green back spikes and spots, red cloth bandana with white printed "12:34". Match the references' polished soft 3D children's-game rendering, proportions, texture and lighting. Keep body color/illumination consistent; the game recolors these sprites.
Composition: single character fully visible on a square transparent canvas, centered horizontally, similar apparent size and margins to reference 2. No cropped head, toes, tail or bandana tips.
Text (verbatim): "12:34" on front of bandana.
Constraints: transparent background with real alpha. No ground, no cast shadow, no stone, no motion trail, no particles, no glow, no extra character, no objects, no labels, no frame or border. Only the new in-between pose.

### 13 — Armen half heffen

Use case: identity-preserve. Asset type: single transparent full-body dinosaur game animation sprite.
Input images: image 1 is the starting animation keyframe reference, image 2 is the following ending keyframe reference. Generate ONE new in-between sprite only.
Primary request: Create the last intermediate landing-recovery pose just BEFORE reference 2 final raised-arms celebration. Use exactly the front-right three-quarter direction of reference 2, same tail on viewer's LEFT, same feet positions and same sole baseline, same smiling face. Knees are almost straight. Both upper arms are extending out at a lower diagonal and BOTH elbows bend so the fists are around shoulder height, HALF WAY between low waist hands and the full high victory fists in reference 2. Keep fists lower than the cheek/eyes. This must flow into reference 2 with only the last small arm lift; do not recreate reference 2's already fully raised victory arms.
Identity and style: preserve this exact cute green dinosaur character, round oversized head, large brown eyes, cheek shapes, smiling open mouth with pink tongue, cream muzzle/belly/toes, dark forest-green back spikes and spots, red cloth bandana with white printed "12:34". Match the references' polished soft 3D children's-game rendering, proportions, texture and lighting. Keep body color/illumination consistent; the game recolors these sprites.
Composition: single character fully visible on a square transparent canvas, centered horizontally, similar apparent size and margins to reference 2. No cropped head, toes, tail or bandana tips.
Text (verbatim): "12:34" on front of bandana.
Constraints: transparent background with real alpha. No ground, no cast shadow, no stone, no motion trail, no particles, no glow, no extra character, no objects, no labels, no frame or border. Only the new in-between pose.

### Correctie van launch

Use case: precise-object-edit. Correct this single transparent dinosaur game sprite. The illustration accidentally has THREE ARMS. Keep exactly TWO arms: keep the small arm extending backward to the LEFT behind the torso, and keep the near arm bent horizontally across the CREAM BELLY in the lower foreground. REMOVE ONLY the extra arm and fist on the far RIGHT at height near the bottom of the snout (the fist at approximately x=1040, y=665 on the 1254 square canvas), including its connecting branch. Rebuild a smooth natural silhouette at the right shoulder/chest where the extra branch was removed. Preserve every other part: the exact face, body pose, two legs, remaining two arms, tail, lighting, colors, texture, red bandana, white "12:34", image dimensions, full-body framing, and transparent background. Do not add anything. Genuine alpha background, no shadow or floor.


### 08 — Achter-links

Use case: stylized-concept. Asset type: ONE transparent animation sprite for an existing children's dinosaur game.
Input image 1 is the rear-view pose immediately BEFORE this missing frame. Input image 2 is the front-left three-quarter pose immediately AFTER it. Preserve the exact same dinosaur identity, head/body proportions, smooth 3D storybook material, green body, dark green dorsal spikes and spots, cream cheeks/belly/claws, red cloth bandana, soft warm upper-left lighting and front camera elevation.
Primary request: create the missing REAR-LEFT THREE-QUARTER view halfway through turning from image 1 toward image 2: approximately 45 degrees beyond the full rear view toward screen-left. The dinosaur is airborne in an upright pirouette, both short arms extended horizontally in the same turn, knees softly bent, one foot tucked and one hanging. We should see MOSTLY ITS BACK, the spine of dark spikes, and ONLY a small slice of the LEFT snout/cheek peeking around the screen-left contour. NO large frontal face, no looking backward over its shoulder. The torso and head must turn together by the same angle. Tail sweeps naturally behind toward screen-right, between the rear and left view references. Bandana knot and red tails remain on screen-right, subtly trailing the spin; the white "12:34" print is on the FRONT of the bandana and therefore is NOT visible from this rear three-quarter angle.
Composition: single full-body dinosaur centered on a square transparent canvas; same scale as references, body occupies roughly 75% canvas width and 92% canvas height, narrow clear margin above spikes and below feet. Entire tail and hands visible.
Constraints: one dinosaur only, no floor, no cast ground shadow, no stone, no environment, no sparkles, no motion streaks, no frame labels, no added text, no watermark, no checkerboard rendered into the image. Genuine transparent alpha background. Match the references closely enough to sit directly between them as a single animation frame.
