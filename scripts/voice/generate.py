#!/usr/bin/env python3
"""Vertont alle Sätze der App mit einer Piper-Stimme und schreibt Audiodateien + Manifest.

Die Satzlisten spiegeln die Daten aus KleineEntdecker/Games/TaskFactory.swift,
Core/Lines.swift, Core/ChildProfile.swift und Views/MemoryGameView.swift.
Ein Unit-Test (VoiceCoverageTests) prüft, dass jeder Satz der App eine Aufnahme hat.

Aufruf: generate.py <modell.onnx> <ausgabeordner>
"""
import hashlib
import json
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

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


def main():
    model, out_dir = sys.argv[1], Path(sys.argv[2])
    from piper import PiperVoice, SynthesisConfig

    voice = PiperVoice.load(model)
    config = SynthesisConfig(length_scale=LENGTH_SCALE, noise_scale=NOISE_SCALE, noise_w_scale=NOISE_W_SCALE)
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {}
    sentences = all_sentences()
    with tempfile.TemporaryDirectory() as tmp:
        for i, sentence in enumerate(sentences, 1):
            wav_path = Path(tmp) / "s.wav"
            # Einzelwörter ohne Satzzeichen („acht“, „Hund“) klingen sonst abgehackt.
            spoken = sentence if sentence[-1] in ".!?" else sentence + "."
            with wave.open(str(wav_path), "wb") as wav:
                voice.synthesize_wav(spoken, wav, syn_config=config)
            name = file_name(sentence)
            subprocess.run(
                ["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav_path),
                 # Etwas Lautstärke-Reserve gegen Übersteuern, kurzer Ausklang.
                 "-af", "volume=-3dB,apad=pad_dur=0.08",
                 "-ac", "1", "-c:a", "aac", "-b:a", "64k", str(out_dir / name)],
                check=True,
            )
            manifest[sentence] = name
            print(f"{i:3}/{len(sentences)} {sentence}")
    (out_dir / "voice_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
