package app.curious.arrow

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Flutter's own HapticFeedback maps to View.performHapticFeedback, which
/// Android silences whenever the user has "touch feedback" off (the default
/// on plenty of phones). The game's haptics therefore talk to the Vibrator
/// service directly through this channel, so a slide always ticks and a
/// bump always buzzes while the in-app switch is on.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "vibrate") {
                    play(call.arguments as? String ?: "click")
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    private fun play(effect: String) {
        val v = vibrator() ?: return
        if (!v.hasVibrator()) return
        val amp = v.hasAmplitudeControl()
        val out = when (effect) {
            // A light tick: tapping an arrow.
            "tick" -> VibrationEffect.createOneShot(14, if (amp) 90 else VibrationEffect.DEFAULT_AMPLITUDE)
            // A crisp click: the arrow slid out.
            "click" -> VibrationEffect.createOneShot(24, if (amp) 170 else VibrationEffect.DEFAULT_AMPLITUDE)
            // A firm thud: the arrow bumped, a life lost.
            "heavy" -> VibrationEffect.createOneShot(48, if (amp) 255 else VibrationEffect.DEFAULT_AMPLITUDE)
            // A double buzz: level lost.
            "long" -> VibrationEffect.createWaveform(longArrayOf(0, 90, 70, 160), -1)
            else -> return
        }
        v.vibrate(out)
    }

    private companion object {
        const val CHANNEL = "app.curious.arrow/haptics"
    }
}
