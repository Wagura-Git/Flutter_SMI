<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';
require_once '../includes/file_storage.php';

// Handle file download/view
if (in_array($_SERVER['REQUEST_METHOD'], ['GET', 'HEAD'], true)) {
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

    $inline = isset($_GET['mode']) && $_GET['mode'] === 'inline';

    if (strpos($file_path, 'db:') === 0) {
        $parts = explode(':', $file_path);
        if (count($parts) !== 3) {
            sendResponse(false, 'Path database tidak valid', null, 400);
        }

        $type = $parts[1];
        $id = (int) $parts[2];
        if ($id <= 0) {
            sendResponse(false, 'ID file tidak valid', null, 400);
        }

        $database = new Database();
        $conn = $database->connect();

        if ($type === 'document') {
            $query = "SELECT d.file_name, d.file_mime_type, d.file_size, d.file_data
                      FROM documents d
                      WHERE d.id = ?
                      AND (
                          d.admin_id = ?
                          OR ? = 'admin'
                          OR d.visibility IN ('public', 'team')
                          OR EXISTS (SELECT 1 FROM document_access da WHERE da.document_id = d.id AND da.user_id = ?)
                      )
                      LIMIT 1";
            $stmt = $conn->prepare($query);
            if (!$stmt) {
                $database->close();
                sendResponse(false, 'Query error: ' . $conn->error, null, 500);
            }

            $userId = (int) $user['id'];
            $userRole = $user['role'] ?? '';
            $stmt->bind_param('iisi', $id, $userId, $userRole, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $file = $result->fetch_assoc();
            $stmt->close();
            $database->close();

            if (!$file || empty($file['file_data'])) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'File tidak ditemukan di database']);
                exit;
            }

            sendBlobFile($file['file_name'], $file['file_mime_type'], $file['file_size'], $file['file_data'], $inline);
        }

        if ($type === 'agenda') {
            $query = "SELECT a.attachment_name, a.attachment_mime_type, a.attachment_size, a.attachment_data
                      FROM agendas a
                      LEFT JOIN agenda_invitations ai ON ai.agenda_id = a.id
                      WHERE a.id = ?
                      AND (a.user_id = ? OR ai.user_id = ?)
                      LIMIT 1";
            $stmt = $conn->prepare($query);
            if (!$stmt) {
                $database->close();
                sendResponse(false, 'Query error: ' . $conn->error, null, 500);
            }

            $userId = (int) $user['id'];
            $stmt->bind_param('iii', $id, $userId, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $file = $result->fetch_assoc();
            $stmt->close();
            $database->close();

            if (!$file || empty($file['attachment_data'])) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'File tidak ditemukan di database']);
                exit;
            }

            sendBlobFile($file['attachment_name'], $file['attachment_mime_type'], $file['attachment_size'], $file['attachment_data'], $inline);
        }

        if ($type === 'agenda_upload') {
            $query = "SELECT original_name, mime_type, file_size, file_data
                      FROM agenda_uploads
                      WHERE id = ? AND user_id = ?
                      LIMIT 1";
            $stmt = $conn->prepare($query);
            if (!$stmt) {
                $database->close();
                sendResponse(false, 'Query error: ' . $conn->error, null, 500);
            }

            $userId = (int) $user['id'];
            $stmt->bind_param('ii', $id, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $file = $result->fetch_assoc();
            $stmt->close();
            $database->close();

            if (!$file || empty($file['file_data'])) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'File tidak ditemukan di database']);
                exit;
            }

            sendBlobFile($file['original_name'], $file['mime_type'], $file['file_size'], $file['file_data'], $inline);
        }

        $database->close();
        sendResponse(false, 'Tipe file database tidak dikenal', null, 400);
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
    $disposition = $inline ? 'inline' : 'attachment';

    // Send file
    header('Content-Type: ' . $file_type);
    header('Content-Disposition: ' . $disposition . '; filename="' . $file_name . '"');
    header('Content-Length: ' . $file_size);
    header('Cache-Control: no-cache, no-store, must-revalidate');
    header('Pragma: no-cache');
    header('Expires: 0');

    // Read and output file
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        readfile($full_path);
    }
    exit;
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?>
