# 🎯 Quick Reference - Development vs Production

## 📋 URL Configuration

### Development
```
Frontend: http://localhost:65432 (Flutter run)
         http://192.168.1.100:65432 (dari device lain di LAN)
         
Backend:  http://localhost/si_manajemen_kampus_backend/api
         http://192.168.1.100/si_manajemen_kampus_backend/api
         
Database: localhost (MySQL local)
```

### Production (SETELAH DEPLOY)
```
Frontend: https://yourdomain.com
         https://www.yourdomain.com
         
Backend:  https://yourdomain.com/api
         https://api.yourdomain.com (jika separate domain)
         
Database: production-db.yourdomain.com (managed hosting)
         production server database
```

---

## 🔧 Configuration Files to Update

### 1️⃣ Flutter Config
**File:** `lib/config/app_config.dart`

```dart
// For Development (sekarang)
static const String currentEnv = DEV;
PROD: 'https://yourdomain.com/api',

// For Production (saat deploy)
static const String currentEnv = PROD;
```

### 2️⃣ PHP Backend Config
**File:** `backend/config/Database.php`

```php
// Development
private $host = 'localhost';
private $username = 'root';

// Production
private $host = 'your-prod-host.com';
private $username = 'prod_user';
private $password = 'STRONG_PASSWORD';
```

### 3️⃣ PHP Security
**File:** `backend/includes/functions.php`

```php
// Change this before production!
$secret = 'Change-this-to-a-long-random-string-32-chars-minimum';
```

---

## 🚀 Deployment Checklist

| Item | Dev | Prod |
|------|-----|------|
| HTTPS | Optional | ✅ REQUIRED |
| Domain | localhost/IP | yourdomain.com |
| Database | localhost | Remote/Managed |
| API URL | localhost | yourdomain.com |
| Debug Logs | ✅ Enabled | ❌ Disabled |
| Error Display | ✅ Show detail | ❌ Hide from user |
| CORS | * (all) | yourdomain.com only |
| JWT Secret | Simple | Complex (32+ chars) |

---

## 📱 Testing URL Pattern

### During Development
- Flutter app: `http://localhost/backend/api`
- Phone/tablet: `http://192.168.1.100/backend/api`
- Postman: `http://localhost/backend/api`

### After Deployment  
- Flutter app: `https://yourdomain.com/api`
- Mobile app: `https://yourdomain.com/api`
- Web: `https://yourdomain.com`
- Postman: `https://yourdomain.com/api`

---

## 🌐 Popular Hosting Options

### Untuk Backend PHP

| Provider | Domain | PHP | MySQL | Price | Lokasi |
|----------|--------|-----|-------|-------|--------|
| IDCloudhost | ✅ | ✅ | ✅ | $2-5/mo | 🇮🇩 Indonesia |
| Niagahoster | ✅ | ✅ | ✅ | $2-3/mo | 🇮🇩 Indonesia |
| SiteGround | ✅ | ✅ | ✅ | $3-7/mo | 🌍 Global |
| Bluehost | ✅ | ✅ | ✅ | $4-6/mo | 🌍 Global |
| DigitalOcean | ✅ | ✅ | ✅ | $5+/mo | 🌍 Global |

### Untuk Frontend (Web Version)

| Provider | Domain | Framework | Price | Static |
|----------|--------|-----------|-------|--------|
| Firebase Hosting | ✅ | Flutter Web | Free | ✅ |
| Netlify | ✅ | Flutter Web | Free | ✅ |
| Vercel | ✅ | Flutter Web | Free | ✅ |
| Shared Hosting | ✅ | Flutter Web | $2-5/mo | Upload manual |

---

## 📝 Example Domain Setup

### yourdomain.com Setup

**Folder Structure (di hosting):**
```
public_html/
├── backend/                    (PHP API)
│   ├── api/
│   ├── config/
│   └── includes/
└── www/ atau public/          (Flutter Web)
    ├── index.html
    ├── assets/
    └── main.dart.js
```

**Access URLs:**
```
API:     https://yourdomain.com/backend/api
Website: https://yourdomain.com
Web App: https://yourdomain.com
```

---

## 🔐 Security Reminders

### ⚠️ JANGAN DI PRODUCTION:
- Hardcoded credentials
- `localhost` atau IP lokal
- Debug logs di console
- `display_errors` enabled
- `CORS: *` (allow all)
- Simple secret keys
- HTTP (tanpa HTTPS)
- Password tersimpan di device

### ✅ HARUS DI PRODUCTION:
- HTTPS only
- Remote database
- Strong JWT secret (32+ chars)
- Error logging (bukan display)
- CORS whitelist domain
- Secure credential storage
- Regular backups
- SSL certificate
- Firewalls & security rules

---

## 🛠️ Common Issues & Solutions

### Issue: "Connection refused"
**Solution:** 
- Check backend URL di `app_config.dart`
- Pastikan backend server running
- Check firewall rules

### Issue: "Invalid certificate"
**Solution:**
- Install SSL certificate
- Gunakan Let's Encrypt (gratis)
- Update cert setiap 90 hari

### Issue: "Localhost works but production doesn't"
**Solution:**
- Update API URL untuk production domain
- Pastikan CORS headers benar
- Check database credentials production

### Issue: "Token always invalid"
**Solution:**
- Pastikan JWT secret sama di backend
- Check server time synchronization
- Verify token format

---

## 📚 Files to Keep Safe

| File | Type | Sensitivity |
|------|------|-------------|
| `backend/config/Database.php` | Config | 🔴 CRITICAL |
| `backend/includes/functions.php` | Config | 🔴 CRITICAL |
| Database backups | Data | 🔴 CRITICAL |
| SSL certificates | Security | 🟠 HIGH |
| `app_config.dart` | Config | 🟡 MEDIUM |

---

## ✅ Pre-Deployment Checklist

- [ ] Update `app_config.dart` dengan production URL
- [ ] Update `backend/config/Database.php` dengan prod credentials
- [ ] Change JWT secret key di `functions.php`
- [ ] Enable HTTPS/SSL certificate
- [ ] Test semua endpoints di production URL
- [ ] Backup database sebelum deploy
- [ ] Test login dengan production account
- [ ] Check all API response times
- [ ] Verify error logging works
- [ ] Monitor error logs setelah deploy

---

**You're ready for production! 🚀**
