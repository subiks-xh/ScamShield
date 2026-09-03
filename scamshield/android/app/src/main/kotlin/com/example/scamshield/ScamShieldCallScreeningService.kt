package com.example.scamshield

import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

class ScamShieldCallScreeningService : CallScreeningService() {
    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = callDetails.handle?.schemeSpecificPart ?: ""
        Log.d("ScamShield", "Incoming call detected: $phoneNumber")

        // Construct response: allow the call but report it to Flutter
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(callDetails, response)

        // Send broadcast to MainActivity/Flutter MethodChannel
        val intent = Intent("com.example.scamshield.INCOMING_CALL")
        intent.putExtra("PHONE_NUMBER", phoneNumber)
        sendBroadcast(intent)
    }
}
