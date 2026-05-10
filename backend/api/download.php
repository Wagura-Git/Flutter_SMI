<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Handle file download/view
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get file from query parameter
    $file_path = isset($_GET['path']) ? $_GET['path'] : null;
    
    if (!$file_path) {
        sendResponse(false, 'File path tidak diberikan', null, 400);
    }

    // Verify token
    $token = getBearerToken();
    if (!$token && isset($_GET['token'])) {
        $token = $_GET['token'];
    }
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    // Security: prevent directory traversal
    $file_path = preg_replace('/\.\./', '', $file_path);
    $file_path = trim($file_path, '/');
    
    $full_path = __DIR__ . '/../' . $file_path;
    
    // Verify file exists
    if (!file_exists($full_path) || !is_file($full_path)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'File tidak ditemukan']);
        exit;
    }

    // Verify file is in uploads directory (security)
    $real_path = realpath($full_path);
    $uploads_dir = realpath(__DIR__ . '/../uploads');
    
    if (strpos($real_path, $uploads_dir) !== 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Akses ditolak']);
        exit;
    }

    // Get file info
    $file_name = basename($full_path);
    $file_size = filesize($full_path);
    $file_type = mime_content_type($full_path) ?: 'application/octet-stream';
    $disposition = (isset($_GET['mode']) && $_GET['mode'] === 'inline') ? 'inline' : 'attachment';

    // Send file
    header('Content-Type: ' . $file_type);
    header('Content-Disposition: ' . $disposition . '; filename="' . $file_name . '"');
    header('Content-Length: ' . $file_size);
    header('Cache-Control: no-cache, no-store, must-revalidate');
    header('Pragma: no-cache');
    header('Expires: 0');

    // Read and output file
    readfile($full_path);
    exit;
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?>
