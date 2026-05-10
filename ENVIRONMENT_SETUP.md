## 🔄 Switching Between Environments

### Development Mode (Default)

**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String currentEnv = DEV;  // ← DEVELOPMENT

  static const Map<String, String> apiUrls = {
    DEV: 'http://localhost/si_manajemen_kampus_backend/api',
    // Buat testing dengan IP lokal di phone/tablet:
    // DEV: 'http://192.168.1.100/si_manajemen_kampus_backend/api',
    
    STAGING: 'https://staging.yourdomain.com/api',
    PROD: 'https://yourdomain.com/api',
  };
}
```

**Usage:**
```bash
flutter run
```

---

### Staging Mode

**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String currentEnv = STAGING;  // ← STAGING

  static const Map<String, String> apiUrls = {
    DEV: 'http://localhost/si_manajemen_kampus_backend/api',
    STAGING: 'https://staging.yourdomain.com/api',  // ← Staging server
    PROD: 'https://yourdomain.com/api',
  };
}
```

---

### Production Mode

**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String currentEnv = PROD;  // ← PRODUCTION

  static const Map<String, String> apiUrls = {
    DEV: 'http://localhost/si_manajemen_kampus_backend/api',
    STAGING: 'https://staging.yourdomain.com/api',
    PROD: 'https://yourdomain.com/api',  // ← Production domain
  };
}
```

**Build untuk production:**
```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📝 Backend Configuration Templates

### Template untuk Development

**File:** `backend/config/Database.php`
```php
private $host = 'localhost';
private $username = 'root';
private $password = '';
private $db_name = 'si_manajemen_kampus';
```

### Template untuk Production

**File:** `backend/config/Database.php`
```php
private $host = 'production-db.yourdomain.com';
private $username = 'prod_user_123';
private $password = 'SecurePassword@2024!';  // Gunakan password kuat
private $db_name = 'prod_esurat_db';
```

### Template untuk Staging

**File:** `backend/config/Database.php`
```php
private $host = 'staging-db.yourdomain.com';
private $username = 'staging_user';
private $password = 'StagingPassword@2024';
private $db_name = 'staging_esurat_db';
```

---

## 🔐 Production Security Configuration

### File: `backend/includes/functions.php`

**DEVELOPMENT (TIDAK AMAN - jangan di production):**
```php
$secret = 'test-secret-key-not-secure';
```

**PRODUCTION (AMAN):**
```php
$secret = 'aB3cD4eF5gH6iJ7kL8mN9oP0qR1sT2uV3wX4yZ5aB6cD7eF8gH9iJ0k';  // Min 32 chars
```

Generate production secret:
```bash
# Linux/Mac
openssl rand -hex 32

# Windows PowerShell
[Convert]::ToHexString([System.Random]::new().GetBytes(32))
```

---

## 🌐 Domain Configuration

### If Menggunakan Custom Domain

**DNS Records Needed:**
```
Type    Name                Record              TTL
A       yourdomain.com      123.45.67.89        3600
A       www.yourdomain.com  123.45.67.89        3600
MX      yourdomain.com      mail.yourdomain.com 3600
```

**SSL Certificate:**
```bash
# Let's Encrypt (FREE)
certbot certonly --apache -d yourdomain.com -d www.yourdomain.com

# Certificate path:
# /etc/letsencrypt/live/yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

---

## 📱 Building Flutter for Distribution

### Android APK

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Upload ke:
# - Google Play Store
# - F-Droid (untuk open source)
# - APK mirror sites
```

### iOS App

```bash
# Build release app
flutter build ios --release

# Upload via Xcode atau via App Store Connect

# Requirements:
# - Apple Developer account
# - Provisioning profiles
# - Code signing certificates
```

### Web Release

```bash
# Build web release
flutter build web --release

# Output: build/web/

# Deploy to:
# - Firebase Hosting
# - Netlify
# - Vercel
# - Shared hosting dengan PHP
# - VPS dengan Nginx/Apache
```

---

## 🎯 Quick Deployment Steps

### Jika website sudah live:

1. **Update API URL di Flutter:**
   ```dart
   // lib/config/app_config.dart
   PROD: 'https://yourdomain.com/api'
   ```

2. **Build web release:**
   ```bash
   flutter build web --release
   ```

3. **Upload ke server:**
   - Upload folder `build/web/` ke hosting Anda
   - Or use Firebase Hosting:
     ```bash
     firebase deploy --only hosting
     ```

4. **Test di production URL:**
   - Buka https://yourdomain.com
   - Test login dengan account demo
   - Verify semua API calls bekerja

---

## ✅ Environment Verification

### Check Current Environment

Di Flutter app, ada logging (development saja):
```dart
print('Current Environment: ${AppConfig.currentEnv}');
print('API URL: ${AppConfig.getApiUrl()}');
```

### Check Backend Configuration

```bash
# Test API health
curl https://yourdomain.com/api/verify_token.php

# Should return error (karena tidak ada token), tapi
# server harus respond (tidak timeout)
```

---

**Ready to deploy! 🚀**
