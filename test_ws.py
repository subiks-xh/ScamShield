import asyncio
import websockets
import json
import time

async def test_ws():
    uri = "ws://127.0.0.1:8000/ws/analyze-live"
    async with websockets.connect(uri) as websocket:
        print("Connected to WebSocket.")
        
        # We will just send small binary chunks and see the response
        # We can send a valid tiny webm file repeatedly.
        # But for now, just to trigger the transcript, we'll send a dummy payload.
        # The endpoint expects valid audio, so we might need to send a real wav file.
        
        try:
            with open("benchmark.wav", "rb") as f:
                audio_data = f.read()
                
            print(f"Sending {len(audio_data)} bytes of audio...")
            await websocket.send(audio_data)
            
            # Wait for response
            response = await websocket.recv()
            print("Response:", response)
            
        except Exception as e:
            print("Error:", e)

if __name__ == "__main__":
    asyncio.run(test_ws())
