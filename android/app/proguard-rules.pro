# Rules to prevent R8 from removing necessary Google ML Kit classes.
# These classes are dynamically referenced by the Flutter plugin.

-keep class com.google.mlkit.** { *; }

-dontwarn com.google.mlkit.**
-dontwarn android.hardware.camera2.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**

# Specific rules for all language options reported as missing:
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }