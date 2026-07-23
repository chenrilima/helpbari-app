# The OCR plugin supports optional scripts whose native ML Kit artifacts are not
# bundled by HelpBari. The app initializes only the Latin recognizer.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
