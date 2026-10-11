# Dino-animaties

De acht salto-assets zijn geen gelijkmatig verdeelde rotatieframes. Beeld 3 toont een ingetrokken pose met ongeveer 45° kanteling, beeld 4 is ondersteboven en beeld 5 alweer vrijwel rechtop. Bij alleen het wisselen van deze PNG's ontbreken dus tussenstanden. Ook liggen de optische middelpunten op verschillende hoogtes in het transparante canvas.

`DinoAnimation` maakt daarom één doorlopende sprong en volledige rotatie. De reeds getekende kanteling wordt per pose gecompenseerd; gemeten alpha-middelpunten houden het draaipunt stabiel. Afzet en landing gebruiken een lichte rek/indrukking, en korte overgangen verbinden de poses. `DinoCharacter` bemonstert deze beweging via SwiftUI `TimelineView` op maximaal 60 beelden per seconde en stopt daarna de updates. De PNG's zelf zijn ongewijzigd.

- **Salto:** `dino-backflip-01` t/m `08`, 1,85 seconde, één keer na maximale punten. Het uitslagscherm reserveert extra ruimte voor de sprong.
- **Duimen:** `dino-thumbs-up-01` t/m `08`, 0,62 seconde bij elk correct antwoord; volgende vraag na 0,72 seconde. De vaste overlay beïnvloedt nooit de klokpositie of titel.
- **Minder beweging:** de eindpose verschijnt zonder sprong of rotatie.

De controle op 120 tijdstappen per seconde bewaakt een volledige monotone draaiing zonder hoeksprongen en een doorlopende hoogte. Daarnaast is de echte simulatoropname bekeken op de duimen, afzet, draaiing en landing.
