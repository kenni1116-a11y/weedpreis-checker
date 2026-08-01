# Weedypedia

Eine mobile, installierbare Wissensoberfläche für nachvollziehbare Informationen
zu Cannabis-Sorten, Herkunft, Verwandtschaft und medizinischen Produkten. Die
Anwendung dient ausschließlich der Produktentwicklung und stellt keine
medizinische Beratung dar.

Der aktuelle Zwischenstand enthält das verifizierte pseudonyme Konto, optionale
TOTP-Absicherung, den privaten persönlichen Bestand, eine quellenbasierte
Sortensuche mit editierbarer Herkunft sowie freiwillige Community-Mittelwerte
für Blüten. Externe Aussagen werden unveränderlich gespeichert, separat geprüft
und erst danach atomar mit öffentlichen Nachweisen veröffentlicht. Private
Namen und Herkunftsangaben verändern diesen Katalog nicht. Die Oberfläche nutzt
vorerst weiterhin klar gekennzeichnete synthetische Daten. Die frühere
Preisvergleichsrichtung ist in der Anwendung nicht mehr erreichbar.

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

Community-Werte werden nur für zugeordnete Blüten und nur als vollständiges
THC-/CBD-Paar vom Etikett oder aus einem Laborbericht angenommen. Pro Konto und
Sorte bleibt ein aktueller Wert; veröffentlicht werden erst ab fünf
verschiedenen Konten ein auf eine Nachkommastelle gerundeter Mittelwert und ein
grobes Band (`5+`, `10+`, `25+`, `50+`). Rohwerte und exakte Beitragendenzahlen
bleiben privat. Preis, Rezept-, Gesundheits- und Konsumdaten sowie Scanner oder
Fotoerkennung gehören nicht zu diesem Stand.

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

Der Wissensgraph verwendet den geschlossenen Adaptervertrag Version 2. Er
unterscheidet `origin_population`, `cultivar`, `genetic_sample` und `product`.
Jede Version-2-Assertion hat eine unveränderte Trace-Angabe mit
`sourceLocator` und `extractionMethod` (`structured`, `manual` oder
`ai_assisted`). Akzeptierte Assertions tragen einen der sechs Zustände
`confirmed`, `single_source`, `disputed`, `historical`, `unknown` oder
`retracted`; der Zustand bleibt im veröffentlichten Nachweis erhalten.

Dokumentierte Abstammung, genetische Ähnlichkeit und Produktzuordnung sind
getrennte Ebenen. Genetische Relationen verbinden ausschließlich zwei
verschiedene `genetic_sample`-Knoten und sind niemals ein Elternschaftsnachweis.
Produktmessungen bleiben Eigenschaften des Produkts, nicht der Sorte. Nur der
Reviewer kann einen unveränderlichen Snapshot veröffentlichen; der Browser hat
nach Anmeldung ausschließlich lesenden Zugriff auf die `api`-Projektion und
keinen Zugriff auf `catalog` oder `private`.

Dieses Paket verbindet keine Live-Quelle, hinterlegt keine reale Sorte,
veröffentlicht keine KI-Ausgabe automatisch, plant keinen quellenspezifischen
Abruf und enthält weder veröffentlichte Bilder noch eine 3D-Visualisierung,
öffentlichen Pilot oder Profil-/Filteroberfläche. Der nächste Schritt ist eine
einzelne Quellenrechteentscheidung je Kandidat.

Reale Quellen werden nur einzeln nach dokumentierter Nutzungserlaubnis,
separater Bildrechteprüfung, synthetischem Vertragstest und einem
veröffentlichungsfreien Pilotimport angebunden. Das verbindliche Gate und der
Rollback-Ablauf stehen in
[docs/operations/weedypedia-source-onboarding.md](docs/operations/weedypedia-source-onboarding.md).
