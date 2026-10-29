# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# App (MainActivity / method channels / native)
-keep class com.picacomic_miuix.** { *; }
-keep class com.github.pacalini.** { *; }

# Keep all JNI natives
-keepclasseswithmembernames,includedescriptorclasses class * { native <methods>; }

# Plugins (reflection / JNI / manifest components)
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-keep class com.pichillilorenzo.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class be.tramckrijte.workmanager.** { *; }
-keep class androidx.work.** { *; }
-keep class soko.ekibun.flutter_qjs.** { *; }
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.llfbandit.app_links.** { *; }
-keep class com.ajinasokan.flutter_displaymode.** { *; }
-keep class io.material.plugins.dynamic_color.** { *; }
-keep class io.github.sparkfun.** { *; }

# flutter_local_notifications uses Gson with generic types
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory

# AndroidX bits used via reflection
-keep class androidx.lifecycle.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.webkit.** { *; }

# Missing optional classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**