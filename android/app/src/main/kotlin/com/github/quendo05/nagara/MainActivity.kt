package com.github.quendo05.nagara

import com.github.quendo05.nagara.widget.VocabWidgetReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Carries no queue, only the news that one was written. The widget
        // reads the file itself, which is the only version of this that still
        // works when the app is not running.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refresh" -> {
                        VocabWidgetReceiver.refresh(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        /** Shared with `PlatformWidgetRefresher` in `widget_refresher.dart`. */
        const val WIDGET_CHANNEL = "nagara/widget"
    }
}
