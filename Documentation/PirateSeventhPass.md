# Tijdpiraten — oversteken, landen en weer opstijgen

21 oktober 2026.

De meeuwen volgen negen vaste oversteekroutes tussen opeenvolgende levelstenen. Hun aantal is op de gecontroleerde breedtes toegenomen van 22 naar 45–49; groepjes bevatten drie tot zes vogels, afhankelijk van de beschikbare veilige rustplekken op de schermbreedte. De routes volgen de kust niet meer. Midden op de kaart ligt elke vlucht halverwege twee levelstenen.

De vogels rusten op kraamranden, steigerpalen, tonnen, rotsbovenkanten, de bovenrand van de grote zandloper en vrij zand. De rustplekken zijn afgeleid van de werkelijk getekende objecten. Losse kuststenen delen daarom hun posities tussen de tekening en de landingsplanner; zandplekken houden afstand tot die stenen en de grote decoraties.

Iedere cyclus bevat rusten, opstijgen, oversteken, landen en opnieuw rusten. Kleine vertrekverschillen houden de groepjes los. Zittende meeuwen hebben ingeklapte vleugels en zichtbare poten; bij vertrek spreiden de vleugels en worden de poten ingetrokken. Meeuwen kijken in hun vliegrichting zonder hun lichaam ondersteboven te draaien.

Alleen zichtbare meeuwen worden getekend, maximaal twintig keer per seconde. De animatie pauzeert buiten beeld, bij een inactieve app en bij **Minder beweging**.

[Bewegend voorbeeld](Screenshots/PirateSeventhPass/flights-and-landings.gif) · [rust- en vliegposes](Screenshots/PirateSeventhPass/gull-poses.png) · [smalle kaart](Screenshots/PirateSeventhPass/native-393.png) · [brede kaart](Screenshots/PirateSeventhPass/native-834.png).

[Buildlog](WorldTestLogs/PirateSeventhPass/build.log) · [geometrie- en renderlog](WorldTestLogs/PirateSeventhPass/native-render.log).

De iOS-simulatorbuild en native renderbuild slagen. Op tien breedtes van 320 tot 1194 punten zijn 500 momenten over 65 seconden gecontroleerd: alle vogels rusten, vliegen en steken door het midden van hun doorgang over. 2.350.000 afstandscontroles houden de volledige meeuwentekenvlakken vrij van de levelstenen. De bestaande controles voor droge aanlegplekken en scheepsrompen blijven slagen. Vier volledige kaarten en acht animatiemomenten zijn gerenderd; honderd verschillende bewegingsbeelden vormen de preview. Twee beelden bij **Minder beweging** zijn pixelgelijk. [Pixelcontrole](WorldTestLogs/PirateSeventhPass/visual-checks.json).
