# We use only the Latin ML Kit text recognizer (§11). The plugin references the
# optional Chinese/Devanagari/Japanese/Korean recognizer classes, which aren't
# on the classpath — tell R8 not to warn/fail on them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.** { *; }
