<?php
require_once '../config/Database.php';

header('Content-Type: application/json; charset=utf-8');

$database = new Database();
$conn = $database->connect();

$columns = [];
$result = $conn->query("SHOW COLUMNS FROM users");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $columns[] = $row['Field'];
    }
}

$queries = [];
if (!in_array('nik', $columns)) {
    $queries[] = "ALTER TABLE users ADD COLUMN nik VARCHAR(50) UNIQUE AFTER id";
}
if (!in_array('jabatan', $columns)) {
    $queries[] = "ALTER TABLE users ADD COLUMN jabatan VARCHAR(100) AFTER role";
}

$results = [];
foreach ($queries as $query) {
    if ($conn->query($query) === true) {
        $results[] = ['query' => $query, 'status' => 'success'];
    } else {
        $results[] = ['query' => $query, 'status' => 'failed', 'error' => $conn->error];
    }
}

$database->close();

if (empty($queries)) {
    echo json_encode(['success' => true, 'message' => 'Kolom nik dan jabatan sudah tersedia.', 'data' => $columns]);
} else {
    echo json_encode(['success' => true, 'message' => 'Migrasi kolom selesai.', 'results' => $results]);
}
