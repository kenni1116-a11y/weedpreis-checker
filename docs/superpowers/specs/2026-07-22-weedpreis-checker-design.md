# Weedpreis Checker – Produkt- und Systemdesign

Stand: 22. Juli 2026

## 1. Ziel

Weedpreis Checker ist eine öffentliche, kostenlose und auf dem iPhone installierbare Progressive Web App (PWA). Sie ermöglicht Patientinnen und Patienten einen neutralen Preis- und Verfügbarkeitsvergleich für verschreibungspflichtiges Medizinalcannabis bei deutschen Apotheken.

Die erste Version konzentriert sich auf fünf bis zehn sorgfältig ausgewählte Apotheken. Verlässlichkeit, nachvollziehbare Quellen und ein transparenter Aktualitätsstatus sind wichtiger als eine möglichst große Zahl von Angeboten.

Die App ist ein Vergleichsdienst. Sie nimmt keine Rezepte entgegen, verkauft keine Produkte und wickelt keine Zahlungen ab.

## 2. Produktgrundsätze

- Medizinischer und neutraler Auftritt statt Deal- oder Konsumsprache
- Keine Therapie-, Wirkungs- oder Sortenempfehlungen
- Kein bezahltes Ranking und keine durch Vergütung beeinflusste Sortierung
- Keine Schätzung fehlender Preise, Packungsgrößen oder Bestände
- Jede Preisinformation zeigt Quelle und Aktualisierungszeit
- Exakte Rezeptsuche als Hauptweg, neutraler Katalog als zusätzlicher Weg
- Versand und Abholung sind gleichwertige Nutzungsarten
- Datenschutz durch Datenminimierung und lokale Speicherung

## 3. Rechtliche Leitplanken

Medizinalcannabis wird ausschließlich als verschreibungspflichtiges Arzneimittel behandelt. Die App weist darauf hin, dass die Abgabe nur durch eine Apotheke und gegen ärztliche Verschreibung erfolgt.

Die öffentliche Darstellung bleibt sachlich und vermeidet Rabattbanner, Konsumanreize, medizinische Heilsversprechen und aggressive Angebotsalarme. Begriffe wie „aktueller Preis“, „Preisvergleich“ und „Preisvorteil“ werden gegenüber werblicher Deal-Sprache bevorzugt.

Vor dem öffentlichen Start sind erforderlich:

- Prüfung des Produktauftritts durch eine auf Heilmittelwerbe- und Apothekenrecht spezialisierte Rechtsberatung
- Prüfung der Nutzungs- und Darstellungsrechte jeder Datenquelle
- Impressum und Datenschutzerklärung
- Dokumentierter Prozess zum Sperren oder Korrigieren einer Apotheke oder Datenquelle

Die Versandfunktion wird zentral konfigurierbar umgesetzt. Sie kann ohne App-Update deaktiviert werden, falls sich die Gesetzeslage ändert. Abholung und Apotheken-Botendienste bleiben technisch getrennt modelliert.

## 4. Zielgruppe und Zugang

Die MVP-Zielgruppe sind volljährige Patientinnen und Patienten in Deutschland, die bereits ein konkretes Rezeptprodukt suchen oder sachlich verfügbare Präparate vergleichen möchten.

Beim ersten Start erscheint eine einfache Altersbestätigung „Ich bin mindestens 18 Jahre alt“. Die Entscheidung wird nur lokal auf dem Gerät gespeichert. Es werden weder Geburtsdatum noch Identitätsnachweis erhoben. Minderjährige werden im MVP nicht unterstützt.

Ein Nutzerkonto ist nicht erforderlich. Favoriten und Altersbestätigung bleiben lokal auf dem jeweiligen Gerät.

## 5. Nutzerablauf

### 5.1 Einstieg

Nach der Altersbestätigung wählt der Nutzer Versand oder Abholung. Für Abholung kann er Ort oder Postleitzahl angeben. Diese Eingabe wird für die Suche verwendet, aber nicht dauerhaft gespeichert. Eine vorab importierte und lizenzrechtlich geprüfte Orts-/PLZ-Referenztabelle liefert dafür einen ungefähren Mittelpunkt; eine externe Geocoding-Anfrage pro Suche ist im MVP nicht erforderlich.

Anschließend stehen zwei Suchwege bereit:

1. Exakte Suche nach dem auf dem Rezept genannten Präparat oder der Sorte
2. Neutraler Katalog mit sachlichen Produktfiltern

### 5.2 Suche und Filter

Die Suche berücksichtigt Produktname, Hersteller und gebräuchliche Produktbezeichnungen. Der Katalog kann mindestens nach Darreichungsform, Hersteller, THC-/CBD-Werten, Preis, Verfügbarkeit sowie Versand oder Abholung gefiltert werden.

Die Filter geben keine medizinischen Empfehlungen ab und ordnen Produkte nicht nach erwarteter Wirkung.

### 5.3 Ergebnisliste

Ein aktueller Treffer zeigt:

- Produktbezeichnung, Hersteller und Darreichungsform
- THC-/CBD-Angaben, soweit die Quelle sie eindeutig liefert
- Apotheke
- Preis pro Gramm oder passende Preiseinheit
- Gesamtpreis für die gewählte Menge
- Versandkosten oder Abholentfernung
- Verfügbarkeit
- Datenherkunft und Zeitpunkt der letzten Aktualisierung
- Kennzeichnung einer exakten Produktübereinstimmung

Standardmäßig wird nach dem für die gewählte Menge relevanten Gesamtpreis sortiert. Bei Abholung werden Entfernung und Abholbarkeit berücksichtigt. Gesponserte Beziehungen haben keinen Einfluss auf die Reihenfolge.

Der Nutzer kann zur öffentlichen Seite oder zum vorhandenen Reservierungsweg der Apotheke wechseln. Bestellung, Rezeptübermittlung und Zahlung finden außerhalb der App statt.

### 5.4 Favoriten

Produkte und Apotheken können lokal als Favoriten gespeichert werden. Eine Synchronisation zwischen Geräten sowie Preis- oder Verfügbarkeitsalarme gehören nicht zum MVP.

## 6. Visuelle Richtung

Die PWA verwendet eine ruhige, dunkle Oberfläche mit grünen Akzenten, hoher Lesbarkeit und klarer visueller Hierarchie. Der Auftritt wirkt medizinisch-sachlich und nicht wie ein Freizeit- oder Lifestyle-Shop.

Auf dem iPhone bleibt die Statusleiste technisch sichtbar und wird optisch in denselben dunklen Hintergrund integriert. Ein echtes Ausblenden ist nicht Ziel der PWA.

Die Hauptnavigation besteht aus Suche, Favoriten und Informationen. Versand und Abholung werden als gut sichtbare, gleichwertige Umschaltung angeboten. Ergebnis-Karten priorisieren Gesamtpreis, Verfügbarkeit und Aktualität.

Der während der Planung verwendete Name „Weedpreis“ ist ein Arbeitstitel. Vor Veröffentlichung wird der Name zusammen mit der rechtlichen und markenrechtlichen Prüfung bewertet; die sachliche Produktpositionierung darf durch den Namen nicht unterlaufen werden.

## 7. Systemarchitektur

### 7.1 GitHub und GitHub Pages

GitHub enthält den Quellcode, die Spezifikationen und die automatischen Prüfabläufe. GitHub Pages veröffentlicht die statischen Dateien der installierbaren PWA.

GitHub Actions führt Tests, Build-Prüfungen und die Veröffentlichung aus. Zeitgesteuerte Preisimporte laufen nicht primär über GitHub Actions, damit verzögerte oder ausgefallene Workflow-Zeitpläne nicht die Datenaktualität bestimmen.

### 7.2 Supabase

Supabase wird in einer geeigneten EU-Region betrieben und ist der einzige erforderliche Hintergrunddienst des MVP. Es stellt bereit:

- PostgreSQL-Datenbank
- öffentliche, ausschließlich lesende Vergleichsschnittstelle
- private Import- und Prüftabellen
- Edge Functions für Quellenadapter und Normalisierung
- Cron-Zeitpläne für Aktualisierungen
- Protokolle für Import- und Laufzeitfehler
- PostGIS für indexierte Entfernungsberechnungen bei der Abholsuche

Es wird keine Supabase-Authentifizierung für Endnutzer benötigt. Administratorische und importierende Zugriffe bleiben serverseitig und getrennt von der öffentlichen Leseoberfläche.

### 7.3 Datenfluss

1. Ein zeitgesteuerter Lauf startet alle sechs Stunden.
2. Für jede aktive Apotheke lädt ein eigener Adapter einen vereinbarten Feed oder eine zulässig verwendete öffentliche Quelle.
3. Rohdaten werden gespeichert und auf Vollständigkeit sowie Format geprüft.
4. Produkte werden einer kanonischen Produktidentität zugeordnet.
5. Preise, Mengen, Versandregeln, Abholorte und Bestände werden normalisiert.
6. Plausibilitätsregeln markieren Abweichungen und Konflikte.
7. Nur freigegebene, aktuelle Datensätze gelangen in die öffentliche Leseansicht.
8. Die PWA lädt ausschließlich diese öffentliche Ansicht.

## 8. Datenmodell

Das logische Datenmodell enthält mindestens folgende Bereiche:

### Apotheken

- interne ID
- Name und öffentliche URL
- Anschrift und indexierter PostGIS-Standortpunkt
- angebotene Erfüllungsarten: Versand, Abholung, Botendienst
- Versandregeln und Mindestbestellwerte
- Quellenart und Nutzungsstatus
- Aktivierungs- und Prüfstatus

### Produkte

- kanonische Produkt-ID
- eindeutige und alternative Bezeichnungen
- Hersteller
- Darreichungsform
- THC-/CBD-Angaben
- passende Preiseinheit

### Angebote

- Apotheke und kanonisches Produkt
- Quellbezeichnung des Produkts
- Preis und Bezugsmenge
- berechneter Preis pro Einheit
- Versand- und Mengenkonditionen
- Verfügbarkeitsstatus
- Quelladresse
- Abruf- und Prüfzeitpunkt
- Qualitäts- und Veröffentlichungsstatus

### Importläufe und Prüffälle

- Quelle, Start, Ende und Ergebnis
- Anzahl gelesener, akzeptierter und verworfener Datensätze
- technische Fehler ohne geheime Zugangsdaten
- erkannte Preis- oder Produktkonflikte
- Bearbeitungs- und Freigabestatus

Preishistorien werden intern gespeichert, damit ungewöhnliche Sprünge erkannt und spätere transparente Entwicklungen ermöglicht werden. Eine öffentliche Verlaufsgrafik ist nicht Bestandteil des MVP.

Fremdschlüssel, eindeutige Produktzuordnungen und Wertebereiche werden durch Datenbank-Constraints abgesichert. Alle Fremdschlüssel sowie die räumlichen Standortpunkte erhalten passende Indizes. Die öffentliche Suche greift auf eine begrenzte, freigegebene Leseansicht zu und nicht auf die internen Importtabellen.

## 9. Datenqualität

- Alle aktiven Quellen werden alle sechs Stunden aktualisiert.
- Daten unter 24 Stunden gelten als aktuell.
- Ältere Angebote werden aus dem aktuellen Preisranking entfernt und höchstens als „zuletzt gesehen“ dargestellt.
- Fehlende oder mehrdeutige Werte werden nicht geschätzt.
- Unbekannte Produktzuordnungen werden nicht automatisch veröffentlicht.
- Starke Preisabweichungen, geänderte Packungsgrößen und plötzlich vollständig leere Bestände erzeugen einen Prüffall.
- Jede öffentliche Zeile bleibt auf eine konkrete Quelle und einen Abrufzeitpunkt zurückführbar.
- Eine einzelne fehlerhafte Quelle blockiert weder andere Apotheken noch die gesamte Aktualisierung.

## 10. Fehlerverhalten

Jeder Apothekenadapter arbeitet isoliert. Schlägt ein Import fehl, bleiben andere Quellen funktionsfähig. Der Fehler wird protokolliert und der Import nach einer begrenzten Wartezeit erneut versucht.

Bei veralteten Daten zeigt die App keinen scheinbar aktuellen Ersatzwert. Der letzte bekannte Preis wird aus dem Ranking entfernt und klar als historischer Fund gekennzeichnet. Eine Quelle oder Apotheke kann serverseitig vollständig deaktiviert werden.

Kann die PWA den Hintergrunddienst nicht erreichen, zeigt sie eine verständliche Fehlermeldung und bereits lokal vorhandene Ansichten nur mit ihrem tatsächlichen Aktualitätsstand. Sie erfindet keine Verfügbarkeit.

## 11. Datenschutz und Sicherheit

- Keine Nutzerkonten im MVP
- Keine Speicherung von Rezepten, Diagnosen oder Zahlungen
- Altersbestätigung und Favoriten ausschließlich lokal
- Orts- oder Postleitzahleingaben werden nicht dauerhaft gespeichert
- Kein personenbezogenes Analyse-Tracking im MVP
- Geheimnisse und Importzugänge niemals im PWA-Code oder öffentlichen GitHub-Inhalt
- Öffentliche Datenbankrolle erhält ausschließlich minimal erforderliche Leserechte
- Row Level Security auf allen über die Data API erreichbaren Tabellen und Ansichten
- Interne Tabellen liegen außerhalb der öffentlichen Schnittstelle
- Schreibzugriffe erfolgen nur über geschützte serverseitige Prozesse
- Sicherheits- und Leistungsprüfungen werden nach Datenbankänderungen ausgeführt

## 12. Prüfstrategie

Die aus dem Zettel-Projekt übernommene Arbeitsregel lautet: Eine Aufforderung „Prüfen“ oder „Überprüfen“ ist ein reiner Prüfauftrag. Der aktuelle Zustand wird untersucht und berichtet; Dateien werden nicht ohne zusätzlichen Änderungsauftrag bearbeitet.

Die automatische Prüfung umfasst:

### Einheiten- und Parsertests

- Preis- und Mengenumrechnung
- Gesamtpreis einschließlich Versandregeln
- Produktnormalisierung und Alias-Zuordnung
- Alters- und Aktualitätsstatus
- Behandlung fehlender, mehrdeutiger und ungültiger Werte

### Importtests

- Gespeicherte, unveränderliche Beispielantworten je Apotheke
- Erfolgreiche und fehlerhafte Importläufe
- Isolation einer ausgefallenen Quelle
- Erkennung von Layout- oder Schemaänderungen
- keine Veröffentlichung ungeprüfter Rohdaten

### Datenbank- und Sicherheitstests

- öffentliche Rolle kann nur freigegebene Vergleichsdaten lesen
- öffentliche Rolle kann keine Daten verändern
- interne Rohdaten und Protokolle sind nicht öffentlich erreichbar
- Row-Level-Security- und Leistungsberater ohne offene kritische Befunde

### PWA- und Oberflächentests

- Installation und Start auf aktuellen iPhones
- sichtbare, dunkel integrierte Statusleiste
- Versand- und Abholablauf
- PLZ-/Ortssuche und korrekte Entfernungssortierung ohne dauerhafte Speicherung der Eingabe
- exakte Suche, Katalog, Filter und Sortierung
- Favoriten und Altersbestätigung bleiben lokal
- verständliche Offline-, Leer- und Fehlerzustände
- barrierearme Kontraste, Fokusführung und ausreichend große Berührungsflächen

### Abschlussprüfung vor Veröffentlichung

- sauberer Git-Status und nachvollziehbarer Änderungsumfang
- alle automatischen Tests und Build-Prüfungen erfolgreich
- keine Syntax-, Format- oder Diff-Fehler
- keine Geheimnisse oder personenbezogenen Testdaten im Repository
- Quellen-, Rechts- und Datenschutzprüfung dokumentiert
- Stichprobenvergleich aktueller App-Preise mit den Originalquellen

## 13. Nicht Bestandteil des MVP

- Rezeptübermittlung oder Rezeptprüfung
- Bestellung, Reservierung innerhalb der App oder Bezahlung
- Nutzerkonten und geräteübergreifende Synchronisation
- Preis- und Verfügbarkeitsalarme
- medizinische Beratung oder Produktempfehlungen
- öffentliche Bewertungen von Produkten oder Apotheken
- bezahlte Platzierungen oder werbliche Rankings
- flächendeckendes Crawling ohne geprüfte Nutzungsgrundlage
- native App-Store-App
- öffentlicher Preisverlauf

## 14. Erfolgskriterien des MVP

Der MVP gilt als fachlich erfolgreich, wenn:

1. fünf bis zehn geprüfte Apotheken zuverlässig eingebunden sind,
2. Versand und Abholung getrennt und korrekt verglichen werden,
3. exakte Rezeptprodukte nachvollziehbar gefunden werden,
4. jeder aktuelle Preis Quelle und Aktualisierungszeit besitzt,
5. fehlerhafte oder veraltete Quellen keine irreführenden Rankings erzeugen,
6. die PWA auf einem aktuellen iPhone installiert und vollständig bedient werden kann,
7. keine Gesundheits-, Rezept- oder Kontodaten erhoben werden,
8. sämtliche automatischen und manuellen Freigabeprüfungen bestanden sind.
