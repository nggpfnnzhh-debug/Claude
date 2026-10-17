#!/usr/bin/env python3
"""Vertont alle Sätze der App mit einer Piper-Stimme und schreibt Audiodateien + Manifest.

Die Satzlisten spiegeln die Daten aus KleineEntdecker/Games/TaskFactory.swift,
Core/Lines.swift, Core/ChildProfile.swift und Views/MemoryGameView.swift.
Ein Unit-Test (VoiceCoverageTests) prüft, dass jeder Satz der App eine Aufnahme hat.

Aufruf:
  generate.py piper <modell.onnx> <ausgabeordner>
  generate.py azure <stimmenname> <ausgabeordner>   (Umgebung: AZURE_SPEECH_KEY, AZURE_SPEECH_REGION)
  generate.py azure-samples <stimme1,stimme2,...> <ausgabeordner>
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import wave
from pathlib import Path
from xml.sax.saxutils import escape

# Kerstin „lebendig“
LENGTH_SCALE = 1.1
NOISE_SCALE = 0.85
NOISE_W_SCALE = 1.0

PRAISE = ["Super!", "Toll gemacht!", "Richtig!", "Klasse!", "Prima!", "Genau!", "Wunderbar!"]
RETRY = ["Fast!", "Versuch es nochmal.", "Schau noch einmal genau hin.", "Probier ein anderes!"]
NUMBER_WORDS = ["eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn"]

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
    ("P", "Pferd"), ("P", "Pinguin"), ("P", "Pilz"),
    ("R", "Rakete"), ("R", "Regenbogen"), ("R", "Roboter"),
    ("S", "Sonne"), ("S", "Socke"),
    ("T", "Tiger"), ("T", "Tomate"), ("T", "Teddy"),
    ("U", "Uhr"), ("U", "Ufo"),
    ("Z", "Zebra"), ("Z", "Zug"), ("Z", "Zitrone"),
]
NICKNAMES = [("Biene", "Kleine"), ("Bär", "Kleiner"), ("Fuchs", "Kleiner"), ("Maus", "Kleine"),
             ("Drache", "Kleiner"), ("Einhorn", "Kleines"), ("Pinguin", "Kleiner"), ("Eule", "Kleine"),
             ("Tiger", "Kleiner"), ("Katze", "Kleine"), ("Frosch", "Kleiner"), ("Dino", "Kleiner"),
             ("Hase", "Kleiner"), ("Löwe", "Kleiner"), ("Schildkröte", "Kleine")]
MEMORY_ANIMALS = ["Hund", "Katze", "Maus", "Hase", "Fuchs", "Bär", "Panda", "Frosch",
                  "Affe", "Schwein", "Kuh", "Löwe"]
FIXED = [
    "Was möchtest du spielen?",
    "Wer bist du?", "Such dir einen Namen aus!",
    "Super gemacht!", "Du hast einen Stern bekommen!",
    "Finde die Paare!", "Tippe auf zwei Karten.",
    "Ein Paar!",
    "Zeit für eine Pause!", "Du hast heute schon toll gespielt.",
    "Hallo!", "Wie viele Äpfel siehst du?",
    # Zählen
    "Zähl noch einmal mit mir.", "Tippe auf jedes Bild!",
    # Muster
    "Was kommt als Nächstes?", "Das Muster geht weiter!", "Schau genau hin.", "Was wiederholt sich?",
]


def all_sentences():
    s = list(PRAISE) + RETRY + NUMBER_WORDS + FIXED
    s += [f"{w.capitalize()}!" for w in NUMBER_WORDS]
    s += [f"Wie viele {p} siehst du?" for p in COUNT_PLURALS]
    for c in COLORS:
        s += [f"Tippe auf {c}!", f"Das ist {c}.", f"Wo ist {c}?"]
    for name, article in SHAPES:
        s += [f"Wo ist {article} {name}?", f"Das ist {article} {name}.", f"Das ist ein {name}."]
    letters = sorted({l for l, _ in LETTER_WORDS})
    for l in letters:
        s += [l, f"Was fängt mit {l} an?", f"Wir suchen {l}."]
    for l, w in LETTER_WORDS:
        s += [f"{w} fängt mit {l} an!", f"{w} fängt mit {l} an."]
    for name, adjective in NICKNAMES:
        spoken = f"{adjective.lower()} {name}"
        s += [f"Hallo, {spoken}!", f"Super gemacht, {spoken}!"]
    s += MEMORY_ANIMALS
    # Reihenfolge erhalten, Dubletten entfernen
    return list(dict.fromkeys(s))


def file_name(sentence: str) -> str:
    return "v_" + hashlib.sha1(sentence.encode("utf-8")).hexdigest()[:12] + ".m4a"


AZURE_RATE = "-8%"  # etwas ruhiger für Kinder
SAMPLE_TEXT = ("Hallo, kleine Biene! Was möchtest du spielen? Wie viele Marienkäfer siehst du? "
               "Super! Drei! Was fängt mit M an? Toll gemacht! Du hast einen Stern bekommen!")


def azure_tts(text: str, voice: str) -> bytes:
    region = os.environ["AZURE_SPEECH_REGION"].strip()
    ssml = (f"<speak version='1.0' xml:lang='de-DE'><voice name='{voice}'>"
            f"<prosody rate='{AZURE_RATE}'>{escape(text)}</prosody></voice></speak>")
    request = urllib.request.Request(
        f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1",
        data=ssml.encode("utf-8"),
        headers={
            "Ocp-Apim-Subscription-Key": os.environ["AZURE_SPEECH_KEY"].strip(),
            "Content-Type": "application/ssml+xml",
            "X-Microsoft-OutputFormat": "audio-24khz-96kbitrate-mono-mp3",
            "User-Agent": "kleine-entdecker-voice",
        },
    )
    for attempt in range(5):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt < 4:  # Gratis-Tarif: Anfragen drosseln
                time.sleep(3 * (attempt + 1))
                continue
            raise


def encode(source: Path, target: Path, extra_filters: str = ""):
    filters = "apad=pad_dur=0.08" + extra_filters
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(source), "-af", filters,
                    "-ac", "1", "-c:a", "aac", "-b:a", "64k", str(target)], check=True)


def main():
    mode, arg, out_dir = sys.argv[1], sys.argv[2], Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)

    if mode == "azure-samples":
        for voice in arg.split(","):
            try:
                (out_dir / f"{voice}.mp3").write_bytes(azure_tts(SAMPLE_TEXT, voice))
                print("ok", voice)
            except Exception as error:  # unbekannte Stimme o. Ä. – die anderen trotzdem erzeugen
                print("FEHLER", voice, error)
        return

    sentences = all_sentences()
    manifest = {}
    with tempfile.TemporaryDirectory() as tmp:
        if mode == "piper":
            from piper import PiperVoice, SynthesisConfig
            voice = PiperVoice.load(arg)
            config = SynthesisConfig(length_scale=LENGTH_SCALE, noise_scale=NOISE_SCALE,
                                     noise_w_scale=NOISE_W_SCALE)
        for i, sentence in enumerate(sentences, 1):
            name = file_name(sentence)
            if mode == "piper":
                # Einzelwörter ohne Satzzeichen („acht“, „Hund“) klingen sonst abgehackt.
                spoken = sentence if sentence[-1] in ".!?" else sentence + "."
                raw = Path(tmp) / "s.wav"
                with wave.open(str(raw), "wb") as wav:
                    voice.synthesize_wav(spoken, wav, syn_config=config)
                # Etwas Lautstärke-Reserve gegen Übersteuern.
                encode(raw, out_dir / name, ",volume=-3dB")
            elif mode == "azure":
                raw = Path(tmp) / "s.mp3"
                raw.write_bytes(azure_tts(sentence, arg))
                encode(raw, out_dir / name)
            else:
                sys.exit(f"Unbekannter Modus: {mode}")
            manifest[sentence] = name
            print(f"{i:3}/{len(sentences)} {sentence}")
    (out_dir / "voice_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
