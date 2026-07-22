# Weedpreis Checker – Umsetzungsroadmap

Die freigegebene Produktspezifikation wird in vier eigenständig prüfbare Vorhaben zerlegt:

1. **iPhone-PWA-Grundbau:** Vollständiger Nutzerablauf mit synthetischen, klar gekennzeichneten Testangeboten; Altersabfrage, Versand/Abholung, Suche, Katalog, Gesamtpreise, Aktualität, Favoriten, Offline-Verhalten und GitHub-Pages-Build.
2. **Supabase-Datenplattform:** Migrationen, PostGIS-Abholsuche, öffentliche Leseansicht, RLS, Importprotokolle, Cron und Verbindung der PWA mit Supabase.
3. **Apothekenadapter:** Ein separat geprüfter Adapter je freigegebener Apotheke oder Feed einschließlich unveränderlicher Quellfixtures, Produktnormalisierung und Ausfallisolation. Die konkreten Pläne entstehen erst nach Auswahl der Quelle und dokumentierter Nutzungsfreigabe.
4. **Produktionsfreigabe:** Reale Stichproben, Quellenprüfung, Rechts- und Datenschutzfreigabe, Impressum, finale Marke und Icons, Sicherheitsprüfung sowie kontrollierter öffentlicher Start.

Jede Stufe erzeugt funktionsfähige, testbare Software. Keine Stufe setzt erfundene Apothekenschnittstellen oder ungeprüfte Rechtsannahmen voraus.
