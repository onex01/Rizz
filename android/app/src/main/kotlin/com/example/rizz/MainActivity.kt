package com.dualproj.rizz

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            super.onActivityResult(requestCode, resultCode, data)
        } catch (e: IllegalStateException) {
            Log.w("MainActivity", "Duplicate result delivery ignored", e)
        }
    }
}