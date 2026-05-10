<?php
require_once '../config/Database.php';

$database = new Database();
$conn = $database->connect();

// Correct bcrypt hash for password123
$correctHash = '$2y$10$vpAJhQJ0znF585EroMPg5.370QZS3UnRUd9.0AgV3X4JcmxXD6duG';

echo "Updating all user passwords to use correct hash...\n";

// Update all users with the correct password hash
$query = "UPDATE users SET password = ? WHERE email IN ('admin@example.com', 'user@example.com', 'admin1@gmail.com')";
$stmt = $conn->prepare($query);
$stmt->bind_param('s', $correctHash);

if ($stmt->execute()) {
    echo "✓ Updated {$stmt->affected_rows} users\n";
} else {
    echo "✗ Failed to update users: " . $stmt->error . "\n";
}

$stmt->close();
$database->close();

echo "\nAll users now have password: password123\n";
?>
