<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';
require_once '../includes/file_storage.php';

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

$validated = validateUploadedDocument($_FILES['document'] ?? null);
if (!$validated['success']) {
    sendResponse(false, $validated['message'], null, 400);
}

$database = new Database();
$conn = $database->connect();

$timestamp = time();
$randomString = bin2hex(random_bytes(8));
$newFileName = "agenda_{$timestamp}_{$randomString}.{$validated['extension']}";

$query = "INSERT INTO agenda_uploads (user_id, original_name, file_name, mime_type, file_size, file_data)
          VALUES (?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($query);
if (!$stmt) {
    $database->close();
    sendResponse(false, 'Query error: ' . $conn->error, null, 500);
}

$blob = null;
$userId = $tokenData['userId'];
$originalName = $validated['original_name'];
$mimeType = $validated['mime_type'];
$fileSize = $validated['size'];
$stmt->bind_param(
    'isssib',
    $userId,
    $originalName,
    $newFileName,
    $mimeType,
    $fileSize,
    $blob
);

if (!bindBlobAndExecute($stmt, 5, $validated['data'])) {
    $stmt->close();
    $database->close();
    sendResponse(false, 'Gagal menyimpan file ke database: ' . $stmt->error, null, 500);
}

$uploadId = $stmt->insert_id;
$stmt->close();
$database->close();

$relativePath = "db:agenda_upload:" . $uploadId;

sendResponse(true, 'File berhasil diupload', [
    'file_name' => $newFileName,
    'original_name' => $validated['original_name'],
    'file_path' => $relativePath,
    'file_size' => $validated['size']
], 200);
?>
