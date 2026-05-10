<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Only allow GET, POST, PUT requests
if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST', 'PUT'])) {
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

// GET - Fetch notifications
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $isRead = $_GET['is_read'] ?? null;
    
    $query = "SELECT id, user_id, title, message, type, related_id AS related_agenda_id, is_read, created_at, created_at AS updated_at 
              FROM notifications 
              WHERE user_id = ?";
    
    if ($isRead !== null) {
        $isReadBool = $isRead === 'true' ? 1 : 0;
        $query .= " AND is_read = ?";
    }
    
    $query .= " ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }

    if ($isRead !== null) {
        $stmt->bind_param('ii', $userId, $isReadBool);
    } else {
        $stmt->bind_param('i', $userId);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = $row;
    }
    $stmt->close();
    
    $database->close();
    sendResponse(true, 'Notifications fetched successfully', $notifications, 200);
}

// POST - Mark notification as read
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $notificationId = $input['id'] ?? null;
    $isRead = $input['is_read'] ?? true;
    
    if (!$notificationId) {
        sendResponse(false, 'ID notifikasi diperlukan', null, 400);
    }
    
    // Check if notification belongs to user
    $checkQuery = "SELECT id FROM notifications WHERE id = ? AND user_id = ?";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param('ii', $notificationId, $userId);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        $checkStmt->close();
        $database->close();
        sendResponse(false, 'Notifikasi tidak ditemukan', null, 404);
    }
    $checkStmt->close();
    
    $isReadInt = $isRead ? 1 : 0;
    $updateQuery = "UPDATE notifications SET is_read = ? WHERE id = ? AND user_id = ?";
    $updateStmt = $conn->prepare($updateQuery);
    $updateStmt->bind_param('iii', $isReadInt, $notificationId, $userId);
    
    if ($updateStmt->execute()) {
        $updateStmt->close();
        $database->close();
        sendResponse(true, 'Notifikasi berhasil diperbarui', null, 200);
    } else {
        $updateStmt->close();
        $database->close();
        sendResponse(false, 'Error updating notification', null, 500);
    }
}

// PUT - Mark all notifications as read
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $updateQuery = "UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0";
    $updateStmt = $conn->prepare($updateQuery);
    $updateStmt->bind_param('i', $userId);
    
    if ($updateStmt->execute()) {
        $updateStmt->close();
        $database->close();
        sendResponse(true, 'Semua notifikasi telah ditandai sebagai dibaca', null, 200);
    } else {
        $updateStmt->close();
        $database->close();
        sendResponse(false, 'Error updating notifications', null, 500);
    }
}

$database->close();
?>
