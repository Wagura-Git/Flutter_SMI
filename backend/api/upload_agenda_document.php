<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Hanya method POST yang diizinkan', null, 405);
}

// Get token from Authorization header
$token = getBearerToken();
if (!$token) {
    sendResponse(false, 'Token diperlukan', null, 401);
}

// Verify token
$tokenData = verifyToken($token);
if (!$tokenData) {
    sendResponse(false, 'Token tidak valid atau sudah kadaluarsa', null, 401);
}

// Check if file is uploaded
if (!isset($_FILES['document']) || $_FILES['document']['error'] !== UPLOAD_ERR_OK) {
    $errorMessage = isset($_FILES['document']) 
        ? $_FILES['document']['error'] 
        : 'File tidak ditemukan';
    sendResponse(false, "Error uploading file: " . $errorMessage, null, 400);
}

$file = $_FILES['document'];

// Validate file
$maxFileSize = 10 * 1024 * 1024; // 10MB
$allowedExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'];

// MIME types mapping - lebih lengkap untuk berbagai sistem
$fileMimeTypes = [
    'pdf' => ['application/pdf', 'application/x-pdf', 'application/postscript', 'text/pdf', 'application/acrobat', 'applications/vnd.pdf', 'application/vnd.adobe.pdf'],
    'doc' => ['application/msword', 'application/x-msword'],
    'docx' => ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-word.document.macroEnabled.12'],
    'xls' => ['application/vnd.ms-excel', 'application/x-msexcel'],
    'xlsx' => ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel.sheet.macroEnabled.12'],
    'ppt' => ['application/vnd.ms-powerpoint', 'application/x-mspowerpoint'],
    'pptx' => ['application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.ms-powerpoint.presentation.macroEnabled.12'],
    'txt' => ['text/plain'],
    'jpg' => ['image/jpeg'],
    'jpeg' => ['image/jpeg'],
    'png' => ['image/png']
];

// Check file size
if ($file['size'] > $maxFileSize) {
    sendResponse(false, 'Ukuran file tidak boleh lebih dari 10MB', null, 400);
}

// Get file extension
$fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

// Check extension
if (!in_array($fileExtension, $allowedExtensions)) {
    sendResponse(false, 'Format file tidak diizinkan. Format yang diperbolehkan: ' . implode(', ', $allowedExtensions), null, 400);
}

// Check MIME type - gunakan validasi berbasis ekstensi terlebih dahulu
// Jika MIME type tidak cocok tapi ekstensi valid, tetap izinkan (karena MIME type bisa bervariasi di berbagai sistem)
$mimeType = strtolower($file['type']);
if (!empty($mimeType) && isset($fileMimeTypes[$fileExtension])) {
    if (!in_array($mimeType, $fileMimeTypes[$fileExtension])) {
        // Hanya log warning, jangan tolak
        error_log("Warning: File '$fileExtension' memiliki MIME type '$mimeType' yang tidak standar. Tetap diizinkan berdasarkan ekstensi file.");
    }
}

// Create upload directory if not exists
$uploadDir = __DIR__ . '/../uploads/agendas';
if (!is_dir($uploadDir)) {
    if (!mkdir($uploadDir, 0755, true)) {
        sendResponse(false, 'Gagal membuat direktori upload', null, 500);
    }
}

// Generate unique filename
$timestamp = time();
$randomString = bin2hex(random_bytes(8));
$newFileName = "agenda_{$timestamp}_{$randomString}.{$fileExtension}";
$filePath = $uploadDir . '/' . $newFileName;

// Move uploaded file
if (!move_uploaded_file($file['tmp_name'], $filePath)) {
    sendResponse(false, 'Gagal menyimpan file', null, 500);
}

// Return relative path for database storage
$relativePath = "uploads/agendas/" . $newFileName;

sendResponse(true, 'File berhasil diupload', [
    'file_name' => $newFileName,
    'original_name' => $file['name'],
    'file_path' => $relativePath,
    'file_size' => $file['size']
], 200);
?>
