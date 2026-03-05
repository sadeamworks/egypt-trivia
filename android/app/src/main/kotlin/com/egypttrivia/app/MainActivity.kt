package com.egypttrivia.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 15 (SDK 35) compliance.
        // Prevents Flutter engine from using deprecated setStatusBarColor /
        // setNavigationBarColor APIs and enables proper inset handling.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
