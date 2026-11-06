# Vraagtype 1: stabiele feedback en minutenschaal

De digitale doelklok reserveert vóór het antwoord geen ruimte voor verborgen hulppijlen. Pas na een fout antwoord groeit de opgave soepel om de genummerde hulp te tonen. De gedeelde digitale klok gebruikt een strakker hulpkader van 50 in plaats van 56 punten; dit verkleint de bovenmarge ook bij andere vraagtypen.

De antwoordklok gebruikt aanvankelijk de volledige binnenruimte van de kaart, zonder marge voor een verborgen minutenschaal of digitale uitleg. Pas na de eerste fout verschijnen **00, 05, 10 … 55** met korte streepjes bij de nog onbeantwoorde klokken. Alleen die klokken passen hun wijzerplaat in de buitenste schaal.

Zodra een klok fout gekozen wordt, verdwijnt zijn schaal en vervalt de schaalmarge. De wijzerplaat gebruikt dan de resterende ruimte boven de werkelijk gemeten digitale tijd. De schaal en de digitale tijd reserveren dus geen ruimte tegelijk. De kaart behoudt haar afmetingen en positie; de klok schaalt en schuift binnen de kaart met een overgang van 0,3 seconde. Bij Verminder beweging vervalt deze animatie. Een volgende vraag begint opnieuw met grote klokken zonder schaal.

De schaal volgt de ronde, vierkante of achthoekige klokvorm en gebruikt de kleur van de lange wijzer. Lichte kleuren krijgen een dunne donkere buitenrand voor leesbaarheid op de witte antwoordkaart. Bij een getoond juist antwoord verdwijnt de schaal eveneens.

De gerichte schermtest `testAnalogWrongClockChoicesKeepTheQuestionVisible` controleert het compacte beginkader en het extra hulpkader na een fout. De overige onbeantwoorde kaarten behouden hun afmetingen en afstand tot de digitale doelklok. Foutbadgejes veranderen de toegankelijkheidsgrenzen van beantwoorde kaarten; daarom meet de positiecontrole de ongewijzigde kaarten. De test bewaakt ook dat de titel en de onderste antwoordrij binnen de viewport blijven.

De bijgewerkte schermtest slaagt op 31 oktober 2026 op iPhone 18 Pro en iPad (A16), met iOS 27: alle drie de foute keuzes behouden de plaats van de titel, doelklok en overige antwoordkaarten, en de volgende vraag begint weer zonder schaal. De screenshots vóór feedback, na de eerste fout, na alle fouten en bij de volgende vraag zijn visueel gecontroleerd. Ook de whitespacecontrole slaagt.

De gewone simulatorbuild stuit op de losstaande fout dat de huidige AppIcon-set geen toepasselijke inhoud heeft. Alleen voor deze testbuild is `ASSETCATALOG_COMPILER_APPICON_NAME=` gebruikt. De icoonbestanden en projectinstellingen zijn niet aangepast voor deze controle.

Hercontrole op 4 november 2026: de aangepaste schermtest slaagt op iPhone 18 Pro en iPad (A16), beide met iOS 27. De digitale klok begint compact, maakt na de eerste fout ruimte voor de hulp en begint bij de volgende vraag opnieuw compact. De beelden vóór en na de fout zijn visueel gecontroleerd. De simulatorbuild en whitespacecontrole slagen.

Lokale beelden: [iPhone vóór het antwoord](Screenshots/AnalogChoiceFeedback/iphone-before-answer.png), [iPhone na de eerste fout](Screenshots/AnalogChoiceFeedback/iphone-first-mistake.png), [iPad na de eerste fout](Screenshots/AnalogChoiceFeedback/ipad-first-mistake.png) en [de volgende vraag zonder schaal](Screenshots/AnalogChoiceFeedback/iphone-next-question.png).
