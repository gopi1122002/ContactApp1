plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.listdemo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.listdemo"
        minSdk = 21 // Required for Firebase and Vonage
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

//dependencies {
//    implementation 'com.google.firebase:firebase-analytics:22.1.2'
//    implementation 'com.google.firebase:firebase-firestore:25.1.0'
//    implementation 'com.google.firebase:firebase-auth:23.1.0'
//    implementation 'com.google.firebase:firebase-functions:21.0.0'
//    implementation 'com.vonage:client-sdk-voice:2.0.0' // For Vonage voice calls
//}

flutter {
    source = "../.."
}