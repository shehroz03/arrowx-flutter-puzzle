"""Synthesize the six trail-effect sounds as 16-bit mono WAVs (22050 Hz)."""
import math, random, struct, wave, os

SR = 22050
random.seed(42)

def env_fade(s, fade_in=0.005, fade_out=0.03):
    n = len(s)
    fi, fo = int(fade_in * SR), int(fade_out * SR)
    for i in range(min(fi, n)):
        s[i] *= i / fi
    for i in range(min(fo, n)):
        s[n - 1 - i] *= i / fo
    return s

def normalize(s, peak=0.55):
    m = max(abs(x) for x in s) or 1.0
    return [x / m * peak for x in s]

def write(name, s):
    s = env_fade(normalize(s))
    path = os.path.join(r"D:\arrow game\assets\sounds", name)
    with wave.open(path, 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x)) * 32767)) for x in s))
    print(name, len(s) / SR, 's')

def lowpass(s, a):
    out, y = [], 0.0
    for x in s:
        y += a * (x - y)
        out.append(y)
    return out

def highpass(s, a):
    lp = lowpass(s, a)
    return [x - l for x, l in zip(s, lp)]

def whoosh(dur, f_lo=0.04, f_hi=0.25, curve=2.0):
    """Band-swept noise: cutoff rises then falls -> classic swish."""
    n = int(dur * SR)
    noise = [random.uniform(-1, 1) for _ in range(n)]
    out, y = [], 0.0
    for i, x in enumerate(noise):
        t = i / n
        sweep = math.sin(math.pi * t) ** curve
        a = f_lo + (f_hi - f_lo) * sweep
        y += a * (x - y)
        out.append(y * sweep)
    return highpass(out, 0.02)

# 1) ECHO — a whoosh followed by two softer ghost repeats
base = whoosh(0.30)
n = int(0.68 * SR)
echo = [0.0] * n
for i, x in enumerate(base):
    echo[i] += x
    j1, j2 = i + int(0.16 * SR), i + int(0.32 * SR)
    if j1 < n: echo[j1] += 0.45 * x
    if j2 < n: echo[j2] += 0.20 * x
write('trail_echo.wav', echo)

# 2) DUST — dry granular crumble, decaying
n = int(0.42 * SR)
dust = []
gate = 0.0
for i in range(n):
    t = i / n
    if random.random() < 0.012:
        gate = random.uniform(0.5, 1.0)
    gate *= 0.9985
    dust.append(random.uniform(-1, 1) * gate * (1 - t) ** 1.4)
dust = lowpass(dust, 0.32)
write('trail_dust.wav', dust)

# 3) WARP — fast rising sci-fi swoosh
n = int(0.42 * SR)
warp = []
ph = 0.0
for i in range(n):
    t = i / n
    f = 230 * (1050 / 230) ** t          # exponential rise 230 -> 1050 Hz
    ph += 2 * math.pi * f / SR
    tone = math.sin(ph) * 0.55
    airy = random.uniform(-1, 1) * 0.6
    amp = math.sin(math.pi * min(1, t * 1.25)) ** 1.5
    warp.append((tone + airy) * amp)
warp = highpass(lowpass(warp, 0.35), 0.03)
write('trail_warp.wav', warp)

# 4) PORTAL — wormhole dive: pitch dips then rises, with shimmer
n = int(0.62 * SR)
portal = []
ph = ph2 = 0.0
for i in range(n):
    t = i / n
    f = 520 - 340 * math.sin(math.pi * t)          # 520 -> 180 -> 520
    f *= 1 + 0.02 * math.sin(2 * math.pi * 9 * t)  # vibrato
    ph += 2 * math.pi * f / SR
    ph2 += 2 * math.pi * f * 2.01 / SR
    amp = math.sin(math.pi * t) ** 0.8
    portal.append((math.sin(ph) * 0.8 + math.sin(ph2) * 0.25) * amp)
write('trail_portal.wav', portal)

# 5) RIPPLE — two soft water-drop pings
n = int(0.50 * SR)
ripple = [0.0] * n
def ping(start, f0, gain, dur=0.30):
    ph = 0.0
    for i in range(int(dur * SR)):
        j = int(start * SR) + i
        if j >= n: break
        t = i / (dur * SR)
        f = f0 * (0.45 + 0.55 * math.exp(-t * 5))   # pitch falls like a droplet
        ph += 2 * math.pi * f / SR
        ripple[j] += math.sin(ph) * math.exp(-t * 7) * gain
ping(0.00, 820, 1.0)
ping(0.20, 560, 0.5)
write('trail_ripple.wav', ripple)

# 6) BOLT — electric crackle: stutter bursts + buzzy undertone
n = int(0.45 * SR)
bolt = []
burst = 0
for i in range(n):
    t = i / n
    if burst <= 0 and random.random() < 0.02:
        burst = random.randint(int(0.004 * SR), int(0.016 * SR))
    z = random.uniform(-1, 1) if burst > 0 else random.uniform(-1, 1) * 0.08
    burst -= 1
    buzz = 0.35 * math.copysign(1, math.sin(2 * math.pi * 110 * t * (n / SR)))
    bolt.append((z + buzz * (random.random() < 0.7)) * (1 - t) ** 0.8)
bolt = highpass(bolt, 0.06)
write('trail_bolt.wav', bolt)
