import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

val keyProperties = Properties()
// In the Android module, the file is at ../key.properties
val keyPropertiesFile = rootProject.file("android/key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.myapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            val storeFileProp = keyProperties.getProperty("storeFile")
            if (!storeFileProp.isNullOrBlank()) {
                // Resolve relative to android/ (where key.properties lives)
                val resolved = keyPropertiesFile.parentFile.resolve(storeFileProp)
                if (resolved.exists()) {
                    storeFile = file(resolved)
                }
            }

            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storePassword = keyProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        applicationId = "com.example.doacoesapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // If keystore isn't present, build an unsigned release APK locally.
            // Proper Play Store builds should always provide a keystore.
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) releaseSigning else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
