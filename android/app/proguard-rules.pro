# BassPro Player ProGuard Rules
# These rules ensure proper code shrinking and obfuscation for release builds

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Audio Service - Critical for background playback
-keep class com.ryanheise.audioservice.** { *; }
-keepclassmembers class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# Just Audio - Critical for audio playback
-keep class com.ryanheise.just_audio.** { *; }
-keepclassmembers class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# ExoPlayer (used by just_audio)
-keep class com.google.android.exoplayer2.** { *; }
-keepclassmembers class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Media session support
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }
-dontwarn androidx.media.**

# SQLite - Database models must be preserved
-keep class com.basspro.player.data.models.** { *; }
-keepclassmembers class com.basspro.player.data.models.** { *; }

# Keep database entity classes (Track, Playlist, StreamSource, EqPreset)
-keep class * extends com.basspro.player.domain.entities.** { *; }
-keepclassmembers class * extends com.basspro.player.domain.entities.** { *; }

# Preserve serialization methods for database models
-keepclassmembers class * {
    public <methods>;
    public <fields>;
}

# Keep methods used for database serialization
-keepclassmembers class * {
    *** toMap();
    *** fromMap(java.util.Map);
    *** copyWith(...);
}

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# Preserve line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom view constructors
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Gson (if used for JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Wakelock
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
-dontwarn dev.fluttercommunity.plus.wakelock.**

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# Sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Cached network image
-keep class com.baseflow.cachednetworkimage.** { *; }
-dontwarn com.baseflow.cachednetworkimage.**
