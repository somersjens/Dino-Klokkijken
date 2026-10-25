# Klokstad — zichtbare tunnelafdaling op iPhone

De onderste metrobocht is hersteld op basis van de geometrie in commit `028be25`. In de latere indeling liep de bocht buiten de stadsranden en stond een gevel vóór de linker tunnelmond. Daardoor was het eerdere diepte-effect nauwelijks zichtbaar.

Beide spoorhelften blijven nu rond de speelroute. Het middelste deel van de onderste bocht ligt onder de straat; de twee aanlopen zakken geleidelijk 58 schaalpunten en komen aan de andere kant terug op straatniveau. De bestaande doorgaande rails, rijtuigrotatie, schaduw en ondergrondse uitsnede volgen dezelfde hellingen.

De stadsindeling houdt de volledige zichtbare aanlopen en tunnelmonden vrij van gevels. De portaalranden en dekstenen worden vóór de verdiepte rijtuigen getekend. De rechter uitrit en de volledige klim blijven ook op smalle telefoons binnen beeld.

## Controle

- De iOS-simulatorbuild slaagt.
- `testCityMetroRouteRemainsPlayable` slaagt op een afzonderlijke iPhone 17 met iOS 26.5: één test, nul fouten. Level 51, de route langs 54 en 57 en eindbaas 60 blijven bereikbaar. [Testlog](WorldTestLogs/CityTunnelRestoration/iphone.log).
- De native geometriecontrole slaagt op tien breedtes van 320 tot 1194 punten. Beide tunnelmonden en de volledige rechter klim staan binnen beeld; gebouwen staan vrij van de zichtbare aanlopen en open rails. [Resultaten](WorldTestLogs/CityTunnelRestoration/geometry.log).
- Vier precieze animatieposities zijn visueel gecontroleerd op 320, 393 en 834 punten. Deze native beelden gebruiken eenvoudige levelcirkels; de afzonderlijke appopname toont de echte interface.

[Afdaling op iPhone](Screenshots/CityTunnelRestoration/iphone-descending.png) · [Uitrit op iPhone](Screenshots/CityTunnelRestoration/iphone-emerging.png) · [Smalle iPhone](Screenshots/CityTunnelRestoration/narrow-iphone-emerging.png) · [iPad](Screenshots/CityTunnelRestoration/ipad-emerging.png) · [App op iPhone](Screenshots/CityTunnelRestoration/app-iphone.png).

De native controle is opnieuw uit te voeren vanuit de projectmap:

```sh
python3 Documentation/WorldTestLogs/CityTunnelRestoration/prepare-native.py /private/tmp/clock-city-tunnel-audit
xcrun swiftc -parse-as-library -module-cache-path /private/tmp/clock-city-tunnel-audit/modules /private/tmp/clock-city-tunnel-audit/native.swift -o /private/tmp/clock-city-tunnel-audit/render
/private/tmp/clock-city-tunnel-audit/render /private/tmp/clock-city-tunnel-audit
```
