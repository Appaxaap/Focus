import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.codecx.focus"
    compileSdk = flutter.compileSdkVersion
    // NDK r28 produces 16 KB page-size-compatible native libraries.
    ndkVersion = "28.1.13356709"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.codecx.focus"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // multiDex support
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // This only runs when key.properties exists locally
            if (keystorePropertiesFile.exists()) {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the configured release keystore both locally and in CI.
            // CI creates key.properties from the repository's signing secrets.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }

            packaging {
                jniLibs {
                    // Keep native libraries uncompressed and 16 KB aligned.
                    useLegacyPackaging = false
                }
            }
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}

dependencies {
    // Core library desugaring dependencies
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")

    // Flutter dependencies
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.20")
}

flutter {
    source = "../.."
}
