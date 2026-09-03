import time
import numpy as np
import soundfile as sf
import whisper

# Generate 3.5 seconds of random noise (simulating speech)
sr = 16000
duration = 3.5
y = np.random.randn(int(sr * duration)).astype(np.float32) * 0.1
sf.write("benchmark.wav", y, sr)

print("Loading model 'tiny'...")
t0 = time.time()
model = whisper.load_model("tiny")
print(f"Model loaded in {time.time()-t0:.2f}s")

print("Running inference on 3.5s chunk...")
t1 = time.time()
res = model.transcribe("benchmark.wav", fp16=False)
t2 = time.time()

print(f"Inference latency: {t2-t1:.2f} seconds")
