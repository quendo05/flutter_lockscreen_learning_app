plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // After Flutter's plugin on purpose: `android.builtInKotlin=false` means that
    // plugin is what imperatively applies `kotlin-android`, so before this line
    // there is no Kotlin compilation for the Compose compiler to attach to.
    //
    // `org.jetbrains.kotlin.android` deliberately does not appear here. Flutter
    // regex-scans this file for it and fails the build telling you to migrate to
    // built-in Kotlin; it applies the plugin itself instead.
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.github.quendo05.nagara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // The legacy spelling, because `android.newDsl=false` in gradle.properties
        // keeps the legacy extension and this is where it lives there.
        compose = true
    }

    defaultConfig {
        // Fixed for the life of the app: Play binds the listing to this string,
        // so it cannot change after the first upload. `com.example` would have
        // been rejected at upload time anyway.
        applicationId = "com.github.quendo05.nagara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Still RemoteViews at the bottom: the launcher draws the widget in its own
    // process and nothing changes that. Glance only replaces hand-built
    // RemoteViews with a Compose tree it translates, which is what buys the
    // suspending data load the widget needs to read its queue off a file.
    //
    // 1.2.0 rather than the 1.3.0 alpha line, which needs AGP 9.2.0 and this
    // project is on 9.1.0.
    implementation("androidx.glance:glance-appwidget:1.2.0")
}
