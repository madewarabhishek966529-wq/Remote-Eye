plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.remote_eye"
    // Explicitly set to 36: flutter_webrtc and mobile_scanner depend on
    // AndroidX libraries (fragment 1.7.1, core-ktx 1.13.1, activity 1.8.1, etc.)
    // that require compileSdk >= 34. Using 36 for forward compatibility.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Replace with your developer namespace, e.g. com.yourname.remoteeye
        applicationId = "com.example.remote_eye"
        // minSdk 24 (Android 7.0) is required by flutter_webrtc for WebRTC APIs.
        minSdk = 24
        targetSdk = 36
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
