<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Only allow POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

// Get token from header
$token = getBearerToken();

if (empty($token)) {
    sendResponse(false, 'Token tidak ditemukan', null, 401);
}

// Verify token
$decoded = verifyToken($token);

if ($decoded === null) {
    sendResponse(false, 'Token tidak valid atau sudah kadaluarsa', null, 401);
}

// Return success response
sendResponse(true, 'Token valid', [
    'userId' => $decoded['userId'],
    'email' => $decoded['email'],
    'role' => $decoded['role'],
    'exp' => $decoded['exp']
], 200);
?>
