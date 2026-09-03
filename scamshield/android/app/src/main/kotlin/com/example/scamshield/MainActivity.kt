package com.example.scamshield

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.scamshield/call_screening"
    private var methodChannel: MethodChannel? = null

    private val callReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val phoneNumber = intent?.getStringExtra("PHONE_NUMBER") ?: return
            methodChannel?.invokeMethod("onIncomingCall", phoneNumber)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Register receiver for calls
        val filter = IntentFilter("com.example.scamshield.INCOMING_CALL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(callReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(callReceiver, filter)
        }
        
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "checkCallScreeningRole") {
                // Return whether we have the role
                // For demo purposes, we assume role is handled via UI intents directly
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(callReceiver)
    }
}
