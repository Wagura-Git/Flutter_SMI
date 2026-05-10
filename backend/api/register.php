<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

/**
 * User Registration Endpoint
 * 
 * ROLE SYSTEM (3 Roles):
 * - pimpinan: Dapat membuat disposisi surat, hanya membuat agenda pribadi, dan fitur lainnya
 * - admin: Disposisi surat sebagai viewer, bisa membuat agenda pribadi dan umum ke user dan pimpinan, dan fitur lainnya
 * - user: Disposisi surat sebagai viewer, hanya bisa membuat agenda pribadi
 * 
 * Default role saat registrasi adalah 'user'
 */

// Only allow POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (empty($input['name']) || empty($input['email']) || empty($input['password']) || empty($input['password_confirm'])) {
    sendResponse(false, 'Semua field harus diisi', null, 400);
}

$name = trim($input['name']);
$email = trim($input['email']);
$password = $input['password'];
$password_confirm = $input['password_confirm'];
$role = isset($input['role']) ? $input['role'] : 'user'; // Default role adalah 'user'
$phone = isset($input['phone']) ? trim($input['phone']) : null;
$department = isset($input['department']) ? trim($input['department']) : null;
$position = isset($input['position']) ? trim($input['position']) : null;

// Validate role
$valid_roles = ['admin', 'pimpinan', 'user'];
if (!in_array($role, $valid_roles)) {
    sendResponse(false, 'Role tidak valid. Pilih: admin, pimpinan, atau user', null, 400);
}

// Validate email format
if (!isValidEmail($email)) {
    sendResponse(false, 'Format email tidak valid', null, 400);
}

// Validate password length
if (strlen($password) < 6) {
    sendResponse(false, 'Password minimal 6 karakter', null, 400);
}

// Validate password match
if ($password !== $password_confirm) {
    sendResponse(false, 'Password tidak cocok', null, 400);
}

// Validate name length
if (strlen($name) < 3) {
    sendResponse(false, 'Nama minimal 3 karakter', null, 400);
}

// Connect to database
$database = new Database();
$conn = $database->connect();

// Check if email already exists
$check_query = "SELECT id FROM users WHERE email = ?";
$check_stmt = $conn->prepare($check_query);

if (!$check_stmt) {
    sendResponse(false, 'Query error: ' . $conn->error, null, 500);
}

$check_stmt->bind_param('s', $email);
$check_stmt->execute();
$check_result = $check_stmt->get_result();
$check_stmt->close();

if ($check_result->num_rows > 0) {
    $database->close();
    sendResponse(false, 'Email sudah terdaftar', null, 400);
}

// Hash password
$hashed_password = hashPassword($password);

// Insert user
$insert_query = "INSERT INTO users (name, email, password, role, phone, department, position, status, created_at) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, 'active', NOW())";
$insert_stmt = $conn->prepare($insert_query);

if (!$insert_stmt) {
    sendResponse(false, 'Query error: ' . $conn->error, null, 500);
}

$insert_stmt->bind_param('sssssss', $name, $email, $hashed_password, $role, $phone, $department, $position);

if (!$insert_stmt->execute()) {
    sendResponse(false, 'Terjadi kesalahan saat registrasi: ' . $insert_stmt->error, null, 500);
}

$user_id = $insert_stmt->insert_id;
$insert_stmt->close();
$database->close();

// Generate JWT token
$token = generateToken($user_id, $email, $role);

// Return success response
sendResponse(true, 'Registrasi berhasil', [
    'token' => $token,
    'user' => [
        'id' => $user_id,
        'name' => $name,
        'email' => $email,
        'role' => $role,
        'phone' => $phone,
        'department' => $department,
        'position' => $position
    ]
], 201);
?>
