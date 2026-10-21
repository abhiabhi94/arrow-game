package app.curious.arrow

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Flutter's own HapticFeedback maps to View.performHapticFeedback, which
/// Android silences whenever the user has "touch feedback" off (the default
/// on plenty of phones). The game's haptics therefore talk to the Vibrator
/// service directly through this channel, so a slide always ticks and a
/// bump always buzzes while the in-app switch is on.
/// A FlutterFragmentActivity rather than a FlutterActivity: it is a
/// ComponentActivity, which is what androidx.activity's enableEdgeToEdge()
/// needs — and that call, by name, is what the Play Console's edge-to-edge
/// check looks for ("Edge-to-edge may not display for all users" kept
/// firing against the equivalent WindowCompat.enableEdgeToEdge, which the
/// scan does not recognise). Nothing else changes: the engine, the plugins
/// and the haptics channel are hosted the same way.
class MainActivity : FlutterFragmentActivity() {
    /// Android 15+ draws a targetSdk-35 app edge to edge on its own; this
    /// does the same on older versions (transparent system bars, content
    /// behind them), so every phone gets the one layout. The Flutter side
    /// already keeps its content clear of the bars through the system insets.
    /// It runs after super.onCreate, which sets its own system-UI flags (and,
    /// below API 35, a grey status-bar scrim) that would otherwise undo it.
    /// proguard-rules.pro keeps the call from being inlined away in release
    /// builds, so the Play scan can see it.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
    }

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
            // The crash of a bump, a life lost: a hard hit, a beat, then a
            // rumble — long enough to be felt without looking.
            "crash" -> if (amp) {
                VibrationEffect.createWaveform(longArrayOf(0, 70, 40, 130), intArrayOf(0, 255, 0, 200), -1)
            } else {
                VibrationEffect.createWaveform(longArrayOf(0, 70, 40, 130), -1)
            }
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
