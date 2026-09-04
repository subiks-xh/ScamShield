import asyncio
import websockets
import json
import subprocess
import os

TESTS = [
    {
        "name": "Test 1 - Normal speech",
        "text": "Hello, my name is John and I am calling about my bank account. I noticed some unusual charges yesterday and I would like to dispute them immediately.",
        "rate": "+0%"
    },
    {
        "name": "Test 2 - Slow speech",
        "text": "Please. Read. This. Very. Slowly. And. Carefully.",
        "rate": "-50%"
    },
    {
        "name": "Test 3 - Fast speech",
        "text": "I need to get this done as fast as possible so please hurry up and listen to me.",
        "rate": "+50%"
    },
    {
        "name": "Test 4 - Longer sentence",
        "text": "This is a much longer sentence that is designed to take significantly more than three and a half seconds to speak so that we can test how the application handles overlapping transcription intervals.",
        "rate": "+0%"
    },
    {
        "name": "Test 5 - Pause",
        "text": "I am speaking now... <break time='2500ms'/> ...and now I am continuing after a pause.",
        "rate": "+0%"
    },
    {
        "name": "Test 6 - Scam example",
        "text": "Hello, this is the bank security department. We detected suspicious activity on your account. You need to verify your identity immediately by providing the OTP that was sent to your phone.",
        "rate": "+0%"
    }
]

async def run_test(test_info, index):
    print(f"\n--- Running {test_info['name']} ---")
    wav_file = f"test_{index}.wav"
    
    # Generate audio
    text = test_info['text']
    rate = test_info['rate']
    cmd = ["edge-tts", "--text", text, "--rate", rate, "--write-media", wav_file]
    subprocess.run(cmd, check=True)
    
    # Read generated audio
    with open(wav_file, "rb") as f:
        audio_data = f.read()
        
    print(f"Generated {len(audio_data)} bytes of audio.")
    
    # Connect and stream simulated cumulative chunks
    uri = "ws://127.0.0.1:8000/ws/analyze-live"
    try:
        async with websockets.connect(uri) as ws:
            # Simulate 3 cumulative chunks
            chunk_size = len(audio_data) // 3
            
            for i in range(1, 4):
                chunk = audio_data[:chunk_size * i]
                if i == 3:
                    chunk = audio_data # send all
                    
                print(f"[{test_info['name']}] Sending cumulative chunk {i}/3 ({len(chunk)} bytes)...")
                await ws.send(chunk)
                
                # Wait for response
                try:
                    res = await asyncio.wait_for(ws.recv(), timeout=20.0)
                    data = json.loads(res)
                    print(f"[{test_info['name']}] Received Transcript: '{data.get('transcript', '')}'")
                    print(f"[{test_info['name']}] Received Score: {data.get('score', 0)}")
                except asyncio.TimeoutError:
                    print(f"[{test_info['name']}] Timeout waiting for response.")
                except Exception as e:
                    print(f"[{test_info['name']}] Error reading response: {e}")
                    
                await asyncio.sleep(3.5) # wait between chunks
                
    except Exception as e:
        print(f"Connection failed: {e}")

async def main():
    for i, test in enumerate(TESTS):
        await run_test(test, i)
        
if __name__ == "__main__":
    asyncio.run(main())
