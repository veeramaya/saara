import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (§18.3). Credentials live in android/key.properties, which is
// gitignored — never commit it or the keystore. With Play App Signing the
// upload key here can be reset via Play Console if it is ever lost.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.realmaya.saara"
    // Pinned to 36: Flutter 3.44 requests compileSdk 37, but only the
    // `android-37.0` platform is published (no plain `android-37`), which breaks
    // plugin compilation. 36 is installed and satisfies every dependency.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications v17 (scheduled/zoned alarms).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.realmaya.saara"
        // Needs API 23+ (flutter_secure_storage) and 26+ for Health Connect
        // (§10). Pin minSdk 26.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Real upload signing when key.properties is present; falls back to
            // debug signing otherwise so `flutter run --release` still works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Disable R8 code shrinking/obfuscation. It caused a release-only
            // startup crash and also forced ML Kit keep-rule juggling; the app
            // only uses the Latin recognizer at runtime, so unshrunk is safe.
            // (Re-enable later with per-plugin keep rules if size matters.)
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles("proguard-rules.pro")
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
    // Core-library desugaring runtime for flutter_local_notifications v17.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
