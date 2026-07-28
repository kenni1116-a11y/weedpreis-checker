# Weedypedia – Bestandssuche, private Herkunft und Community-Werte

Stand: 28. Juli 2026

## 1. Ziel und Einordnung

Diese Spezifikation ergänzt das bestehende Weedypedia-Produktdesign. Sie
beschreibt:

- ein Suchfeld für Sorten und Blütenprodukte im persönlichen Bestand,
- automatisch vorgeschlagene, privat editierbare Ursprungssorten,
- freiwillige Community-Mittelwerte für THC und CBD,
- sowie die frühzeitige Vorbereitung externer Quellenadapter.

Belegte Wissensdaten, persönliche Bestandsdaten und Community-Beiträge bleiben
technisch und visuell getrennt. Keine Community-Angabe verändert eine
veröffentlichte Quellenaussage oder einen belegten Durchschnitt.

## 2. Bestandsformular

### 2.1 Suche und freie Eingabe

Das bisherige Auswahlmenü „Sorte oder Produkt“ wird durch ein Suchfeld mit
Vorschlägen ersetzt. Die Suche berücksichtigt kanonische Sortennamen, belegte
Aliase und zugeordnete Blütenprodukte.

Ein Suchtreffer nennt:

- den gefundenen Namen,
- Sorte oder Blütenprodukt,
- und den Grund des Treffers, etwa kanonischer Name, Alias oder
  Produktzuordnung.

Der vom Nutzer eingegebene Name bleibt erhalten. Eine abweichende kanonische
Schreibweise erscheint als Vorschlag und ersetzt die Eingabe nicht unbemerkt.

Ist kein passender Katalogeintrag vorhanden, darf der Name als privater
Bestandseintrag gespeichert werden. Ein solcher Eintrag:

- besitzt keine öffentliche Weedypedia-Zuordnung,
- verändert weder Katalog noch Wissensgraph,
- und ist nicht für Community-Werte freigabefähig.

### 2.2 Private Ursprungssorten

Nach Auswahl einer bekannten Sorte oder eines zugeordneten Blütenprodukts
erscheinen zwei kleinere Felder:

- Ursprung 1
- Ursprung 2

Belegte Eltern- oder Ursprungsaussagen füllen diese Felder vor. Bei mehreren
widersprüchlichen Aussagen verwendet die Vorbelegung nur die als bevorzugt
veröffentlichte Beziehung und kennzeichnet, dass weitere Aussagen im
Sortenprofil vorhanden sind.

Beide Felder bleiben editierbar. Eine Änderung:

- gilt ausschließlich für den persönlichen Bestandseintrag,
- verändert keine kanonische Sorte und keine Quellenaussage,
- wird nicht als Community-Korrektur veröffentlicht,
- und darf leer bleiben.

Für freie, nicht zugeordnete Namen beginnen beide Felder leer.

### 2.3 Reihenfolge und Pflichtfelder

Das Formular zeigt von oben nach unten:

1. Suchfeld „Sorte oder Produkt“
2. Ursprung 1 und Ursprung 2 nebeneinander
3. belegte THC-/CBD-Werte, sofern vorhanden
4. kompakter Community-Mittelwert, sofern verfügbar
5. Menge und Einheit
6. Charge, Haltbarkeit, Lagerort und Notiz
7. freiwillige Community-Eingabe

Menge und Einheit bleiben Pflichtfelder. Herkunft und Community-Beitrag sind
freiwillig.

## 3. Community-Beitrag

### 3.1 Umfang

Community-Werte gelten in Version 1 ausschließlich für Cannabisblüten. Andere
Darreichungsformen sowie mg/g-, mg/ml- oder dosisbezogene Angaben sind
ausgeschlossen.

Ein Beitrag enthält:

- kanonische Weedypedia-Sorten-ID,
- THC in Prozent,
- CBD in Prozent,
- Quellenart `label` oder `laboratory`,
- aktuelle Einwilligungsfassung,
- Erstellungs- und Änderungszeitpunkt.

THC und CBD werden als exakte Dezimalwerte zwischen 0 und 100 Prozent
gespeichert. Punkt und Komma sind bei der Eingabe zulässig; gespeichert wird
normalisiert mit höchstens zwei Nachkommastellen. Angaben wie „unter 1 %“
werden in Version 1 nicht in einen Mittelwert umgewandelt. Ist kein exakter
THC- oder CBD-Wert vorhanden, kann der private Bestand trotzdem ohne
Community-Beitrag gespeichert werden.

Vor dem Speichern bestätigt der Nutzer verpflichtend:

> Die Angaben stammen vom Etikett oder aus einem Analyse-/Laborwert und sind
> nicht geschätzt.

Zusätzlich ist ein ausdrückliches Opt-in für genau diesen Beitrag erforderlich.
Ein Foto oder Dokumenten-Upload ist nicht Teil von Version 1.

### 3.2 Zuordnung und Gewichtung

Pro Konto und kanonischer Sorte existiert genau ein aktueller Beitrag.

- Bei direkter Sortenauswahl wird diese Sorte verwendet.
- Ein bekanntes Blütenprodukt verwendet seine belegte Sortenzuordnung.
- Mehrere Bestandspositionen derselben Sorte erhöhen das Gewicht nicht.
- Eine neue Eingabe ersetzt den bisherigen Beitrag dieses Kontos atomar.
- Es existiert keine anwendungsseitige Historientabelle alter Werte.

Ein Beitrag ist von der Bestandszeile getrennt, wird aber über deren Formular
erstellt. Entfernt der Nutzer sein Opt-in oder löscht seinen letzten
Bestandseintrag der Sorte, wird auch sein Community-Beitrag entfernt. Die
Kontolöschung entfernt alle Beiträge über die bestehende Löschkaskade.

### 3.3 Feedback und Fehler

Nach erfolgreicher Speicherung erscheint:

> Gespeichert. Der Community-Mittelwert wird später aktualisiert.

Bestand und Beitrag werden gemeinsam bestätigt, aber getrennt gespeichert. Ist
die Bestandsspeicherung erfolgreich und die Beitragsspeicherung nicht, zeigt
die Oberfläche ausdrücklich:

> Der Bestand wurde gespeichert. Der Community-Beitrag konnte nicht
> übernommen werden.

Ein Beitrag wird nicht stillschweigend verworfen. Die Oberfläche bietet einen
gezielten erneuten Versuch, ohne den Bestand doppelt anzulegen.

## 4. Community-Mittelwert

### 4.1 Berechnung

Der sichtbare Mittelwert ist das arithmetische Mittel der jeweils aktuellen
Beiträge unterschiedlicher Konten für dieselbe kanonische Sorte. THC und CBD
werden auf eine Nachkommastelle gerundet.

Die Veröffentlichung wird höchstens alle sechs Stunden gesammelt neu
berechnet. Das unmittelbare Speichern eines Beitrags verändert den sichtbaren
Mittelwert nicht synchron. Dadurch kann ein Nutzer durch wiederholte Änderungen
nicht direkt auf andere Einzelwerte zurückrechnen.

Ein Mittelwert wird nur veröffentlicht, wenn mindestens fünf unterschiedliche
Konten einen vollständigen THC-/CBD-Beitrag besitzen. Sinkt die Zahl darunter,
wird die veröffentlichte Zusammenfassung beim nächsten Lauf entfernt.

Die genaue Anzahl wird nicht ausgegeben. Stattdessen erscheint:

- `5+` für 5 bis 9 Beiträge
- `10+` für 10 bis 24 Beiträge
- `25+` für 25 bis 49 Beiträge
- `50+` ab 50 Beiträgen

Jede Zusammenfassung enthält intern den Berechnungszeitpunkt. Die Oberfläche
kennzeichnet die Werte immer als Community-Mittelwert und niemals als
Laborwert, Herstellerangabe oder belegten Sortendurchschnitt.

### 4.2 Darstellung

Im Bestandsformular erscheinen zwei kompakte Ebenen:

1. belegte Sortenwerte
2. Community-Mittelwert

Die Community-Ebene verwendet:

- ein dominantes `Ø`,
- unmittelbar danach ein Drei-Personen-Piktogramm,
- die Bezeichnung „Community-Mittelwert“,
- THC und CBD in einer flachen Zweierreihe,
- sowie die abgestufte Beitragsanzahl.

Das Mittelwertzeichen steht nicht zusätzlich hinter THC oder CBD. Beide
Werteblöcke verwenden kleine Typografie und geringe Innenabstände, damit Menge
und Einheit unmittelbar anschließen.

Im Sortenprofil erscheint nur eine dezente Sekundärzeile unter den belegten
Werten, beispielsweise:

`Ø [Community] THC 21,3 % · CBD 0,7 % · 25+`

Suchergebnisse und Übersichtslisten zeigen in Version 1 keinen
Community-Mittelwert. Unter fünf Beiträgen erscheint:

> Noch nicht genügend Community-Werte.

## 5. Daten- und Sicherheitsarchitektur

### 5.1 Private Beiträge

Rohbeiträge liegen in einer eigenen privaten Tabelle und nicht in
Bestandszeilen oder öffentlichen Katalogtabellen. Die fachliche Eindeutigkeit
lautet `(user_id, cultivar_id)`.

Browserzugriffe erfolgen nur über eng begrenzte authentifizierte Funktionen:

- eigenen Beitrag anlegen oder ersetzen,
- eigenen Beitrag entfernen,
- eigenen aktuellen Beitrag für das Formular lesen.

Die Funktionen:

- verwenden ausschließlich die serverseitig ermittelte Konto-ID,
- prüfen die kanonische Sortenzuordnung und die Blütenform,
- prüfen Werte, Quellenart und Einwilligung,
- respektieren die bestehende AAL2-Pflicht bei aktiviertem TOTP,
- verwenden einen festen `search_path`,
- und geben keine fremden Rohwerte oder Nutzerkennungen zurück.

Direkte Tabellenrechte für `anon` oder `authenticated` werden nicht vergeben.

### 5.2 Veröffentlichte Aggregate

Ein geplanter Serverlauf liest private Beiträge, berechnet nur ausreichend
große Aggregate und ersetzt ein separates veröffentlichtes Lesemodell atomar.
Das öffentliche Modell enthält ausschließlich:

- Sorten-ID,
- gerundeten THC-Mittelwert,
- gerundeten CBD-Mittelwert,
- Beitragsstufe,
- Berechnungszeitpunkt.

Es enthält keine Konto-ID, keinen exakten Zähler, keine Quellenart einzelner
Beiträge und keine Bestandsreferenz. Das PWA-Lesemodell besitzt ausschließlich
Leserechte.

### 5.3 Datenschutzgrenzen

- Die Teilnahme ist freiwillig und pro Beitrag ausdrücklich bestätigt.
- Community-Werte werden nicht für Werbung, Nutzerprofile, Empfehlungen,
  Rankings oder Therapieaussagen verwendet.
- Ein Nutzer kann seinen Beitrag entfernen und durch einen neuen ersetzen.
- Export und Löschung berücksichtigen den eigenen Beitrag.
- Backups und technische Aufbewahrungsfristen bleiben Bestandteil der
  Datenschutz- und Löschdokumentation; die App behauptet keine sofortige
  physische Entfernung aus bereits erstellten Backups.
- Exakte Zähler und Rohwerte erscheinen weder in Browserantworten noch
  Telemetrie oder Fehlerberichten.

## 6. Vorbereitung externer Datenquellen

Die Quellenarchitektur wird jetzt stabilisiert, produktive Fremdquellen werden
jedoch einzeln und erst nach Freigabe aktiviert.

### 6.1 Gemeinsamer Adaptervertrag

Jeder Quellenadapter liefert:

- eindeutigen Quellen- und externen Datensatzschlüssel,
- Abrufzeit und Quellversion,
- unveränderte Rohfassung oder dokumentierte Prüfsumme,
- normalisierte Aussagen zu Namen, Beziehungen, Produkten oder Messungen,
- Gültigkeits- und Zeitangaben,
- Lizenz- und Nutzungsstatus,
- sowie Fehler und Fortsetzungscursor.

Quellenspezifische Feldnamen gelangen nicht in UI-Komponenten oder kanonische
Tabellen. Ein Adapter darf nur neue Quellenversionen und Prüffälle erzeugen; er
veröffentlicht keine Aussagen direkt.

### 6.2 Quellenregister und Prüffluss

Vor Aktivierung besitzt jede Quelle:

- Besitzer oder Herausgeber,
- Zugriffsmethode und erlaubte Frequenz,
- Lizenz- und Speicherberechtigung,
- Darstellungs- und Namensnennungsregeln,
- Bildrechte getrennt von strukturierten Daten,
- Vertrauensklasse,
- verantwortliche Prüfung,
- Aktivierungs- und Sperrstatus.

Importe sind idempotent. Unbekannte Aliase, widersprüchliche Abstammungen,
auffällige Messwerte und gelöschte Quelldaten erzeugen Prüffälle. Ein
fehlgeschlagener Adapter verändert den letzten veröffentlichten Stand nicht.

### 6.3 Erste Pilotquellen

Die ersten Adapter bleiben klein und lesend:

- Wikidata für CC0-basierte externe IDs, Basisnamen und einzelne Aliase; nicht
  als alleiniger Abstammungsbeleg.
- Crossref oder Europe PMC für DOI-, Publikations- und Forschungsmetadaten;
  nicht für automatisch abgeleitete Sortenwahrheiten.
- BfArM/PharmNet.Bund nur nach gesonderter Prüfung von Zugriff,
  Datenumfang und Weiterverwendungsrechten.

Breeder-, Hersteller-, Labor- und kommerzielle Sortendaten werden nur nach
schriftlich dokumentierter Nutzungsfreigabe produktiv angebunden. Scraping,
Bildübernahme und automatisierte Weiterveröffentlichung ohne Freigabe sind
ausgeschlossen.

## 7. Tests und Abnahmekriterien

### 7.1 Suche und private Herkunft

- Katalogname, Alias und Produktname liefern erklärbare Vorschläge.
- Freie Eingaben lassen sich privat speichern.
- Bekannte Abstammung füllt zwei Ursprungsfelder.
- Nutzeränderungen bleiben nach Neuladen erhalten und verändern den Katalog
  nicht.
- Nicht zugeordnete Einträge bieten keinen Community-Beitrag an.

### 7.2 Community-Beiträge

- Ohne Opt-in oder Quellenbestätigung wird kein Beitrag gespeichert.
- Ein zweiter Beitrag desselben Kontos und derselben Sorte ersetzt den ersten.
- Mehrere Bestandszeilen erzeugen kein mehrfaches Gewicht.
- Fremde Rohbeiträge sind über REST, RPC und RLS nicht les- oder veränderbar.
- TOTP-geschützte Konten benötigen AAL2.
- Entfernen des Opt-ins, Löschen des letzten passenden Bestands und
  Kontolöschung entfernen den Beitrag.
- Teilfehler zwischen Bestand und Beitrag erzeugen eine eindeutige,
  wiederholbare Oberfläche.

### 7.3 Aggregate

- Vier Konten veröffentlichen keinen Mittelwert.
- Fünf Konten veröffentlichen Mittelwerte und `5+`.
- Grenzwerte 10, 25 und 50 wechseln nur die Beitragsstufe.
- Exakte Zähler und Rohwerte fehlen im veröffentlichten Modell.
- Neue Beiträge ändern das sichtbare Aggregat erst nach dem Berechnungslauf.
- Sinkt die Zahl unter fünf, verschwindet das Aggregat.
- Quellenwerte und Community-Werte bleiben in UI und Datenmodell getrennt.

### 7.4 Quellenadapter

- Vertragsprüfungen verwenden ausschließlich synthetische Fixtures.
- Doppelte Rohfassungen erzeugen keine doppelten Aussagen.
- Schemaänderungen und Zeitüberschreitungen isolieren nur den betroffenen
  Adapter.
- Unbekannte Zuordnungen werden nicht automatisch veröffentlicht.
- Jede veröffentlichte Aussage bleibt auf Quelle und Quellversion
  zurückführbar.

## 8. Nicht Bestandteil von Version 1

- Kamera-, OCR-, Barcode- oder Etikettscanner
- Foto- und Dokumenten-Uploads
- Community-Werte für Extrakte, Öle oder andere Darreichungsformen
- produktbezogene Community-Mittelwerte
- öffentliche Einzelbeiträge, Bewertungen, Kommentare oder Ranglisten
- unmittelbare Neuberechnung nach einer Eingabe
- automatische Korrektur der Sortendatenbank durch Nutzerangaben
- breite oder ungeprüfte Übernahme kommerzieller Sortendatenbanken

Der Scanner bleibt als spätere Ausbaustufe vorgemerkt. Eine spätere
Scanner-Spezifikation muss Einwilligung, lokale Vorverarbeitung, Bildlöschung,
OCR-Fehler, Einheiten und Nachweisqualität neu bewerten.

## 9. Referenzen für die Pilotquellen

- [Wikidata-Lizenz](https://www.wikidata.org/wiki/Wikidata%3ALicensing)
- [Wikidata-Datenzugriff](https://www.wikidata.org/wiki/Help%3AData_access)
- [Crossref REST API](https://www.crossref.org/documentation/retrieve-metadata/rest-api/)
- [Europe PMC REST API](https://europepmc.org/RestfulWebService)
- [BfArM zu PharmNet.Bund](https://www.bfarm.de/DE/Arzneimittel/Zulassung/Zulassungsrelevante-Themen/e-Submission/Pharmnet-Bund.html)
