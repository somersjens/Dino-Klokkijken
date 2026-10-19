# Pirouette – vloeiendere afzet en landing

De veertien beelden van de tweesterrensprong zijn genummerd in de afspeelvolgorde, van `dino-pirouette-01` tot en met `dino-pirouette-14`. De extra tussenbeelden zijn gemaakt met de ingebouwde imagegen-tool. De originele eindafbeelding `dino-pirouette-14`, de offsets (`−0,012`, `−0,029`) en de resultaatsteen blijven behouden.

## Assets in afspeelvolgorde

| Asset | Pose |
| --- | --- |
| [dino-pirouette-01](../Assets.xcassets/dino-pirouette-01.imageset/dino-pirouette-01.png) | Staan |
| [dino-pirouette-02](../Assets.xcassets/dino-pirouette-02.imageset/dino-pirouette-02.png) | Inveren voor afzet |
| [dino-pirouette-03](../Assets.xcassets/dino-pirouette-03.imageset/dino-pirouette-03.png) | Afzetten |
| [dino-pirouette-04](../Assets.xcassets/dino-pirouette-04.imageset/dino-pirouette-04.png) | Begin draai |
| [dino-pirouette-05](../Assets.xcassets/dino-pirouette-05.imageset/dino-pirouette-05.png) | Rechterzijaanzicht |
| [dino-pirouette-06](../Assets.xcassets/dino-pirouette-06.imageset/dino-pirouette-06.png) | Draaien naar achteren |
| [dino-pirouette-07](../Assets.xcassets/dino-pirouette-07.imageset/dino-pirouette-07.png) | Achteraanzicht |
| [dino-pirouette-08](../Assets.xcassets/dino-pirouette-08.imageset/dino-pirouette-08.png) | Achter-links |
| [dino-pirouette-09](../Assets.xcassets/dino-pirouette-09.imageset/dino-pirouette-09.png) | Linkerzijaanzicht |
| [dino-pirouette-10](../Assets.xcassets/dino-pirouette-10.imageset/dino-pirouette-10.png) | Draaien naar voren |
| [dino-pirouette-11](../Assets.xcassets/dino-pirouette-11.imageset/dino-pirouette-11.png) | Landing opvangen |
| [dino-pirouette-12](../Assets.xcassets/dino-pirouette-12.imageset/dino-pirouette-12.png) | Overeind komen |
| [dino-pirouette-13](../Assets.xcassets/dino-pirouette-13.imageset/dino-pirouette-13.png) | Armen heffen |
| [dino-pirouette-14](../Assets.xcassets/dino-pirouette-14.imageset/dino-pirouette-14.png) | Juichen |

De gegenereerde PNG’s zijn met hun oorspronkelijke alpha naar de assetcatalogus gekopieerd. De vier beelden hebben eigen contourmaskers, gebieden voor de cijfers en gemeten lichtpaletten voor de gekozen Dino-kleuren.

## Timing

De schermovergang krijgt 0,24 seconde aanloop. De volledige posevolgorde speelt daarna op 1,7× tempo: ongeveer 0,28 seconde voorbereiding, 0,82 seconde springen en draaien, en twee landingsposes van elk 0,09 seconde. De voeten landen na ongeveer 1,35 seconde; de hele animatie duurt ongeveer 1,63 seconde. De verplaatsing gebruikt een curve met een krachtige start (`0,20 / 0,65 / 0,35 / 1`): na het inveren krijgt Dino onmiddellijk vaart omhoog en remt hij af naar de steen. De sprongboog zorgt onderweg voor hoogte boven de landingsplek. Alle veertien beelden, kleurmaskers en de exacte eindpositie blijven behouden. De sterren beginnen na de landing. De beweging bij drie sterren en de statische weergave bij Minder beweging blijven behouden.

## Verificatie

De hernoeming is gecontroleerd met SHA-256: alle veertien PNG’s zijn ongewijzigd en staan nu in hun afspeelvolgorde. De assetcatalogus bevat precies `dino-pirouette-01` t/m `14`; bestandsnamen, kleurmaskers, lichtpaletten, opdrukgebieden en documentatielinks zijn bijgewerkt. Verouderde pirouettevoorbeelden en dubbele documentatie zijn verwijderd. De actuele kernsuite slaagt met 805.404 controles, inclusief de volledige genummerde afspeelvolgorde. De SwiftUI-aanroep voor de nieuwe bewegingscurve is apart op types gecontroleerd.

De voorafgaande versie is vanuit een volledig gespeeld level gecontroleerd op iPhone 17 en iPad Pro 11-inch. De laatste wijziging maakt de afzet krachtiger en de reis korter. Een nieuwe Xcode-build kon niet worden uitgevoerd: de automatische goedkeuringscontrole bereikte de gebruikslimiet. De onderstaande simulatoropname toont daarom de voorafgaande versie; het kleurenoverzicht toont de actuele nummering.

[Vorige simulatoropname](Animations/pirouette-two-stars-v4-iphone.mp4) · [Actuele assets en kleuren](Screenshots/PirouetteV4/colors.jpg) · [iPhone](Screenshots/PirouetteV4/iphone.png) · [iPad](Screenshots/PirouetteV4/ipad.png).

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
