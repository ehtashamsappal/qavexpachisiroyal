# Qavex Pachisi Royal ProGuard rules
-keep class com.qavex.qavexpachisiroyal.** { *; }
# flame / flutter
-keep class io.flutter.** { *; }
# Play Core (referenced by Flutter embedding, not bundled)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
