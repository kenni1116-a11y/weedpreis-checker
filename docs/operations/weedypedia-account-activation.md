# Weedypedia Kontoaktivierung und Vorfallbetrieb

Stand: 28. Juli 2026

## Status und Freigabegrenze

Produktive Registrierung und persönliche Schreibzugriffe bleiben deaktiviert,
bis jede Pflichtprüfung in diesem Dokument mit Datum, prüfender Person und
Beleg abgeschlossen wurde. Ein Build, eine Pages-Bereitstellung oder eine
erfolgreiche lokale Prüfung aktiviert kein produktives Konto.

Die lokale Supabase-Umgebung, Mailpit-Adressen unter `.invalid` und synthetische
Katalogdaten sind ausschließlich für Entwicklung und CI bestimmt.

## Browser- und Geheimnisgrenze

GitHub Pages erhält nur:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `PRIVACY_VERSION`
- `TERMS_VERSION`
- `COMMUNITY_VALUES_CONSENT_VERSION`
- `AUTH_REDIRECT_URL`

Der Pages-Workflow ordnet diese Werte den gleichnamigen `VITE_`-Variablen zu
und bricht bei fehlenden Werten oder einem `sb_secret_`-Präfix ab.

Der Secret-/Service-Role-Key darf ausschließlich in der serverseitigen
Laufzeit der Funktion `account-delete` vorhanden sein. Er darf niemals in:

- `VITE_*`-Variablen,
- GitHub-Pages-Artefakten,
- Browser-Logs oder Fehlerberichten,
- Playwright-Statusdateien oder Screenshots,
- E-Mails oder Supportnachrichten

erscheinen.

## Pflichtcheckliste vor Aktivierung

Jeder Punkt benötigt einen Beleglink oder ein abgelegtes Prüfartefakt.

- [ ] EU-Region des Supabase-Projekts bestätigt.
- [ ] Auftragsverarbeitungsvertrag und Unterauftragsverarbeiter freigegeben.
- [ ] Datenschutzerklärung, Nutzungsbedingungen und Wortlaut der
  18+-Bestätigung rechtlich freigegeben; aktive Versionskennungen stimmen mit
  der Datenbank überein.
- [ ] Die freiwillige Community-Einwilligung
  `weedypedia-community-values-2026-07-28` einschließlich Zweck,
  Widerruf, Export, Löschung und des Wortlauts „Etikett oder Laborbericht,
  nicht geschätzt“ ist rechtlich und datenschutzfachlich freigegeben.
- [ ] Eigener SMTP-Anbieter einschließlich Auftragsverarbeitung freigegeben.
- [ ] SMTP-Öffnungs- und Klicktracking deaktiviert.
- [ ] Datenminimierte Auth-E-Mails geprüft: Betreff und Vorschautext enthalten
  keine Angaben zu Cannabis, medizinischen Produkten, Sorten oder Beständen.
- [ ] Produktive Site URL und jede exakte GitHub-Pages-Callback-URL in Supabase
  allowlisted; keine Wildcard-Weiterleitung vorhanden.
- [ ] `Confirm Email` aktiviert.
- [ ] `Secure Email Change` mit Bestätigung an alter und neuer Adresse
  aktiviert.
- [ ] Passwortminimum von 12 Zeichen aktiv.
- [ ] Auth- und E-Mail-Ratenlimits geprüft.
- [ ] MFA für alle Supabase-/GitHub-Administrationskonten aktiviert.
- [ ] TOTP für App-Konten mit AAL2-Anhebung, Abmeldung und erneuter Anmeldung
  gegen Staging geprüft.
- [ ] Publishable Key ausschließlich im Browser; Secret Key ausschließlich in
  der Löschfunktion nachgewiesen.
- [ ] Cross-User-RLS-Prüfung mit zwei frischen Staging-Konten wiederholt:
  Nutzer B kann Profil und Bestand von Nutzer A weder lesen noch verändern.
- [ ] E-Mail wird weder in `api.profiles`, `api.inventory_items`,
  Wissens-/Analysedaten noch Telemetrie dupliziert.
- [ ] Konto- und Bestandswerte erscheinen nicht in URLs, Referrern, Logs oder
  Analytik.
- [ ] Wiederherstellung für bekannte und unbekannte E-Mail-Adresse zeigt
  denselben sichtbaren Text.
- [ ] E-Mail-Änderung verlangt aktuelles Passwort sowie Bestätigung an alter
  und neuer Adresse.
- [ ] Export verlangt eine höchstens fünf Minuten alte isolierte
  Passwortsitzung und bei verifiziertem TOTP zusätzlich AAL2.
- [ ] Exportstichprobe enthält nur Konto, Einwilligungsbelege, Bestand und die
  aktuellen eigenen Community-Blütenwerte; kein fremder Wert, öffentlicher
  exakter Zähler, Passwort, Token, Auth-Metadatum oder interne Rolle.
- [ ] Löschung verlangt normalisierten Benutzernamen, zweite Bestätigung,
  höchstens fünf Minuten alten Passwortnachweis und bei verifiziertem TOTP
  zusätzlich AAL2.
- [ ] Löschstichprobe bestätigt: Auth-Nutzer, Profil, Einwilligungen, Bestände
  und Community-Beiträge sind entfernt; erneute Anmeldung und API-Zugriff
  scheitern.
- [ ] Vier synthetische Beitragende veröffentlichen keinen Mittelwert; ab fünf
  erscheint ausschließlich das Band `5+`, niemals eine exakte Anzahl.
- [ ] Browserrollen können die Rohwerttabelle weder über REST noch über RPC
  oder RLS lesen.
- [ ] Der sechs-stündliche Aggregationsjob ist aktiv und sein letzter Lauf
  wurde geprüft.
- [ ] Backup erstellt und eine Wiederherstellung in eine getrennte
  Testumgebung erfolgreich geprüft.
- [ ] iPhone-WebKit-Prüfung bestätigt dunkle Statusleiste, Safe Areas,
  44-Pixel-Ziele, Tastaturfokus, reduzierte Bewegung und keinen horizontalen
  Seitenüberlauf.
- [ ] CI-Gates `test:db`, `test:functions`, `db lint`, Unit-Tests, Build und
  Playwright sind auf dem freizugebenden Commit grün.

## Lokale und Staging-Prüfung

Docker Desktop muss laufen. Danach:

```sh
pnpm exec supabase start
umask 077
pnpm exec supabase status -o env \
  | grep -E '^(API_URL|ANON_KEY)=' \
  > supabase/.temp/status.env
chmod 600 supabase/.temp/status.env
pnpm exec supabase db reset
pnpm test:db
pnpm test:functions
pnpm exec supabase db lint --schema api,catalog,private,public --level error --fail-on error
pnpm test
pnpm build
pnpm exec playwright install webkit
pnpm test:e2e
```

`supabase/.temp/status.env` bleibt ignoriert. Playwright liest daraus nur
`API_URL` und `ANON_KEY`. Der Test bricht vor dem Browserstart ab, wenn einer
der Werte fehlt. `SERVICE_ROLE_KEY` wird nicht an Vite oder den Browser
weitergegeben.

Aufzubewahrende Freigabebelege:

- Commit-SHA und vollständige CI-Links,
- pgTAP- und Functions-Ausgaben,
- Mailpit-Screenshots der neutralen Bestätigung, Wiederherstellung und
  E-Mail-Änderung,
- TOTP-Aktivierungs- und erneute Anmeldeprüfung,
- bereinigte Exportstichprobe,
- Lösch- und anschließender Loginfehler,
- Zwei-Nutzer-RLS-Nachweis,
- iPhone-WebKit-Trace und Screenshots.

Belege dürfen keine Passwörter, TOTP-Geheimnisse, Codes, Token oder Secret Keys
enthalten.

## Community-Blütenwerte und Aggregation

Community-Werte sind freiwillig, gelten ausschließlich für zugeordnete Blüten
und müssen als vollständiges THC-/CBD-Paar vom Etikett oder aus einem
Laborbericht stammen. Werte über 70 Prozent werden im Browser und in der
Datenbank abgewiesen. Pro Konto und kanonischer Sorte existiert nur der jeweils
aktuelle Beitrag; eine neue Angabe ersetzt die vorherige. Der freigegebene
Wortlaut und die aktive Einwilligungsversion lauten:

- `weedypedia-community-values-2026-07-28`
- „Keine Fantasiewerte. Bitte AUSSCHLIESSLICH die Werte des Labels oder eines
  Laborberichts angeben.“

Der produktive Einsatz benötigt vor Aktivierung eine erneute rechtliche und
datenschutzfachliche Prüfung dieses Wortlauts. Ein Scanner, Foto-Upload oder
eine automatische Etiketterkennung gehört nur zum Backlog und ist nicht Teil
dieser Freigabe.

Der Datenbankjob
`weedypedia-community-flower-averages-six-hourly` läuft bei Minute 17 alle
sechs Stunden. Konfiguration und letzte Läufe werden als Datenbank-Owner
geprüft:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'weedypedia-community-flower-averages-six-hourly';

select jobid, status, start_time, end_time, return_message
from cron.job_run_details
where jobid = (
  select jobid
  from cron.job
  where jobname = 'weedypedia-community-flower-averages-six-hourly'
)
order by start_time desc
limit 10;
```

Eine kontrollierte manuelle Aktualisierung darf ausschließlich der
Datenbank-Owner ausführen:

```sql
select private.refresh_community_flower_averages();
```

Der Download nach frischem Passwort- und gegebenenfalls TOTP-Nachweis enthält
nur die aktuellen Beiträge des anfragenden Kontos. Das Löschen des letzten
passenden Blüten-Bestandseintrags entfernt den Beitrag; die Kontolöschung
entfernt Bestand und Beiträge über serverseitige Fremdschlüssel-Kaskaden.

Produktive Backup-Aufbewahrung, Wiederherstellungsfenster und endgültige
Löschfristen müssen vor Aktivierung dokumentiert und rechtlich freigegeben
werden. Eine Löschung wirkt sofort im aktiven System. Bis zum Ablauf der
verbindlich festgelegten Backup-Aufbewahrung können verschlüsselte Sicherungen
noch Altstände enthalten; sie dürfen nicht als aktive Nutzerdaten
wiederhergestellt werden, ohne die zwischenzeitlichen Löschungen erneut
anzuwenden.

## Aktivierung

1. Freigabecheckliste von Datenschutz, Betrieb und Sicherheit gegenzeichnen
   lassen.
2. Staging-Datenbankmigrationen, Funktionen und exakte Callback-URLs prüfen.
3. Hosted Supabase Auth weiterhin geschlossen halten und Pages mit den sechs
   browser-sicheren Variablen bereitstellen.
4. Einen vollständigen Smoke-Test mit einem ausschließlich dafür vorgesehenen
   Konto durchführen.
5. Erst danach `enable_signup` und E-Mail-Signup serverseitig aktivieren.
6. Registrierung, Fehlerquote, E-Mail-Zustellung und RLS-Ablehnungen während
   des vereinbarten Beobachtungsfensters überwachen.

## Vorfallverfahren

### Verdacht auf Kontoaufzählung

1. Produktive Registrierung und Recovery-E-Mail-Versand drosseln oder
   deaktivieren.
2. Sichtbare Antworten, Statuscodes und Zeitunterschiede vergleichen.
3. Auth-Logs nach systematischen Adressversuchen prüfen, ohne Adressen in neue
   Analysesysteme zu kopieren.
4. Generische Antworten und Ratenlimits korrigieren, Staging erneut prüfen und
   erst nach Freigabe öffnen.

### Postfachkompromittierung

1. Betroffenes Konto global abmelden und Schreibzugriffe sperren.
2. E-Mail-Änderungen, Recovery und TOTP-Faktoren auf unautorisierte Vorgänge
   prüfen.
3. Sichere Identitätswiederherstellung außerhalb unverschlüsselter
   Supportnachrichten durchführen.
4. Passwort, E-Mail und Faktoren erneuern; alle Sitzungen widerrufen.

### Unautorisierter Bestandszugriff

1. Registrierung und persönliche Schreibzugriffe sofort deaktivieren.
2. Betroffene JWTs/Sitzungen widerrufen und RLS-Änderungen einfrieren.
3. Reproduzierbaren Zwei-Nutzer-Test sichern; keine Echtdaten in Tickets
   kopieren.
4. Umfang, Zeitraum und Meldepflicht mit Datenschutz und Incident Response
   bestimmen.
5. Korrektur erst nach erneuter Cross-User-Prüfung und Review ausrollen.

### Verdacht auf Offenlegung von Community-Rohwerten

1. Aggregat-Lesezugriff und Community-Schreibzugriffe sofort sperren.
2. Niemals einzelne THC-/CBD-Rohwerte, exakte Beitragendenzahlen oder
   Konto-Zuordnungen in Logs, Tickets, Screenshots oder Supportnachrichten
   kopieren.
3. REST-, RPC-, RLS- und AAL-Grenzen mit ausschließlich synthetischen Daten
   reproduzieren.
4. Betroffenen Zeitraum, Exporte und Aggregationsläufe mit Datenschutz und
   Incident Response bestimmen.
5. Erst nach erneuter Schwellenwert-, Zwei-Nutzer- und Exportprüfung öffnen.

### Token- oder Secret-Leak

1. Betroffenen Key oder Token sofort widerrufen beziehungsweise rotieren.
2. Pages-Artefakte, Actions-Logs, Playwright-Artefakte und Browser-Bundles
   prüfen und gegebenenfalls löschen.
3. Service-Role-Nutzung und Datenänderungen seit frühestmöglichem Leak-Zeitpunkt
   untersuchen.
4. Neue Keys erst nach Bestätigung der Browser-/Servergrenze ausrollen.

### Fehlgeschlagene oder teilweise Löschung

1. Konto sperren und weitere Schreibvorgänge verhindern.
2. Löschfunktion mit derselben Konto-ID idempotent erneut ausführen.
3. Auth, Profil, Einwilligungen, Bestand und Backups getrennt prüfen.
4. Nutzer transparent über Status und Aufbewahrungsfristen informieren.
5. Ursache beheben und Löschstichprobe wiederholen.

## Rollback

Rollback bedeutet:

1. Registrierung und persönliche Schreibzugriffe serverseitig deaktivieren.
2. Bestehende Konten nicht löschen und keine Migration rückwärts erzwingen.
3. Read-only-Zugriff nur beibehalten, wenn RLS und Vorfalllage ihn zulassen.
4. Pages auf den letzten geprüften Commit zurücksetzen.
5. SMTP-Versand bei E-Mail- oder Enumeration-Vorfällen pausieren.
6. Ursache in Staging beheben und die komplette Pflichtcheckliste erneut
   durchlaufen.

Für einen isolierten Community-Aggregations-Rollback führt der
Datenbank-Owner zusätzlich aus:

```sql
select cron.unschedule(jobid)
from cron.job
where jobname = 'weedypedia-community-flower-averages-six-hourly';

revoke select on api.community_flower_averages from authenticated;
```

Die privaten Funktionen zum Lesen, Ersetzen, Widerrufen und Exportieren der
eigenen Beiträge bleiben dabei verfügbar, damit Nutzerkontrolle und Löschung
erhalten bleiben. Die Rohwerttabelle wird nicht freigegeben und nicht
verändert.

Ein Rollback darf niemals durch Entfernen vorhandener Konten oder Bestände
„bereinigen“.
