# Weedypedia: Freigabe externer Datenquellen

Dieses Runbook ist das verbindliche Gate für jede externe Datenquelle. Der
aktuelle Stand aktiviert ausschließlich `synthetic-contract-source`; sie bleibt
`inactive` und enthält klar gekennzeichnete Testdaten. Eine technische
Erreichbarkeit oder öffentliche Lesbarkeit einer Quelle ist keine
Nutzungserlaubnis.

## Nicht verhandelbare Grenzen

- Adapter liefern ausschließlich den geschlossenen, versionierten
  `AdapterBatch`-Vertrag.
- Der Import darf unveränderliche Quellbelege und Review-Fälle speichern, aber
  weder prüfen noch veröffentlichen.
- Der Import-Endpunkt erhält keinen Service-Role-Key und keine
  Reviewer-Berechtigung. Sein Datenbank-Login darf nur `source_ingestor`
  annehmen.
- Browserrollen erhalten keinen Zugriff auf `catalog`, Quellbelege,
  Review-Notizen, Staging-Tabellen oder Management-Funktionen.
- Erst eine akzeptierte Prüfung und ein atomar erfolgreicher Publisher-Lauf
  dürfen öffentliche Suchdaten verändern.
- Blütenwerte über 70 Prozent bleiben Review-Fälle und dürfen nicht
  veröffentlicht werden.
- Bilder werden unabhängig von strukturierten Daten geprüft. Eine
  Datennutzungserlaubnis schließt Bildrechte nicht ein.
- Upstream-Löschungen entfernen niemals automatisch eine veröffentlichte
  Sorte, ein Produkt oder einen persönlichen Bestand.

## Freigabeakte

Für jede Quelle wird vor Codeänderungen eine eigene Freigabeakte angelegt. Sie
enthält mindestens:

| Feld | Erforderlicher Nachweis |
| --- | --- |
| Quellen-ID | Stabile, kleingeschriebene interne ID |
| Eigentümer | Verantwortliche Organisation und Kontaktweg |
| Zugriff | Dokumentierter Endpunkt, Export oder manueller Prozess |
| Frequenz | Erlaubte Abrufhäufigkeit, Backoff und Timeout |
| Lizenz | Primärlink zur aktuellen Lizenz oder schriftlichen Erlaubnis |
| Speicherung | Getrennte Entscheidung für Rohdaten, Prüfsumme und Metadaten |
| Attribution | Wortlaut und Linkanforderungen für öffentliche Nachweise |
| Bildrechte | Separates Ergebnis; standardmäßig keine Bildübernahme |
| Vertrauensklasse | `discovery`, `supporting` oder `authoritative` |
| Reviewer | Namentlich verantwortliche prüfende Person |
| Rollback-Verantwortung | Person für Sperrung, Prüfung und Wiederfreigabe |

Secrets, Zugangsdaten, Cookies, proprietäre Header und vollständige
Verbindungsstrings gehören weder in diese Akte noch in Git.

## Pflichtcheckliste vor `pilot`

Alle Punkte brauchen einen datierten Nachweis:

1. Eigentümer und Zugriffsmethode sind bestätigt.
2. Erlaubte Frequenz, Timeout, Retry/Backoff und Kontakt-`User-Agent` sind
   dokumentiert.
3. Lizenzreferenz und Erlaubnis zur Speicherung strukturierter Daten sind
   geprüft. Rohspeicherung wird separat und standardmäßig mit `false`
   entschieden.
4. Attributionsvorgaben sind als öffentlicher, nicht sensibler Text erfasst.
5. Bildrechte sind separat geprüft; ohne positive Freigabe werden keine Bilder
   importiert.
6. Die Vertrauensklasse ist begründet. Sie bestimmt nicht automatisch die
   Wahrheit oder den Rang eines Fakts.
7. Ein verantwortlicher Reviewer und eine Rollback-Verantwortung sind benannt.
8. Contract-, Schemaänderungs-, Timeout-, Rate-Limit- und Fehlerisolations-Tests
   laufen ausschließlich gegen synthetische Fixtures und bestehen.
9. Ein Staging-Import wurde durchgeführt und hat nachweislich null automatische
   Veröffentlichungen erzeugt.
10. Die Review-Queue wurde auf unbekannte Zuordnungen, Alias-Konflikte,
    widersprüchliche Abstammung, Löschhinweise und unrealistische Messwerte
    geprüft.
11. Der Rollback wurde geprobt: Quelle auf `blocked`, Import gestoppt, letzter
    veröffentlichter Stand unverändert, unveränderliche Belege erhalten.

Erst danach darf der Quellenstatus durch einen eigenen, überprüfbaren
Betriebsschritt auf `pilot` gesetzt werden. `active` benötigt zusätzlich eine
beobachtete Pilotphase, dokumentierte Datenqualität, stabile Fehlerquote und
erneute Freigabe. Statusänderung, Scheduler und Secret-Provisionierung sind
getrennte Vorgänge.

## Technische Abnahme

Vor jeder Freigabe müssen lokal und in CI bestehen:

```sh
pnpm test:functions
pnpm test:db
pnpm test
pnpm build
pnpm exec supabase db lint --schema api,catalog,private,public --level error
```

Zusätzlich ist zu belegen:

- gleicher Import erzeugt keine doppelten Quellrecords oder Assertions;
- gleicher Publisher-Lauf erzeugt keine doppelten Referenzen oder Suchbegriffe;
- abgelehnte, ungeprüfte und widersprüchliche Fakten bleiben privat;
- ein absichtlich ungültiger Snapshot lässt den letzten veröffentlichten Stand
  unverändert;
- öffentliche Zitate enthalten nur Quellenname, Version, Abrufzeit,
  freigegebene HTTPS-URL und Attribution;
- Logs enthalten nur Korrelations-ID, Quellen-ID und sicheren Ergebniscode;
- der Browser-Build enthält weder `SOURCE_IMPORT_TRIGGER_TOKEN` noch
  `SOURCE_INGESTOR_POOLER_URL` oder einen Supabase-Secret-/Service-Role-Key.

CI darf keine echte Quell-API aufrufen. Es werden weder produktive Payloads noch
externe Zugangsdaten als Testfixture gespeichert.

## Betrieb und Rollback

1. Quelle im Register sofort auf `blocked` setzen.
2. Externen Trigger oder Scheduler deaktivieren, ohne Belege zu löschen.
3. Import- und Review-Logs über sichere Korrelations-IDs eingrenzen.
4. Letzten öffentlichen Snapshot unverändert lassen. Keine automatische
   Rücknahme aufgrund eines einzelnen Upstream-Löschsignals.
5. Lizenz-, Schema-, Qualitäts- oder Zugriffsvorfall dokumentieren.
6. Betroffene Assertions erneut prüfen. Eine Veröffentlichung erfolgt nur über
   den Reviewer-Publisher.
7. Erst nach neuer Freigabe auf `pilot` zurückkehren; nie direkt auf `active`.

## Erste Kandidaten, noch nicht aktiviert

### Wikidata

Vorgesehener Umfang: externe IDs, Basisnamen und Aliasse. Wikidata kann
Hinweise und zitierte Referenzen liefern, ist aber niemals alleiniger Nachweis
für eine Abstammungsbeziehung. Strukturierte Wikidata-Daten stehen unter CC0;
ein späterer Adapter muss trotzdem Quelle und Abrufzeit sichtbar machen sowie
User-Agent, Rate Limits, `Retry-After`, `maxlag` und angemessene Timeouts
beachten:

- [Wikidata-Lizenz](https://www.wikidata.org/wiki/Wikidata:Licensing)
- [Wikidata-Datenzugriff und API-Etikette](https://www.wikidata.org/wiki/Help:Data_access)

### Crossref und Europe PMC

Vorgesehener Umfang: DOI beziehungsweise Publikations-ID, Titel,
Publikationsdatum und zitierfähige Metadaten. Ein Treffer ist ein
Literaturhinweis und keine automatische Sortenwahrheit. Crossref-Anfragen
müssen gecacht, identifizierbar und mit Backoff betrieben werden. Bei Europe
PMC werden Metadaten und Open-Access-Inhalte getrennt behandelt; frei
zugänglicher Volltext ist nicht automatisch frei nachnutzbar:

- [Crossref REST API: Zugriff und Etikette](https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/)
- [Europe PMC Entwicklerzugänge](https://europepmc.org/developers)
- [Europe PMC REST API](https://europepmc.org/RestfulWebService)

### BfArM / PharmNet.Bund / AMIce

Vorgesehener Umfang: amtliche Produkt- und Zulassungsmetadaten, sofern Zugriff,
Weiterverwendung, Speicherumfang und Attribution ausdrücklich geklärt sind.
Öffentliche Recherche bedeutet nicht automatisch erlaubten Bulk-Abruf oder
Weiterveröffentlichung. Vor einem Adapter ist deshalb eine separate
Rechteprüfung zwingend:

- [BfArM: PharmNet.Bund-Portal](https://www.bfarm.de/DE/Arzneimittel/Zulassung/Zulassungsrelevante-Themen/e-Submission/Pharmnet-Bund.html)
- [BfArM: AMIce Öffentlicher Teil](https://www.bfarm.de/DE/Arzneimittel/Arzneimittelinformationen/Arzneimittel-recherchieren/AMIce/_artikel.html)

Für jeden Kandidaten folgt vor Implementierung ein eigener Plan mit
Feldzuordnung, Lizenzentscheidung, Frequenz, Löschsemantik, Testfixtures und
benanntem Reviewer. Dieses Dokument erteilt selbst keine Quellenfreigabe.
