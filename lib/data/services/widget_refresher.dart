import 'package:flutter/services.dart';

/// Tells the native side that a new queue is waiting to be read.
///
/// An interface rather than a bare [MethodChannel] call, because a widget
/// exists on some of the platforms this app runs on and not others. The web
/// build and every test need something that does nothing, and one seam is
/// cheaper than a null check at each call site.
///
/// Deliberately carries no payload. The queue travels through the file the
/// schedule store writes, which the widget can re-read whenever it likes — a
/// channel message only arrives while the app is alive, so anything sent this
/// way would be gone by the moment it mattered.
abstract class WidgetRefresher {
  Future<void> refresh();
}

/// Pokes the Android home screen widget through the app's method channel.
class PlatformWidgetRefresher implements WidgetRefresher {
  const PlatformWidgetRefresher();

  /// Shared with `MainActivity.kt`; the two have no compiler between them, so
  /// renaming here means renaming there.
  static const channel = MethodChannel('lockscreen_learning_app/widget');

  @override
  Future<void> refresh() async {
    await channel.invokeMethod<void>('refresh');
  }
}
