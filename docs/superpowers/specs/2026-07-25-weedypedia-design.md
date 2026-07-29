# Weedypedia – Produkt- und Systemdesign

Stand: 25. Juli 2026

## 1. Ziel

Weedypedia ist eine internationale, auf dem iPhone installierbare
Wissens-PWA zu Cannabis-Sorten, ihrer Herkunft, ihren Verwandtschaftsbeziehungen
und den daraus angebotenen medizinischen Produkten.

Der Schwerpunkt liegt auf nachvollziehbarem Wissen, nicht auf Preisen. Die App
verbindet Sortensuche, Stammbaum, horizontalen Zeitstrahl, Produktdaten und eine
persönliche Bestandsübersicht. Jede sichtbare Sachangabe bleibt auf eine konkrete
Quelle und Quellenversion zurückführbar.

Diese Spezifikation ersetzt für die weitere Produktentwicklung die bisherige
Preisvergleichsrichtung. Die bestehenden Preisvergleichs-Spezifikationen bleiben
als historische Dokumente erhalten.

## 2. Produktgrundsätze

- Herkunft, Beziehungen und Produktdaten sind gleichwertige Wissensbereiche.
- Keine Aussage wird ohne Quelle oder ausdrücklich gekennzeichneten Belegstatus
  dargestellt.
- Widersprüchliche Quellen werden sichtbar gemacht und nicht zu einem
  scheinbar eindeutigen Ergebnis zusammengeführt.
- Genetische Nähe, behauptete Elternschaft und historisch überlieferte
  Kreuzungen bleiben unterschiedliche Beziehungstypen.
- Neue Daten ergänzen eine Versionierung; sie überschreiben keine Historie.
- Preise sind kein Schwerpunkt und gehören nicht zur ersten Version.
- Die App gibt keine Therapie-, Dosierungs-, Wirkungs- oder Kaufempfehlungen.
- Sativa, Indica und Hybrid bleiben als vertraute traditionelle Navigation
  erhalten. Chemotyp, Genotyp, Terpene und Laborwerte werden getrennt davon
  dargestellt.
- Bilder erscheinen nur mit dokumentierter Quelle und zulässigem
  Nutzungsrecht.

## 3. Umfang der ersten Version

### Enthalten

- verpflichtendes, pseudonymes Benutzerkonto mit minimalen Angaben
- internationale Sortensuche einschließlich belegter Aliase
- Sativa-, Indica- und Hybrid-Übersichten
- Deutschland als Filter für zugeordnete medizinische Produkte
- Einzelansicht einer Sorte mit Gesten und sichtbaren Tipp-Alternativen
- Vorfahren, Nachfahren und weitere belegte Beziehungen
- horizontaler Herkunfts- und Produktzeitstrahl
- medizinische Produkte und konkrete Chargen- oder Analysedaten
- durchschnittliche THC-/CBD- und weitere Werte, sofern sie aus vergleichbaren
  Datensätzen transparent berechnet werden können
- Herkunft, Breeder, traditionelle Einordnung und dokumentierte historische
  Ereignisse
- belegte Zeitspanne von Aussaat oder Keimung bis Ernte, sofern eine Quelle
  diese Angabe eindeutig liefert
- tägliche Quellenaktualisierung und gezielte Aktualisierung auf Anfrage
- Quellenanzeige, Gültigkeitszeitraum, Abrufdatum und Belegstatus
- persönliche Bestandsübersicht im Profil

### Nicht enthalten

- Preisvergleich, Angebotsranking oder bezahlte Platzierungen
- Bestellung, Reservierung, Rezeptübermittlung oder Zahlung
- Diagnose-, Rezept-, Therapie- oder Dosierungsdaten
- Konsumtagebuch oder Verbrauchshistorie
- Wirkungs- und Therapieempfehlungen
- Nutzerbewertungen, Kommentare oder soziale Funktionen
- öffentliche Nutzerbestände
- KI-basierte Anbieter- oder Verfügbarkeitsrecherche
- Anbauanleitungen, Ertragsoptimierung oder sonstige schrittweise
  Kultivierungsberatung
- ungeprüfte, direkt veröffentlichte Community-Einträge

## 4. Zugang und persönliches Konto

Der Zugang zur App setzt ein Konto voraus. Bei der Registrierung werden nur
folgende Angaben oder Bestätigungen verlangt:

- eindeutiger pseudonymer Benutzername
- verifizierte, nicht öffentliche E-Mail-Adresse
- Passwort
- Bestätigung „Ich bin mindestens 18 Jahre alt“
- Zustimmung zur aktuellen Datenschutz- und Nutzungsfassung

Die App verlangt keinen echten Namen, keine Anschrift, keine Telefonnummer und
kein Geburtsdatum. Eine zufällige interne Konto-ID, Erstellungszeitpunkte,
Zustimmungsstände und Sicherheitsmetadaten werden systemseitig erzeugt.

Passwörter werden nie im Klartext gespeichert. Die E-Mail-Adresse dient nur
der Anmeldung, Verifizierung, Kontowiederherstellung und sicherheitsbezogenen
Benachrichtigung. Sie wird getrennt vom sichtbaren Benutzernamen verwaltet,
nicht öffentlich angezeigt und nicht für Werbung oder Analyse verwendet.
Eine E-Mail-Änderung erfordert das aktuelle Passwort sowie die Bestätigung an
der alten und neuen Adresse. Eine optionale TOTP-Zwei-Faktor-Authentisierung
über eine Authenticator-App schützt Anmeldung und sensible Kontoaktionen
zusätzlich; SMS wird dafür nicht verwendet. Passkeys können später nach einer
gesonderten Sicherheits- und Kompatibilitätsprüfung ergänzt werden.

Nutzer können ihre Kontodaten und persönlichen Bestände exportieren und ihr
Konto vollständig löschen. Export und Löschung erfordern eine frische
Passwortbestätigung und bei aktivierter Zwei-Faktor-Authentisierung zusätzlich
einen frischen TOTP-Code. Die Bestandsdaten werden weder zur öffentlichen
Sortierung noch für Empfehlungen, Werbung oder Profilbildung verwendet.

## 5. Persönliche Bestandsübersicht

Ein Bestandseintrag gehört ausschließlich seinem Konto und enthält:

### Verpflichtend

- Verweis auf eine Weedypedia-Sorte oder ein medizinisches Produkt
- aktuelle Menge
- Mengeneinheit

### Freiwillig

- Charge
- Haltbarkeit
- Lagerort
- persönliche Notiz

Ein fehlendes Produkt darf als privater, noch nicht zugeordneter Eintrag
gespeichert werden. Dieser Eintrag verändert die öffentliche Wissensdatenbank
nicht. Eine spätere Zuordnung erfordert eine bewusste Bestätigung durch den
Nutzer.

## 6. Navigation und Übersichten

### Hauptnavigation

Die erste Version besitzt die Bereiche:

- Entdecken
- Suche
- Persönlicher Bestand
- Profil und Informationen

### Sativa-, Indica- und Hybrid-Übersichten

Die Übersichten verwenden normales vertikales Scrollen und Tippen. Die
Sativa-Ansicht beginnt mit fünf besonders grundlegenden, gut belegten
Ursprungslinien. Darunter erscheinen Mischungen in einem zweispaltigen Raster.

Eine Karte kann zeigen:

- Name
- traditioneller Typ
- durchschnittliche THC-/CBD-Spanne mit Stichprobengröße
- Bild mit Quellen- und Lizenzangabe
- belegte Zeitspanne von Aussaat oder Keimung bis Ernte
- Belegstatus
- Kennzeichnung zugeordneter deutscher Medizinprodukte

Deutschland ist ein Filter und nicht die Grenze der Sortendatenbank.

## 7. Sortensuche

Die Suche berücksichtigt:

- kanonische Sortennamen
- belegte Aliasnamen und Schreibvarianten
- Breeder
- verknüpfte Produkt- und Handelsnamen

Jeder Treffer erklärt, warum er gefunden wurde, zum Beispiel „direkter
Sortenname“, „belegter Alias“ oder „über Produktname zugeordnet“.

Die Standardsortierung richtet sich nach Suchübereinstimmung. Belegstatus,
Produktverfügbarkeit und traditionelle Einordnung sind Filter und beeinflussen
keine vermeintliche Qualitätswertung.

Ein Treffer bietet zwei klare Ziele:

1. Sortenprofil öffnen
2. direkt zur horizontalen Historie wechseln

## 8. Einzelansicht und Gesten

Die Einzelansicht zeigt zunächst ein ruhiges Sortenporträt. Vier Richtungen
erschließen die tieferen Ebenen:

- vom oberen Rand nach unten: zurück in das Sortenmenü
- nach rechts wischen: Nachfahren
- nach links wischen: Vorfahren
- vom unteren Rand nach oben: vollständige Informationen

Jede Richtung besitzt eine sichtbare und tippbare Alternative. Die App setzt
keine versteckte Geste als einzige Bedienmöglichkeit voraus.

Beim ersten Öffnen wird das Sortenbild einmal sichtbar nach links gezogen,
federt sauber zurück, pausiert und wiederholt die Bewegung nach rechts. Nur das
Bild bewegt sich. Ein kleines Gestensymbol kann den Hinweis erneut abspielen.
Die Animation respektiert die Systemeinstellung für reduzierte Bewegung.

## 9. Horizontaler Zeitstrahl

Die Historie läuft chronologisch von links nach rechts und wird auf dem iPhone
horizontal gewischt. Ereigniskarten können zur besseren Lesbarkeit abwechselnd
ober- und unterhalb der Achse stehen.

Der gemeinsame Zeitstrahl kann enthalten:

- dokumentierte Herkunft
- Kreuzung oder Weiterentwicklung
- veröffentlichte genetische Probe oder Forschungsdaten
- Namens- oder Breeder-Ereignis
- Markteintritt eines medizinischen Produkts
- neue Charge oder Analyse
- erneute Quellenprüfung

Filter blenden Herkunft, Kreuzungen, Produkte oder Belege ein und aus. Ein
Tippen auf ein Ereignis öffnet die zugehörigen Aussagen, Quellen,
Gültigkeitszeiträume und abweichenden Überlieferungen.

Das Layout bleibt anpassbar. Tatsächliche Ereignisdichte, Zeitgenauigkeit und
Quellenumfang bestimmen später Kartenbreite, Beschriftung und Gruppierung.

## 10. Datenarchitektur

Weedypedia verwendet einen versionierten Wissensgraphen. Quellen schreiben
nicht direkt in sichtbare Sortenfelder. Stattdessen werden ihre einzelnen
Aussagen gespeichert und mit kanonischen Einträgen verknüpft.

### Zentrale Datentypen

#### Sorte oder Cultivar

- stabile Weedypedia-ID
- bevorzugter Anzeigename
- traditionelle Einordnung
- dokumentierter Breeder und Herkunft

#### Name oder Alias

- Schreibweise und Sprache
- Beziehung zur Sorte
- Quellenaussage und Gültigkeit

#### Abstammungsaussage

- Ausgangssorte und Zielsorte
- Beziehungstyp, zum Beispiel Elternteil, Nachfahre, Kreuzung oder genetische
  Nähe
- Richtung der Beziehung
- Methode, Belegstatus und Quellen

#### Medizinprodukt

- Hersteller und Handelsname
- Land und Marktzeitraum
- behauptete oder bestätigte Cultivar-Zuordnung
- Darreichungs- oder Produktform

#### Charge und Analyse

- Produkt und Chargenkennung
- THC, CBD, Terpene und weitere eindeutig gelieferte Messwerte
- Labor, Analysedatum und Analysezertifikat
- Gültigkeitszeitraum

#### Historisches Ereignis

- Ereignistyp
- bekannte oder geschätzte Zeit mit Genauigkeitsangabe
- beteiligte Sorten, Produkte oder Organisationen
- zugrunde liegende Aussagen

#### Aussage

- Subjekt
- Prädikat
- Objekt, Beziehung oder Messwert
- gültig von und bis
- Belegstatus
- Quellenversion

#### Quelle und Quellenversion

- Herausgeber, Fundstelle und Quellentyp
- Abrufzeitpunkt
- unveränderte Rohfassung oder dokumentierter Fingerabdruck
- Lizenz- und Nutzungsstatus
- Vertrauensstufe

## 11. Belegstatus und Konflikte

Der Belegstatus lautet:

- bestätigt
- gut belegt
- plausibel
- umstritten
- nicht belegt

„Nicht belegt“ bedeutet nicht „ohne Herkunft“. Auch eine unbelegte Behauptung
ist nur sichtbar, wenn nachvollziehbar ist, wer sie aufgestellt hat.

Quellen werden nach ihrer Rolle eingeordnet:

- Primärquelle oder Breeder-Angabe
- behördliche oder offizielle Produktquelle
- Herstellerangabe oder Analysezertifikat
- genetischer Forschungsdatensatz
- fachliche Sekundärquelle
- Community-Hinweis nur zur Entdeckung weiterer Belege

Eine genetische Ähnlichkeit bestätigt nicht automatisch eine historische
Elternschaft. Abweichende Elternangaben bleiben als parallele Aussagen sichtbar.

## 12. Durchschnittswerte

THC-, CBD-, Terpen- und Zeitangaben werden nicht dauerhaft als pauschaler Wert
an einer Sorte gespeichert. Die Oberfläche berechnet oder liest transparente
Zusammenfassungen aus vergleichbaren Datensätzen.

Jede Zusammenfassung nennt:

- Datentyp
- Stichprobengröße
- Wertebereich
- betrachteten Zeitraum
- Quellenklasse
- Datum der letzten Berechnung

Laborwerte, Herstellerangaben und Züchter-Schätzungen werden nie unbemerkt zu
einem gemeinsamen Durchschnitt vermischt. Für weniger als zwei vergleichbare
Werte wird kein Durchschnitt ausgegeben; stattdessen erscheint der einzelne
belegte Wert.

## 13. Quellenregister

Jede produktive Quelle benötigt vor Aktivierung einen Registereintrag mit:

- Besitzer oder Herausgeber
- Datenumfang und Zugriffsart
- schriftlich geprüfter Nutzungs-, Speicher- und Darstellungsberechtigung
- erlaubter Aktualisierungsfrequenz
- Regeln für Namensnennung und Verlinkung
- Erlaubnis zur Bildnutzung, falls zutreffend
- Vertrauensstufe
- verantwortlicher Prüfer
- Aktivierungs- und Sperrstatus

Quellen, deren Bedingungen automatisierte Übernahme, Speicherung oder
Weiterveröffentlichung verbieten, werden nicht importiert. Die erste produktive
Version benötigt mindestens je eine freigegebene Quelle für Herkunft oder
Abstammung, genetische Nachweise, deutsche Medizinprodukte und Chargen- oder
Analysedaten. Fehlende Bereiche werden als nicht verfügbar gekennzeichnet und
nicht geschätzt.

## 14. Aktualisierung und Veröffentlichung

Die geplante Aktualisierung läuft einmal innerhalb von 24 Stunden. Eine
manuelle Aktualisierung prüft gezielt eine Sorte oder ein Produkt und verwendet
denselben Prozess.

1. Quelle über eine erlaubte Schnittstelle oder ein freigegebenes Dokument
   abrufen.
2. Original und Abrufmetadaten als neue Quellenversion sichern.
3. Namen, Beziehungen, Werte und Ereignisse als einzelne Aussagen erkennen.
4. Aussagen über stabile IDs und Aliase zuordnen.
5. Änderungen mit dem letzten erfolgreichen Stand vergleichen.
6. widerspruchsfreie Änderungen als neue Version veröffentlichen.
7. unbekannte Zuordnungen, Konflikte und auffällige Werte in eine Prüfliste
   stellen.

Eine fehlerhafte Quelle blockiert keine anderen Quellen. Wiederholte Verarbeitung
desselben Inhalts erzeugt keine doppelten Aussagen oder Ereignisse.

## 15. Systemkomponenten

### PWA

Die bestehende React-, TypeScript- und Vite-PWA wird für Weedypedia
weiterentwickelt und über GitHub Pages veröffentlicht. Sie enthält nur
öffentliche Wissensdaten und die für das angemeldete Konto freigegebenen
persönlichen Daten.

### Öffentliche Wissensschnittstelle

Eine ausschließlich lesende Schnittstelle liefert veröffentlichte Sorten,
Beziehungen, Produkte, Analysen, Ereignisse und Belegmetadaten. Interne
Rohdaten, Prüffälle und Zugangsschlüssel sind nicht erreichbar.

### Konto- und Profilschnittstelle

Eine getrennte authentifizierte Schnittstelle verwaltet Konto,
Wiederherstellung und persönlichen Bestand. Die Authentifizierung verwendet
die verifizierte E-Mail-Adresse und das Passwort. Der Benutzername bleibt das
sichtbare Pseudonym im persönlichen Profil. Die PWA implementiert keine eigene
Passwortprüfung oder Passwortspeicherung.

### Import- und Prüfbereich

Jede Quelle besitzt einen isolierten Adapter. Der Bereich speichert
Quellenversionen, normalisiert Aussagen, erkennt Änderungen und führt
Prüffälle. Nur veröffentlichte Versionen gelangen in die Leseansicht.

### Datenbank

Öffentliches Wissen, interne Imports und persönliche Daten liegen in getrennten
Schemas oder gleichwertig isolierten Bereichen. Persönliche Datensätze sind
über zeilenbasierte Zugriffsregeln ausschließlich ihrer Konto-ID zugänglich.

## 16. Fehlerverhalten

- Ist eine Quelle nicht erreichbar, bleibt der letzte erfolgreiche Stand mit
  tatsächlichem Prüfdatum sichtbar.
- Eine Schema- oder Formatänderung stoppt nur den betroffenen Adapter.
- Mehrdeutige Aliase und Beziehungen werden nicht automatisch zusammengeführt.
- Ein fehlgeschlagener Import löscht oder entwertet keinen veröffentlichten
  Stand.
- Eine manuelle Aktualisierung zeigt „aktuell“, „neue Version“, „in Prüfung“
  oder „zuletzt gesehen“.
- Kann die App keine aktuellen Daten laden, zeigt sie vorhandene, datierte
  Cache-Inhalte und einen verständlichen Fehlerzustand.
- Fehlgeschlagene Anmeldung und Wiederherstellung geben keine Auskunft darüber,
  ob ein bestimmter Benutzername oder eine E-Mail existiert.

## 17. Datenschutz und Sicherheit

- Datenminimierung und Zweckbindung gelten für Konto und Bestand.
- Persönliche Bestände bleiben vollständig getrennt vom öffentlichen
  Wissensgraphen.
- Transport- und Speicherverschlüsselung sind verpflichtend.
- Passwörter werden ausschließlich über einen geprüften
  Authentifizierungsdienst als starker, gesalzener Hash verarbeitet.
- E-Mail-Verifizierung, Passwortwiederherstellung und sichere E-Mail-Änderung
  verwenden die nativen, zeitlich begrenzten Authentifizierungsabläufe.
- Die E-Mail-Adresse verbleibt im geschützten Authentifizierungsbereich und
  wird nicht in Profil-, Bestands-, Wissens- oder Analysedaten dupliziert.
- Authentifizierungsnachrichten verwenden neutrale Betreff- und Vorschautexte
  ohne Cannabis-, Medizin- oder Bestandsangaben und kein Öffnungs- oder
  Klick-Tracking.
- Vor Produktivbetrieb sind EU-Datenregion, Auftragsverarbeitungsvertrag,
  Unterauftragnehmer und Löschfristen geprüft und dokumentiert.
- Kontoerstellung, Anmeldung, Wiederherstellung und manuelle Aktualisierung
  erhalten Ratenbegrenzung und Missbrauchsschutz.
- Öffentliche Rollen besitzen keine Schreibrechte.
- Persönliche Rollen können ausschließlich das eigene Profil lesen und eigene
  Bestandsdaten lesen und ändern.
- Hat ein Konto TOTP aktiviert, sperrt die Datenbank persönliche Daten für
  Sitzungen ohne erfolgreich abgeschlossenen zweiten Faktor.
- Administratorische Rechte sind getrennt und durch Mehrfaktor-
  Authentisierung geschützt.
- Protokolle enthalten keine Passwörter, Tokens, Bestandsnotizen oder
  vollständigen persönlichen Datensätze.
- Es gibt kein personenbezogenes Werbe- oder Analyse-Tracking.
- Vor öffentlicher Freigabe erfolgen Datenschutz-, Marken- und
  Datenlizenzprüfung.

## 18. Prüfstrategie

Eine Aufforderung „Prüfen“ oder „Überprüfen“ bleibt ein reiner Prüfauftrag.
Dateien werden nur nach einem zusätzlichen Änderungsauftrag bearbeitet.

### Datenmodell

- stabile IDs und eindeutige Aliaszuordnungen
- Erkennung unmöglicher Stammbaumkreise
- getrennte Beziehungstypen für Elternschaft und genetische Nähe
- keine verwaiste sichtbare Aussage ohne Quellenversion
- Versionierung überschreibt keinen historischen Stand

### Durchschnittswerte

- Einheiten- und Wertebereichsprüfung
- nur vergleichbare Datentypen werden zusammengefasst
- korrekte Stichprobengröße, Spanne und Zeitraum
- einzelner Wert wird nicht als Durchschnitt bezeichnet

### Quellenadapter

- unveränderliche Beispielantworten je Quelle
- erfolgreiche, leere, fehlerhafte und unvollständige Antworten
- Erkennung von Schema- und Formatänderungen
- Isolation einer ausgefallenen Quelle
- idempotente Wiederholung
- keine Veröffentlichung gesperrter oder ungeklärter Quellen

### Suche und Oberfläche

- direkter Name, Alias, Breeder und Produktname
- verständliche Erklärung des Treffergrunds
- Filter für traditionelle Einordnung, Deutschland und Belegstatus
- Profil- und Historienziel funktionieren unabhängig
- horizontaler Zeitstrahl mit Tastatur- und Tippbedienung
- alle vier Einzelansichtsgesten mit sichtbarer Alternative
- Pull-and-Bounce-Hinweis nur einmal und bei reduzierter Bewegung deaktiviert
- verständliche Lade-, Leer-, Konflikt-, Cache- und Fehlerzustände
- ausreichende Kontraste, Fokusführung und Berührungsflächen

### Konten und persönlicher Bestand

- Alters- und Zustimmungsnachweis ohne Geburtsdatum
- E-Mail-Verifizierung, Passwortwiederherstellung und Ratenbegrenzungsabläufe
- E-Mail-Adresse erscheint weder öffentlich noch in Bestandsdaten oder
  Analyseereignissen
- neutrale Authentifizierungsnachrichten ohne Tracking oder inhaltlichen
  Rückschluss auf Cannabis- oder Bestandsdaten
- Export und Löschung verlangen eine frische Passwortbestätigung und bei
  aktiviertem TOTP zusätzlich einen aktuellen zweiten Faktor
- Nutzer können ausschließlich eigene Bestände lesen und ändern
- Export und vollständige Löschung
- persönliche Bestände beeinflussen keine öffentlichen Ergebnisse
- öffentliche oder fremde Konten können Bestandsdaten nicht lesen

### Abschlussprüfung

- alle automatischen Tests, Typprüfungen und Builds erfolgreich
- keine Geheimnisse oder personenbezogenen Testdaten im Repository
- jede sichtbare Aussage auf Quelle und Version zurückführbar
- Quellenregister und Nutzungsfreigaben vollständig
- Stichprobenvergleich mit den freigegebenen Originalquellen
- iPhone-Prüfung der Suche, Gesten, Zeitleiste, Anmeldung und Bestände

## 19. Umsetzungsetappen

Der freigegebene Produktumfang wird nicht als unteilbarer Großumbau umgesetzt.
Die technische Planung gliedert ihn in fünf eigenständig prüfbare Etappen:

1. Konto-, Alters-, Zustimmungs- und Bestandsgrundlage einschließlich
   Zugriffsschutz, Export und Löschung
2. Wissensgraph, Quellenregister, Versionierung und Adaptervertrag
3. Suche, Übersichten und gestengestützte Sortenansicht
4. Produkte, Chargen, Durchschnittswerte und horizontaler Zeitstrahl
5. produktive Quellenadapter, tägliche und manuelle Aktualisierung, Prüfliste
   und Betriebsüberwachung

Jede Etappe besitzt eigene Datenmigrationen, automatisierte Prüfungen und
Abnahmekriterien. Eine spätere Etappe darf frühere Sicherheits- und
Nachweisgrenzen nicht aufweichen.

## 20. Abnahmekriterien

Weedypedia Version 1 ist abnahmefähig, wenn:

1. ein Nutzer ein minimales pseudonymes Konto mit verifizierter, nicht
   öffentlicher E-Mail-Adresse erstellen, wiederherstellen, exportieren und
   löschen kann;
2. eine Suche direkte Namen, Aliase und Produktzuordnungen findet und den
   Treffergrund erklärt;
3. ein Sortenprofil Vorfahren, Nachfahren, vollständige Informationen und
   Tipp-Alternativen für alle Gesten anbietet;
4. der Zeitstrahl Herkunfts-, Beleg- und Produktinformationen von links nach
   rechts darstellt;
5. Produkt- und Chargenwerte nicht mit dauerhaften Sortenwerten verwechselt
   werden;
6. jede sichtbare Aussage Quelle, Abrufdatum, Gültigkeit und Belegstatus
   auflösen kann;
7. tägliche und manuelle Aktualisierung bestehende Daten niemals unbemerkt
   überschreiben;
8. Widersprüche und Quellenausfälle verständlich sichtbar bleiben;
9. persönliche Bestände ausschließlich dem zugehörigen Konto zugänglich sind;
10. sämtliche automatischen, sicherheitsbezogenen und iPhone-spezifischen
    Prüfungen erfolgreich abgeschlossen sind.
