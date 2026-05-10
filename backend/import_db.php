<?php
// Import database script
$servername = "localhost";
$username = "root";
$password = ""; // Kosong jika default XAMPP
$dbname = "si_manajemen_kampus";

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Create database
// $sql = "CREATE DATABASE IF NOT EXISTS $dbname";
// if ($conn->query($sql) === TRUE) {
//     echo "Database created successfully\n";
// } else {
//     echo "Error creating database: " . $conn->error . "\n";
// }

// Select database
$conn->select_db($dbname);

// Drop existing tables if any
$tables = ['users', 'documents', 'document_recipients', 'dispositions', 'agendas', 'agenda_invitations', 'notifications'];
foreach ($tables as $table) {
    $conn->query("DROP TABLE IF EXISTS $table");
    echo "Dropped table $table if exists\n";
}

// Read and execute SQL file
$sqlFile = __DIR__ . '/database.sql';
if (file_exists($sqlFile)) {
    $sqlContent = file_get_contents($sqlFile);
    // Split by semicolon, but handle multi-line statements
    $statements = array_filter(array_map('trim', explode(';', $sqlContent)));
    foreach ($statements as $statement) {
        if (!empty($statement) && !preg_match('/^--/', $statement) && !preg_match('/CREATE DATABASE/i', $statement)) {
            if ($conn->query($statement) === TRUE) {
                echo "Executed: " . substr($statement, 0, 50) . "...\n";
            } else {
                echo "Error executing: " . $conn->error . "\n";
                echo "Statement: " . $statement . "\n";
            }
        }
    }
} else {
    echo "SQL file not found: $sqlFile\n";
}

$conn->close();
echo "Import completed.\n";
?>