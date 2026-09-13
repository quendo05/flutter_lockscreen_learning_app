<h1 align="center">Nagara</h1>

<p align="center">
  <b>ながら</b> — Japanese for <i>“while doing something else”</i>.<br />
  Learn a language in the seconds you already spend unlocking your phone.
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.13+-0175C2?style=flat-square&logo=dart&logoColor=white"></a>
  <a href="https://kotlinlang.org"><img alt="Kotlin" src="https://img.shields.io/badge/Kotlin-2.4-7F52FF?style=flat-square&logo=kotlin&logoColor=white"></a>
  <a href="https://developer.android.com/develop/ui/compose/glance"><img alt="Glance" src="https://img.shields.io/badge/Jetpack%20Glance-1.2-4285F4?style=flat-square&logo=android&logoColor=white"></a>
  <a href="https://pub.dev/packages/sqflite"><img alt="SQLite" src="https://img.shields.io/badge/SQLite-sqflite-003B57?style=flat-square&logo=sqlite&logoColor=white"></a>
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/Android-supported-3DDC84?style=flat-square&logo=android&logoColor=white">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-planned-8E8E93?style=flat-square&logo=apple&logoColor=white">
  <img alt="Tests" src="https://img.shields.io/badge/tests-331%20passing-brightgreen?style=flat-square">
  <a href="https://github.com/quendo05/flutter_lockscreen_learning_app/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/quendo05/flutter_lockscreen_learning_app?style=flat-square&labelColor=343b41"></a>
</p>

---

## Overview

Nagara turns the most-visited screen on your phone into a flashcard. The name is
the Japanese grammatical form for doing one thing while doing another —
ながら学習 is the word for exactly the kind of incidental learning this app is.
Vocabulary you save is grouped into decks and rotates on your lock screen
through the day — one term every few hours, seen dozens of times without ever
opening an app.

The constraint that shapes the whole project is this: **no Dart runs at display
time.** A lock screen widget is drawn by the platform, not by Flutter. The app
therefore cannot answer "what should I show now?" when it matters — it has to
have answered already.

Everything else follows from that. Scheduling is a batch that produces a queue
rather than a "give me the next term" call. The clock is injected rather than
read, so a queue can be asserted against exact timestamps. And the handover to
the native side is a file, not a method call, because a method call only
arrives while the app is alive — which is precisely when the widget does not
need one.

## How it works

```
  While the app is open                      Long after it was closed
  ─────────────────────                      ────────────────────────

  BuildVocabScheduleUseCase                  VocabWidgetReceiver
    picks the next N terms                     woken by the system
            │                                          │
  PublishedSchedule                          ScheduleFile
    the payload both sides agree on            reads the same path
            │                                          │
  NotifyingScheduleStore                     PublishedSchedule.currentAt(now)
    writes, then pings the widget               works out what is due
            │                                          │
            └────────►  schedule.json  ◄───────────────┘
                     (app-private, written
                      atomically via rename)
```

`PublishedSchedule` exists twice — once in Dart, once in Kotlin — with no
compiler between the two halves. A `schemaVersion` field is what catches a
change made on only one side: a payload the widget does not recognise is
treated as no payload at all rather than guessed at.

The widget is written with **Jetpack Glance**, so the same composition serves
the home screen and the lock screen. Android has no separate API for the lock
screen surface: an ordinary app widget appears there on a release that supports
it, unless it opts out. One provider, not two.

## Status

| | |
|---|---|
| ✅ | **Decks** — create, rename, delete, and choose which one feeds the lock screen |
| ✅ | **Per-deck settings** — display interval and language pair |
| ✅ | **Vocabulary** — add, edit and delete, with multi-select for bulk removal |
| ✅ | **Local persistence** — SQLite with versioned schema migrations |
| ✅ | **Scheduling** — a queue computed ahead of time that survives the app closing |
| ✅ | **Android widget** — Jetpack Glance, responsive across five size buckets, light and dark |
| 🚧 | **iOS widget** — WidgetKit, reading the same payload from an App Group container |
| 📋 | **Spaced repetition** — instead of the current flat rotation |

> **Note on the lock screen.** Android brought lock screen widgets back with
> Android 16 QPR1. No code change is needed for them — the widget already
> declares `widgetCategory="home_screen"`, which is what makes it eligible.
> Generic emulator images do not ship the feature, so a physical device is
> needed to see it there.

## Getting started

```sh
flutter pub get
flutter run                                    # Android; web runs but does not persist
flutter run --dart-define=SEED_DEMO_DECKS=true # start with demo vocabulary
```

Before committing:

```sh
flutter analyze            # expected to be silent
flutter test               # the full suite
flutter build apk --debug  # the only check that compiles the widget
dart format .
```

There is no CI. `flutter analyze` and `flutter test` are the gate for Dart, and
neither compiles a line of Kotlin — a change under `android/` is only checked
by building.

The web build exists for quick UI iteration, but nothing it stores survives a
reload: `sqflite` has no web implementation, so `main.dart` wires up the
in-memory repositories there rather than failing to start.

## Architecture

<details>
  <summary><b>How the code is laid out</b></summary>

  <br />

```
lib/
  config/       what the app does out of the box: its name, its defaults
  domain/       the vocabulary itself and the rules for scheduling it
    models/
    use_cases/
  data/         where that vocabulary is kept, and how it reaches the widget
    repositories/
    services/
  ui/           one folder per screen, plus the pieces screens share
    core/
    home/
    deck_list/
    deck_settings/
    vocab_list/
  utils/        small seams the layers share, such as the injectable clock

android/app/src/main/kotlin/.../widget/
                the Glance widget, which reads what the app published
                and nothing else
```

Dependencies point one way. `ui` may use `domain` and the repository interfaces
in `data`; `data` may use `domain`; `domain` depends on nothing above it. The
concrete repositories are chosen once, in `main.dart`, and passed down through
constructors — there is no service locator, no provider package and no global
state.

`test/` mirrors `lib/` file for file, so the tests covering a change sit at the
matching path.

</details>

<details>
  <summary><b>Patterns worth knowing before adding a screen</b></summary>

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

**Models are immutable value objects** — `const` constructor, `copyWith`,
`toMap`/`fromMap`, hand-written equality. No code generation.

</details>

<details>
  <summary><b>The native seam</b></summary>

  <br />

| | |
|---|---|
| `data/services/file_schedule_store.dart` | writes `schedule.json`, atomically via rename |
| `data/services/notifying_schedule_store.dart` | decorator: write, then refresh the widget |
| `data/services/widget_refresher.dart` | the method channel, carrying news rather than data |
| `widget/PublishedSchedule.kt` | the same payload, parsed with `org.json` |
| `widget/ScheduleFile.kt` | the only place that knows the path |
| `widget/VocabWidget.kt` | the Glance composition |
| `widget/VocabWidgetReceiver.kt` | the system's way in |

The file lives in `getApplicationSupportDirectory()`, which is
`Context.getFilesDir()` on Android. An app widget's provider runs in the app's
own process, so it reads the private file directly — no permission, no content
provider, and no locking, because the write is a rename. iOS will need the App
Group container instead, which is a change to one line in `main.dart`.

Two Glance behaviours are worth knowing before touching the widget, because
both are easy to get wrong:

- `update` does **not** restart `provideGlance` while a composition is alive,
  and one stays alive for roughly 45 seconds. The composition therefore
  observes a revision flow rather than reading the file once.
- `SizeMode.Responsive` sizes are a **contract, not a hint**. Glance lays the
  composition out against the bucket it picks, so content taller than that
  bucket is clipped however much room the widget really has.

</details>

<details>
  <summary><b>Conventions the analyzer enforces</b></summary>

  <br />

`analysis_options.yaml` is deliberately stricter than the Flutter defaults:
implicit downcasts, inferred `dynamic` and raw generics are all rejected, and
an unawaited future is an error rather than a hint. Run `flutter analyze`
before committing; it is expected to be silent, and `dart format .` keeps the
diff honest.

Doc comments here explain **why** a decision was made rather than what the code
does — the trade-off taken, the alternative rejected, or the constraint that
forced the shape. A comment restating a signature is worse than none.

</details>

## Testing

```sh
flutter test                                              # all 331
flutter test test/ui/home/home_view_model_test.dart       # one file
flutter test --plain-name 'lists decks oldest first'      # one test
```

Test names read as specifications and state their reason — *"lists decks oldest
first, so the list order stays stable"*. Repository tests run a shared contract
against both implementations. Widget tests pump the real screen inside a
`MaterialApp`. In-memory repositories are preferred over mocks throughout.

The Kotlin side has no test infrastructure yet; `PublishedSchedule.currentAt`
and the JSON parsing are the first things that should get one.

<div align="center">
  <br />
  <sub>Built with Flutter by <a href="https://github.com/quendo05">@quendo05</a></sub>
</div>
