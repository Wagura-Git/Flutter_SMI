<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';
require_once '../includes/file_storage.php';

// Only allow POST, GET, PUT, DELETE requests
if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST', 'PUT', 'DELETE'])) {
    sendResponse(false, 'Method not allowed', null, 405);
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

$userId = $tokenData['userId'];
$database = new Database();
$conn = $database->connect();

// Get current user role
$roleQuery = "SELECT role FROM users WHERE id = ?";
$roleStmt = $conn->prepare($roleQuery);
$roleStmt->bind_param('i', $userId);
$roleStmt->execute();
$roleResult = $roleStmt->get_result();
$userData = $roleResult->fetch_assoc();
$userRole = $userData['role'] ?? 'user';
$roleStmt->close();

// GET - Fetch agendas based on role
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $agendaId = isset($_GET['id']) ? (int) $_GET['id'] : null;

    if ($agendaId) {
        $query = "SELECT DISTINCT a.id, a.user_id, a.title, a.description, a.date_start, a.date_end, a.time_start, a.time_end, 
                         a.location, a.agenda_type, a.notif_value, a.notif_unit, a.attachment_path, a.status, a.created_at, a.updated_at 
                  FROM agendas a
                  LEFT JOIN agenda_invitations ai ON ai.agenda_id = a.id
                  WHERE a.id = ?
                  AND (a.user_id = ? OR ai.user_id = ?)
                  LIMIT 1";

        $stmt = $conn->prepare($query);
        if (!$stmt) {
            sendResponse(false, 'Query error: ' . $conn->error, null, 500);
        }

        $stmt->bind_param('iii', $agendaId, $userId, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();

        if (!$row) {
            $database->close();
            sendResponse(false, 'Agenda tidak ditemukan', null, 404);
        }

        $recipients = [];
        if ($row['agenda_type'] === 'umum') {
            $recipientQuery = "SELECT u.id, u.name FROM users u
                             INNER JOIN agenda_invitations ai ON u.id = ai.user_id
                             WHERE ai.agenda_id = ?";
            $recipientStmt = $conn->prepare($recipientQuery);
            $recipientStmt->bind_param('i', $agendaId);
            $recipientStmt->execute();
            $recipientResult = $recipientStmt->get_result();

            while ($recipientRow = $recipientResult->fetch_assoc()) {
                $recipients[] = $recipientRow;
            }
            $recipientStmt->close();
        }

        $row['recipients'] = $recipients;

        $database->close();
        sendResponse(true, 'Agenda fetched successfully', $row, 200);
    }

    // Hanya tampilkan agenda institusi yang dibuat oleh admin/pimpinan
    // dan mengundang user yang sedang login.
    $query = "SELECT DISTINCT a.id, a.user_id, a.title, a.description, a.date_start, a.date_end, a.time_start, a.time_end, 
                     a.location, a.agenda_type, a.notif_value, a.notif_unit, a.attachment_path, a.status, a.created_at, a.updated_at 
              FROM agendas a
              INNER JOIN users creator ON creator.id = a.user_id
              LEFT JOIN agenda_invitations ai ON ai.agenda_id = a.id
              WHERE a.agenda_type = 'umum'
              AND creator.role IN ('admin', 'pimpinan')
              AND (a.user_id = ? OR ai.user_id = ?)
              ORDER BY a.date_start ASC, a.time_start ASC";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }
    
    $stmt->bind_param('ii', $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $agendas = [];
    while ($row = $result->fetch_assoc()) {
        $agendaId = $row['id'];
        
        // Dapatkan list penerima untuk agenda umum
        $recipients = [];
        if ($row['agenda_type'] === 'umum') {
            $recipientQuery = "SELECT u.id, u.name FROM users u
                             INNER JOIN agenda_invitations ai ON u.id = ai.user_id
                             WHERE ai.agenda_id = ?";
            $recipientStmt = $conn->prepare($recipientQuery);
            $recipientStmt->bind_param('i', $agendaId);
            $recipientStmt->execute();
            $recipientResult = $recipientStmt->get_result();
            
            while ($recipientRow = $recipientResult->fetch_assoc()) {
                $recipients[] = $recipientRow;
            }
            $recipientStmt->close();
        }
        
        $row['recipients'] = $recipients;
        $agendas[] = $row;
    }
    
    $stmt->close();
    $database->close();
    sendResponse(true, 'Agendas fetched successfully', $agendas, 200);
}

// POST - Create new agenda
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!is_array($input)) {
        sendResponse(false, 'Payload JSON tidak valid', null, 400);
    }
    
    $title = $input['title'] ?? null;
    $description = $input['description'] ?? null;
    $date_start = $input['date_start'] ?? null;
    $date_end = $input['date_end'] ?? null;
    $time_start = $input['time_start'] ?? null;
    $time_end = $input['time_end'] ?? null;
    $location = $input['location'] ?? null;
    $agenda_type = $input['agenda_type'] ?? 'pribadi'; // pribadi atau umum
    $notif_value = isset($input['notif_value']) ? (int) $input['notif_value'] : 30;
    $notif_unit = $input['notif_unit'] ?? 'Menit';
    $attachment_path = $input['attachment_path'] ?? null;
    $invitations = $input['invitations'] ?? []; // Array of user IDs untuk agenda umum
    $attachment = null;
    
    if (!$title || !$date_start || !$time_start) {
        sendResponse(false, 'Title, date_start, dan time_start harus diisi', null, 400);
    }
    
    if ($attachment_path && strpos($attachment_path, 'db:agenda_upload:') === 0) {
        $uploadId = (int) substr($attachment_path, strlen('db:agenda_upload:'));
        $uploadQuery = "SELECT id, original_name, file_name, mime_type, file_size, file_data
                        FROM agenda_uploads
                        WHERE id = ? AND user_id = ?
                        LIMIT 1";
        $uploadStmt = $conn->prepare($uploadQuery);
        if (!$uploadStmt) {
            sendResponse(false, 'Query error: ' . $conn->error, null, 500);
        }

        $uploadStmt->bind_param('ii', $uploadId, $userId);
        $uploadStmt->execute();
        $uploadResult = $uploadStmt->get_result();
        $attachment = $uploadResult->fetch_assoc();
        $uploadStmt->close();

        if (!$attachment) {
            sendResponse(false, 'File agenda tidak ditemukan di database', null, 400);
        }
    }

    $query = "INSERT INTO agendas (user_id, title, description, date_start, date_end, time_start, time_end, location, agenda_type, notif_value, notif_unit, attachment_path, status)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'scheduled')";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }
    
    $stmt->bind_param('issssssssiss', $userId, $title, $description, $date_start, $date_end, $time_start, $time_end, $location, $agenda_type, $notif_value, $notif_unit, $attachment_path);
    
    if ($stmt->execute()) {
        $agendaId = $conn->insert_id;
        $finalAttachmentPath = $attachment ? "db:agenda:$agendaId" : $attachment_path;

        if ($attachment) {
            $attachmentName = $attachment['original_name'] ?: $attachment['file_name'];
            $attachmentMimeType = $attachment['mime_type'];
            $attachmentSize = (int) $attachment['file_size'];
            $attachmentBlob = null;

            $updateFileQuery = "UPDATE agendas
                                SET attachment_path = ?, attachment_name = ?, attachment_mime_type = ?, attachment_size = ?, attachment_data = ?
                                WHERE id = ?";
            $updateFileStmt = $conn->prepare($updateFileQuery);
            if (!$updateFileStmt) {
                $stmt->close();
                $database->close();
                sendResponse(false, 'Query error: ' . $conn->error, null, 500);
            }

            $updateFileStmt->bind_param(
                'sssibi',
                $finalAttachmentPath,
                $attachmentName,
                $attachmentMimeType,
                $attachmentSize,
                $attachmentBlob,
                $agendaId
            );

            if (!bindBlobAndExecute($updateFileStmt, 4, $attachment['file_data'])) {
                $updateFileStmt->close();
                $stmt->close();
                $database->close();
                sendResponse(false, 'Gagal menyimpan lampiran agenda ke database', null, 500);
            }
            $updateFileStmt->close();

            $deleteUploadQuery = "DELETE FROM agenda_uploads WHERE id = ?";
            $deleteUploadStmt = $conn->prepare($deleteUploadQuery);
            if ($deleteUploadStmt) {
                $attachmentUploadId = (int) $attachment['id'];
                $deleteUploadStmt->bind_param('i', $attachmentUploadId);
                $deleteUploadStmt->execute();
                $deleteUploadStmt->close();
            }
        }
        
        // Insert undangan jika agenda tipe umum
        if ($agenda_type === 'umum' && !empty($invitations)) {
            $invitQuery = "INSERT INTO agenda_invitations (agenda_id, user_id) VALUES (?, ?)";
            $invitStmt = $conn->prepare($invitQuery);
            
            foreach ($invitations as $invitUserId) {
                $invitStmt->bind_param('ii', $agendaId, $invitUserId);
                $invitStmt->execute();
            }
            $invitStmt->close();
        }
        
        // Create notification for new agenda
        $notifQuery = "INSERT INTO notifications (user_id, title, message, type, related_id) 
                      VALUES (?, ?, ?, 'agenda', ?)";
        $notifStmt = $conn->prepare($notifQuery);
        
        if ($notifStmt) {
            $notifTitle = "Agenda Baru: $title";
            $notifMessage = "Agenda baru telah ditambahkan pada " . date('d-m-Y H:i');
            $notifStmt->bind_param('issi', $userId, $notifTitle, $notifMessage, $agendaId);
            $notifStmt->execute();
            $notifStmt->close();
        }
        
        // Jika agenda umum, buat notifikasi untuk semua yang diundang
        if ($agenda_type === 'umum' && !empty($invitations)) {
            $notifInviteQuery = "INSERT INTO notifications (user_id, title, message, type, related_id) 
                               VALUES (?, ?, ?, 'agenda', ?)";
            $notifInviteStmt = $conn->prepare($notifInviteQuery);
            
            foreach ($invitations as $invitUserId) {
                $inviteTitle = "Anda Diundang: $title";
                $inviteMessage = "Anda diundang ke agenda: $title pada " . date('d-m-Y H:i');
                $notifInviteStmt->bind_param('issi', $invitUserId, $inviteTitle, $inviteMessage, $agendaId);
                $notifInviteStmt->execute();
            }
            $notifInviteStmt->close();
        }
        
        $stmt->close();
        $database->close();
        sendResponse(true, 'Agenda berhasil dibuat', ['id' => $agendaId, 'type' => $agenda_type, 'attachment_path' => $finalAttachmentPath], 201);
    } else {
        $stmt->close();
        $database->close();
        sendResponse(false, 'Error creating agenda: ' . $conn->error, null, 500);
    }
}

// PUT - Update agenda
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    $input = json_decode(file_get_contents('php://input'), true);
    
    $agendaId = $input['id'] ?? null;
    $title = $input['title'] ?? null;
    $description = $input['description'] ?? null;
    $date_start = $input['date_start'] ?? null;
    $date_end = $input['date_end'] ?? null;
    $time_start = $input['time_start'] ?? null;
    $time_end = $input['time_end'] ?? null;
    $location = $input['location'] ?? null;
    $agenda_type = $input['agenda_type'] ?? null;
    $notif_value = $input['notif_value'] ?? null;
    $notif_unit = $input['notif_unit'] ?? null;
    $attachment_path = $input['attachment_path'] ?? null;
    $status = $input['status'] ?? null;
    $invitations = $input['invitations'] ?? null;
    
    if (!$agendaId) {
        sendResponse(false, 'ID agenda diperlukan', null, 400);
    }
    
    // Check if agenda belongs to user or user is recipient or is admin
    $checkQuery = "SELECT id, user_id FROM agendas WHERE id = ? AND (user_id = ? OR EXISTS(SELECT 1 FROM agenda_invitations WHERE agenda_id = ? AND user_id = ?))";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param('iiii', $agendaId, $userId, $agendaId, $userId);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0 && $userRole !== 'admin') {
        $checkStmt->close();
        $database->close();
        sendResponse(false, 'Agenda tidak ditemukan atau Anda tidak memiliki akses', null, 404);
    }
    $checkStmt->close();
    
    $updateQuery = "UPDATE agendas SET ";
    $params = [];
    $types = "";
    
    if ($title) { $updateQuery .= "title = ?, "; $params[] = $title; $types .= "s"; }
    if ($description) { $updateQuery .= "description = ?, "; $params[] = $description; $types .= "s"; }
    if ($date_start) { $updateQuery .= "date_start = ?, "; $params[] = $date_start; $types .= "s"; }
    if ($date_end) { $updateQuery .= "date_end = ?, "; $params[] = $date_end; $types .= "s"; }
    if ($time_start) { $updateQuery .= "time_start = ?, "; $params[] = $time_start; $types .= "s"; }
    if ($time_end) { $updateQuery .= "time_end = ?, "; $params[] = $time_end; $types .= "s"; }
    if ($location) { $updateQuery .= "location = ?, "; $params[] = $location; $types .= "s"; }
    if ($agenda_type) { $updateQuery .= "agenda_type = ?, "; $params[] = $agenda_type; $types .= "s"; }
    if ($notif_value) { $updateQuery .= "notif_value = ?, "; $params[] = $notif_value; $types .= "i"; }
    if ($notif_unit) { $updateQuery .= "notif_unit = ?, "; $params[] = $notif_unit; $types .= "s"; }
    if ($attachment_path) { $updateQuery .= "attachment_path = ?, "; $params[] = $attachment_path; $types .= "s"; }
    if ($status) { $updateQuery .= "status = ?, "; $params[] = $status; $types .= "s"; }
    
    $updateQuery = rtrim($updateQuery, ", ");
    $updateQuery .= " WHERE id = ?";
    $params[] = $agendaId;
    $types .= "i";
    
    $updateStmt = $conn->prepare($updateQuery);
    if (!$updateStmt) {
        $database->close();
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }
    
    $updateStmt->bind_param($types, ...$params);
    
    if ($updateStmt->execute()) {
        // Update invitations jika dikirim
        if ($invitations !== null) {
            // Hapus invitations lama
            $deleteInvitQuery = "DELETE FROM agenda_invitations WHERE agenda_id = ?";
            $deleteInvitStmt = $conn->prepare($deleteInvitQuery);
            $deleteInvitStmt->bind_param('i', $agendaId);
            $deleteInvitStmt->execute();
            $deleteInvitStmt->close();
            
            // Insert invitations baru
            if (!empty($invitations)) {
                $invitQuery = "INSERT INTO agenda_invitations (agenda_id, user_id) VALUES (?, ?)";
                $invitStmt = $conn->prepare($invitQuery);
                
                foreach ($invitations as $invitUserId) {
                    $invitStmt->bind_param('ii', $agendaId, $invitUserId);
                    $invitStmt->execute();
                }
                $invitStmt->close();
            }
        }
        
        $updateStmt->close();
        $database->close();
        sendResponse(true, 'Agenda berhasil diperbarui', null, 200);
    } else {
        $updateStmt->close();
        $database->close();
        sendResponse(false, 'Error updating agenda', null, 500);
    }
}

// DELETE - Delete agenda
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $input = json_decode(file_get_contents('php://input'), true);
    $agendaId = $input['id'] ?? null;
    
    if (!$agendaId) {
        sendResponse(false, 'ID agenda diperlukan', null, 400);
    }
    
    // Hanya admin/pimpinan yang boleh menghapus agenda institusi.
    if (!in_array($userRole, ['admin', 'pimpinan'])) {
        $database->close();
        sendResponse(false, 'Anda tidak memiliki izin untuk menghapus agenda', null, 403);
    }

    // Admin/pimpinan dapat menghapus agenda yang dibuat oleh admin/pimpinan.
    $checkQuery = "SELECT a.id, a.user_id
                   FROM agendas a
                   INNER JOIN users creator ON creator.id = a.user_id
                   WHERE a.id = ? AND creator.role IN ('admin', 'pimpinan')";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param('i', $agendaId);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        $checkStmt->close();
        $database->close();
        sendResponse(false, 'Agenda tidak ditemukan', null, 404);
    }
    $checkStmt->close();
    
    $deleteQuery = "DELETE FROM agendas WHERE id = ?";
    $deleteStmt = $conn->prepare($deleteQuery);
    $deleteStmt->bind_param('i', $agendaId);
    
    if ($deleteStmt->execute()) {
        $deleteStmt->close();
        $database->close();
        sendResponse(true, 'Agenda berhasil dihapus', null, 200);
    } else {
        $deleteStmt->close();
        $database->close();
        sendResponse(false, 'Error deleting agenda', null, 500);
    }
}

$database->close();
?>
