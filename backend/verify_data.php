<?php
require 'config/Database.php';

$db = new Database();
$conn = $db->connect();
$conn->select_db('si_manajemen_kampus');

$result = $conn->query("SELECT id, name, email, role FROM users");

if ($result && $result->num_rows > 0) {
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    echo json_encode([
        'success' => true,
        'message' => 'Users found (data preserved)',
        'count' => count($users),
        'users' => $users
    ], JSON_PRETTY_PRINT);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'No users found',
        'error' => $conn->error
    ]);
}

$db->close();
?>
