# Android Security Reference

## Manifest Flags — Check All of These

```xml
<!-- FLAG — allows debugger attach, heap inspection, RN dev menu -->
android:debuggable="true"

<!-- FLAG — enables full ADB data extraction without root -->
android:allowBackup="true"

<!-- FLAG — all network traffic travels unencrypted -->
android:usesCleartextTraffic="true"

<!-- FLAG — activity reachable from any app on device -->
android:exported="true"  <!-- without a permission check -->
```

Safe manifest pattern:
```xml
<application
    android:debuggable="false"
    android:allowBackup="false"
    android:networkSecurityConfig="@xml/network_security_config">

    <!-- Internal activities explicitly non-exported -->
    <activity android:name=".AdminActivity" android:exported="false"/>

    <!-- Exported only if needed, with a signature permission -->
    <activity android:name=".DeepLinkActivity"
        android:exported="true"
        android:permission="com.example.CUSTOM_PERMISSION"/>
</application>
```

## Insecure Data Storage

### SharedPreferences (plaintext — always flag for sensitive data)
```kotlin
// FLAG — credentials/tokens in plaintext
val prefs = getSharedPreferences("AppPrefs", MODE_PRIVATE)
prefs.edit()
    .putString("password", rawPassword)   // plaintext
    .putString("token", authToken)
    .apply()

// SAFE — EncryptedSharedPreferences
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()
val encryptedPrefs = EncryptedSharedPreferences.create(
    context, "AppPrefs", masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)
// ALSO: never store raw passwords — only short-lived session tokens
```

### SQLite (check for unencrypted sensitive data)
```kotlin
// FLAG — sensitive PII in unencrypted SQLite
db.execSQL("INSERT INTO users VALUES (?, ?, ?)", arrayOf(ssn, creditCard, password))

// SAFE — use SQLCipher for sensitive databases
// Or: store only non-sensitive data in SQLite
```

### Logcat Leakage
```kotlin
// FLAG — tokens, passwords, PII in logs
Log.d("Auth", "Token: $token")
Log.d("User", "Password: $password")

// SAFE — no sensitive data in logs; use level-gated logging
if (BuildConfig.DEBUG) {
    Log.d("Auth", "Login successful for user_id=${userId}")
}
```

## Hardcoded Secrets (Secrets.java / Secrets.kt)

JADX recovers this class with original names intact if ProGuard is disabled.

```java
// FLAG — recoverable by any APK decompiler
public class Secrets {
    public static final String API_KEY = "sk_live_abc123";
    public static final String ADMIN_JWT = "eyJhbG...";
    public static final String DEBUG_URL = "http://internal.api/debug";
}
```

**Remediation:** Delete Secrets.java. Fetch all sensitive values from the
authentication server at runtime after successful login.

## APK Binary Analysis Commands

```bash
# Decode manifest and resources (no Java decompilation)
apktool d app.apk -o decoded/

# Read decoded manifest
cat decoded/AndroidManifest.xml

# Decompile to Java source
jadx -d jadx-out/ app.apk

# Extract React Native bundle (APK = ZIP)
unzip app.apk assets/index.android.bundle -d extracted/

# Find JWT tokens in JS bundle
grep -oE 'eyJ[A-Za-z0-9._-]{20,}' extracted/assets/index.android.bundle

# Find hardcoded API keys
grep -oE '(sk_|pk_|api_|key_)[A-Za-z0-9_-]{16,}' extracted/assets/index.android.bundle

# ADB backup extraction (no root needed if allowBackup=true)
adb backup -noapk -f backup.ab com.example.app
dd if=backup.ab bs=24 skip=1 | python3 -c \
  "import zlib,sys; sys.stdout.buffer.write(zlib.decompress(sys.stdin.buffer.read()))" \
  | tar xvf -

# Extract SharedPreferences
cat apps/com.example.app/sp/*.xml
```

## Build Configuration

```groovy
// build.gradle
buildTypes {
    release {
        debuggable false          // MUST be false
        minifyEnabled true        // Enable ProGuard/R8
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                      'proguard-rules.pro'
        signingConfig signingConfigs.release  // production keystore, not debug
    }
}
```

## Network Security Config (enforce HTTPS + optional pinning)

```xml
<!-- res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
    <!-- Certificate pinning (optional but recommended) -->
    <domain-config>
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set expiration="2027-01-01">
            <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
            <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin><!-- backup -->
        </pin-set>
    </domain-config>
</network-security-config>
```

## Root Detection (soft control — bypassable but raises the bar)

```kotlin
fun isRooted(): Boolean {
    val knownPaths = listOf(
        "/system/app/Superuser.apk",
        "/sbin/su", "/system/bin/su",
        "/data/local/bin/su", "/system/sd/xbin/su"
    )
    return knownPaths.any { File(it).exists() } ||
           runCatching { Runtime.getRuntime().exec("su") }.isSuccess
}

// Better: use RootBeer library
// https://github.com/scottyab/rootbeer
```

## Exported Component Abuse (Dynamic Testing)

```bash
# List exported activities
adb shell dumpsys package com.example.app | grep -A1 "Activity Resolver"

# Launch exported activity directly (bypass login)
adb shell am start -n com.example.app/.AdminPanelActivity

# Send broadcast to exported receiver
adb shell am broadcast -a com.example.ADMIN_ACTION
```

## React Native Specific

```bash
# index.android.bundle is plaintext JavaScript — extract and grep
unzip app.apk assets/index.android.bundle -d /tmp/rn/

# All API base URLs
grep -oE 'https?://[^"'\'']+' /tmp/rn/assets/index.android.bundle | sort -u

# All secrets-looking strings
grep -oE '"[A-Za-z0-9+/=]{32,}"' /tmp/rn/assets/index.android.bundle
```

AsyncStorage (React Native) stores data in SQLite at:
`/data/data/com.example.app/databases/RCTAsyncLocalStorage_V1`
Readable with root or ADB backup.

**Fix:** Use `react-native-keychain` (backed by Android Keystore / iOS Keychain).
