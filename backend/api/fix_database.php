<?php
// Fix database schema
require_once '../config/Database.php';

echo "=== Fixing Database Schema ===\n";

$database = new Database();
$conn = $database->connect();

// Check existing columns
$columns_result = $conn->query("SHOW COLUMNS FROM users WHERE Field IN ('department', 'position')");
$existing_columns = [];
while ($row = $columns_result->fetch_assoc()) {
    $existing_columns[] = $row['Field'];
}

// Add missing columns
if (!in_array('position', $existing_columns)) {
    echo "Adding 'position' column...\n";
    $sql2 = "ALTER TABLE users ADD COLUMN position VARCHAR(255) AFTER profile_photo";
    if ($conn->query($sql2)) {
        echo "✓ 'position' column added\n";
    } else {
        echo "✗ Error adding 'position' column: " . $conn->error . "\n";
    }
}

if (!in_array('department', $existing_columns)) {
    echo "Adding 'department' column...\n";
    $sql1 = "ALTER TABLE users ADD COLUMN department VARCHAR(255) AFTER position";
    if ($conn->query($sql1)) {
        echo "✓ 'department' column added\n";
    } else {
        echo "✗ Error adding 'department' column: " . $conn->error . "\n";
    }
}

// Check if role enum has 'pimpinan'
$role_result = $conn->query("SHOW COLUMNS FROM users WHERE Field = 'role'");
$role_info = $role_result->fetch_assoc();
echo "\nCurrent 'role' column type: " . $role_info['Type'] . "\n";

if (strpos($role_info['Type'], 'pimpinan') === false) {
    echo "Adding 'pimpinan' to role ENUM...\n";
    $sql3 = "ALTER TABLE users MODIFY role ENUM('admin', 'pimpinan', 'user') DEFAULT 'user'";
    if ($conn->query($sql3)) {
        echo "✓ 'pimpinan' role added to ENUM\n";
    } else {
        echo "✗ Error modifying role ENUM: " . $conn->error . "\n";
    }
}

// Verify final schema
echo "\n=== Final Schema Verification ===\n";
$final_columns = $conn->query("SHOW COLUMNS FROM users");
echo "Users table columns:\n";
while ($col = $final_columns->fetch_assoc()) {
    echo "  - " . $col['Field'] . " (" . $col['Type'] . ")\n";
}

$database->close();
echo "\n✓ Database schema fixed successfully!\n";
?>
