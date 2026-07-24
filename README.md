# Weedpreis

Eine mobile, installierbare Vergleichsoberfläche für Medizinalcannabis-Angebote. Die Anwendung dient ausschließlich der Produktentwicklung und stellt keine medizinische Beratung dar.

## Lokal starten

Voraussetzungen: Node.js 24 und pnpm 11.9.0.

```sh
pnpm install --frozen-lockfile
pnpm dev
```

Weitere Prüfungen:

```sh
pnpm test
pnpm build
pnpm exec playwright install webkit
pnpm test:e2e
pnpm check
```

## Daten und Speicherung

Alle sichtbaren Angebote sind ausschließlich synthetische Testdaten. Es gibt keine Live-Preise, keine realen Apotheken, keine Gesundheitsdaten und keine Standortverfolgung.

Die Altersbestätigung und Favoriten werden nur auf dem jeweiligen Gerät im Browser gespeichert. Sie werden weder synchronisiert noch an einen Server übertragen.

## Überprüfen

Wenn ein Auftrag nur „Überprüfen“ lautet, ist damit eine reine, lesende Prüfung des aktuellen Zustands gemeint. Dabei werden keine Dateien oder Daten verändert, sofern nicht ausdrücklich ein Änderungsauftrag folgt.

## Roadmap

Eine spätere Ausbaustufe kann eine Live-Datenplattform auf Supabase ergänzen. Auch echte Apotheken-Adapter gehören erst in diese spätere Phase, nachdem Quelle und Nutzungserlaubnis für jede Anbindung dokumentiert wurden.
