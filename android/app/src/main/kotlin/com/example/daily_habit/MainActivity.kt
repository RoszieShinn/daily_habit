package com.example.daily_habit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.os.Build
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.daily_habit/alarms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<String>("id")?.toLongOrNull() ?: run { result.error("invalid", "Missing alarm id", null); return@setMethodCallHandler }
                        val title = call.argument<String>("title") ?: "Habit reminder"
                        val profileName = call.argument<String>("profileName") ?: ""
                        val description = call.argument<String>("description") ?: ""
                        val hour = call.argument<Int>("hour") ?: 9
                        val minute = call.argument<Int>("minute") ?: 0
                        val year = call.argument<Int>("year") ?: 2026
                        val month = call.argument<Int>("month") ?: 1
                        val day = call.argument<Int>("day") ?: 1
                        val repeat = call.argument<Boolean>("repeatDaily") ?: false
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4101)
                        }
                        try {
                            HabitAlarms.schedule(this, id, title, year, month, day, hour, minute, repeat, profileName, description)
                            result.success(null)
                        } catch (error: SecurityException) {
                            result.error("exact_alarm_permission", "Allow exact alarms for Day by Day in Android settings, then save the reminder again.", null)
                        }
                    }
                    "cancel" -> {
                        val id = call.argument<String>("id")?.toLongOrNull()
                        if (id != null) HabitAlarms.cancel(this, id)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
