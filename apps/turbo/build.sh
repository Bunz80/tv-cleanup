#!/bin/sh
# Builds out/turbo.apk with the Android SDK build tools only (no Gradle). Needs JDK 17, platform 34, build-tools 34.
set -e
cd "$(dirname "$0")"
[ -n "$JAVA_HOME" ] || JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
[ -n "$JAVA_HOME" ] && export PATH="$JAVA_HOME/bin:$PATH"
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
BT=$SDK/build-tools/34.0.0; JAR=$SDK/platforms/android-34/android.jar
rm -rf out; mkdir -p out/classes out/dex
"$BT/aapt2" compile --dir res -o out/res.zip
"$BT/aapt2" link -o out/base.apk -I "$JAR" --manifest AndroidManifest.xml --min-sdk-version 22 --target-sdk-version 34 out/res.zip
javac -nowarn -Xlint:-options -encoding UTF-8 -source 1.8 -target 1.8 -bootclasspath "$JAR:$BT/core-lambda-stubs.jar" \
  -d out/classes $(find src -name "*.java")
"$BT/d8" --min-api 22 --release --lib "$JAR" --output out/dex $(find out/classes -name '*.class')
cp out/base.apk out/unsigned.apk; (cd out/dex && zip -q ../unsigned.apk classes.dex)
"$BT/zipalign" -f 4 out/unsigned.apk out/aligned.apk
KS=${KEYSTORE:-$HOME/.config/tv-cleanup/turbo.jks}; PASS=${KEYSTORE_PASS:-turbo-local}
mkdir -p "$(dirname "$KS")"
[ -f "$KS" ] || keytool -genkeypair -keystore "$KS" -storepass "$PASS" -keypass "$PASS" -alias turbo \
  -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=turbo" >/dev/null 2>&1
"$BT/apksigner" sign --ks "$KS" --ks-pass "pass:$PASS" --out out/turbo.apk out/aligned.apk
echo "Built $(pwd)/out/turbo.apk"
