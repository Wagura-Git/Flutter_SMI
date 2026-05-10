<?php
// Debug file untuk test registrasi
header('Content-Type: application/json; charset=utf-8');

// Test 1: Check file paths
echo "=== TEST 1: Check File Paths ===\n";
$files_to_check = [
    '../config/Database.php',
    '../includes/functions.php'
];

foreach ($files_to_check as $file) {
    $path = __DIR__ . '/' . $file;
    echo "Checking $file: ";
    if (file_exists($path)) {
        echo "✓ EXISTS\n";
    } else {
        echo "✗ NOT FOUND\n";
    }
}

// Test 2: Check if we can require files
echo "\n=== TEST 2: Try Requiring Files ===\n";
try {
    require_once '../config/Database.php';
    echo "✓ Database.php loaded successfully\n";
} catch (Exception $e) {
    echo "✗ Error loading Database.php: " . $e->getMessage() . "\n";
}

try {
    require_once '../includes/functions.php';
    echo "✓ functions.php loaded successfully\n";
} catch (Exception $e) {
    echo "✗ Error loading functions.php: " . $e->getMessage() . "\n";
}

// Test 3: Check database connection
echo "\n=== TEST 3: Database Connection ===\n";
try {
    $database = new Database();
    $conn = $database->connect();
    echo "✓ Database connection successful\n";
    
    // Test 4: Check if users table exists
    echo "\n=== TEST 4: Check Users Table ===\n";
    $result = $conn->query("SHOW TABLES LIKE 'users'");
    if ($result && $result->num_rows > 0) {
        echo "✓ Users table exists\n";
        
        // Get table structure
        $columns = $conn->query("SHOW COLUMNS FROM users");
        echo "\nUsers table columns:\n";
        while ($col = $columns->fetch_assoc()) {
            echo "  - " . $col['Field'] . " (" . $col['Type'] . ")\n";
        }
    } else {
        echo "✗ Users table does NOT exist\n";
    }
    
    $database->close();
} catch (Exception $e) {
    echo "✗ Database connection error: " . $e->getMessage() . "\n";
}

// Test 5: Try a test registration
echo "\n=== TEST 5: Try Test Registration ===\n";
$_SERVER['REQUEST_METHOD'] = 'POST';
$test_data = [
    'name' => 'Test User',
    'email' => 'test' . time() . '@example.com',
    'password' => 'password123',
    'password_confirm' => 'password123',
    'role' => 'user'
];

// Mock the input
$input = $test_data;

try {
    // Validate input
    if (empty($input['name']) || empty($input['email']) || empty($input['password']) || empty($input['password_confirm'])) {
        echo "✗ Validation failed: Missing required fields\n";
    } else {
        $name = trim($input['name']);
        $email = trim($input['email']);
        $password = $input['password'];
        $password_confirm = $input['password_confirm'];
        $role = isset($input['role']) ? $input['role'] : 'user';
        $phone = isset($input['phone']) ? trim($input['phone']) : null;
        $address = isset($input['address']) ? trim($input['address']) : null;
        $department = isset($input['department']) ? trim($input['department']) : null;
        $position = isset($input['position']) ? trim($input['position']) : null;

        // Basic validations
        echo "✓ Input validation passed\n";

        // Connect database
        $database = new Database();
        $conn = $database->connect();

        // Check if email exists
        $check_query = "SELECT id FROM users WHERE email = ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param('s', $email);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        $check_stmt->close();

        if ($check_result->num_rows > 0) {
            echo "✗ Email sudah terdaftar\n";
        } else {
            echo "✓ Email is unique\n";

            // Hash password
            $hashed_password = hashPassword($password);
            echo "✓ Password hashed successfully\n";

            // Insert user
            $insert_query = "INSERT INTO users (name, email, password, role, phone, address, department, position, status, created_at) 
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW())";
            $insert_stmt = $conn->prepare($insert_query);

            if (!$insert_stmt) {
                echo "✗ Query prepare error: " . $conn->error . "\n";
            } else {
                $insert_stmt->bind_param('ssssssss', $name, $email, $hashed_password, $role, $phone, $address, $department, $position);
                
                if (!$insert_stmt->execute()) {
                    echo "✗ Insert failed: " . $insert_stmt->error . "\n";
                } else {
                    echo "✓ User inserted successfully with ID: " . $insert_stmt->insert_id . "\n";
                    
                    // Try to generate token
                    $token = generateToken($insert_stmt->insert_id, $email, $role);
                    echo "✓ Token generated successfully\n";
                }
                $insert_stmt->close();
            }
        }

        $database->close();
    }
} catch (Exception $e) {
    echo "✗ Exception: " . $e->getMessage() . "\n";
}

echo "\n=== DEBUG COMPLETE ===\n";
?>
