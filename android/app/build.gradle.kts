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
    ndkVersion = "26.3.11579264"

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
        versionCode = 6
        versionName = "2.1.0"

        // multiDex support
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // This only runs when key.properties exists locally
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if properties exist, otherwise debug (for CI)
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )


            ndk {
                debugSymbolLevel = "none"
            }
        }
    }

    // SPLIT PER ABI CONFIGURATION
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            // This will generate split APKs when using --split-per-abi
            isUniversalApk = true
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