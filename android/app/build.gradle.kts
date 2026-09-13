import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties (gitignored). If that
// file is absent, release falls back to debug signing so anyone can still build
// locally. Create the file from key.properties.example to sign for the Play Store.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// `flutter build ... --dart-define=UNLOCK_ALL=true` reaches Gradle as a
// comma-separated list of base64 strings. A build with every level unlocked
// is a tester build, so it takes the testing identity (.testing app id,
// "Arrow Testing") even in release mode and installs alongside the real app.
val dartDefines: List<String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.filter { it.isNotBlank() }
    ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?: emptyList()
val unlockAllTesterBuild = dartDefines.contains("UNLOCK_ALL=true")

android {
    namespace = "app.curious.arrow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Required to use resValue() for the per-build-type app name.
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "app.curious.arrow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        // Debug = the testing build: installs alongside release with its own app
        // id (.testing) and the name "Arrow Testing". All levels are unlocked
        // (kDebugMode) so testers can play any level.
        getByName("debug") {
            applicationIdSuffix = ".testing"
            resValue("string", "app_name", "Arrow Testing")
        }
        // Release = the production build: "Arrow", levels locked until cleared.
        // Signed with the upload key when key.properties exists, else debug.
        // With --dart-define=UNLOCK_ALL=true it becomes the small tester build
        // and borrows the debug identity so it never overwrites the real app.
        getByName("release") {
            signingConfig = if (hasReleaseKeystore && !unlockAllTesterBuild) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            if (unlockAllTesterBuild) {
                applicationIdSuffix = ".testing"
                resValue("string", "app_name", "Arrow Testing")
            } else {
                resValue("string", "app_name", "Arrow")
            }
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
