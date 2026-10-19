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

## 2. Neue Stimme: Microsoft Azure

- [ ] Azure-Konto + Speech-Ressource (Tarif **Free F0**) anlegen
- [ ] GitHub-Secrets `AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION` hinterlegen
- [ ] Workflow „Stimmproben Azure“ → Stimme auswählen
- [ ] Workflow „Stimme erzeugen“ (anbieter=azure, stimme=…) → Aufnahmen in `KleineEntdecker/Resources/Voice/` übernehmen
- [ ] Kerstin-Aufnahmen (Piper) vollständig ersetzen – Lizenz der Basisstimme „Ryan“ ist CC BY-NC-SA 4.0
- [ ] Stimmenauswahl im Elternbereich umbenennen („Kerstin (in der App)“ → neuer Stimmenname)
- [ ] Datenschutzerklärung prüfen (Aufnahmen sind in der App enthalten, keine Datenübertragung)

## 3. Bereits fertig, noch nicht im App Store

- Vergrößerte iPad-Oberfläche
- Eigener Name / Spitzname für das Kind
- Natürlichere iPhone-Stimme (beste installierte Stimme, Auswahl im Elternbereich)

## 4. Optional

- Hinweis im Elternbereich, ob eine Premium-iPhone-Stimme installiert ist
