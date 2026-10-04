package com.example.daily_habit

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.Calendar

private const val ALARM_CHANNEL = "habit_alarms"
private const val ALARM_NOTIFICATION_ID = 8701
private const val PREFS = "scheduled_habit_alarms"

object HabitAlarms {
    fun schedule(context: Context, id: Long, title: String, year: Int, month: Int, day: Int, hour: Int, minute: Int, repeatDaily: Boolean) {
        ensureChannel(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val entry = JSONObject().put("title", title).put("year", year).put("month", month).put("day", day).put("hour", hour).put("minute", minute).put("repeat", repeatDaily)
        prefs.edit().putString(id.toString(), entry.toString()).apply()
        arm(context, id, title, year, month, day, hour, minute, repeatDaily)
    }

    fun cancel(context: Context, id: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(alarmPendingIntent(context, id))
    }

    fun arm(context: Context, id: Long, title: String, year: Int, month: Int, day: Int, hour: Int, minute: Int, repeatDaily: Boolean) {
        val whenToRing = Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis() && repeatDaily) {
                timeInMillis = System.currentTimeMillis()
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val broadcast = Intent(context, HabitAlarmReceiver::class.java).putExtra("id", id).putExtra("title", title).putExtra("repeat", repeatDaily)
        val pending = PendingIntent.getBroadcast(context, requestCode(id), broadcast, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenToRing.timeInMillis, pending)
            else manager.setExact(AlarmManager.RTC_WAKEUP, whenToRing.timeInMillis, pending)
        } catch (_: SecurityException) {
            // Keep the reminder functional when Android's exact-alarm access is disabled.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenToRing.timeInMillis, pending)
            else manager.set(AlarmManager.RTC_WAKEUP, whenToRing.timeInMillis, pending)
        }
    }

    fun armNextDaily(context: Context, id: Long, title: String, hour: Int, minute: Int) {
        val now = Calendar.getInstance()
        arm(context, id, title, now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH), hour, minute, true)
    }

    fun restore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        for ((key, value) in prefs.all) {
            val id = key.toLongOrNull() ?: continue
            val data = runCatching { JSONObject(value as String) }.getOrNull() ?: continue
            val title = data.optString("title", "Habit reminder")
            val hour = data.optInt("hour", 9)
            val minute = data.optInt("minute", 0)
            if (data.optBoolean("repeat", false)) {
                armNextDaily(context, id, title, hour, minute)
            } else {
                arm(context, id, title, data.optInt("year", 2026), data.optInt("month", 1), data.optInt("day", 1), hour, minute, false)
            }
        }
    }

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(NotificationChannel(ALARM_CHANNEL, "Habit alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Ringing reminders for your habits"
                setSound(null, null)
            })
        }
    }

    private fun requestCode(id: Long) = (id xor (id ushr 32)).toInt()
    private fun alarmPendingIntent(context: Context, id: Long) = PendingIntent.getBroadcast(
        context,
        requestCode(id),
        Intent(context, HabitAlarmReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

class HabitAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getLongExtra("id", 0L)
        val saved = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(id.toString(), null)
        if (saved == null) return
        val data = runCatching { JSONObject(saved) }.getOrNull() ?: return
        if (data.optBoolean("repeat", false)) {
            HabitAlarms.armNextDaily(context, id, data.optString("title"), data.optInt("hour"), data.optInt("minute"))
        } else {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
        }
        val service = Intent(context, AlarmSoundService::class.java).putExtra("title", data.optString("title", "Habit reminder"))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(service) else context.startService(service)
    }
}

class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = HabitAlarms.restore(context)
}

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        context.stopService(Intent(context, AlarmSoundService::class.java))
    }
}

class AlarmSoundService : Service() {
    private var ringtone: Ringtone? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        HabitAlarms.ensureChannel(this)
        val title = intent?.getStringExtra("title") ?: "Habit reminder"
        val stopIntent = PendingIntent.getBroadcast(this, 9102, Intent(this, AlarmActionReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = launchIntent?.let { PendingIntent.getActivity(this, 9103, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE) }
        val notification = NotificationCompat.Builder(this, ALARM_CHANNEL)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Time for your habit")
            .setContentText(title)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentIntent)
            .addAction(0, "Stop", stopIntent)
            .addAction(0, "Got it", stopIntent)
            .build()
        startForeground(ALARM_NOTIFICATION_ID, notification)
        if (ringtone?.isPlaying != true) {
            val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ringtone = RingtoneManager.getRingtone(this, sound)?.apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
                audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
                play()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        ringtone?.stop()
        ringtone = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
