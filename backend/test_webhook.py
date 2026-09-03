import os
import sys

# Add backend directory to path so we can import main
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from main import trigger_guardian_alert

print("Testing Guardian Webhook...")
dummy_transcript = "Hello, this is the police. You have an unpaid fine of $500. Buy gift cards now or we will arrest you."
trigger_guardian_alert("test_123", 95.0, dummy_transcript)
print("Trigger function returned.")
