import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_missing_api_key_demo():
    # If groq api key isn't provided, it falls back to demo
    response = client.post("/analyze", data={"is_demo": "true"}, files={"file": ("test.webm", b"dummy audio", "audio/webm")})
    assert response.status_code == 200
    data = response.json()
    assert "verdict" in data
    assert "transcript" in data
    assert data["transcription_method"] in ["demo_mock", "mock_demo"]

def test_report_number():
    response = client.post("/report-number", json={"phone_number": "+1234567890", "notes": "Test scam"})
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True

def test_check_number():
    response = client.get("/check-number/+1234567890")
    assert response.status_code == 200
    data = response.json()
    assert data["found"] is True
