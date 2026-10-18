# Eindlevel: illustraties en ontwerp

De nieuwe eindscène combineert een geïllustreerde jungle, een houten titelbord, een podium van steen en gouden sterren met de bestaande personaliseerbare Dino. De titel, score, sterrenverdeling en knoppen blijven native SwiftUI. De andere werelden houden hun eigen achtergrondpalet. De illustratie schaalt als geheel mee met het venster; de bediening blijft zichtbaar.

De vijf beelden zijn gemaakt met de ingebouwde `image_gen`-tool (imagegen-skill). Het aangeleverde voorbeeld is alleen gebruikt als stijl- en materiaalreferentie. Transparantie van bord, podium, ster en trofee is behouden. De originele bestanden staan in de volgende assetsets:

- `Assets.xcassets/result-jungle.imageset/result-jungle.png`
- `Assets.xcassets/result-podium.imageset/result-podium.png`
- `Assets.xcassets/result-sign.imageset/result-sign.png`
- `Assets.xcassets/result-star.imageset/result-star.png`
- `Assets.xcassets/result-trophy.imageset/result-trophy.png`

## Gebruikte prompts

### result-jungle

Use case: stylized-concept. Asset type: production background plate for a premium children's dinosaur game level-complete screen. Input image 1 is STYLE AND LIGHTING REFERENCE ONLY. Create a beautiful polished 3D storybook jungle clearing in the same art direction: juicy luminous rounded green tropical leaves framing upper corners and lower corners, turquoise blue sky across top half, soft white clouds, distant hazy rolling teal-green jungle hills, a glimpse of aqua river at lower right, lush sunlit grass at bottom. Strong soft warm sunlight coming from the clearing at center, atmospheric depth, subtle golden airborne dust, tactile foliage and warm cinematic bounce light. PORTRAIT 2:3 composition. Keep the central 65 percent of the picture open, quiet and bright with gentle light-green haze so a separate animated dinosaur, podium and interface can be placed over it. Ground line at 80 percent from top. Upper central area is just open sky. Rich leafy framing, asymmetry, foreground depth. Crisp professionally finished mobile game art. NO characters, NO dinosaurs, NO rocks or pedestals in center, NO wooden signs, NO text, NO letters, NO stars, NO confetti, NO buttons, NO borders. Full bleed illustration.

### result-podium

Use case: stylized-concept. Asset type: isolated transparent game sprite, celebration rock podium. Input image 1 is STYLE AND MATERIAL REFERENCE. Create only the gorgeous wide moss-covered gray stone podium from the lower area of the reference, together with its surrounding lush tropical green leaves and tiny grassy base. NO dinosaur, NO stars, NO sign, NO sky, NO scenery. Front view slightly from above, a wide squat natural rounded boulder with gently flattened broad top where a dinosaur can stand. Large rock dominates center, about 65 percent of total sprite width and 60 percent of total sprite height; grass roots at bottom, lush glossy tropical leaves fan outward at both sides without blocking the top surface. Soft gray-beige tactile stone with faceted irregular edges, fine cracks, subtle mottled texture, warm sunlight on top left, soft darker shaded front, velvet vivid chartreuse moss patches draping over upper corners. One tiny white daisy near each lower corner. The stone front is large and quiet for separate gold stars to be overlaid. Premium 3D rendered children's storybook mobile game, polished rounded forms, beautifully lit dimensional materials matching reference. Landscape composition about 2:1. Fill canvas with object with narrow transparent margin. Actual transparent alpha background; no floor rectangle, no backdrop, no drop shadow outside grass. NO text, NO gold stars, NO character.

### result-sign

Use case: stylized-concept. Asset type: isolated transparent UI wooden level sign for premium children's dinosaur game. Input image 1 is STYLE AND MATERIAL REFERENCE. Create a gorgeous blank horizontal honey-colored wooden sign like the reference upper sign. Shape is a thick broad rustic plank, softly irregular rounded rectangular outline, gently arched top and bottom, beveled smooth edges, beautiful restrained woodgrain, warm light peach-gold highlights upper left, orange amber shaded bottom edge, a dark subtle wooden thickness on lower edge. Lush dimensional glossy green tropical leaf clusters and slender little curving vine attached at both ends, few small leaves cresting top corners. Broad central 70 percent of the wooden surface must remain perfectly clear, low-contrast and blank for separately rendered title text. Landscape composition about 3:1, fill canvas nearly edge to edge with narrow transparent margin. Premium 3D storybook mobile game render with tactile surfaces, soft lighting, polished rounded forms. Genuine transparent alpha background. NO text, NO letters, NO numbers, NO icons, NO dinosaur, NO stars, NO sky, NO scenery, NO supports or posts.

### result-star

Use case: stylized-concept. Asset type: isolated transparent gold reward star sprite for a premium children's dinosaur mobile game. Input image 1 is the STYLE REFERENCE: reproduce the material and quality of one of its big reward stars at bottom. Exactly ONE chunky five pointed gold star, front view, upright with one point at top, gently rounded tips and rounded inner corners, plump smoothly inflated golden shape with dimensional beveled orange-gold lower edge, brilliant lemon yellow central face, pale creamy gold rim catching the light, soft bright specular highlight near upper left. Strong luminous warm gold, beautifully smooth shading, polished 3D storybook game render, simple perfect star silhouette, matching the three reward stars in reference. Fill square canvas with star with 8 percent transparent margin. Genuine transparent alpha background. NO other objects, NO rock, NO text, NO face, NO eyes, NO sparkles outside star, NO ground, NO backdrop, NO circles.

### result-trophy

Use case: stylized-concept. Asset type: isolated transparent reward trophy sprite for a premium children's dinosaur mobile game. Make ONE beautiful chunky polished gold trophy, upright front view slightly from above. Rounded bowl, two curved symmetrical gold handles, short thick stem and broad rounded gold foot. Embossed little five-point gold star centered on the bowl. Match the reference image's big gold reward stars: luminous lemon yellow face, thick warm orange-gold beveled edges, creamy highlights on upper left, soft sculpted 3D material, rounded child-friendly storybook mobile game art. Proportions broad and compact, handles fully visible. Fill square canvas nearly edge to edge with narrow transparent margins, single centered object. Genuine transparent alpha background. NO backdrop, NO floor, NO scenery, NO character, NO text or letters, NO confetti, NO sparkles outside object.

## Verificatie

- De Debug-build en de testbuild slagen met Xcode.
- `Tools/test-dino.sh` slaagt met 807.909 controles.
- `testResultRewardStatesAndNavigation` controleert nul, één, twee en drie sterren, zichtbare en bereikbare knoppen, opnieuw spelen, verdergaan, terug naar de kaart, boss-verlies, perfecte boss-winst in het Engels en een nachtwereld. De controles zijn uitgevoerd op iPhone 17, iPhone SE (3e generatie) en iPad Pro 11-inch.
- De gedeelde Dino, zijn eigen kleuren en de bestaande salto blijven onderdeel van de scène. De illustratie is apart schaalbaar; de bedieningsknoppen zijn native. Confetti stopt na de korte uitbarsting en houdt rekening met Verminder beweging.
- De testfixtures werken uitsluitend in Debug met een afzonderlijke `DINO_TEST_SUITE`. Ze vervangen geen echte spelersopslag. De tijdelijke iPhone SE-simulator is na controle verwijderd.
- `git diff --check` is schoon.

### Beelden

[iPhone](Screenshots/LevelResultDesign/result-iphone.png) · [iPhone SE](Screenshots/LevelResultDesign/result-compact.png) · [iPad](Screenshots/LevelResultDesign/result-ipad.png) · [Boss-trofee](Screenshots/LevelResultDesign/result-boss.png).

### Beperking van de rotatiecontrole

De interface op de gedeelde iPad-simulator (iPadOS 26.5) bleef portret tonen terwijl zowel XCTest als Device Hub het apparaat lieten draaien. Landschapstand is daardoor niet visueel geverifieerd. De poging staat in [rotation-attempt.log](WorldTestLogs/LevelResultDesign/rotation-attempt.log). De optionele harde controle is beschikbaar via `DINO_TEST_RESULT_ROTATION=1` in de test-runneromgeving, na controle van de oriëntatie op het testapparaat. De gewone schermtest controleert alle genoemde score- en navigatievarianten in portretstand.

[Build](WorldTestLogs/LevelResultDesign/build.log) · [iPhone](WorldTestLogs/LevelResultDesign/iphone.log) · [iPhone SE](WorldTestLogs/LevelResultDesign/compact.log) · [iPad portret](WorldTestLogs/LevelResultDesign/ipad.log).

## Bijstelling na gebruikersfeedback

De steen staat iets naar rechts en omhoog ten opzichte van Dino. De sterren zijn ongeveer 11% kleiner, volgen het midden van de steen en staan hoger op de rotswand. De leveltitel is hoger op het houten bord geplaatst.

De score heeft geen kader of materiaalachtergrond meer. Het water en de lage vallei zijn in de achtergrond vervangen door doorlopend gras. De nieuwe illustratie is gemaakt met de ingebouwde imagegen-tool en opgeslagen als `Assets.xcassets/result-jungle-grounded.imageset/result-jungle-grounded.png`. Het eerdere beeld is behouden. `DinoRewardStar` deelt het gouden sterbeeld tussen eindscherm, levelkaart, vriendenresultaten en sterrenoverzicht; de kaartsterren zijn iets groter om de vorm op dat formaat duidelijk te laten zien.

### Prompt van de grasbewerking

Use case: precise-object-edit. Edit target: the attached existing background plate for a children's dinosaur game. Make one precise landscape correction while preserving the established style and upper composition. Keep the blue sky, white clouds, upper corner jungle leaves, warm sunshine, distant hills, all framing and the polished 3D storybook rendering. Replace the turquoise water/river and the entire distant lower valley opening with a continuous, gently sloped, lush sunlit grassy clearing that extends uninterrupted from the middle distance to the bottom foreground. The grass clearing should start around 58 percent down from the top, run behind the future central rock, and continue smoothly all the way to the bottom edge. Short dimensional lime-green grass, warm yellow-green highlights, subtle natural tufts and a few tiny daisies, coherent ground perspective and soft shadows, absolutely NO turquoise or blue holes, NO water, NO lake, NO river, NO empty gap or cliff in the lower half. Keep a broad quiet central grass area at 65–92 percent height for overlaid game UI text. Side foliage stays lush and dimensional, consistent with the original. Preserve the portrait aspect ratio, same overall scene identity. Do not add any rock/podium, dinosaur, sign, characters, reward stars, text or UI buttons. Opaque full-bleed image.

### Controle van de bijstelling

De gerichte schermtest omvat nu ook het teruggaan naar de levelkaart en het openen/sluiten van het sterrenoverzicht. Zo worden de nieuwe gouden sterren in dezelfde sessie gecontroleerd als de resultaatvarianten.

De build en de gerichte schermtest slagen op iPhone 17 en iPad Pro 11-inch. Beide uitvoeringen hebben nul fouten: [iPhone-log](WorldTestLogs/LevelResultGrounding/iphone.log), [iPad-log](WorldTestLogs/LevelResultGrounding/ipad.log), [build](WorldTestLogs/LevelResultGrounding/build.log). De beelden zijn visueel nagekeken; `git diff --check` is schoon. De aparte test-iPhone is na de controle verwijderd.

[Bijgesteld eindscherm op iPhone](Screenshots/LevelResultGrounding/result-iphone.png) · [iPad](Screenshots/LevelResultGrounding/result-ipad.png) · [Gouden sterren op de kaart](Screenshots/LevelResultGrounding/map-iphone.png) · [Sterrenoverzicht](Screenshots/LevelResultGrounding/stars-overview-ipad.png).





