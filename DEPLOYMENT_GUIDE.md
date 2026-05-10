# 🚀 Deployment Guide - Production Ready

## 📋 Checklist Sebelum Deploy

### Backend PHP

- [ ] Ganti database credentials dengan yang production
- [ ] Ganti JWT secret key dengan yang aman (minimal 32 karakter)
- [ ] Disable PHP error display di production
- [ ] Enable HTTPS (SSL certificate)
- [ ] Update CORS policy untuk domain production Anda saja
- [ ] Setup rate limiting di server
- [ ] Backup database
- [ ] Test semua API endpoints di production URL

### Flutter Frontend

- [ ] Update `app_config.dart` dengan production URL
- [ ] Ganti `currentEnv` dari `DEV` ke `PROD`
- [ ] Disable debug mode
- [ ] Build APK/IPA untuk production
- [ ] Test di device nyata sebelum upload ke app store

---

## 🌐 Step 1: Setup Backend di Production Server

### Option A: Hosting Berbayar (Rekomendasi)

Gunakan hosting yang mendukung PHP & MySQL:
- **Bluehost**
- **SiteGround**
- **Hostgator**
- **IDCloudhost** (lokal Indonesia)
- **Niagahoster** (lokal Indonesia)

**Steps:**
1. Upload folder `backend/` ke public_html atau www
2. Import `database.sql` via hosting control panel
3. Update database credentials di `backend/config/Database.php`
4. Ganti JWT secret key di `backend/includes/functions.php`
5. Test API endpoints via Postman

### Option B: VPS Pribadi

Jika punya VPS:
```bash
# SSH ke server
ssh user@your-server.com

# Setup PHP & MySQL
apt-get update
apt-get install php php-mysql mysql-server apache2

# Upload backend
scp -r backend/ user@your-server.com:/var/www/html/

# Setup database
mysql -u root -p < backend/database.sql
```

---

## 🔧 Step 2: Update Backend untuk Production

### File: `backend/config/Database.php`

```php
<?php
class Database {
    private $host = 'your-db-host.com';      // Ganti dengan host production
    private $db_name = 'si_manajemen_kampus';
    private $username = 'prod_user';         // Ganti dengan username production
    private $password = 'strong_password';   // Ganti dengan password yang aman
    private $port = 3306;
```

### File: `backend/includes/functions.php`

**Line ~43 dan ~97:**
```php
$secret = 'your-production-secret-key-32-characters-or-more-CHANGE-THIS!';
```

Gunakan password generator untuk secret key yang aman:
```bash
# Di Linux/Mac:
openssl rand -hex 32

# Contoh output:
# 9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b
```

### HTTPS & SSL Certificate

Jangan lupa setup HTTPS! Gunakan Let's Encrypt (gratis):

```bash
# Jika pakai certbot
sudo certbot certonly --apache -d yourdomain.com
```

Update CORS di `backend/includes/functions.php`:

```php
// Production: specify domain saja
header('Access-Control-Allow-Origin: https://yourdomain.com');

// Jangan gunakan * di production!
```

---

## 📱 Step 3: Update Flutter untuk Production

### File: `lib/config/app_config.dart`

```dart
class AppConfig {
  // Ubah ini dari DEV ke PROD
  static const String currentEnv = PROD;

  static const Map<String, String> apiUrls = {
    DEV: 'http://localhost/si_manajemen_kampus_backend/api',
    STAGING: 'https://staging.yourdomain.com/api',
    PROD: 'https://yourdomain.com/api',  // ← Update dengan domain Anda
  };
}
```

### Build for Production

```bash
# Untuk Web
flutter build web --release

# Untuk Android
flutter build apk --release

# Untuk iOS
flutter build ios --release
```

---

## 🧪 Testing Production

### Via Postman

**Update base URL di Postman:**
```
https://yourdomain.com/api
```

Test endpoints:
```bash
# Login test
POST https://yourdomain.com/api/login.php
Body: {
    "email": "admin@example.com",
    "password": "password123"
}
```

### Via Flutter App

1. Build production APK/IOS
2. Install di device
3. Test login dengan account demo
4. Verify semua fitur berjalan dengan baik

---

## 📊 Production Environment Example

### Backend Structure

```
production-server/
├── public_html/
│   └── backend/
│       ├── api/
│       │   ├── login.php
│       │   ├── register.php
│       │   └── verify_token.php
│       ├── config/
│       │   └── Database.php (with prod credentials)
│       ├── includes/
│       │   └── functions.php (with prod secret)
│       └── .htaccess (security rules)
├── ssl/ (SSL certificates)
│   ├── certificate.crt
│       └── private.key
```

### `.htaccess` Security Rules

```apache
# Enable mod_rewrite
<IfModule mod_rewrite.c>
    RewriteEngine On
</IfModule>

# Disable directory listing
<FilesMatch "^\." >
    Order allow,deny
    Deny from all
</FilesMatch>

# Add security headers
<IfModule mod_headers.c>
    Header set X-Content-Type-Options "nosniff"
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-XSS-Protection "1; mode=block"
</IfModule>
```

---

## 🔒 Security Checklist Production

### PHP Backend

- [ ] Database credentials bukan hardcoded (gunakan .env file)
- [ ] JWT secret key yang kuat (min 32 chars)
- [ ] Input validation untuk semua endpoint
- [ ] SQL injection protection (gunakan prepared statements) ✅
- [ ] HTTPS mandatory
- [ ] CORS whitelist domain saja
- [ ] Rate limiting enabled
- [ ] Error logging bukan tampil ke user
- [ ] Disable `display_errors` di php.ini
- [ ] Set `error_reporting` hanya ke file
- [ ] Regular database backups
- [ ] Monitor failed login attempts

### Flutter App

- [ ] Disable debug logs di production
- [ ] Hapus console.log di web version
- [ ] Enable certificate pinning untuk API calls
- [ ] Validate SSL certificate
- [ ] Store sensitive data di secure storage
- [ ] Jangan store password, hanya token
- [ ] Implement token refresh logic
- [ ] Handle token expiry gracefully

---

## 📈 Scaling Tips

### Jika traffic tinggi:

1. **Database Optimization**
   - Add proper indexes
   - Monitor slow queries
   - Consider database replication

2. **API Caching**
   - Implement Redis for token caching
   - Cache user data
   - Cache frequently accessed queries

3. **Load Balancing**
   - Use multiple server instances
   - Setup load balancer (nginx)
   - Database replication/clustering

4. **CDN**
   - Use CDN untuk static assets
   - Cache HTTP responses

---

## 🆘 Troubleshooting Production

### CORS Error

**Problem:** Browser block API calls
**Solution:**
```php
// Make sure CORS headers are set
header('Access-Control-Allow-Origin: https://yourdomain.com');
header('Access-Control-Allow-Credentials: true');
```

### SSL Certificate Error

**Problem:** `ERR_CERT_COMMON_NAME_INVALID`
**Solution:**
- Ensure certificate matches domain
- Regenerate certificate
- Update DNS records

### Database Connection Error

**Problem:** "Can't connect to MySQL server"
**Solution:**
- Check database host/port
- Verify credentials
- Check firewall rules
- Verify database user has proper permissions

### Token Always Expired

**Problem:** Login success tapi langsung logout
**Solution:**
- Check server time sync
- Verify JWT secret key match
- Check token expiry time in code

---

## 🎯 Deployment Checklist

### Before Going Live

- [ ] All tests passing
- [ ] Database backup taken
- [ ] SSL certificate installed
- [ ] CORS properly configured
- [ ] Error logging setup
- [ ] Monitoring setup
- [ ] Backup plan ready
- [ ] Support team trained
- [ ] Documentation updated
- [ ] Performance tested

### After Going Live

- [ ] Monitor error logs
- [ ] Check API response times
- [ ] Monitor database performance
- [ ] Check user feedback
- [ ] Setup alerts for errors
- [ ] Regular database backups
- [ ] Security patches applied promptly

---

## 📞 Support

- Test API: Use Postman collection
- Monitor logs: Check server error logs
- Debug: Enable logging at different levels
- Backup: Always maintain database backups

**Happy deploying! 🚀**
