<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Check request method
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    handleGetDispositions();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    handleCreateDisposition();
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    handleUpdateDisposition();
} elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    handleDeleteDispositionHistory();
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}

function handleGetDispositions() {
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
    ensureDispositionsSchema($conn);

    if ($user_role === 'admin') {
        $query = "SELECT d.*, sender.name AS sender_name, recipient.name AS recipient_name,
                         recipient.role AS recipient_role, doc.title AS document_title,
                         doc.file_path AS document_file, doc.doc_date AS document_date
                  FROM dispositions d
                  JOIN users sender ON d.from_user_id = sender.id
                  JOIN users recipient ON d.to_user_id = recipient.id
                  LEFT JOIN documents doc ON d.document_id = doc.id
                  ORDER BY d.created_at DESC";
        $stmt = $conn->prepare($query);
    } else {
        $query = "SELECT d.*, sender.name AS sender_name, recipient.name AS recipient_name,
                         recipient.role AS recipient_role, doc.title AS document_title,
                         doc.file_path AS document_file, doc.doc_date AS document_date
                  FROM dispositions d
                  JOIN users sender ON d.from_user_id = sender.id
                  JOIN users recipient ON d.to_user_id = recipient.id
                  LEFT JOIN documents doc ON d.document_id = doc.id
                  WHERE d.from_user_id = ? OR d.to_user_id = ?
                  ORDER BY d.created_at DESC";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('ii', $user_id, $user_id);
    }

    if (!$stmt || !$stmt->execute()) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }

    $result = $stmt->get_result();
    if (!$result) {
        sendResponse(false, 'Query result error: ' . $conn->error, null, 500);
    }

    $dispositions = [];
    while ($row = $result->fetch_assoc()) {
        $dispositions[] = formatDispositionRow($row);
    }

    $stmt->close();
    $database->close();
    sendResponse(true, 'Berhasil mengambil data disposisi', $dispositions, 200);
}

function handleCreateDisposition() {
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    if ($user['role'] === 'user') {
        sendResponse(false, 'Hanya pimpinan dan admin yang dapat membuat disposisi', null, 403);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        sendResponse(false, 'Payload JSON tidak valid', null, 400);
    }

    if (empty($input['document_id']) || empty($input['instruction'])) {
        sendResponse(false, 'document_id dan instruction harus diisi', null, 400);
    }

    $document_id = intval($input['document_id']);
    $instruction = trim($input['instruction']);
    $sender_id = $user['id'];
    $status = 'pending';

    $recipient_ids = [];
    if (!empty($input['recipient_ids']) && is_array($input['recipient_ids'])) {
        foreach ($input['recipient_ids'] as $recipient_id) {
            $recipient_ids[] = intval($recipient_id);
        }
    } elseif (!empty($input['to_user_id'])) {
        $recipient_ids[] = intval($input['to_user_id']);
    }

    $recipient_ids = array_unique($recipient_ids);
    if (empty($recipient_ids)) {
        sendResponse(false, 'recipient_ids harus diisi', null, 400);
    }

    if (in_array($sender_id, $recipient_ids, true)) {
        sendResponse(false, 'Tidak dapat mengirim disposisi kepada diri sendiri', null, 400);
    }

    $database = new Database();
    $conn = $database->connect();
    ensureDispositionsSchema($conn);

    $document_query = 'SELECT id, title FROM documents WHERE id = ?';
    $document_stmt = $conn->prepare($document_query);
    $document_stmt->bind_param('i', $document_id);
    $document_stmt->execute();
    $document_result = $document_stmt->get_result();
    if ($document_result->num_rows === 0) {
        $document_stmt->close();
        sendResponse(false, 'Dokumen tidak ditemukan', null, 404);
    }
    $document = $document_result->fetch_assoc();
    $document_title = isset($document['title']) ? $document['title'] : 'Surat';
    $document_stmt->close();

    $placeholders = implode(', ', array_fill(0, count($recipient_ids), '?'));
    $recipient_query = 'SELECT id FROM users WHERE id IN (' . $placeholders . ') AND status = "active"';
    $recipient_stmt = $conn->prepare($recipient_query);
    if (!$recipient_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $types = str_repeat('i', count($recipient_ids));
    $params = array_merge([$types], $recipient_ids);
    $refs = [];
    foreach ($params as $key => $value) {
        $refs[$key] = &$params[$key];
    }
    call_user_func_array([$recipient_stmt, 'bind_param'], $refs);
    $recipient_stmt->execute();
    $recipient_result = $recipient_stmt->get_result();

    $valid_recipients = [];
    while ($row = $recipient_result->fetch_assoc()) {
        $valid_recipients[] = intval($row['id']);
    }
    $recipient_stmt->close();

    if (count($valid_recipients) !== count($recipient_ids)) {
        sendResponse(false, 'Beberapa penerima tidak ditemukan atau tidak aktif', null, 400);
    }

    $insert_query = 'INSERT INTO dispositions (document_id, from_user_id, to_user_id, instruction, status) VALUES (?, ?, ?, ?, ?)';
    $insert_stmt = $conn->prepare($insert_query);
    if (!$insert_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $notif_query = "INSERT INTO notifications (user_id, title, message, type, related_id) VALUES (?, ?, ?, 'disposisi', ?)";
    $notif_stmt = $conn->prepare($notif_query);
    if (!$notif_stmt) {
        sendResponse(false, 'Prepare notification error: ' . $conn->error, null, 500);
    }

    $created_ids = [];
    foreach ($recipient_ids as $to_user_id) {
        $insert_stmt->bind_param('iiiss', $document_id, $sender_id, $to_user_id, $instruction, $status);
        if (!$insert_stmt->execute()) {
            sendResponse(false, 'Error: ' . $insert_stmt->error, null, 500);
        }
        $disposition_id = $insert_stmt->insert_id;
        $created_ids[] = $disposition_id;

        $notif_title = 'Disposisi Baru';
        $notif_message = 'Anda menerima disposisi baru untuk dokumen: ' . $document_title;
        $notif_stmt->bind_param('issi', $to_user_id, $notif_title, $notif_message, $disposition_id);
        if (!$notif_stmt->execute()) {
            sendResponse(false, 'Error notification: ' . $notif_stmt->error, null, 500);
        }
    }
    $notif_stmt->close();
    $insert_stmt->close();

    $new_dispositions = [];
    foreach ($created_ids as $disposition_id) {
        $new_dispositions[] = getDispositionById($conn, $disposition_id);
    }

    $database->close();
    sendResponse(true, 'Disposisi berhasil dibuat', ['dispositions' => $new_dispositions], 201);
}

function handleUpdateDisposition() {
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        sendResponse(false, 'Payload JSON tidak valid', null, 400);
    }

    if (empty($input['id'])) {
        sendResponse(false, 'ID disposisi harus diberikan', null, 400);
    }

    $disposition_id = intval($input['id']);
    $new_status = isset($input['status']) ? trim($input['status']) : null;
    $reply_instruction = isset($input['reply_instruction']) ? trim($input['reply_instruction']) : null;

    // Validate status if provided
    if ($new_status !== null) {
        $valid_status = ['pending', 'processed', 'completed'];
        if (!in_array($new_status, $valid_status, true)) {
            sendResponse(false, 'Status tidak valid', null, 400);
        }
    }

    $database = new Database();
    $conn = $database->connect();
    ensureDispositionsSchema($conn);
    $has_reply_instruction = tableHasColumn($conn, 'dispositions', 'reply_instruction');
    $has_updated_at = tableHasColumn($conn, 'dispositions', 'updated_at');

    $get_query = 'SELECT * FROM dispositions WHERE id = ?';
    $get_stmt = $conn->prepare($get_query);
    $get_stmt->bind_param('i', $disposition_id);
    $get_stmt->execute();
    $get_result = $get_stmt->get_result();

    if ($get_result->num_rows === 0) {
        $get_stmt->close();
        $database->close();
        sendResponse(false, 'Disposisi tidak ditemukan', null, 404);
    }

    $disposition = $get_result->fetch_assoc();
    $get_stmt->close();

    if ($user['role'] !== 'admin' && $disposition['from_user_id'] !== $user['id'] && $disposition['to_user_id'] !== $user['id']) {
        $database->close();
        sendResponse(false, 'Anda tidak memiliki izin untuk mengubah disposisi ini', null, 403);
    }

    // Build dynamic UPDATE query based on what needs to be updated
    $update_fields = [];
    $update_params = [];
    $param_types = '';

    if ($new_status !== null) {
        $update_fields[] = 'status = ?';
        $update_params[] = $new_status;
        $param_types .= 's';
    }

    if ($reply_instruction !== null) {
        if (!$has_reply_instruction) {
            $database->close();
            sendResponse(false, 'Kolom reply_instruction belum tersedia di tabel dispositions', null, 500);
        }
        $update_fields[] = 'reply_instruction = ?';
        $update_params[] = $reply_instruction;
        $param_types .= 's';
    }

    if (empty($update_fields)) {
        $database->close();
        sendResponse(false, 'Tidak ada data yang perlu diupdate', null, 400);
    }

    if ($has_updated_at) {
        $update_fields[] = 'updated_at = CURRENT_TIMESTAMP';
    }
    $update_query = 'UPDATE dispositions SET ' . implode(', ', $update_fields) . ' WHERE id = ?';
    
    $update_stmt = $conn->prepare($update_query);
    $update_params[] = $disposition_id;
    $param_types .= 'i';
    
    $update_stmt->bind_param($param_types, ...$update_params);

    if (!$update_stmt->execute()) {
        sendResponse(false, 'Error: ' . $update_stmt->error, null, 500);
    }

    $update_stmt->close();
    $updated_disposition = getDispositionById($conn, $disposition_id);
    $database->close();

    sendResponse(true, 'Disposisi berhasil diubah', $updated_disposition, 200);
}

function handleDeleteDispositionHistory() {
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    if (!$user) {
        sendResponse(false, 'Token tidak valid', null, 401);
    }

    if ($user['role'] !== 'admin') {
        sendResponse(false, 'Hanya admin yang dapat menghapus disposisi', null, 403);
    }

    $requestBody = json_decode(file_get_contents('php://input'), true);
    $disposition_id = null;
    if (is_array($requestBody) && !empty($requestBody['id'])) {
        $disposition_id = intval($requestBody['id']);
    } elseif (!empty($_GET['id'])) {
        $disposition_id = intval($_GET['id']);
    }

    if (empty($disposition_id)) {
        sendResponse(false, 'ID disposisi harus diberikan', null, 400);
    }

    $database = new Database();
    $conn = $database->connect();
    ensureDispositionsSchema($conn);

    $delete_query = 'DELETE FROM dispositions WHERE id = ?';
    $delete_stmt = $conn->prepare($delete_query);
    $delete_stmt->bind_param('i', $disposition_id);

    if (!$delete_stmt->execute()) {
        sendResponse(false, 'Error: ' . $delete_stmt->error, null, 500);
    }

    if ($delete_stmt->affected_rows === 0) {
        $delete_stmt->close();
        $database->close();
        sendResponse(false, 'Disposisi tidak ditemukan', null, 404);
    }

    $delete_stmt->close();
    $database->close();
    sendResponse(true, 'Disposisi berhasil dihapus', null, 200);
}

function getDispositionById($conn, $disposition_id) {
    $query = "SELECT d.*, sender.name AS sender_name, recipient.name AS recipient_name,
                     recipient.role AS recipient_role, doc.title AS document_title,
                     doc.file_path AS document_file, doc.doc_date AS document_date
              FROM dispositions d
              JOIN users sender ON d.from_user_id = sender.id
              JOIN users recipient ON d.to_user_id = recipient.id
              LEFT JOIN documents doc ON d.document_id = doc.id
              WHERE d.id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $disposition_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $stmt->close();
        return formatDispositionRow($row);
    }

    $stmt->close();
    return null;
}

function formatDispositionRow($row) {
    $document_date = isset($row['document_date']) ? $row['document_date'] : null;
    $created_at = isset($row['created_at']) ? $row['created_at'] : date('Y-m-d H:i:s');
    $updated_at = isset($row['updated_at']) ? $row['updated_at'] : $created_at;
    $recipient_id = isset($row['to_user_id']) ? intval($row['to_user_id']) : null;
    $updates = [];

    if (!empty($row['reply_instruction'])) {
        $updates[] = [
            'id' => intval($row['id']),
            'disposition_id' => intval($row['id']),
            'updated_by' => $recipient_id,
            'updated_by_name' => isset($row['recipient_name']) ? $row['recipient_name'] : 'Unknown',
            'old_status' => 'pending',
            'new_status' => isset($row['status']) ? $row['status'] : 'processed',
            'update_notes' => $row['reply_instruction'],
            'created_at' => $updated_at,
        ];
    }

    return [
        'id' => intval($row['id']),
        'document_id' => intval($row['document_id']),
        'sender_id' => intval($row['from_user_id']),
        'letter_number' => null,
        'letter_date' => $document_date,
        'letter_subject' => isset($row['document_title']) ? $row['document_title'] : 'Disposisi Surat',
        'letter_content' => isset($row['instruction']) ? $row['instruction'] : null,
        'document_file' => isset($row['document_file']) ? $row['document_file'] : null,
        'priority' => 'normal',
        'status' => isset($row['status']) ? $row['status'] : 'pending',
        'notes' => null,
        'created_at' => $created_at,
        'updated_at' => $updated_at,
        'sender_name' => isset($row['sender_name']) ? $row['sender_name'] : 'Unknown',
        'recipients' => [
            [
                'id' => $recipient_id,
                'recipient_user_id' => $recipient_id,
                'recipient_name' => isset($row['recipient_name']) ? $row['recipient_name'] : 'Unknown',
                'role_at_assignment' => isset($row['recipient_role']) ? $row['recipient_role'] : null,
                'assigned_at' => $created_at,
            ],
        ],
        'updates' => $updates,
    ];
}

function tableHasColumn($conn, $table_name, $column_name) {
    $table_name = $conn->real_escape_string($table_name);
    $column_name = $conn->real_escape_string($column_name);
    $query = "SHOW COLUMNS FROM `$table_name` LIKE '$column_name'";
    $result = $conn->query($query);
    return $result && $result->num_rows > 0;
}

function ensureDispositionsSchema($conn) {
    if (!tableHasColumn($conn, 'dispositions', 'reply_instruction')) {
        $alter_reply = "ALTER TABLE dispositions ADD COLUMN reply_instruction TEXT NULL AFTER instruction";
        if (!$conn->query($alter_reply)) {
            sendResponse(false, 'Gagal menambahkan kolom reply_instruction: ' . $conn->error, null, 500);
        }
    }

    if (!tableHasColumn($conn, 'dispositions', 'updated_at')) {
        $alter_updated = "ALTER TABLE dispositions ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at";
        if (!$conn->query($alter_updated)) {
            sendResponse(false, 'Gagal menambahkan kolom updated_at: ' . $conn->error, null, 500);
        }
    }
}
?>
