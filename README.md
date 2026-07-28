# Weedypedia

Eine mobile, installierbare Wissensoberfläche für nachvollziehbare Informationen
zu Cannabis-Sorten, Herkunft, Verwandtschaft und medizinischen Produkten. Die
Anwendung dient ausschließlich der Produktentwicklung und stellt keine
medizinische Beratung dar.

Der aktuelle Zwischenstand enthält das verifizierte pseudonyme Konto, optionale
TOTP-Absicherung und den privaten persönlichen Bestand. Die Bereiche Entdecken
und Suche bleiben bis zur nächsten freigegebenen, quellenbasierten Datenetappe
als klar gekennzeichnete Vorschau sichtbar. Die frühere Preisvergleichsrichtung
ist in der Anwendung nicht mehr erreichbar.

## Lokal starten

Voraussetzungen: Node.js 24, pnpm 11.9.0 und Docker Desktop.

```sh
pnpm install --frozen-lockfile
cp .env.example .env.local
pnpm supabase:start
pnpm dev
```

Weitere Prüfungen:

```sh
pnpm test
pnpm build
pnpm check:platform
pnpm exec playwright install webkit
pnpm test:e2e
pnpm check
```

## Konto- und Datenschutzgrenze

Die erste Umsetzungsstufe verwendet eine verifizierte, nicht öffentliche
E-Mail-Adresse für Anmeldung, Wiederherstellung und Sicherheitsmeldungen. Der
sichtbare Benutzername ist pseudonym. E-Mail-Adressen werden nicht in Profil-,
Bestands-, Wissens- oder Analysedaten kopiert.

Lokale Auth-Nachrichten werden von Mailpit aufgefangen. Produktive
Registrierung bleibt deaktiviert, bis Datenschutzprüfung, EU-Datenregion,
Auftragsverarbeitung, SMTP, RLS sowie Export und Löschung freigegeben sind. Ein
Browser-Build allein aktiviert keine Registrierung; die Freigabe erfolgt erst
nach dem dokumentierten Betriebs- und Sicherheitstest über die serverseitige
Supabase-Konfiguration.

## Überprüfen

Wenn ein Auftrag nur „Überprüfen“ lautet, ist damit eine reine, lesende Prüfung des aktuellen Zustands gemeint. Dabei werden keine Dateien oder Daten verändert, sofern nicht ausdrücklich ein Änderungsauftrag folgt.

## Daten

Bis zum Wissensgraphen werden ausschließlich als Testdaten gekennzeichnete
synthetische Katalogreferenzen verwendet. Reale Quellen werden erst nach
dokumentierter Nutzungserlaubnis angebunden.
