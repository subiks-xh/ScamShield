import requests

# Create dummy wav (just 10 bytes)
with open("test.wav", "wb") as f:
    f.write(b"0" * 44)

res = requests.post("http://localhost:3000/api/analyze", files={"file": open("test.wav", "rb")})
print(res.status_code)
print(res.text)
