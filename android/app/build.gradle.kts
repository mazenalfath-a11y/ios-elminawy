plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.coursesappgenuiswebatwan"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ صح هنا
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.coursesappgenuiswebatwan"
        minSdk = 24
        targetSdk = 36
        multiDexEnabled = true
        versionCode = 28
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            storeFile = file("../../my-release-key.keystore") // المسار النسبي من app إلى root
            storePassword = "12345678Mm"
            keyAlias = "my-key-alias"
            keyPassword = "12345678Mm"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ لازم تضيف دي مع desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
