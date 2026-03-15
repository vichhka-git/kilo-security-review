# iOS Security Reference

## Info.plist — Check These Keys

```xml
<!-- FLAG — disables HTTPS enforcement globally -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- SAFE — no NSAppTransportSecurity key (default = HTTPS only)
     OR domain-scoped exception only -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-api.internal</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

```xml
<!-- FLAG — hardcoded API keys in Info.plist -->
<key>API_KEY</key>
<string>sk_live_abc123</string>

<!-- FLAG — exposed URL scheme without validation -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array><string>myapp</string></array>
    </dict>
</array>
```

Deep links registered via URL schemes must validate the incoming URL in
`AppDelegate` — failure to do so allows any app to launch arbitrary in-app
flows (e.g., skip login, trigger payment).

## Insecure Data Storage

### UserDefaults — Never for Sensitive Data

```swift
// FLAG — credentials/tokens in UserDefaults
UserDefaults.standard.set(token, forKey: "authToken")
UserDefaults.standard.set(password, forKey: "password")
// File location: /var/mobile/Containers/Data/Application/<UUID>/Library/Preferences/<bundle>.plist
// Readable on jailbroken device and in iTunes backups (if unencrypted)

// SAFE — iOS Keychain
import Security

func saveToken(_ token: String) throws {
    let data = token.data(using: .utf8)!
    let query: [CFString: Any] = [
        kSecClass:          kSecClassGenericPassword,
        kSecAttrService:    "com.example.app",
        kSecAttrAccount:    "authToken",
        kSecValueData:      data,
        kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    SecItemDelete(query as CFDictionary)  // delete old first
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError.saveFailed }
}
```

### Files Written to Disk

```swift
// FLAG — sensitive data in unprotected file
let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let file = path.appendingPathComponent("session.json")
try data.write(to: file)  // no file protection attribute

// SAFE — encrypted file protection
try data.write(to: file, options: .completeFileProtectionUntilFirstUserAuthentication)
```

### NSLog / print Leakage

```swift
// FLAG — tokens in console output
NSLog("Auth response: %@", token)
print("Password: \(password)")

// SAFE — no sensitive data logged; use os.log with private modifier
import os
let log = Logger(subsystem: "com.example.app", category: "auth")
log.info("Login success for user: \(userId, privacy: .public)")
// token/password would be: \(token, privacy: .private)
```

## Certificate Pinning

```swift
// Using TrustKit (recommended library)
// AppDelegate.swift
let trustKitConfig: [String: Any] = [
    kTSKSwizzleNetworkDelegates: true,
    kTSKPinnedDomains: [
        "api.example.com": [
            kTSKEnforcePinning: true,
            kTSKIncludeSubdomains: true,
            kTSKPublicKeyHashes: [
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",  // current cert
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="   // backup pin
            ]
        ]
    ]
]
TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
```

## Jailbreak Detection

```swift
// Basic detection (easily bypassed, but raises the bar)
func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    let paths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/"
    ]
    if paths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
        return true
    }
    // Try writing to a location normally forbidden
    let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
    do {
        try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: testPath)
        return true
    } catch { return false }
    #endif
}

// Better: use IOSSecuritySuite
// https://github.com/securing/IOSSecuritySuite
```

## Screenshot Protection (Banking / Sensitive Screens)

```swift
// Blur screen when app goes to background (prevents screenshot in app switcher)
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive),
        name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive),
        name: UIApplication.didBecomeActiveNotification, object: nil)
}

@objc func appWillResignActive() {
    let blur = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blur)
    blurView.frame = view.bounds
    blurView.tag = 999
    view.addSubview(blurView)
}

@objc func appDidBecomeActive() {
    view.viewWithTag(999)?.removeFromSuperview()
}
```

## Static Analysis Commands

```bash
# Decode Info.plist
plutil -convert xml1 Info.plist -o -

# Scan for hardcoded secrets in Swift source
grep -rE '(password|secret|apiKey|token)\s*=\s*"[^"]{8,}"' . --include='*.swift'

# Dump class headers from compiled binary
class-dump -H AppBinary -o headers/

# Check linked frameworks (look for dangerous ones)
otool -L AppBinary

# Check entitlements
codesign -d --entitlements - AppBinary

# On jailbroken device: dump Keychain
objection -g "App Name" explore
# ios keychain dump
```

## Dynamic Analysis (Jailbroken Device)

```bash
# Intercept all network traffic (no proxy config needed on jailbroken)
# Install SSL Kill Switch 2 → Cydia
# Then use Burp Suite normally

# Hook functions at runtime
frida -U -l bypass_ssl.js "App Name"

# Dump UserDefaults at runtime
objection -g "App Name" explore
ios nsuserdefaults get
```
