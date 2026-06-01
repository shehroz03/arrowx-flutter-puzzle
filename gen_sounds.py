import wave, struct, math

def generate_tone(filename, freq, duration, mod_freq=0, decay=True, attack=0.01):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setparams((1, 2, sample_rate, num_samples, 'NONE', 'not compressed'))
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Frequency modulation
            f = freq + (mod_freq * t * 10)
            
            # Simple Synthesis
            value = float(32767.0 * math.sin(2.0 * math.pi * f * t))
            
            # Envelope (Attack & Decay)
            env = 1.0
            if t < attack:
                env = t / attack
            elif decay:
                env = max(0.0, 1.0 - ( (t - attack) / (duration - attack) ))
                
            value = int(value * env * 0.5) # 50% volume to prevent clipping
            if value > 32767: value = 32767
            if value < -32768: value = -32768
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

# 'tap' - short, crisp pop
generate_tone('assets/sounds/tap.wav', freq=800, duration=0.08, decay=True, attack=0.005)
# 'whoosh' - sliding down pitch
generate_tone('assets/sounds/whoosh.wav', freq=600, duration=0.25, mod_freq=-3000, decay=True)
# 'error' - low buzz
generate_tone('assets/sounds/error.wav', freq=150, duration=0.3, mod_freq=-50, decay=True)
# 'success' - rising high pitch chime
generate_tone('assets/sounds/success.wav', freq=500, duration=1.0, mod_freq=2000, decay=True)
# 'bgm' - a more pleasant melodic loop
def generate_bgm(filename):
    sample_rate = 44100
    duration = 4.0 # 4 seconds loop
    num_samples = int(sample_rate * duration)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setparams((1, 2, sample_rate, num_samples, 'NONE', 'not compressed'))
        notes = [261.63, 329.63, 392.00, 523.25] # C4, E4, G4, C5
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Cycle through notes every second
            note_idx = int(t) % len(notes)
            freq = notes[note_idx]
            
            # Sub-beat pulse
            beat_t = t % 1.0
            env = math.exp(-beat_t * 3.0)
            
            value = float(32767.0 * math.sin(2.0 * math.pi * freq * t))
            value = int(value * env * 0.3)
            
            if value > 32767: value = 32767
            if value < -32768: value = -32768
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

generate_bgm('assets/sounds/bgm.wav')

print("Generated all audio files in assets/sounds/")
