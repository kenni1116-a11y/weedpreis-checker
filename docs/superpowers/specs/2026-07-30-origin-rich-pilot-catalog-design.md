# Weedypedia – Herkunftsorientierter Pilotkatalog

Stand: 30. Juli 2026

## 1. Ziel und Einordnung

Diese Spezifikation beschreibt den ersten realen, quellenbasierten
Weedypedia-Pilotkatalog mit 50 bis 75 Sorten. Der Schwerpunkt liegt auf
Herkunftspopulationen, historischen Referenzlinien, dokumentierten Kreuzungen
und nachvollziehbaren Verwandtschaftsbeziehungen.

Der Pilot ersetzt keine botanische oder genetische Fachpublikation. Er führt
unterschiedliche Belegarten in einem versionierten Wissensgraphen zusammen,
ohne dokumentierte Abstammung, genetische Ähnlichkeit, Produktzuordnung und
persönliche Angaben miteinander zu vermischen.

Der bereits freigegebene belegte Quellenmix bleibt verbindlich:

- dokumentierte Abstammung bevorzugt aus Primärquellen,
- genetische Beziehungen aus nachvollziehbaren Probendaten und Studien,
- Produkt- und Chargenangaben aus Hersteller-, Labor- oder freigegebenen
  Produktquellen,
- Sekundärdatenbanken nur nach dokumentierter Quellenfreigabe,
- jede sichtbare Aussage mit Quelle, Abrufdatum, Version und Belegstatus.

## 2. Umfang und Nicht-Ziele

### 2.1 Pilotumfang

Der Pilot enthält 50 bis 75 eindeutige veröffentlichte Sorten- oder
Herkunftseinträge. Die Auswahl ist absichtlich herkunftsorientiert:

- 20 bis 25 Herkunftspopulationen, Landrassen oder historische
  Referenzlinien,
- 25 bis 35 gut dokumentierte Kreuzungen und einflussreiche Nachfahren,
- 10 bis 15 Sorten mit belegtem Bezug zu deutschen medizinischen
  Blütenprodukten.

Die Gruppen dürfen sich überschneiden. Ein Eintrag wird im Gesamtumfang nur
einmal gezählt. Deutschland bleibt eine Filter- und Produktperspektive; es
begrenzt den internationalen Wissensgraphen nicht.

### 2.2 Nicht-Ziele dieses Piloten

Nicht Bestandteil dieser Etappe sind:

- der bereits vertagte interaktive 3D-Stammbaum,
- eine endgültige visuelle Gestaltung der späteren Baumansicht,
- automatische Therapie-, Wirkungs- oder Sortenempfehlungen,
- Preisvergleich, Bestellung, Reservierung oder Rezeptverarbeitung,
- automatische Veröffentlichung von Bildern oder Bildlizenzen,
- eine vollständige Erfassung aller bekannten Cannabis-Sorten,
- die Gleichsetzung traditioneller Sativa-/Indica-Bezeichnungen mit
  genetisch bewiesenen Hauptstämmen.

Die Datenstruktur muss den späteren 3D-Graphen ermöglichen, ohne dessen
Bedienung oder Darstellung in dieser Etappe vorwegzunehmen.

## 3. Fachliches Datenmodell

### 3.1 Knotentypen

Der Wissensgraph unterscheidet vier fachliche Knotentypen.

#### Herkunftspopulation

Eine geografisch oder historisch beschriebene Population, Landrasse oder
Ursprungslinie. Sie darf nicht als einzelner stabiler Klon oder eindeutig
registrierte Sorte ausgegeben werden.

#### Sorte oder Cultivar

Eine benannte Züchtung, Samenlinie, Selektion oder ein konkreter Cut. Ein
kanonischer Weedypedia-Eintrag kann mehrere belegte Aliase besitzen.

#### Genetische Probe

Tatsächlich untersuchtes Pflanzenmaterial. Eine Probe besitzt eigene
Identifikatoren, Einreicher, Labor- oder Datensatzangaben, Analyseversion und
Probenzeitpunkt, sofern diese Daten in der Quelle vorliegen.

#### Medizinisches Produkt

Ein benanntes medizinisches Blütenprodukt. Produkt, Charge und gemessene Werte
bleiben vom zugrunde liegenden Sorteneintrag getrennt.

### 3.2 Identität und Aliase

Ein kanonischer Eintrag besitzt eine stabile Weedypedia-ID. Namen sind keine
zuverlässigen technischen Schlüssel.

Aliase speichern:

- Schreibweise,
- Sprache oder Markt,
- zugeordneten kanonischen Eintrag,
- Quelle,
- Aliasart,
- Gültigkeits- oder Belegstatus.

Gleiche Namen dürfen auf unterschiedliche Sorten oder Proben verweisen. Eine
Zusammenführung verlangt einen nachvollziehbaren Identitätsbeleg. Jede
Zusammenführung und spätere Trennung bleibt versioniert und rückrollbar.

### 3.3 Verbindungsarten

Der Graph unterstützt getrennte Beziehungstypen:

- behauptete Eltern-Kind-Abstammung,
- Kreuzung,
- Rückkreuzung,
- Selektion aus einer Linie oder Population,
- Zugehörigkeit zu einer Herkunftspopulation,
- dokumentierte unbekannte oder nur teilweise bekannte Elternschaft,
- genetische Ähnlichkeit,
- Klon- oder Probenübereinstimmung,
- Produkt-zu-Sorte-Zuordnung.

Eine genetische Ähnlichkeit wird nie automatisch als Elternschaft, Nachfahr,
Geschwisterbeziehung oder Züchtungsweg veröffentlicht.

## 4. Aussagen und Belege

Quellen schreiben nicht direkt in sichtbare Sortenfelder. Jede extrahierte
Information wird zunächst als einzelne, unveränderlich belegte Aussage
gespeichert.

Eine Aussage enthält mindestens:

- betroffene Entität oder Beziehung,
- behaupteten Wert,
- Quelleneintrag und Quellenversion,
- möglichst genaue Fundstelle,
- Abruf- oder Veröffentlichungszeitpunkt,
- Extraktionsart,
- Belegstatus,
- Prüf- und Veröffentlichungsverlauf.

### 4.1 Belegstatus

Die öffentliche und redaktionelle Verarbeitung unterscheidet:

- `confirmed`: Quellenregel erfüllt, kein bekannter Widerspruch,
- `single_source`: vorhandener, aber noch nicht ausreichender Einzelbeleg,
- `disputed`: mindestens eine belegte widersprüchliche Aussage,
- `historical`: historisch überlieferte, nicht genetisch bewiesene Aussage,
- `unknown`: keine belastbare Aussage vorhanden,
- `retracted`: zurückgezogene oder widerlegte Veröffentlichung.

Die Benutzeroberfläche darf verständliche deutsche Bezeichnungen verwenden.
Die gespeicherten Zustände bleiben eindeutig und maschinenprüfbar.

### 4.2 Automatische Veröffentlichungsregel

Eine Abstammungsaussage darf automatisch veröffentlicht werden, wenn:

- alle beteiligten Quellen für den konkreten Nutzungszweck freigegeben sind,
- eine freigegebene Primärquelle vorliegt oder zwei voneinander unabhängige
  freigegebene Sekundärquellen übereinstimmen,
- Sorte, Alias und beteiligte Beziehungen eindeutig zugeordnet sind,
- kein offener Widerspruch existiert,
- jede Aussage auf eine konkrete Fundstelle zurückgeführt werden kann,
- alle strukturellen und fachlichen Validierungen erfolgreich sind.

Ein vom KI-Modell ausgegebener Konfidenzwert ersetzt keine dieser Regeln.

Immer prüfpflichtig bleiben:

- widersprüchliche Abstammungen,
- unklare Namens- oder Probenzuordnungen,
- ungewöhnliche Messwerte,
- Bilder und Bildlizenzen,
- Aussagen, die genetische Ähnlichkeit in eine Abstammung umdeuten würden,
- Quellen mit ungeklärtem oder eingeschränktem Nutzungsstatus.

## 5. Zwei getrennte Verwandtschaftsebenen

Weedypedia führt zwei unabhängige Ebenen.

### 5.1 Dokumentierter Stammbaum

Diese Ebene enthält behauptete oder belegte Züchtungsbeziehungen aus
Primär- und freigegebenen Sekundärquellen. Sie kann mehrere widersprüchliche
Varianten derselben Abstammung speichern.

### 5.2 Genetische Ähnlichkeit

Diese Ebene enthält Beziehungen aus untersuchten Proben. Jede Beziehung bleibt
an Methode, Datensatz, Analyseversion und beteiligte Proben gebunden.

Beide Ebenen dürfen später gemeinsam dargestellt oder gefiltert werden. Ihre
Verbindungstypen und Bedeutungen bleiben jedoch getrennt. Eine visuelle Nähe im
späteren 3D-Graphen ist kein Abstammungsbeweis.

## 6. Quellenstrategie

### 6.1 Quellenregister

Vor der ersten Verarbeitung erhält jede Quelle einen Registereintrag mit:

- Betreiber oder Herausgeber,
- Quellentyp,
- technischem Zugriffsweg,
- erlaubten Feldern und erlaubter Nutzung,
- Bild- und Textrechten,
- Aktualisierungsrhythmus,
- Kontakt- und Freigabenachweis,
- Ausfall- und Rollbackregel.

Der Nutzungsstatus ist einer der folgenden Zustände:

- `approved_import`,
- `approved_reference_only`,
- `under_review`,
- `prohibited`.

Nur `approved_import` darf automatisiert Inhalte übernehmen.
`approved_reference_only` erlaubt einen redaktionellen Einzelbeleg, aber keinen
Massenimport. `under_review` und `prohibited` dürfen keine öffentlichen
Aussagen speisen.

### 6.2 Quellenschichten

Der Pilot verwendet einen belegten Quellenmix:

1. Primärquellen wie ursprüngliche Breeder- oder Rechteinhaberseiten für
   dokumentierte Elternschaft.
2. Offene wissenschaftliche Daten für genetische Proben und Ähnlichkeit.
3. Wissenschaftliche Veröffentlichungen für Population, Domestikation und
   Methodik.
4. Freigegebene Sekundärdatenbanken zur unabhängigen Bestätigung oder
   Konflikterkennung.
5. Hersteller-, Labor- oder Produktquellen für deutsche medizinische Produkte.

### 6.3 Geprüfte Kandidaten

Die folgenden Kandidaten begründen die technische Machbarkeit, sind aber nicht
alle automatisch für einen Massenimport freigegeben:

- [CannSeek](https://pmc.ncbi.nlm.nih.gov/articles/PMC11480739/) bietet offene
  Forschungsdaten, eine dokumentierte API und phylogenetische Analysen. Diese
  Daten gehören ausschließlich in die Ebene genetischer Ähnlichkeit.
- [Kannapedia](https://kannapedia.net/) enthält öffentliche genetische
  Vergleichsberichte. Vor einem automatisierten Import ist die konkrete
  Wiederverwendung separat freizugeben; andernfalls bleibt die Quelle
  `approved_reference_only`.
- Die interaktive
  [Phylos Galaxy](https://phylos.bio/legal/phylos-testing-services) ist
  eingestellt. Bestehende Reports und öffentlich archivierte Rohdaten können
  nach Rechte- und Datensatzprüfung für genetische Beziehungen genutzt werden,
  nicht als Beweis eines dokumentierten Stammbaums.
- Breeder-, Hersteller- und Labordaten werden jeweils einzeln in das
  Quellenregister aufgenommen. Es gibt keine pauschale Freigabe für eine ganze
  Anbieterklasse.

## 7. Import-, Prüf- und Veröffentlichungsfluss

### 7.1 Aufnahme

Jeder Abruf wird mit Zeitpunkt, Quellenversion und Prüfsumme unveränderlich
archiviert. Änderungen an einer Quelle erzeugen eine neue Version und
überschreiben keinen älteren Stand.

### 7.2 KI-Extraktion

Die KI darf:

- vorhandene Aussagen strukturiert extrahieren,
- mögliche Entitäten und Aliase vorschlagen,
- übereinstimmende Quellen gruppieren,
- Widersprüche und ungewöhnliche Werte markieren.

Die KI darf keine fehlenden Eltern, Werte oder Herkunftsangaben ergänzen und
keine Quelle umdeuten.

### 7.3 Identitätsabgleich

Der Abgleich erzeugt entweder:

- eine eindeutige Zuordnung,
- eine neue eindeutig beschriebene Entität,
- oder einen Prüffall.

Mehrdeutige Namen, wechselnde Schreibweisen, fehlende Breeder-Angaben und
widersprüchliche Probenkennungen erzeugen immer einen Prüffall.

### 7.4 Regelprüfung und Veröffentlichung

Die Regelprüfung bewertet ausschließlich nachvollziehbare Quellen- und
Zuordnungsregeln. Freigegebene Aussagen werden atomar in eine versionierte
öffentliche Projektion veröffentlicht.

Die öffentliche Anwendung liest nie direkt aus:

- unbearbeiteten Quellenabrufen,
- KI-Ausgaben,
- privaten Prüfnotizen,
- nicht freigegebenen Aussagen,
- persönlichen Bestands- oder Communitydaten.

### 7.5 Rücknahme

Eine einzelne Aussage, ein Quellensatz oder ein kompletter Importlauf kann auf
die vorherige öffentliche Version zurückgesetzt werden. Eine Rücknahme löscht
den Belegverlauf nicht.

## 8. Aktualisierung

Der Pilot verwendet quellentypabhängige Intervalle:

- aktuelle medizinische Produktquellen täglich,
- aktive Sorten- und Breederquellen wöchentlich,
- historische oder wissenschaftliche Quellen monatlich,
- zusätzlich jederzeit eine gezielte manuelle Prüfung.

Ein Quellenausfall entfernt veröffentlichte Angaben nicht. Die Oberfläche zeigt
den letzten erfolgreichen Bestätigungszeitpunkt und gegebenenfalls einen
veralteten oder gestörten Quellenstatus.

## 9. Bilder

Ein Bild ist keine Pflichtangabe für die Aufnahme einer Sorte.

Ein echtes Bild darf nur veröffentlicht werden, wenn:

- Rechteinhaber oder Lizenz eindeutig dokumentiert sind,
- die konkrete Nutzungsart erlaubt ist,
- Quelle und Lizenzversion gespeichert sind,
- die Zuordnung zur Sorte oder Probe ausreichend belegt ist.

Ohne geklärte Rechte verwendet Weedypedia einen hochwertigen neutralen
Platzhalter. KI-generierte Bilder dürfen reale Sorten oder Proben nicht als
dokumentarische Abbildung darstellen.

## 10. Öffentliche Darstellung und Filter

Sativa, Indica und Hybrid bleiben traditionelle Beschreibungs- und
Filterbegriffe. Sie bilden keine erzwungenen Hauptstämme des Wissensgraphen.

Der spätere Stammbaum muss kombinierbare Filter unterstützen:

- traditionelle Sativa-/Indica-/Hybrid-Beschreibung,
- Herkunftsregion,
- Epoche,
- Beziehungstyp,
- Belegstatus,
- einzelne Sorte oder Sortengruppe,
- Bezug zu deutschen medizinischen Produkten,
- dokumentierte Abstammung oder genetische Ähnlichkeit.

Eine gut sichtbare Funktion „Alle anzeigen“ setzt ausschließlich die
Darstellungsfilter zurück. Filter verändern keine gespeicherten Daten.

## 11. Konflikte und Fehlerfälle

Widersprüchliche Aussagen bleiben nebeneinander erhalten. Eine bevorzugte
Variante darf nur veröffentlicht werden, wenn ihre Beleglage nach festen Regeln
stärker ist. Andere belegte Varianten bleiben sichtbar auflösbar.

Der Pilot behandelt mindestens:

- gleichnamige unterschiedliche Sorten,
- mehrere Schreibweisen einer Sorte,
- unbekannte oder nur teilweise bekannte Eltern,
- widersprüchliche Elternangaben,
- vermeintliche Elternschaft aus bloßer genetischer Nähe,
- unterschiedliche Proben mit gleichem Sortennamen,
- geänderte oder entfernte Quellenseiten,
- zurückgezogene Aussagen,
- fehlende Bilder oder Nutzungsrechte,
- Produktwerte, die nicht als Sorteneigenschaft gelten dürfen.

Eine kritische Fehlzuordnung pausiert die automatische Veröffentlichung für die
betroffene Quelle. Kritisch sind insbesondere falsche Elternschaft, falsche
Probenidentität und die Vermischung von Produkt-, Chargen- oder Sortenwerten.
Eine pausierte Quelle darf erst nach dokumentierter Ursachenprüfung,
korrigiertem Adapterlauf und bestandener menschlicher Stichprobe erneut
automatisch veröffentlichen.

## 12. Datenschutz und Sicherheitsgrenzen

Der Quellenpilot verarbeitet keine persönlichen Bestands-, Gesundheits-,
Rezept- oder Konsumdaten.

Unverändert gelten:

- nur freigegebene öffentliche Projektionen im Browser,
- keine Service- oder geheimen Schlüssel im Browser,
- private Import-, Prüf- und Katalogdaten außerhalb der öffentlichen Data API,
- explizite Grants und RLS als getrennte Schutzschichten,
- keine direkte Browser-Schreibmöglichkeit in den Wissensgraphen,
- vollständig protokollierte administrative Veröffentlichung und Rücknahme.

Communitywerte und persönliche Bestandsangaben korrigieren weder automatisch
noch manuell eine öffentliche Herkunftsaussage.

## 13. Prüfung und Abnahme

Der Pilot ist abnahmefähig, wenn:

1. 50 bis 75 eindeutige veröffentlichte Sorten- oder Herkunftseinträge
   vorhanden sind.
2. Mindestens 20 Einträge Herkunftspopulationen, Landrassen oder historische
   Referenzlinien abbilden.
3. Jede sichtbare Aussage einen auflösbaren Beleg, Abrufzeitpunkt und
   Belegstatus besitzt.
4. Dokumentierte Abstammung und genetische Ähnlichkeit technisch und fachlich
   getrennt bleiben.
5. Aliase, gleichnamige Sorten und unterschiedliche Proben nicht unbemerkt
   zusammengeführt werden.
6. Mindestens zehn bewusst widersprüchliche Testfälle zuverlässig die
   Prüfwarteschlange erreichen.
7. Ein vollständiger Importlauf ohne Verlust der Beleggeschichte
   zurückgerollt werden kann.
8. Kein Bild ohne dokumentierte Rechte veröffentlicht wird.
9. Vor dem öffentlichen Pilotstart alle automatisch veröffentlichten Aussagen
   manuell gegengeprüft wurden.
10. Nach dem Start pro Kalendermonat mindestens 20 Prozent der in diesem Monat
    automatisch veröffentlichten Aussagen stichprobenartig kontrolliert
    werden.
11. Eine simulierte kritische Fehlzuordnung die betroffene Quelle automatisch
    pausiert.
12. Suche, Quellenauflösung, Filter und mobile Bedienung auf iPhone und Android
    geprüft sind.
13. Automatisierte Datenbank-, Sicherheits-, Import-, Publisher- und
    Regressionstests erfolgreich sind.

## 14. Umsetzungsschnitt

Diese Spezifikation wird in getrennte, einzeln prüfbare Pakete zerlegt:

1. Graph- und Belegmodell für Herkunftspopulationen, Sorten, Proben, Produkte
   und getrennte Beziehungsebenen.
2. Quellenregister und Rechtefreigabe für die ersten konkreten Kandidaten.
3. KI-Extraktion, Identitätsabgleich und feste automatische
   Veröffentlichungsregeln.
4. Konfliktwarteschlange, Versionierung, Rücknahme und Quellenpausierung.
5. unveröffentlichter Pilotimport mit 50 bis 75 ausgewählten Einträgen.
6. vollständige manuelle Pilotprüfung.
7. öffentliche Projektion, Suche, Quellenanzeige und Filter.
8. mobile Abnahme und kontrollierte Pilotfreigabe.

Der vertagte 3D-Stammbaum erhält später eine eigene Spezifikation. Er darf nur
auf dem hier definierten Wissensgraphen aufbauen und keine zusätzlichen
Abstammungen aus visueller Nähe ableiten.
