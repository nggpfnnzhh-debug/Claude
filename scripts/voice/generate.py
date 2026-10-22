#!/usr/bin/env python3
"""Vertont alle Sätze der App mit einer Microsoft-Azure-Stimme und schreibt Audiodateien + Manifest.

Die Satzlisten spiegeln die Daten aus KleineEntdecker/Games/TaskFactory.swift,
Core/Lines.swift, Core/Speaker.swift (Phrases), Core/ChildProfile.swift und Views/MemoryGameView.swift.
Der Unit-Test VoiceCoverageTests prüft, dass jeder Satz der App eine Aufnahme hat.

Besonderheiten der Aussprache:
- Einzelne Großbuchstaben (Anlaute) werden als Laut gesprochen: „mmm“ statt „Em“.
- Silbenwörter wie „Ba-na-ne.“ werden mit kurzen Pausen zwischen den Silben gesprochen.

Aufruf (Umgebung: AZURE_SPEECH_KEY, AZURE_SPEECH_REGION):
  generate.py list                                   – alle Sätze ausgeben
  generate.py azure <stimme> <ausgabeordner> [ordner] – alle Sätze vertonen (optional: vorhandene wiederverwenden)
  generate.py azure-samples <spec|spec|…> <ordner>   – Hörproben
  generate.py azure-ssml <stimme> <ordner> <datei>   – Hörproben aus einer Datei „name|SSML-Text“ je Zeile
Eine Stimmen-Angabe kann Einstellungen enthalten: „de-DE-KatjaNeural;style=cheerful;pitch=+5%;rate=-8%;name=Datei“.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path
from xml.sax.saxutils import escape

AZURE_RATE = "-8%"  # etwas ruhiger für Kinder
AZURE_PAUSE = 3.2  # Sekunden zwischen zwei Anfragen (Gratis-Tarif F0: ca. 20 Anfragen pro Minute)
SAMPLE_TEXT = ("Huhu, kleine Biene! Was möchtest du heute mit mir spielen? Wie viele Marienkäfer siehst du? "
               "Super! Drei! Was fängt mit M an? Toll gemacht! Du hast einen Stern bekommen!")

# --- Daten (gespiegelt aus der App) -------------------------------------------------------------

FIRST_TRY_PRAISE = ["Super!", "Toll gemacht!", "Richtig!", "Klasse!", "Prima!", "Genau!", "Wunderbar!",
                    "Du hast genau hingeschaut!", "Gut überlegt!"]
PERSISTENCE_PRAISE = ["Du hast nicht aufgegeben!", "Gut, dass du es nochmal versucht hast!", "Geschafft!",
                      "Weiter so!"]
NUMBER_WORDS = ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn",
                "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn",
                "neunzehn", "zwanzig"]

COUNT_PLURALS = ["Marienkäfer", "Fische", "Küken", "Äpfel", "Sterne", "Frösche",
                 "Schmetterlinge", "Autos", "Blumen", "Hunde"]
COLORS = ["Rot", "Blau", "Gelb", "Grün", "Orange", "Lila", "Rosa", "Braun"]
SHAPES = [("Kreis", "der"), ("Quadrat", "das"), ("Dreieck", "das"), ("Rechteck", "das"),
          ("Stern", "der"), ("Herz", "das"), ("Oval", "das")]
LETTER_WORDS = [
    ("A", "Affe"), ("A", "Apfel"), ("A", "Ananas"),
    ("B", "Banane"), ("B", "Bär"), ("B", "Baum"),
    ("E", "Ente"), ("E", "Elefant"), ("E", "Erdbeere"),
    ("F", "Fisch"), ("F", "Frosch"), ("F", "Feuer"),
    ("H", "Hund"), ("H", "Haus"), ("H", "Herz"),
    ("K", "Katze"), ("K", "Käse"), ("K", "Kuh"),
    ("L", "Löwe"), ("L", "Löffel"),
    ("M", "Maus"), ("M", "Mond"), ("M", "Milch"),
    ("N", "Nase"), ("N", "Nashorn"),
    ("O", "Ohr"), ("O", "Oktopus"),
    ("P", "Pizza"), ("P", "Pinguin"), ("P", "Pilz"),
    ("R", "Rakete"), ("R", "Regenbogen"), ("R", "Roboter"),
    ("S", "Sonne"), ("S", "Socke"),
    ("T", "Tiger"), ("T", "Tomate"), ("T", "Teddy"),
    ("U", "Uhr"), ("U", "Ufo"),
    ("Z", "Zebra"), ("Z", "Zug"), ("Z", "Zitrone"),
]
# Laut statt Buchstabenname (IPA), gesprochen im Muster „M, M, Mama“ (wie in TaskFactory.soundPattern).
# Haltbare Laute lang wie „mmm“, kurze Laute mit Mini-Vokal wie „te“ – so klingen sie in der Sprachsynthese deutlich.
LETTER_SOUNDS = {
    "A": "aː", "E": "eː", "O": "oː", "U": "uː",
    "M": "mː", "N": "nː", "L": "lː", "F": "fː", "S": "sː",
    "T": "tə", "K": "kə", "P": "pə", "B": "bɐ", "H": "hə", "R": "ʁə", "Z": "tsə",
}
ANCHOR_WORDS = {
    "A": "Ameise", "B": "Ball", "E": "Esel", "F": "Fuß", "H": "Hut", "K": "Kind", "L": "Lampe", "M": "Mama",
    "N": "Nudel", "O": "Opa", "P": "Papa", "R": "Rose", "S": "Sofa", "T": "Tasse", "U": "Uhu", "Z": "Zahn",
}
SYLLABLE_WORDS = [
    ("Hund", ["Hund"]), ("Baum", ["Baum"]), ("Haus", ["Haus"]), ("Mond", ["Mond"]), ("Fisch", ["Fisch"]),
    ("Kuh", ["Kuh"]), ("Ball", ["Ball"]),
    ("Ente", ["En", "te"]), ("Katze", ["Kat", "ze"]), ("Sonne", ["Son", "ne"]), ("Apfel", ["Ap", "fel"]),
    ("Tiger", ["Ti", "ger"]), ("Zebra", ["Ze", "bra"]), ("Auto", ["Au", "to"]),
    ("Banane", ["Ba", "na", "ne"]), ("Tomate", ["To", "ma", "te"]), ("Rakete", ["Ra", "ke", "te"]),
    ("Giraffe", ["Gi", "raf", "fe"]), ("Elefant", ["E", "le", "fant"]), ("Ananas", ["A", "na", "nas"]),
    ("Krokodil", ["Kro", "ko", "dil"]),
    ("Regenbogen", ["Re", "gen", "bo", "gen"]), ("Avocado", ["A", "vo", "ca", "do"]),
    ("Schokolade", ["Scho", "ko", "la", "de"]), ("Krankenwagen", ["Kran", "ken", "wa", "gen"]),
]
SYLLABLE_COUNT_TEXTS = ["Eine Silbe!", "Zwei Silben!", "Drei Silben!", "Vier Silben!"]
NICKNAMES = [("Biene", "Kleine"), ("Bär", "Kleiner"), ("Fuchs", "Kleiner"), ("Maus", "Kleine"),
             ("Drache", "Kleiner"), ("Einhorn", "Kleines"), ("Pinguin", "Kleiner"), ("Igel", "Kleiner"),
             ("Tiger", "Kleiner"), ("Katze", "Kleine"), ("Frosch", "Kleiner"), ("Dino", "Kleiner"),
             ("Hase", "Kleiner"), ("Löwe", "Kleiner"), ("Schildkröte", "Kleine")]
MEMORY_ANIMALS = ["Hund", "Katze", "Maus", "Hase", "Fuchs", "Bär", "Panda", "Frosch",
                  "Affe", "Schwein", "Kuh", "Löwe"]
FIXED = [
    # Huhu, die Eule (Lines.swift)
    "Huhu!", "Ich bin Huhu, die Eule.",
    "Was möchtest du heute mit mir spielen?",
    "Wer bist du?", "Such dir einen Namen aus!",
    "Super gemacht!", "Huhu freut sich!", "Ein neuer Stern für deinen Sternenhimmel!",
    "Schau mal, so viele Sterne leuchten schon für dich!",
    "Finde die Paare!", "Tippe auf zwei Karten.", "Ein Paar!",
    "Zeit für eine Pause!", "Huhu macht jetzt ein Nickerchen.", "Bis später!",
    "Huhu hilft dir.", "Schau mal hier!", "Wir zählen zusammen!",
    # Zählen
    "Zähl noch einmal mit mir.", "Tippe auf jedes Bild!",
    # Muster
    "Was kommt als Nächstes?", "Das Muster geht weiter!", "Schau genau hin.", "Was wiederholt sich?",
    # Mehr oder weniger?
    "Das sind mehr!", "Das sind weniger!", "Zähl mal nach!",
    # Silben
    "Hör nochmal genau hin.",
]


def time_text(hour: int, minute: int) -> str:
    if minute == 0:
        return "ein Uhr" if hour == 1 else f"{NUMBER_WORDS[hour]} Uhr"
    return f"halb {NUMBER_WORDS[hour % 12 + 1]}"


def all_sentences():
    s = FIRST_TRY_PRAISE + PERSISTENCE_PRAISE + NUMBER_WORDS[1:] + FIXED
    s += [f"{w.capitalize()}!" for w in NUMBER_WORDS[1:]]
    s += [f"Wie viele {p} siehst du?" for p in COUNT_PLURALS]
    for c in COLORS:
        s += [f"Tippe auf {c}!", f"Das ist {c}.", f"Wo ist {c}?"]
    for name, article in SHAPES:
        s += [f"Wo ist {article} {name}?", f"Das ist {article} {name}.", f"Das ist ein {name}."]
    s.append("Was fängt auch so an?")
    for letter in sorted({l for l, _ in LETTER_WORDS}):
        anchor = f"{letter}, {letter}, {ANCHOR_WORDS[letter]}"
        s += [f"Hör mal: {anchor}.", f"Wir suchen: {anchor}."]
    for letter, word in LETTER_WORDS:
        s += [f"{letter}, {letter}, {word}!", f"{letter}, {letter}, {word}."]
    # Mehr oder weniger? (Mengen 2–10)
    for plural in COUNT_PLURALS:
        s += [f"Wo sind mehr {plural}?", f"Wo sind weniger {plural}?"]
    s += [f"Hier sind es {NUMBER_WORDS[n]}." for n in range(2, 11)]
    # Silben
    for word, syllables in SYLLABLE_WORDS:
        s += [f"Wie oft klatschst du bei {word}?", "-".join(syllables) + "."]
    s += SYLLABLE_COUNT_TEXTS
    # Uhr
    for hour in range(1, 13):
        for minute in (0, 30):
            t = time_text(hour, minute)
            s += [f"Wo ist es {t}?", f"Es ist {t}.", f"Hier ist es {t}."]
    # Namen
    for name, adjective in NICKNAMES:
        spoken = f"{adjective.lower()} {name}"
        s += [f"Huhu, {spoken}!", f"Super gemacht, {spoken}!"]
    s += MEMORY_ANIMALS
    return list(dict.fromkeys(s))  # Reihenfolge erhalten, Dubletten entfernen


# --- Azure -----------------------------------------------------------------------------------------

LETTER_PATTERN = re.compile(r"(?<![\w-])([A-ZÄÖÜ])(?![\w-])")
SYLLABLE_PATTERN = re.compile(r"\b\w+(?:-\w+)+\b")


def ssml_body(text: str) -> str:
    """Text → SSML-Inhalt mit Laut-Aussprache für Anlaute und Pausen zwischen Silben."""
    body = escape(text)
    # Erst Anlaute (Silben-Teile wie das „E“ in „E-le-fant“ sind durch den Bindestrich ausgenommen) …
    body = LETTER_PATTERN.sub(
        lambda m: f"<phoneme alphabet='ipa' ph='{LETTER_SOUNDS[m.group(1)]}'>{m.group(1)}</phoneme>"
        if m.group(1) in LETTER_SOUNDS else m.group(1),
        body,
    )
    # … dann Pausen zwischen den Silben.
    return SYLLABLE_PATTERN.sub(lambda m: "<break time='350ms'/>".join(m.group(0).split("-")), body)


def parse_voice_spec(spec: str) -> dict:
    parts = spec.strip().split(";")
    settings = {"voice": parts[0], "rate": AZURE_RATE}
    for part in parts[1:]:
        key, _, value = part.partition("=")
        settings[key.strip()] = value.strip()
    return settings


def azure_tts(text: str, spec: str, raw_ssml: bool = False) -> bytes:
    settings = parse_voice_spec(spec)
    region = os.environ["AZURE_SPEECH_REGION"].strip()
    prosody = f"rate='{settings['rate']}'"
    if settings.get("pitch"):
        prosody += f" pitch='{settings['pitch']}'"
    body = f"<prosody {prosody}>{text if raw_ssml else ssml_body(text)}</prosody>"
    if settings.get("style"):
        degree = f" styledegree='{settings['degree']}'" if settings.get("degree") else ""
        body = f"<mstts:express-as style='{settings['style']}'{degree}>{body}</mstts:express-as>"
    ssml = ("<speak version='1.0' xml:lang='de-DE' xmlns:mstts='https://www.w3.org/2001/mstts'>"
            f"<voice name='{settings['voice']}'>{body}</voice></speak>")
    request = urllib.request.Request(
        f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1",
        data=ssml.encode("utf-8"),
        headers={
            "Ocp-Apim-Subscription-Key": os.environ["AZURE_SPEECH_KEY"].strip(),
            "Content-Type": "application/ssml+xml",
            "X-Microsoft-OutputFormat": "audio-24khz-96kbitrate-mono-mp3",
            "User-Agent": "huhu-eule-voice",
        },
    )
    for attempt in range(8):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt < 7:  # Gratis-Tarif: Anfragen drosseln
                time.sleep(10 * (attempt + 1))
                continue
            raise


def file_name(sentence: str) -> str:
    return "v_" + hashlib.sha1(sentence.encode("utf-8")).hexdigest()[:12] + ".m4a"


# Azure hängt bis zu 1,6 s Stille an – vorne und hinten abschneiden, kurze natürliche Pause anhängen.
TRIM_FILTER = ("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,"
               "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,areverse,"
               "apad=pad_dur=0.1")


def encode(source: Path, target: Path):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(source), "-af", TRIM_FILTER,
                    "-ac", "1", "-c:a", "aac", "-b:a", "64k", str(target)], check=True)


def main():
    mode = sys.argv[1]
    if mode == "list":
        for sentence in all_sentences():
            print(sentence)
        return

    arg, out_dir = sys.argv[2], Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)

    if mode == "azure-ssml":
        for line in Path(sys.argv[4]).read_text(encoding="utf-8").splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            label, _, fragment = line.partition("|")
            (out_dir / f"{label.strip()}.mp3").write_bytes(azure_tts(fragment.strip(), arg, raw_ssml=True))
            print("ok", label.strip())
            time.sleep(AZURE_PAUSE)
        return

    if mode == "azure-samples":
        specs = arg.split("|") if "|" in arg else arg.split(",")
        for spec in specs:
            label = parse_voice_spec(spec).get("name") or parse_voice_spec(spec)["voice"]
            try:
                (out_dir / f"{label}.mp3").write_bytes(azure_tts(SAMPLE_TEXT, spec))
                print("ok", label)
            except Exception as error:  # unbekannte Stimme o. Ä. – die anderen trotzdem erzeugen
                print("FEHLER", label, error)
        return

    if mode != "azure":
        sys.exit(f"Unbekannter Modus: {mode}")

    # Optional: vorhandene Aufnahmen (gleiche Stimme!) wiederverwenden und nur neue Sätze vertonen.
    reuse_dir = Path(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else None
    existing = {}
    if reuse_dir and (reuse_dir / "voice_manifest.json").exists():
        existing = json.loads((reuse_dir / "voice_manifest.json").read_text(encoding="utf-8"))

    sentences = all_sentences()
    manifest = {}
    new_count = 0
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "s.mp3"
        for i, sentence in enumerate(sentences, 1):
            name = file_name(sentence)
            if sentence in existing and (reuse_dir / existing[sentence]).exists():
                (out_dir / name).write_bytes((reuse_dir / existing[sentence]).read_bytes())
            else:
                raw.write_bytes(azure_tts(sentence, arg))
                encode(raw, out_dir / name)
                new_count += 1
                print(f"{i:3}/{len(sentences)} NEU {sentence}")
                time.sleep(AZURE_PAUSE)
            manifest[sentence] = name
    print(f"{len(sentences)} Sätze, davon {new_count} neu vertont")
    (out_dir / "voice_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
