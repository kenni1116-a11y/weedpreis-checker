# Cannaflow–Supabase-Datenplattform

Stand: 24. Juli 2026

## 1. Ziel

Diese Phase ersetzt die synthetische Angebotsquelle der Weedpreis-PWA durch eine
geschützte, nachvollziehbare Datenplattform auf Supabase. Cannaflow ist die erste
Zielintegration, weil die dokumentierte Partner-API Produkte, Apotheken,
Verfügbarkeit sowie Versand- und Abholarten modelliert.

Die Plattform aktualisiert freigegebene Angebotsdaten alle sechs Stunden. Nur
eindeutig zugeordnete, plausible und aktuelle Datensätze gelangen in den
öffentlichen Preisvergleich.

Die PWA bleibt ein neutraler Vergleichsdienst. Sie verarbeitet keine Rezepte,
Bestellungen, Zahlungen, Diagnosen oder sonstigen Patientendaten.

## 2. Freigegebene Entscheidungen

- Cannaflow ist die erste Zielintegration.
- Supabase ist der einzige neue Hintergrunddienst.
- Ein Import läuft alle sechs Stunden.
- Die PWA hat ausschließlich lesenden Zugriff auf ein öffentliches Datenmodell.
- Partnerzugänge und interne Importdaten bleiben serverseitig.
- Daten unter 24 Stunden gelten als aktuell.
- Ältere Angebote werden aus dem Preisranking entfernt.
- Fehlende, mehrdeutige oder auffällige Werte werden nicht geschätzt.
- Versand und Abholung bleiben gleichwertige Vergleichswege.
- Ein Live-Import wird erst nach Partnerzugang und dokumentierter
  Datennutzungsfreigabe aktiviert.

## 3. Umfang

### Enthalten

- Supabase-Projektstruktur und versionierte Datenbankmigrationen
- getrennte interne, kanonische und öffentliche Datenbereiche
- Cannaflow-Adaptervertrag und unveränderliche Beispielantworten
- zeitgesteuerte, idempotente Importläufe
- Normalisierung von Apotheken, Produkten, Angeboten und Erfüllungsarten
- Qualitätsregeln, Prüffälle und Aktualitätsstatus
- PostGIS-basierte Abholsuche über PLZ-Mittelpunkte
- öffentliche, anonyme und ausschließlich lesende Vergleichsschnittstelle
- Anbindung der bestehenden PWA an diese Schnittstelle
- lokale Tests, Sicherheitsprüfungen und ein kontrollierter Aktivierungsweg

### Nicht enthalten

- Rezeptübermittlung und Nutzung der Cannaflow-Rezeptendpunkte
- Checkout, Reservierung, Bestellung oder Zahlung
- Nutzerkonten und Supabase Auth
- Speicherung genauer Nutzeradressen oder Suchverläufe
- medizinische Empfehlungen, Wirkungsrankings oder Diagnosen
- Preis- oder Verfügbarkeitsalarme
- öffentliche Preisverlaufsgrafiken
- Anbindung einer zweiten Infrastruktur oder einzelner Apothekenseiten

## 4. Quellenvertrag

Der Cannaflow-Adapter verwendet ausschließlich die für den Vergleich
erforderlichen lesenden Partnerendpunkte:

- Produktliste für Produktdaten, Preis und Verfügbarkeit
- Apothekenliste für öffentliche Apothekeninformationen und Erfüllungsarten
- bei schriftlich bestätigtem Umfang weitere lesende Metadatenendpunkte

Rezept-, Checkout-, Zahlungs-, Favoriten- und Webhookendpunkte sind nicht Teil
des Adapters.

Der Adapter besitzt einen stabilen internen Vertrag:

```text
fetchPharmacies(cursor) -> SourcePharmacyPage
fetchProducts(cursor, pharmacyIds?) -> SourceProductPage
```

Transportobjekte bleiben vom fachlichen Datenmodell getrennt. Der Adapter
liefert rohe Cannaflow-Felder an die Importpipeline; Normalisierung und
Veröffentlichungsentscheidungen liegen nicht im HTTP-Client.

Bis ein Partnerzugang vorliegt, werden ausschließlich versionierte,
unveränderliche Beispieldaten verwendet. Die CI ruft keine Live-API auf.

## 5. Systemarchitektur

```text
Cannaflow Partner-API
        |
        | geschützter Abruf alle sechs Stunden
        v
Supabase Edge Function
        |
        +--> interner Rohdaten- und Importbereich
        |
        +--> Normalisierung und Qualitätsregeln
        |
        +--> kanonische Vergleichsdaten
        |
        +--> atomar veröffentlichte Leseansicht
                         |
                         | anonymes SELECT
                         v
                  Weedpreis-PWA
```

### Cannaflow-Client

Der Client verantwortet Authentifizierung, Paginierung, Zeitüberschreitungen,
begrenzte Wiederholungen und die unveränderte Übergabe von Antworten. Er kennt
keine PWA-Sortierung und keine Supabase-Tabellen.

### Import-Orchestrierung

Eine zeitgesteuerte Edge Function startet einen Importlauf. Sie ruft jede
freigegebene Quelle isoliert ab, speichert Rohdaten, normalisiert Datensätze,
führt Qualitätsprüfungen aus und veröffentlicht nur einen vollständig
erfolgreichen Quellstand.

### Normalisierung

Kleine, getrennte Normalisierer bearbeiten:

- Apothekenidentität und öffentliche Kontaktdaten
- Produktidentität und Quellalias
- Preiseinheit und Geldbetrag
- Verfügbarkeit und Quellzeitpunkt
- Versand-, Same-Day- und Abholarten
- Standorte und PLZ-Mittelpunkte

### Öffentliches Lesemodell

Die PWA liest denormalisierte, freigegebene Angebots- und Apothekenzeilen. Das
Lesemodell enthält nur Felder, die öffentlich dargestellt werden dürfen. Es
wird nach einem erfolgreichen Import in einer Transaktion aktualisiert, damit
die PWA nie einen halbfertigen Datenstand sieht.

## 6. Datenmodell

### 6.1 Interner Bereich

Der interne Bereich liegt in einem nicht über die Data API angebotenen Schema.

#### `data_sources`

- interne ID und stabiler Quellenschlüssel
- Quellenart und Basisadresse
- Aktivierungsstatus
- dokumentierter Nutzungs- und Freigabestatus
- Importintervall und letzter erfolgreicher Lauf
- keine Zugangsschlüssel

#### `import_runs`

- Quelle, Start, Ende und Ergebnis
- gelesene, akzeptierte, verworfene und veröffentlichte Anzahl
- Fehlerklasse und sichere Fehlermeldung ohne Geheimnisse
- Verweis auf den vorherigen erfolgreichen Lauf

#### `raw_payloads`

- Importlauf, Endpunkt, Seitenkennung und Abrufzeit
- unveränderliche JSON-Antwort
- Prüfsumme zur Erkennung doppelter Inhalte

#### `review_cases`

- Quelle und betroffener Datensatz
- Regel, Schweregrad und erkannter Unterschied
- offen, freigegeben, verworfen oder erledigt
- Bearbeitungszeitpunkt und sachliche Begründung

### 6.2 Kanonischer Bereich

Der kanonische Bereich ist ebenfalls nicht direkt öffentlich erreichbar.

#### `pharmacies`

- interne ID und Cannaflow-ID
- öffentlicher Name und Ziel-URL
- Versand, Express, Same-Day und Selbstabholung
- Aktivierungs- und Veröffentlichungsstatus

#### `pharmacy_locations`

- Apotheke, öffentliche Anschrift und PLZ
- PostGIS-Punkt für räumliche Suche
- getrennte Kennzeichnung von Filiale und Liefergebiet

#### `products`

- kanonische Produkt-ID
- Produktname, Hersteller und Darreichungsform
- THC- und CBD-Werte mit Einheit
- Preiseinheit

#### `product_aliases`

- Quelle, Quellprodukt-ID und Quellbezeichnung
- kanonisches Produkt
- Zuordnungsart und Freigabestatus

#### `offers`

- Apotheke, Produkt und Quellprodukt
- Preis in kleinster Währungseinheit
- Bezugsmenge und Preiseinheit
- normalisierter Einheitspreis
- Verfügbarkeit
- Quellzeitpunkt, Abrufzeit und Qualitätsstatus

#### `delivery_rules`

- Apotheke und Erfüllungsart
- Versandbetrag, Freigrenze und Mindestwert, sofern eindeutig geliefert
- Gültigkeitszeit und Herkunft

Fehlen verlässliche Versandkosten, wird kein Gesamtpreis geschätzt. Ein solches
Versandangebot darf nicht im Gesamtpreisranking erscheinen, bis die
Partnerdaten den Betrag eindeutig liefern.

#### `offer_snapshots`

- Angebot, Preis, Bestand und Zeitpunkt
- interne Historie für Sprung- und Fehlererkennung

Die Historie ist nicht öffentlich.

### 6.3 Öffentliches API-Schema

Das exponierte Schema enthält ein denormalisiertes Lesemodell:

- `published_offers`
- `published_pharmacies`
- eine ausschließlich lesende PostGIS-Suchfunktion für Abholung

Das Lesemodell wird technisch als eigene veröffentlichte Tabellen umgesetzt.
Dadurch benötigt die öffentliche Rolle keine Rechte auf interne Basistabellen.
Row Level Security ist aktiviert. `anon` erhält ausschließlich `SELECT`; es
existieren keine öffentlichen Schreibpolicies.

## 7. Datenfluss

1. Supabase Cron startet die Importfunktion alle sechs Stunden.
2. Die Funktion legt einen Importlauf an.
3. Der Cannaflow-Client liest Apotheken und Produkte vollständig paginiert.
4. Jede Antwort wird unverändert mit Prüfsumme gespeichert.
5. Pflichtfelder, Typen, Wertebereiche und Beziehungen werden geprüft.
6. Quellprodukte werden einer freigegebenen kanonischen Produkt-ID zugeordnet.
7. Preise, Einheiten, Verfügbarkeit und Erfüllungsarten werden normalisiert.
8. Abweichungen erzeugen Prüffälle und werden nicht veröffentlicht.
9. Ein erfolgreicher Quellstand ersetzt das öffentliche Lesemodell atomar.
10. Der Importlauf speichert Ergebnis und Zähler.
11. Die PWA liest ausschließlich das öffentliche Lesemodell.

Wiederholte Ausführung desselben Importinhalts erzeugt keine doppelten
Apotheken, Produkte, Angebote oder Snapshots.

## 8. Datenqualität und Aktualität

### Veröffentlichungsbedingungen

Ein Angebot wird nur veröffentlicht, wenn:

- Quelle und Apotheke aktiv und freigegeben sind,
- Produkt und Apotheke eindeutig zugeordnet sind,
- Preis, Bezugsmenge und Einheit gültig sind,
- Verfügbarkeit einen bekannten Wert besitzt,
- Quell- und Abrufzeit vorhanden sind,
- keine blockierende Qualitätsregel verletzt ist.

### Aktualitätsregeln

- Ein Import wird alle sechs Stunden versucht.
- Daten unter 24 Stunden gelten als aktuell.
- Daten ab 24 Stunden werden aus dem Ranking entfernt.
- Ein letzter bekannter Preis darf höchstens klar als „zuletzt gesehen“
  dargestellt werden.
- Es wird kein neuer Zeitstempel erzeugt, wenn die Quelle nicht erfolgreich
  abgerufen wurde.

### Prüffälle

Mindestens folgende Ereignisse blockieren die automatische Veröffentlichung:

- unbekannte oder mehrdeutige Produktzuordnung
- fehlender oder nicht positiver Preis
- unbekannte Preiseinheit
- Wechsel der Bezugsmenge oder Einheit ohne eindeutige Erklärung
- Preisabweichung von mehr als 30 Prozent gegenüber dem letzten akzeptierten
  Snapshot derselben Apotheke, desselben Produkts und derselben Einheit
- plötzlich leerer Gesamtbestand einer zuvor aktiven Quelle
- unvollständige Seite oder geändertes Antwortschema

Der Schwellwert wird als Konfiguration versioniert. Eine spätere Änderung
benötigt dokumentierte Stichproben, passende Fixtures und einen eigenen
Review.

## 9. Versand und Abholung

### Versand

Der Vergleich verwendet nur statische oder partnerseitig eindeutig
übermittelte Versandregeln. Die PWA sendet keine genaue Nutzeradresse an
Cannaflow. Fehlen Versandkosten, zeigt die App keinen erfundenen Gesamtpreis und
nimmt das Angebot nicht in die Gesamtpreissortierung auf.

### Abholung

Die PWA wandelt eine eingegebene PLZ lokal über eine geprüfte Referenztabelle in
einen ungefähren Mittelpunkt um. Nur dieser Punkt wird für die
PostGIS-Entfernungssuche verwendet. Die Eingabe und das Suchergebnis werden
nicht dauerhaft gespeichert.

Same-Day-Lieferung bleibt fachlich von Selbstabholung getrennt und gehört nur
dann in den Vergleich, wenn Reichweite und Kosten eindeutig geliefert werden.

## 10. Fehlerverhalten und Betrieb

- Eine fehlerhafte Apotheke blockiert keine andere Apotheke.
- Ein technischer Abruffehler wird einmal mit begrenzter Wartezeit wiederholt.
- Ein fehlgeschlagener Lauf verändert das öffentliche Lesemodell nicht.
- Der letzte gültige Stand bleibt nur bis zur 24-Stunden-Grenze im Ranking.
- Zwei aufeinanderfolgende fehlgeschlagene Läufe erzeugen einen internen
  Prüffall.
- Geheimnisse, vollständige Header und mögliche personenbezogene Werte werden
  nicht protokolliert.
- Quelle oder Apotheke können ohne PWA-Deployment serverseitig deaktiviert
  werden.
- Ein einfacher interner Status zeigt letzten Erfolg, Dauer, Zähler und offene
  Prüffälle. Ein öffentliches Administrations-Dashboard ist nicht Teil dieser
  Phase.

## 11. Sicherheit und Datenschutz

- Cannaflow-Schlüssel liegen ausschließlich in Supabase Secrets.
- Weder Schlüssel noch `service_role` gelangen in Browsercode, GitHub oder
  Build-Artefakte.
- Nur das öffentliche API-Schema wird über die Data API angeboten.
- Alle Tabellen im exponierten Schema verwenden Row Level Security.
- `anon` darf veröffentlichte Zeilen lesen, aber nichts anlegen, ändern oder
  löschen.
- Interne und kanonische Schemas erhalten keine Rechte für `anon` oder
  `authenticated`.
- Es wird keine Supabase-Endnutzeranmeldung eingerichtet.
- Öffentliche SQL-Funktionen laufen mit Aufruferrechten.
- Es werden keine Rezepte, Diagnosen, Zahlungen, Nutzeradressen oder
  Suchverläufe gespeichert.
- Nach jeder Datenbankänderung werden Sicherheits- und Leistungsberater sowie
  negative Zugriffstests ausgeführt.

## 12. PWA-Anbindung

Die vorhandene `OffersRepository`-Grenze bleibt bestehen. Zwei Implementierungen
werden unterstützt:

- synthetisches Repository für lokale Entwicklung und deterministische Tests
- Supabase-Repository für freigegebene öffentliche Daten

Die Auswahl erfolgt über eine Build-Konfiguration. Fehlen Konfiguration oder
Live-Freigabe, bleibt die PWA im klar gekennzeichneten Testdatenmodus.

Die Oberfläche ergänzt:

- Quelle und tatsächlichen Aktualisierungszeitpunkt
- klaren Status für aktuell, veraltet und nicht verfügbar
- Fehlerzustand bei nicht erreichbarer Vergleichsschnittstelle
- Ausschluss unvollständiger Versandangebote aus dem Gesamtpreisranking

Favoriten und Altersbestätigung bleiben unverändert lokal.

## 13. Prüfstrategie

### Adapter- und Einheitstests

- versionierte Cannaflow-Fixtures für Produkte und Apotheken
- Paginierung, leere Seiten und doppelte Datensätze
- Zeitüberschreitung, HTTP-Fehler und Schemaänderung
- Preis-, Mengen- und Einheitenumrechnung
- Produktalias und unbekannte Zuordnung
- Versand- und Abholarten

### Importtests

- erfolgreicher vollständiger Lauf
- idempotente Wiederholung
- atomare Veröffentlichung
- Isolation einer fehlerhaften Apotheke
- fehlgeschlagener Lauf verändert öffentliche Daten nicht
- 24-Stunden-Aktualitätsgrenze
- Erzeugung und Auflösung von Prüffällen

### Datenbank- und Sicherheitstests

- Fremdschlüssel, Eindeutigkeit und Wertebereiche
- Indizes für Fremdschlüssel, Aktualität und PostGIS
- `anon` kann nur veröffentlichte Daten lesen
- `anon` kann keine Daten schreiben
- interne und kanonische Tabellen sind für öffentliche Rollen unerreichbar
- öffentliche Funktionen laufen mit Aufruferrechten
- Supabase Sicherheits- und Leistungsberater ohne offene kritische Befunde

### PWA- und End-to-End-Tests

- Versand und Abholung mit Supabase-Testdaten
- Gesamtpreis nur bei vollständigen Kosten
- PLZ-Entfernungssuche ohne dauerhafte Speicherung
- aktuelle und veraltete Kennzeichnung
- Fehler-, Leer- und Offlinezustände
- lokale Favoriten bleiben funktionsfähig
- iPhone-WebKit-Ablauf bleibt vollständig bedienbar

Live-Partnerzugriffe laufen nicht in der öffentlichen CI.

## 14. Aktivierungsweg

1. Schema, Migrationen und lokale Testdaten werden erstellt.
2. Cannaflow-Vertrag und Adapter werden gegen Fixtures umgesetzt.
3. Die PWA wird gegen ein lokales Supabase-Lesemodell geprüft.
4. Cannaflow-Partnerzugang und Datennutzungsfreigabe werden dokumentiert.
5. Zugangsdaten werden ausschließlich in einer nicht öffentlichen
   Supabase-Umgebung hinterlegt.
6. Mindestens acht aufeinanderfolgende Importläufe über 48 Stunden werden
   geprüft.
7. Preise, Verfügbarkeit und Versandregeln werden stichprobenartig mit der
   Partnerquelle verglichen.
8. Erst danach wird die Quelle für die öffentliche PWA aktiviert.

## 15. Erfolgskriterien

Die Phase ist abgeschlossen, wenn:

1. Cannaflow-Produkte und -Apotheken reproduzierbar importiert werden,
2. wiederholte Importe keine Duplikate erzeugen,
3. Versand und Abholung fachlich getrennt und nachvollziehbar sind,
4. jeder öffentliche Preis Quelle und Aktualisierungszeit besitzt,
5. veraltete oder auffällige Daten nicht im Ranking erscheinen,
6. öffentliche Rollen keine internen Daten lesen oder verändern können,
7. die PWA auf dem iPhone mit dem Supabase-Lesemodell funktioniert,
8. Live-Daten nur nach dokumentierter Partner- und Nutzungsfreigabe aktiv sind.

## 16. Referenzen

- Cannaflow API-Übersicht:
  https://cannaflow.readme.io/reference/version
- Cannaflow Produktliste:
  https://cannaflow.readme.io/reference/products-list
- Cannaflow Apothekenliste:
  https://cannaflow.readme.io/reference/pharmacies-list
- Supabase Row Level Security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase geplante Edge Functions:
  https://supabase.com/docs/guides/functions/schedule-functions
- Supabase PostGIS:
  https://supabase.com/docs/guides/database/extensions/postgis

Vor der Umsetzung werden Supabase-Changelog und aktuelle Dokumentation erneut
geprüft, weil sich CLI-, Cron-, Data-API- und Edge-Function-Konventionen ändern
können.
