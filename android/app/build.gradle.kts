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
    ndkVersion = "27.0.12077973"

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
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Only sign release builds locally when a release keystore is present.
            // CI builds should stay unsigned so the APK can be signed offline.
            signingConfig = if (keystorePropertiesFile.exists() && System.getenv("CI") != "true") {
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
                    useLegacyPackaging = true
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
