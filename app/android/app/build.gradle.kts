import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key material, injected rather than committed.
//
// key.properties is gitignored and is written by CI (see the android-play
// workflow in codemagic.yaml, which generates it from Codemagic's CM_KEYSTORE_*
// variables). Locally it is absent, and that is fine: only RELEASE builds need
// it, and the release block below fails loudly rather than falling back.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "app.nimit.nimit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Matches the iOS bundle id, deliberately: one identity for the app on
        // both stores. Registered with Apple already; Play claims it on first
        // upload and it can NEVER be changed after that.
        applicationId = "app.nimit.nimit"
        // Flutter's defaults, checked rather than assumed: minSdk 24
        // (Android 7.0), targetSdk 36, compileSdk 36. minSdk 24 covers
        // essentially every OPPO and Vivo still in service, which is the
        // audience; targetSdk 36 clears Play's floor for new apps.
        minSdk = flutter.minSdkVersion
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
            // FAILING HERE IS THE CORRECT BEHAVIOUR when key.properties is
            // absent. The template signed release builds with the DEBUG keystore
            // — every Android developer's shared, publicly-known key — which
            // produces an AAB that builds cleanly, looks finished, and is
            // refused by Play on upload. Worse, it would be refused only after a
            // full CI run, with an error about the certificate rather than about
            // this file.
            //
            // So: no silent fallback. An unsigned release is a configuration
            // mistake and says so, at the start of the build instead of the end
            // of the upload.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Says which file is missing, before Gradle says something less useful about a
// null storeFile. Only fires for release tasks, so debug builds and
// `flutter test` are untouched.
gradle.taskGraph.whenReady {
    val releaseTask = allTasks.any { it.name.contains("Release") }
    if (releaseTask && !rootProject.file("key.properties").exists()) {
        throw GradleException(
            "android/key.properties is missing, so this release build has no " +
                "upload key.\n" +
                "It is gitignored on purpose — the keystore and its passwords " +
                "must not be committed.\n" +
                "In CI: the android-play workflow writes it from Codemagic's " +
                "CM_KEYSTORE_* variables; add the keystore under Settings → " +
                "Code signing identities → Android keystores.\n" +
                "Locally: create android/key.properties with storeFile, " +
                "storePassword, keyAlias and keyPassword.\n" +
                "Do NOT restore the template's debug-keystore fallback: Play " +
                "rejects debug-signed uploads."
        )
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
