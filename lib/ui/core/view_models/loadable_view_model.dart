import 'package:flutter/foundation.dart';

/// The four situations every screen in this app renders: loading, a failed
/// read, nothing saved yet, and content.
///
/// Each view model used to carry its own copy of these flags along with the
/// same try/catch around every repository call. Keeping them here means a new
/// screen inherits the behaviour rather than re-deriving it, and the rule that
/// a failed read is not an empty collection is enforced in one place instead
/// of being restated per screen.
///
/// Subclasses supply three things: how to read their content, how to drop it,
/// and what to say when the read fails.
abstract class LoadableViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadError;
  String? _validationMessage;

  /// True while a repository call is in flight.
  bool get isLoading => _isLoading;

  /// Set when the store could not be read. Replaces the content, because
  /// there is nothing trustworthy left to show.
  String? get loadError => _loadError;

  /// Set when the user's input was unusable. Deliberately kept apart from
  /// [loadError]: a blank field is not a failure of the app, so the content
  /// stays on screen while the message is surfaced transiently.
  String? get validationMessage => _validationMessage;

  /// True only when a read succeeded and there is nothing saved to show.
  ///
  /// Guarding on the read having succeeded here, rather than in each subclass,
  /// is what stops a failure from being presented as an empty collection.
  bool get isEmpty => !_isLoading && _loadError == null && hasNoContent;

  /// Whether the subclass is holding anything worth rendering.
  @protected
  bool get hasNoContent;

  /// What to tell the user when a repository call throws, worded in terms of
  /// what they were looking at.
  @protected
  String get loadErrorMessage;

  /// Reads whatever the subclass shows. May throw: the failure is caught and
  /// turned into [loadError] for it.
  @protected
  Future<void> readContent();

  /// Drops whatever the subclass is holding, so a failed read never leaves
  /// stale content sitting next to an error message.
  @protected
  void discardContent();

  /// Fills the view model from its repositories.
  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    await _read();
  }

  /// Marks the validation message as delivered.
  ///
  /// Does not notify: nothing in the tree renders from this field directly, so
  /// notifying here would only re-enter the listener that consumed it.
  void clearValidationMessage() => _validationMessage = null;

  /// Rejects what the user typed, leaving the content on screen untouched.
  @protected
  void rejectInput(String message) {
    _validationMessage = message;
    notifyListeners();
  }

  /// Runs a write and re-reads afterwards, so the screen reflects the result.
  ///
  /// A write that throws is reported the same way a failed read is: there is
  /// no longer any reason to trust what is on screen.
  @protected
  Future<void> guard(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error) {
      _reportFailure(error);
      return;
    }

    await _read();
  }

  Future<void> _read() async {
    try {
      await readContent();
    } on Object catch (error) {
      _reportFailure(error);
      return;
    }

    _isLoading = false;
    _loadError = null;
    notifyListeners();
  }

  void _reportFailure(Object error) {
    debugPrint('$runtimeType: $error');
    discardContent();
    _isLoading = false;
    _loadError = loadErrorMessage;
    notifyListeners();
  }
}
