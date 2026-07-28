# Weedypedia

Eine mobile, installierbare Wissensoberfläche für nachvollziehbare Informationen
zu Cannabis-Sorten, Herkunft, Verwandtschaft und medizinischen Produkten. Die
Anwendung dient ausschließlich der Produktentwicklung und stellt keine
medizinische Beratung dar.

Der aktuelle Zwischenstand enthält das verifizierte pseudonyme Konto, optionale
TOTP-Absicherung, den privaten persönlichen Bestand und die technische
Grundlage für eine quellenbasierte Sortensuche. Externe Aussagen werden
unveränderlich gespeichert, separat geprüft und erst danach atomar mit
öffentlichen Nachweisen veröffentlicht. Die Oberfläche nutzt vorerst weiterhin
klar gekennzeichnete synthetische Daten. Die frühere Preisvergleichsrichtung
ist in der Anwendung nicht mehr erreichbar.

## Lokal starten

Voraussetzungen: Node.js 24, pnpm 11.9.0 und Docker Desktop.

```sh
pnpm install --frozen-lockfile
cp .env.example .env.local
pnpm supabase:start
umask 077
pnpm exec supabase status -o env \
  | grep -E '^(API_URL|ANON_KEY)=' \
  > supabase/.temp/status.env
chmod 600 supabase/.temp/status.env
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

Die iPhone-E2E-Prüfung startet fail-closed: Ohne laufendes lokales Supabase und
eine frisch erzeugte `supabase/.temp/status.env` wird kein Browser geöffnet.
Playwright übernimmt daraus ausschließlich `API_URL` und `ANON_KEY`.

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

Die verbindliche Freigabe-, Rollback- und Vorfallcheckliste steht in
[docs/operations/weedypedia-account-activation.md](docs/operations/weedypedia-account-activation.md).
Bis sie vollständig gegengezeichnet ist, bleiben Hosted-Supabase-Signups und
persönliche Schreibzugriffe serverseitig deaktiviert.

## Überprüfen

Wenn ein Auftrag nur „Überprüfen“ lautet, ist damit eine reine, lesende Prüfung des aktuellen Zustands gemeint. Dabei werden keine Dateien oder Daten verändert, sofern nicht ausdrücklich ein Änderungsauftrag folgt.

## Daten

Bis zur Freigabe eines ersten Quellenadapters werden ausschließlich als
Testdaten gekennzeichnete synthetische Katalogreferenzen verwendet. Auch diese
durchlaufen Import, Review und Publisher; direkte öffentliche Seed-Schreibwege
gibt es nicht mehr.

Reale Quellen werden nur einzeln nach dokumentierter Nutzungserlaubnis,
separater Bildrechteprüfung, synthetischem Vertragstest und einem
veröffentlichungsfreien Pilotimport angebunden. Das verbindliche Gate und der
Rollback-Ablauf stehen in
[docs/operations/weedypedia-source-onboarding.md](docs/operations/weedypedia-source-onboarding.md).
