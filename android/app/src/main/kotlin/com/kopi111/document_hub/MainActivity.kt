package com.kopi111.document_hub

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // App-wide privacy: FLAG_SECURE blocks screenshots and screen recording
        // across every screen, and hides the app in the recents switcher.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }
}
