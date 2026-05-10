<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';
require_once '../includes/file_storage.php';

// Check request method
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    handleGetDocuments();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    handleCreateDocument();
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    handleUpdateDocument();
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}

function handleGetDocuments() {
    // Verify token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    $user_id = $user['id'];
    $user_role = $user['role'];
    $database = new Database();
    $conn = $database->connect();

    // Build query based on user role
    if ($user_role === 'admin') {
        // Admin can see all documents
        $query = "SELECT d.*, u.name as user_name FROM documents d
                  JOIN users u ON d.admin_id = u.id
                  ORDER BY d.created_at DESC";
        $result = $conn->query($query);
    } else {
        // User sees own documents and documents shared with them
        $query = "SELECT DISTINCT d.*, u.name as user_name 
                  FROM documents d
                  JOIN users u ON d.admin_id = u.id
                  WHERE d.admin_id = ? 
                  OR d.visibility = 'public'
                  OR d.visibility = 'team'
                  OR EXISTS (SELECT 1 FROM document_access da WHERE da.document_id = d.id AND da.user_id = ?)
                  ORDER BY d.created_at DESC";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('ii', $user_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
    }

    if (!$result) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }

    $documents = [];
    while ($row = $result->fetch_assoc()) {
        $document_id = $row['id'];
        unset($row['file_data']);

        // Get document access
        $access_query = "SELECT da.id, da.user_id, u.name as user_name, da.access_type, da.created_at
                        FROM document_access da
                        JOIN users u ON da.user_id = u.id
                        WHERE da.document_id = ?";
        $access_stmt = $conn->prepare($access_query);
        $access_stmt->bind_param('i', $document_id);
        $access_stmt->execute();
        $access_result = $access_stmt->get_result();

        $access_list = [];
        while ($access = $access_result->fetch_assoc()) {
            $access_list[] = $access;
        }
        $access_stmt->close();

        $row['access_list'] = $access_list;
        $documents[] = $row;
    }

    $database->close();
    sendResponse(true, 'Berhasil mengambil data dokumen', $documents, 200);
}

function handleCreateDocument() {
    // Verify token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($contentType, 'multipart/form-data') !== false) {
        $input = $_POST;
    } else {
        $input = json_decode(file_get_contents('php://input'), true);
    }

    // Validate input
    if (empty($input['title'])) {
        sendResponse(false, 'Judul dokumen harus diisi', null, 400);
    }

    $user_id = $user['id'];
    $title = trim($input['title']);
    $description = isset($input['description']) ? trim($input['description']) : null;
    $doc_type = isset($input['doc_type']) ? trim($input['doc_type']) : null;
    $doc_date = isset($input['doc_date']) ? trim($input['doc_date']) : null;
    $doc_time = isset($input['doc_time']) ? trim($input['doc_time']) : null;
    $document_number = isset($input['document_number']) ? trim($input['document_number']) : null;
    $status = isset($input['status']) ? trim($input['status']) : 'draft';
    $visibility = isset($input['visibility']) ? trim($input['visibility']) : 'private';
    $file_path = null;
    $file_upload = null;

    if (empty($doc_type)) {
        sendResponse(false, 'Jenis dokumen harus diisi', null, 400);
    }

    if (empty($doc_date)) {
        sendResponse(false, 'Tanggal dokumen harus diisi', null, 400);
    }

    $valid_doc_types = ['Surat Keputusan', 'Surat Tugas', 'Surat Personal', 'Lain-lain'];
    if (!in_array($doc_type, $valid_doc_types, true)) {
        sendResponse(false, 'Jenis dokumen tidak valid', null, 400);
    }

    if (isset($_FILES['document_file']) && $_FILES['document_file']['error'] === UPLOAD_ERR_OK) {
        $file_upload = validateUploadedDocument($_FILES['document_file']);
        if (!$file_upload['success']) {
            sendResponse(false, $file_upload['message'], null, 400);
        }
    }

    // Validate status
    $valid_status = ['draft', 'published', 'archived'];
    if (!in_array($status, $valid_status)) {
        sendResponse(false, 'Status tidak valid', null, 400);
    }

    // Validate visibility
    $valid_visibility = ['private', 'team', 'public'];
    if (!in_array($visibility, $valid_visibility)) {
        sendResponse(false, 'Visibility tidak valid', null, 400);
    }

    $database = new Database();
    $conn = $database->connect();

    // Check if document_number already exists (if provided)
    if (!empty($document_number)) {
        $check_query = "SELECT id, title, doc_type, doc_date, doc_time, description, file_path FROM documents WHERE document_number = ? LIMIT 1";
        $check_stmt = $conn->prepare($check_query);
        
        if ($check_stmt) {
            $check_stmt->bind_param('s', $document_number);
            $check_stmt->execute();
            $check_result = $check_stmt->get_result();
            
            if ($check_result->num_rows > 0) {
                // Document with this number already exists, return it
                $existing = $check_result->fetch_assoc();
                $check_stmt->close();
                $database->close();
                
                $response_data = [
                    'id' => $existing['id'],
                    'is_existing' => true,
                    'message' => 'Dokumen dengan nomor ini sudah ada, menggunakan dokumen yang ada',
                    'user_id' => $user['id'],
                    'document_number' => $document_number,
                    'title' => $existing['title'],
                    'description' => $existing['description'],
                    'doc_type' => $existing['doc_type'],
                    'doc_date' => $existing['doc_date'],
                    'doc_time' => $existing['doc_time'],
                    'file_path' => $existing['file_path']
                ];
                
                sendResponse(true, 'Dokumen dengan nomor ini sudah ada, menggunakan dokumen yang ada', $response_data, 200);
            }
            $check_stmt->close();
        }
    }

    // Insert new document
    $insert_query = "INSERT INTO documents (admin_id, title, doc_type, description, doc_date, doc_time, document_number, file_path, status, visibility)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    $insert_stmt = $conn->prepare($insert_query);

    if (!$insert_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $insert_stmt->bind_param('isssssssss', $user_id, $title, $doc_type, $description, $doc_date, $doc_time, $document_number, $file_path, $status, $visibility);

    if ($insert_stmt->execute()) {
        $document_id = $insert_stmt->insert_id;

        if ($file_upload) {
            $file_path = "db:document:$document_id";
            $file_name = $file_upload['original_name'];
            $file_mime_type = $file_upload['mime_type'];
            $file_size = $file_upload['size'];
            $file_blob = null;

            $file_update_query = "UPDATE documents
                                  SET file_path = ?, file_name = ?, file_mime_type = ?, file_size = ?, file_data = ?
                                  WHERE id = ?";
            $file_update_stmt = $conn->prepare($file_update_query);
            if (!$file_update_stmt) {
                $insert_stmt->close();
                $database->close();
                sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
            }

            $file_update_stmt->bind_param(
                'sssibi',
                $file_path,
                $file_name,
                $file_mime_type,
                $file_size,
                $file_blob,
                $document_id
            );

            if (!bindBlobAndExecute($file_update_stmt, 4, $file_upload['data'])) {
                $file_update_stmt->close();
                $insert_stmt->close();
                $database->close();
                sendResponse(false, 'Gagal menyimpan file ke database: ' . $file_update_stmt->error, null, 500);
            }
            $file_update_stmt->close();
        }

        $insert_stmt->close();
        $database->close();

        $response_data = [
            'id' => $document_id,
            'is_existing' => false,
            'user_id' => $user_id,
            'document_number' => $document_number,
            'title' => $title,
            'description' => $description,
            'doc_type' => $doc_type,
            'doc_date' => $doc_date,
            'doc_time' => $doc_time,
            'file_path' => $file_path,
            'status' => $status,
            'visibility' => $visibility
        ];

        sendResponse(true, 'Dokumen berhasil dibuat', $response_data, 201);
    } else {
        sendResponse(false, 'Error: ' . $insert_stmt->error, null, 500);
    }
}

function handleUpdateDocument() {
    // Verify token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input['id'])) {
        sendResponse(false, 'ID dokumen harus diberikan', null, 400);
    }

    $document_id = $input['id'];
    $database = new Database();
    $conn = $database->connect();

    // Get current document
    $get_query = "SELECT * FROM documents WHERE id = ?";
    $get_stmt = $conn->prepare($get_query);
    $get_stmt->bind_param('i', $document_id);
    $get_stmt->execute();
    $get_result = $get_stmt->get_result();

    if ($get_result->num_rows === 0) {
        $get_stmt->close();
        $database->close();
        sendResponse(false, 'Dokumen tidak ditemukan', null, 404);
    }

    $document = $get_result->fetch_assoc();
    $get_stmt->close();

    // Check permission - only owner or admin can update
    if ((int) $document['admin_id'] !== (int) $user['id'] && $user['role'] !== 'admin') {
        $database->close();
        sendResponse(false, 'Anda tidak memiliki izin untuk mengubah dokumen ini', null, 403);
    }

    // Build update query
    $update_fields = [];
    $update_params = [];
    $update_types = '';

    if (!empty($input['title'])) {
        $update_fields[] = 'title = ?';
        $update_params[] = trim($input['title']);
        $update_types .= 's';
    }
    if (!empty($input['description'])) {
        $update_fields[] = 'description = ?';
        $update_params[] = trim($input['description']);
        $update_types .= 's';
    }
    if (!empty($input['status'])) {
        $valid_status = ['draft', 'published', 'archived'];
        if (!in_array($input['status'], $valid_status)) {
            sendResponse(false, 'Status tidak valid', null, 400);
        }
        $update_fields[] = 'status = ?';
        $update_params[] = $input['status'];
        $update_types .= 's';
    }
    if (!empty($input['visibility'])) {
        $valid_visibility = ['private', 'team', 'public'];
        if (!in_array($input['visibility'], $valid_visibility)) {
            sendResponse(false, 'Visibility tidak valid', null, 400);
        }
        $update_fields[] = 'visibility = ?';
        $update_params[] = $input['visibility'];
        $update_types .= 's';
    }
    if (isset($input['share_with']) && is_array($input['share_with'])) {
        // Handle sharing/access management
        $share_user_ids = $input['share_with'];
        
        // Delete existing access (except for owner)
        $delete_access_query = "DELETE FROM document_access WHERE document_id = ? AND user_id != ?";
        $delete_access_stmt = $conn->prepare($delete_access_query);
        $delete_access_stmt->bind_param('ii', $document_id, $document['admin_id']);
        $delete_access_stmt->execute();
        $delete_access_stmt->close();

        // Add new access
        $access_insert_query = "INSERT INTO document_access (document_id, user_id, access_type) VALUES (?, ?, ?)";
        $access_insert_stmt = $conn->prepare($access_insert_query);

        foreach ($share_user_ids as $share_user_id) {
            $access_type = 'view'; // default access type
            $access_insert_stmt->bind_param('iis', $document_id, $share_user_id, $access_type);
            $access_insert_stmt->execute();
        }
        $access_insert_stmt->close();
    }

    if (empty($update_fields)) {
        $database->close();
        sendResponse(false, 'Tidak ada field yang diubah', null, 400);
    }

    $update_query = 'UPDATE documents SET ' . implode(', ', $update_fields) . ', updated_at = NOW() WHERE id = ?';
    $update_params[] = $document_id;
    $update_types .= 'i';

    $update_stmt = $conn->prepare($update_query);
    if (!$update_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $update_stmt->bind_param($update_types, ...$update_params);

    if ($update_stmt->execute()) {
        $update_stmt->close();
        $database->close();
        sendResponse(true, 'Dokumen berhasil diubah', null, 200);
    } else {
        sendResponse(false, 'Error: ' . $update_stmt->error, null, 500);
    }
}
?>
