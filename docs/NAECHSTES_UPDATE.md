# Geplantes großes Update (Version 1.1)

Stand: Oktober 2026. Diese Punkte sollen gemeinsam in einem Update erscheinen.

## 1. Neuer Name: „Huhu Eule“ (entschieden: ja, Umsetzung später)

| Feld | Neuer Wert | Zeichen |
|---|---|---|
| App-Store-Name | `Huhu Eule – Lernspiele ab 4` | 27/30 |
| Untertitel | `Zählen, ABC, Formen & Farben` | 28/30 |
| Schlüsselwörter | `kinder,vorschule,kita,kindergarten,zahlen,buchstaben,anlaute,memory,muster,logik,lernen,spiel,mathe` | 99/100 |
| Name unter dem App-Symbol (`CFBundleDisplayName`) | `Huhu Eule` | |

Begründung (Wettbewerbsanalyse): Viele Konkurrenz-Apps heißen fast gleich
(„Lernspiele Kinder ab 4“, „Vorschule Lernspiele“) und finanzieren sich über Abos/In-App-Käufe.
Marke + Suchbegriff hebt sich ab und bleibt gut auffindbar; die Eule ist bereits Maskottchen/App-Symbol.
„Kleine Eule“ meiden (Kinderbuchmarke). Hinweis: HABA-Brettspiel „Huhuuh“ existiert.
Werbefrei/ohne Abo in Beschreibung und Screenshots hervorheben – nicht im Namen (Apple-Richtlinie 2.3.7).

Vorher: Verfügbarkeit des Namens in App Store Connect prüfen, optional DPMA-Markenregister.

Umzustellen:
- [ ] App Store Connect → App-Informationen → Name (macht der Inhaber selbst)
- [ ] `project.yml` → `CFBundleDisplayName`
- [ ] Startbildschirm-Titel (`ChildProfile.defaultTitle`)
- [ ] `fastlane/metadata/de-DE/` (Untertitel, Schlüsselwörter, Beschreibung)
- [ ] `docs/privacy.html`, `docs/index.html`, `README.md`, `docs/APP_STORE.md`
- [ ] Screenshots neu erzeugen
- [ ] Neue Adresse für Datenschutz- und Hilfeseite (ohne „Claude“), z. B. `huhu-eule.podolskis.de`
      oder eigenes öffentliches Mini-Repository; danach URLs in App Store Connect und
      `fastlane/metadata/de-DE/privacy_url.txt` / `support_url.txt` anpassen
- [ ] Optional: dieses Repository danach auf privat stellen (erst nachdem die neue Datenschutz-Adresse in App Store Connect eingetragen ist)

## 2. Neue Stimme: Microsoft Azure

- [ ] Azure-Konto + Speech-Ressource (Tarif **Free F0**) anlegen
- [ ] GitHub-Secrets `AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION` hinterlegen
- [ ] Workflow „Stimmproben Azure“ → Stimme auswählen
- [ ] Workflow „Stimme erzeugen“ (anbieter=azure, stimme=…) → Aufnahmen in `KleineEntdecker/Resources/Voice/` übernehmen
- [ ] Kerstin-Aufnahmen (Piper) vollständig ersetzen – Lizenz der Basisstimme „Ryan“ ist CC BY-NC-SA 4.0
- [ ] Stimmenauswahl im Elternbereich umbenennen („Kerstin (in der App)“ → neuer Stimmenname)
- [ ] Datenschutzerklärung prüfen (Aufnahmen sind in der App enthalten, keine Datenübertragung)

## 3. Fördertipps im Elternbereich (entschieden: ja)

Kostenlos, ohne Kaufangebote, ohne Datenübertragung.

- [ ] Pro Spiel nur auf dem Gerät merken, wie oft das Kind beim **ersten Versuch** richtig liegt
      (gleitend über die letzten ~5 Runden; wird mit „Fortschritt zurücksetzen“ gelöscht)
- [ ] Elternbereich: Abschnitt „Ideen zum gemeinsamen Üben“ – je Spiel 3–5 Alltagsideen
      (z. B. Zählen: Treppenstufen zählen; Farben: „Ich sehe was, was du nicht siehst“;
      Anlaute: Anlaut-Spiel beim Einkaufen; Muster: Perlen auffädeln; Memory: Tisch-Memory mit Alltagsgegenständen)
- [ ] Spiele, bei denen es noch hakt, zuerst zeigen – freundlich formuliert
      („Hier macht gemeinsames Üben besonders Spaß“), **keine** Defizit-Sprache, keine Noten
- [ ] Ideen immer für alle Spiele erreichbar, nicht nur bei „Schwächen“
- [ ] Hinweis: kurze Spielrunden sind keine Diagnose; normale Entwicklung verläuft unterschiedlich schnell
- [ ] Datenschutzerklärung ergänzen: Spielergebnisse werden nur lokal gespeichert
- [ ] Unit-Tests für die Auswertung

## 4. Bereits fertig, noch nicht im App Store

- Eindeutige Farben im Farbspiel (Rosa war kaum von Rot zu unterscheiden)

- Vergrößerte iPad-Oberfläche
- Eigener Name / Spitzname für das Kind
- Natürlichere iPhone-Stimme (beste installierte Stimme, Auswahl im Elternbereich)

## 5. Optional

- Hinweis im Elternbereich, ob eine Premium-iPhone-Stimme installiert ist

---

# Vorgemerkt für Version 2.1: „Vorschul-Paket 2“ (entschieden, Umsetzung nach Start der 2.0)

Auswahl nach Nutzen für die kognitive Entwicklung (Vorläuferfähigkeiten für die Schule):

1. **Welche Zahl fehlt?** – Zahlenstrahl/Zahlenreihe mit Lücke (z. B. 1, 2, _, 4).
   Zahlreihenfolge und -größe auf einer Linie; gut belegter Prädiktor für späteren Matheerfolg.
   Stufen: bis 5 → bis 10 → bis 20, später auch rückwärts.
2. **Oben, unten, neben, hinter** – Raum-Lage-Begriffe („Wo ist die Katze? Unter dem Tisch!“).
   Räumliches Denken + räumliche Sprache; Thema bei Einschulungsuntersuchungen.
3. **Bildergeschichten ordnen** – 3 (später 4) Bilder in die richtige Reihenfolge bringen
   (z. B. Samen → Pflänzchen → Blume). Ursache/Folge, zeitliche Abfolge, Erzählen.

Dazu passend: Fördertipps im Elternbereich für jedes neue Spiel (Übertrag in den Alltag).
Vertonung erst nach Freigabe der Texte.

Weitere Ideen (nicht vorgemerkt): Laute zusammenziehen, Würfelbilder als Zähl-Stufe, Mach 5!,
Was passt nicht dazu?, Gegenteile, Schatten zuordnen, Gefühle erkennen, Sternbilder im
Sternenhimmel, Huhus Tagesrunde, mehrere Kinderprofile, englische Version, Feedback im Elternbereich.
