<?php
require_once '../config/Database.php';
require_once '../includes/functions.php';

// Check request method
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get all users or specific user
    handleGetUsers();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Create new user
    handleCreateUser();
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    // Update user
    handleUpdateUser();
} elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    // Delete user
    handleDeleteUser();
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}

function handleGetUsers() {
    // Verify admin token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user || ($user['role'] !== 'admin' && $user['role'] !== 'pimpinan')) {
        sendResponse(false, 'Unauthorized: Hanya admin atau pimpinan yang dapat mengakses', null, 403);
    }

    $database = new Database();
    $conn = $database->connect();

    // Get search query if provided
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';

    // Get all users or search users
    if (!empty($search)) {
        $searchTerm = '%' . $search . '%';
        $query = "SELECT id, nik, name, email, role, status, phone, department, position, jabatan, created_at FROM users 
                  WHERE name LIKE ? OR email LIKE ? OR nik LIKE ? 
                  ORDER BY created_at DESC";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            sendResponse(false, 'Query error: ' . $conn->error, null, 500);
        }
        $stmt->bind_param('sss', $searchTerm, $searchTerm, $searchTerm);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        $query = "SELECT id, nik, name, email, role, status, phone, department, position, jabatan, created_at FROM users ORDER BY created_at DESC";
        $result = $conn->query($query);
    }

    if (!$result) {
        sendResponse(false, 'Query error: ' . $conn->error, null, 500);
    }

    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }

    $database->close();
    sendResponse(true, 'Berhasil mengambil data users', $users, 200);
}

function handleCreateUser() {
    // Verify admin token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user || $user['role'] !== 'admin') {
        sendResponse(false, 'Unauthorized: Hanya admin yang dapat membuat akun', null, 403);
    }

    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (empty($input['name']) || empty($input['email']) || empty($input['password']) || empty($input['role'])) {
        sendResponse(false, 'Nama, email, password, dan role harus diisi', null, 400);
    }

    $name = trim($input['name']);
    $email = trim($input['email']);
    $password = $input['password'];
    $role = $input['role'];
    $nik = isset($input['nik']) ? trim($input['nik']) : null;
    $jabatan = isset($input['jabatan']) ? trim($input['jabatan']) : null;
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

    $database = new Database();
    $conn = $database->connect();

    // Check if email already exists
    $check_query = "SELECT id FROM users WHERE email = ?";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bind_param('s', $email);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows > 0) {
        $check_stmt->close();
        $database->close();
        sendResponse(false, 'Email sudah terdaftar', null, 409);
    }
    $check_stmt->close();

    // Hash password
    $hashed_password = password_hash($password, PASSWORD_BCRYPT);

    // Insert user
    $insert_query = "INSERT INTO users (name, email, password, role, nik, jabatan, phone, department, position, status) 
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')";
    $insert_stmt = $conn->prepare($insert_query);

    if (!$insert_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $insert_stmt->bind_param('sssssssss', $name, $email, $hashed_password, $role, $nik, $jabatan, $phone, $department, $position);

    if ($insert_stmt->execute()) {
        $new_user_id = $insert_stmt->insert_id;
        $insert_stmt->close();
        $database->close();

        $response_data = [
            'id' => $new_user_id,
            'nik' => $nik,
            'name' => $name,
            'email' => $email,
            'role' => $role,
            'jabatan' => $jabatan,
            'phone' => $phone,
            'department' => $department,
            'position' => $position,
            'status' => 'active'
        ];

        sendResponse(true, 'User berhasil dibuat', $response_data, 201);
    } else {
        sendResponse(false, 'Error: ' . $insert_stmt->error, null, 500);
    }
}

function handleUpdateUser() {
    // Verify admin token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user) {
        sendResponse(false, 'Unauthorized: Token tidak valid', null, 403);
    }

    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['id'])) {
        sendResponse(false, 'User ID harus diberikan', null, 400);
    }

    $user_id = $input['id'];
    $isAdmin = $user['role'] === 'admin';
    $isSelf = $user['userId'] === $user_id;

    if (!$isAdmin && !$isSelf) {
        sendResponse(false, 'Unauthorized: Hanya admin atau pemilik akun yang dapat mengubah data ini', null, 403);
    }

    if (!$isAdmin && !empty($input['role'])) {
        sendResponse(false, 'Unauthorized: Anda tidak dapat mengubah role akun ini', null, 403);
    }

    if (!$isAdmin && !empty($input['status'])) {
        sendResponse(false, 'Unauthorized: Anda tidak dapat mengubah status akun ini', null, 403);
    }

    $database = new Database();
    $conn = $database->connect();

    // Build update query dynamically
    $update_fields = [];
    $update_params = [];
    $update_types = '';

    if (!empty($input['name'])) {
        $update_fields[] = 'name = ?';
        $update_params[] = trim($input['name']);
        $update_types .= 's';
    }
    if (!empty($input['email'])) {
        // Check if email already exists
        $check_query = "SELECT id FROM users WHERE email = ? AND id != ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param('si', $input['email'], $user_id);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        if ($check_result->num_rows > 0) {
            $check_stmt->close();
            $database->close();
            sendResponse(false, 'Email sudah digunakan', null, 409);
        }
        $check_stmt->close();

        $update_fields[] = 'email = ?';
        $update_params[] = trim($input['email']);
        $update_types .= 's';
    }
    if (!empty($input['role'])) {
        $valid_roles = ['admin', 'pimpinan', 'user'];
        if (!in_array($input['role'], $valid_roles)) {
            sendResponse(false, 'Role tidak valid', null, 400);
        }
        $update_fields[] = 'role = ?';
        $update_params[] = $input['role'];
        $update_types .= 's';
    }
    if (!empty($input['status'])) {
        $valid_status = ['active', 'inactive'];
        if (!in_array($input['status'], $valid_status)) {
            sendResponse(false, 'Status tidak valid', null, 400);
        }
        $update_fields[] = 'status = ?';
        $update_params[] = $input['status'];
        $update_types .= 's';
    }
    if (!empty($input['phone'])) {
        $update_fields[] = 'phone = ?';
        $update_params[] = trim($input['phone']);
        $update_types .= 's';
    }
    if (!empty($input['nik'])) {
        $update_fields[] = 'nik = ?';
        $update_params[] = trim($input['nik']);
        $update_types .= 's';
    }
    if (!empty($input['jabatan'])) {
        $update_fields[] = 'jabatan = ?';
        $update_params[] = trim($input['jabatan']);
        $update_types .= 's';
    }
    if (!empty($input['address'])) {
        $update_fields[] = 'address = ?';
        $update_params[] = trim($input['address']);
        $update_types .= 's';
    }
    if (!empty($input['department'])) {
        $update_fields[] = 'department = ?';
        $update_params[] = trim($input['department']);
        $update_types .= 's';
    }
    if (!empty($input['position'])) {
        $update_fields[] = 'position = ?';
        $update_params[] = trim($input['position']);
        $update_types .= 's';
    }
    if (!empty($input['password'])) {
        if (strlen($input['password']) < 6) {
            sendResponse(false, 'Password minimal 6 karakter', null, 400);
        }
        $update_fields[] = 'password = ?';
        $update_params[] = password_hash($input['password'], PASSWORD_BCRYPT);
        $update_types .= 's';
    }

    if (empty($update_fields)) {
        sendResponse(false, 'Tidak ada field yang diubah', null, 400);
    }

    $update_query = 'UPDATE users SET ' . implode(', ', $update_fields) . ' WHERE id = ?';
    $update_params[] = $user_id;
    $update_types .= 'i';

    $update_stmt = $conn->prepare($update_query);
    if (!$update_stmt) {
        sendResponse(false, 'Prepare error: ' . $conn->error, null, 500);
    }

    $update_stmt->bind_param($update_types, ...$update_params);

    if ($update_stmt->execute()) {
        $update_stmt->close();
        $database->close();
        sendResponse(true, 'User berhasil diubah', null, 200);
    } else {
        sendResponse(false, 'Error: ' . $update_stmt->error, null, 500);
    }
}

function handleDeleteUser() {
    // Verify admin token
    $token = getBearerToken();
    if (!$token) {
        sendResponse(false, 'Token tidak ditemukan', null, 401);
    }

    $user = verifyUserFromToken($token);
    
    if (!$user || $user['role'] !== 'admin') {
        sendResponse(false, 'Unauthorized: Hanya admin yang dapat menghapus user', null, 403);
    }

    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input['id'])) {
        sendResponse(false, 'User ID harus diberikan', null, 400);
    }

    $user_id = $input['id'];

    // Prevent deleting the last admin
    $database = new Database();
    $conn = $database->connect();

    $check_query = "SELECT role FROM users WHERE id = ?";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bind_param('i', $user_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows === 0) {
        $check_stmt->close();
        $database->close();
        sendResponse(false, 'User tidak ditemukan', null, 404);
    }

    $user_data = $check_result->fetch_assoc();
    $check_stmt->close();

    if ($user_data['role'] === 'admin') {
        $admin_count_query = "SELECT COUNT(*) as count FROM users WHERE role = 'admin'";
        $admin_count_result = $conn->query($admin_count_query);
        $admin_count = $admin_count_result->fetch_assoc()['count'];

        if ($admin_count <= 1) {
            $database->close();
            sendResponse(false, 'Tidak dapat menghapus admin terakhir', null, 400);
        }
    }

    // Delete user
    $delete_query = "DELETE FROM users WHERE id = ?";
    $delete_stmt = $conn->prepare($delete_query);
    $delete_stmt->bind_param('i', $user_id);

    if ($delete_stmt->execute()) {
        $delete_stmt->close();
        $database->close();
        sendResponse(true, 'User berhasil dihapus', null, 200);
    } else {
        sendResponse(false, 'Error: ' . $delete_stmt->error, null, 500);
    }
}
?>
