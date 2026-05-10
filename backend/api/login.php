<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Only allow POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (empty($input['email']) || empty($input['password'])) {
    sendResponse(false, 'Email dan password harus diisi', null, 400);
}

$email = trim($input['email']);
$password = $input['password'];

// Validate email format
if (!isValidEmail($email)) {
    sendResponse(false, 'Format email tidak valid', null, 400);
}

// Connect to database
$database = new Database();
$conn = $database->connect();

// Query user by email
$query = "SELECT id, name, email, password, role, status, created_at FROM users WHERE email = ?";
$stmt = $conn->prepare($query);

if (!$stmt) {
    sendResponse(false, 'Query error: ' . $conn->error, null, 500);
}

$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(false, 'Email atau password salah', null, 401);
}

$user = $result->fetch_assoc();
$stmt->close();

// Check if user status is active
if ($user['status'] !== 'active') {
    sendResponse(false, 'Akun Anda telah dinonaktifkan', null, 401);
}

// Verify password
if (!verifyPassword($password, $user['password'])) {
    sendResponse(false, 'Email atau password salah', null, 401);
}

// Generate JWT token
$token = generateToken($user['id'], $user['email'], $user['role']);

// Update last login
$update_query = "UPDATE users SET last_login = NOW() WHERE id = ?";
$update_stmt = $conn->prepare($update_query);
if ($update_stmt) {
    $update_stmt->bind_param('i', $user['id']);
    $update_stmt->execute();
    $update_stmt->close();
}

$database->close();

// Return success response
sendResponse(true, 'Login berhasil', [
    'token' => $token,
    'user' => [
        'id' => $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'role' => $user['role']
    ]
], 200);
?>
