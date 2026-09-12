pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    // Glance widgets are Compose, so the Compose compiler has to run over the app
    // module. Version-locked to the Kotlin plugin above: since Kotlin 2.0 the
    // Compose compiler ships as part of the Kotlin release, which is also why no
    // `composeOptions { kotlinCompilerExtensionVersion }` appears anywhere.
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.0" apply false
}

include(":app")
