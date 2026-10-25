# Wereldbadges naar de beeldreferentie — 24 oktober 2026

Alle tien badges in het leveloverzicht zijn opnieuw opgebouwd naar de aangeleverde referentie. De app tekent ze volledig met native SwiftUI-shapes en Canvas in [JungleLandscape.swift](../Dino/Views/JungleLandscape.swift). De illustratie wordt niet als bitmap in de game gebruikt.

De oude generieke drager met twee zijornamenten is vervangen door kleine wereldscènes. Elke scène heeft een eigen ondergrond, achterste structuren die het bord dragen en voorgrondgroei of materiaal dat over de randen aansluit. Het wereldnummer zit op een voet die doorloopt naar het titelvlak. De hoofdtitels krijgen zwaardere ronde letters met een lichte vulling, een donkere contour en een zichtbare onderkant; het kasteel behoudt klassieke schreefletters.

De ondertitels zijn duidelijk groter: van **11,5 naar 14,5 punten** en van semibold naar bold. Hun vlakken worden breder en groeien van 34 naar 41 punten hoog. Lange beschrijvingen krijgen twee regels. De lichte beschrijvingsvlakken en donkergekleurde letters geven in alle werelden een vaste, herkenbare leesplek.

| Wereld | Uitwerking als één scène |
| --- | --- |
| Oerwoud | Houten planken, een doorlopende liaanconstructie, gevouwen tropische bladeren, begroeide rotsvoeten en bloemen |
| Woestijn | Gestapelde zandsteenformaties, een palm, cactus, inheemse planten en een voetafdruk in een steen |
| Vulkaanland | Donker basalt rondom een onregelmatige steenplaat, met lavanaden die aansluiten op het lavabed |
| Klokdorp | Houten bord met klimplanten, twee klokhuisjes, dorpsgroen, bloemen en een bestrate onderrand |
| Kristalgrot | Een blauwe gefacetteerde steenplaat in een geode met cyaan, blauwe en paarse kristallen en een doorlopende rotsvoet |
| Klokstad | Een blauwe metalen plaat met aangesloten buizen, kloktorens, koepels en een lichte onderrand |
| Slaapvallei | Een zachte paarse plaat, nachtelijk bladwerk en begroeiing, bevestigde lantaarns, maanlicht en een slapend dinotje |
| Tijdmachine | Een messing draagconstructie met pijpen, grote klokken, assen, gekoppelde tandwielen en een mechanisch platform |
| Tijdpiraten | Scheepshout, een mast met uurglasvlag, een touwomranding, verbonden anker en scheepswiel, strandgroen en een zandvoet |
| Tijdkasteel | Een ivoren bord in een gouden omlijsting, vier kasteeltorens, blauwe vaandels, een kroon en blauwe paleistrappen |

[Overzicht Nederlands](Screenshots/WorldBadgeReferenceRedesign/ten-worlds-nl.png) · [Overzicht Engels](Screenshots/WorldBadgeReferenceRedesign/ten-worlds-en.png).

## Tekst en inpassing

De native controlebeelden omvatten alle werelden op 284, 354 en 564 punten, in het Nederlands en Engels, plus hoog contrast op de smalle breedte. De titelgrootte volgt de gemeten vertaalde naam. Eén echte tekstweergave blijft beschikbaar voor VoiceOver; de decoratieve contour wordt afzonderlijk getekend.

De hoogte van 212 punten en het titelmiddelpunt tussen de levels blijven behouden. De landschaptekening, levelposities, voortgang en vraaginhoud zijn voor deze wijziging niet aangepast. De tijdmachine gebruikt de bestaande animatieklok en pauzeert buiten beeld of bij Minder beweging. De cijfers op gespiegelde klokconstructies blijven normaal leesbaar en op de juiste posities staan.

## Controle

- Native renders van alle tien badges, beide talen en drie breedtes zijn gemaakt en visueel beoordeeld. Smalle ondertitels, materiaalranden en de ruimte tussen tekst en voorgrond zijn afzonderlijk bekeken.
- De definitieve simulatorbuild: [buildlog](WorldTestLogs/WorldBadgeReferenceRedesign/final-build.log).

- iPhone 17: alle negen wereldgrenzen gecontroleerd met de bestaande afstandscontrole; drie reeksen met nul fouten ([wereld 2–4](WorldTestLogs/WorldBadgeReferenceRedesign/iphone-2-3-4.log), [wereld 5–7](WorldTestLogs/WorldBadgeReferenceRedesign/iphone-5-6-7.log), [wereld 8–10](WorldTestLogs/WorldBadgeReferenceRedesign/iphone-8-9-10.log)). De screenshots zijn ook visueel beoordeeld.
- iPad A16: de kristalgrot, tijdmachine en het kasteel zijn met dezelfde bestaande afstandscontrole gecontroleerd, met nul fouten ([testlog](WorldTestLogs/WorldBadgeReferenceRedesign/ipad-5-8-10.log)).
- Na de laatste bladafwerking en de volledig vrijgemaakte kasteelkroon is de build herhaald en de kasteelafstand op iPhone opnieuw geslaagd ([iPhone](WorldTestLogs/WorldBadgeReferenceRedesign/iphone-final-castle.log), [iPad](WorldTestLogs/WorldBadgeReferenceRedesign/ipad-final-castle.log)). De oerwoud-entree is rechtstreeks in de app bekeken.
