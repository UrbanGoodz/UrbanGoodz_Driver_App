import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.urbangoodz.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // com.urbaneatz.driver, not com.urbangoodz.driver: the live Play
        // listing is com.urbaneatz.driver and a different applicationId is a
        // different app to Google, so building the urbangoodz id would create
        // a second listing and strand the existing installs with no update
        // path. google-services.json already carries a client for this id.
        // namespace above stays as-is - it is the code package, not the app id.
        applicationId = "com.urbaneatz.driver"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                keyProperties.load(FileInputStream(keyPropertiesFile))
            }
            val storeFilePath = keyProperties.getProperty("storeFile") ?: ""
            storeFile = if (storeFilePath.isNotBlank()) {
                if (File(storeFilePath).isAbsolute) File(storeFilePath) else rootProject.file(storeFilePath)
            } else File("")
            storePassword = keyProperties.getProperty("storePassword") ?: ""
            keyAlias = keyProperties.getProperty("keyAlias") ?: ""
            keyPassword = keyProperties.getProperty("keyPassword") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = true
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
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    implementation("com.google.firebase:firebase-analytics")
}
