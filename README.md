<h1 align="center">🔒 LockScreenVocab</h1>

<p align="center">
    Ｌｅａｒｎ　ａ　ｌａｎｇｕａｇｅ　ｉｎ　ｔｈｅ　ｓｅｃｏｎｄｓ　ｙｏｕ　ａｌｒｅａｄｙ　ｓｐｅｎｄ　ｕｎｌｏｃｋｉｎｇ　ｙｏｕｒ　ｐｈｏｎｅ
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.13+-0175C2?style=flat-square&logo=dart&logoColor=white"></a>
  <a href="https://pub.dev/packages/sqflite"><img alt="SQLite" src="https://img.shields.io/badge/SQLite-sqflite-003B57?style=flat-square&logo=sqlite&logoColor=white"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-3DDC84?style=flat-square&logo=android&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/Status-Work%20in%20progress-orange?style=flat-square">
</p>

<p align="center">
  <a href="https://github.com/quendo05/flutter_lockscreen_learning_app/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/quendo05/flutter_lockscreen_learning_app?style=flat-square&labelColor=343b41"></a>
  <a href="https://github.com/quendo05/flutter_lockscreen_learning_app/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/quendo05/flutter_lockscreen_learning_app?style=flat-square&labelColor=343b41"></a>
  <a href="https://github.com/quendo05/flutter_lockscreen_learning_app/issues"><img alt="Issues" src="https://img.shields.io/github/issues/quendo05/flutter_lockscreen_learning_app?style=flat-square&labelColor=343b41"></a>
  <img alt="Top language" src="https://img.shields.io/github/languages/top/quendo05/flutter_lockscreen_learning_app?style=flat-square&labelColor=343b41">
</p>

---

## 📖 About

**LockScreenVocab** turns the most-visited screen on your phone into a flashcard.
Vocabulary you save is grouped into decks and rotates on your lock screen
through the day — one term every few hours, seen dozens of times without ever
opening an app.

The interesting constraint is that **no Dart runs at display time**. A lock
screen widget is drawn by the platform, not by Flutter, so the app computes a
schedule of upcoming terms *while it is open* and the native widget simply
reads the next entry off that schedule.

> ⚠️ **Early days.** The Flutter side — decks, vocabulary, storage, scheduling —
> is taking shape. The native lock screen widget is not built yet. Expect this
> README to grow.

## ✨ Status

| | Feature |
|---|---|
| ✅ | Decks as the unit of vocabulary — browse, create, choose |
| ✅ | Add and list terms with their translations |
| ✅ | Local persistence on SQLite, with schema migrations |
| ✅ | Schedule of upcoming terms computed ahead of time |
| 🚧 | Native lock screen widget (Android first, then iOS) |
| 🚧 | Settings screen — interval, languages |
| 📋 | Spaced repetition instead of a flat rotation |

## 🛠️ Tech

<code><img height="30" alt="Flutter" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/flutter/flutter.png"></code>
<code><img height="30" alt="Dart" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/dart/dart.png"></code>
<code><img height="30" alt="SQLite" src="https://raw.githubusercontent.com/github/explore/31ea1181d4a76262931a39ca68e0203774a69b60/topics/sqlite/sqlite.png"></code>
<code><img height="30" alt="Android" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/android/android.png"></code>
<code><img height="30" alt="iOS" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/ios/ios.png"></code>
<code><img height="30" alt="Git" src="https://raw.githubusercontent.com/github/explore/31ea1181d4a76262931a39ca68e0203774a69b60/topics/git/git.png"></code>

## 🚀 Getting started

```sh
flutter pub get
flutter run       # Android or iOS
flutter test
flutter analyze
```

The web build runs too, for quick UI iteration, but nothing it stores survives
a reload: `sqflite` has no web implementation, so `main.dart` wires up the
in-memory repositories there instead of failing to start.

## 🧱 Architecture

<details>
  <summary><b>📂 How the code is laid out</b></summary>

  <br />

```
lib/
  config/      what the app does out of the box: its name, its defaults
  domain/      the vocabulary itself and the rules for scheduling it
    models/
    use_cases/
  data/        where that vocabulary is kept
    repositories/
    services/
  ui/          one folder per screen, plus the pieces screens share
    core/
    home/
    deck_list/
    vocab_list/
  utils/       small seams the layers share, such as the injectable clock
```

Dependencies point one way. `ui` may use `domain` and the repository interfaces
in `data`; `data` may use `domain`; `domain` depends on nothing above it. The
concrete repositories are chosen once, in `main.dart`, and passed down — there
is no service locator to consult.

`test/` mirrors `lib/` file for file, so the tests covering a change sit at the
matching path.

</details>

<details>
  <summary><b>🧩 Patterns worth knowing before adding a screen</b></summary>

  <br />

**A screen is a folder** holding `view_models/` and `widgets/`. The widget
renders; the view model does the reading. Nothing fetches data from `build`.

**View models extend `LoadableViewModel`.** It owns the four states every
screen renders — loading, failed read, nothing saved yet, content — along with
the try/catch around every repository call. A subclass supplies three things:
how to read its content, how to drop it, and what to say when a read fails.

Input problems are kept apart from read failures on purpose. A blank field is
not a failure of the app, so `validationMessage` surfaces transiently and
leaves the content on screen, while `loadError` replaces it.

**A repository is an interface with two implementations**, one in memory and
one on SQLite. Both run the same contract test suite, which is what makes
swapping them safe. Add a method to the interface and the contract test is
where its behaviour gets pinned down.

**`AppDatabase` owns the schema and its migrations.** Changing a table means
bumping `schemaVersion` and adding an `_upgrade` branch, with a test that opens
a database at the old version and reads it back at the new one.

</details>

<details>
  <summary><b>⚙️ Conventions the analyzer enforces</b></summary>

  <br />

`analysis_options.yaml` is deliberately stricter than the Flutter defaults:
implicit downcasts, inferred `dynamic` and raw generics are all rejected, and
an unawaited future is an error rather than a hint. Run `flutter analyze`
before committing; it is expected to be silent, and `dart format .` keeps the
diff honest.

</details>

<div align="center">
  <br />
  <sub>Built with Flutter by <a href="https://github.com/quendo05">@quendo05</a> · ⭐ if the idea appeals to you</sub>
</div>
