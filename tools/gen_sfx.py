# Sintesis SFX 8-bit sederhana -> WAV 16-bit mono 22050Hz (stdlib only).
import math, random, wave, os, struct

OUT = r"E:\Proyek Custom Game Kimi\game\assets\audio\sfx"
SR = 22050
random.seed(13)


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 30000)) for s in samples)
        w.writeframes(frames)
    print("OK", name, round(len(samples) / SR, 2), "s")


def env(n, attack=0.01, decay_pow=2.0):
    out = []
    for i in range(n):
        t = i / n
        a = min(1.0, i / max(1, int(attack * SR)))
        out.append(a * (1.0 - t) ** decay_pow)
    return out


def sweep(name, f0, f1, dur, vol=0.6, kind="noise"):
    n = int(dur * SR)
    e = env(n)
    ph = 0.0
    out = []
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        ph += 2 * math.pi * f / SR
        if kind == "noise":
            s = random.uniform(-1, 1) * (0.5 + 0.5 * math.sin(ph))
        elif kind == "sine":
            s = math.sin(ph)
        else:  # saw kasar
            s = 2.0 * (ph / (2 * math.pi) % 1.0) - 1.0
        out.append(s * e[i] * vol)
    write_wav(name, out)


def arp(name, notes, note_dur=0.09, vol=0.5):
    out = []
    for f in notes:
        n = int(note_dur * SR)
        e = env(n, 0.005, 1.2)
        for i in range(n):
            ph = 2 * math.pi * f * i / SR
            out.append(math.sin(ph) * e[i] * vol)
    write_wav(name, out)


def rattle(name, ticks, dur, vol=0.55):
    n = int(dur * SR)
    out = [0.0] * n
    for k in range(ticks):
        start = int(n * (k / ticks) * random.uniform(0.85, 1.1))
        ln = int(0.03 * SR)
        f = 300 + k * 80
        for i in range(ln):
            if start + i >= n:
                break
            amp = (1 - i / ln) * (1 - k / ticks)
            out[start + i] += (random.uniform(-1, 1) * 0.6 + math.sin(2 * math.pi * f * i / SR) * 0.4) * amp * vol
    write_wav(name, out)


def boom(name, dur, vol=0.9):
    # dentuman besar: sine rendah jatuh + ledakan noise
    n = int(dur * SR)
    e = env(n, 0.004, 1.6)
    ph = 0.0
    out = []
    for i in range(n):
        t = i / n
        f = 160 * (1.0 - 0.75 * t) + 30
        ph += 2 * math.pi * f / SR
        s = math.sin(ph) * 0.9 + random.uniform(-1, 1) * (1.0 - t) * 0.5
        out.append(s * e[i] * vol)
    write_wav(name, out)


def shimmer(name, dur, vol=0.45):
    # kilau naik (peti harta)
    n = int(dur * SR)
    out = []
    notes = [784, 988, 1175, 1568]
    for k, f in enumerate(notes):
        start = int(n * k * 0.18)
        ln = int(0.16 * SR)
        for i in range(ln):
            if start + i >= n:
                break
            while len(out) <= start + i:
                out.append(0.0)
            amp = (1 - i / ln)
            out[start + i] += math.sin(2 * math.pi * f * i / SR) * amp * vol
    write_wav(name, out)


sweep("swing", 2400, 300, 0.22, 0.5, "noise")
sweep("hit", 400, 90, 0.16, 0.8, "sine")
rattle("death", 7, 0.7)
arp("levelup", [523, 659, 784, 1047], 0.11)
arp("click", [1200], 0.04, 0.4)
sweep("door", 55, 38, 1.4, 0.7, "sine")
sweep("hurt", 320, 140, 0.22, 0.6, "saw")
arp("pickup", [880, 1319], 0.09, 0.5)
# v4
sweep("dash", 600, 3200, 0.18, 0.55, "noise")
sweep("whirl", 400, 1600, 0.45, 0.6, "noise")
boom("thunder", 0.6)
arp("xp", [1568], 0.05, 0.35)
shimmer("chest", 0.7)
boom("gate", 0.5, 0.8)
arp("deny", [220, 180], 0.09, 0.45)
print("SFX SYNTH DONE")
