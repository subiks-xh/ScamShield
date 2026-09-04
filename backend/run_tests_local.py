import asyncio
import edge_tts
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from main import transcribe_audio

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
        "text": "I am speaking now. And now I am continuing after a pause.",
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
    wav_file = f"test_{index}.mp3"
    
    # Generate audio
    text = test_info['text']
    rate = test_info['rate']
    communicate = edge_tts.Communicate(text, "en-US-AriaNeural", rate=rate)
    await communicate.save(wav_file)
    
    # Transcribe directly using backend function
    result = transcribe_audio(wav_file)
    
    print(f"[{test_info['name']}] Expected: {text}")
    print(f"[{test_info['name']}] Actual  : {result['text']}")

async def main():
    for i, test in enumerate(TESTS):
        await run_test(test, i)
        
if __name__ == "__main__":
    asyncio.run(main())
