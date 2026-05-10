<?php
/**
 * Safe Database Migration Script
 * =============================
 * This script safely updates the database schema without deleting existing data.
 * 
 * Usage:
 * 1. First time setup: run_initial_setup.php
 * 2. Updates: safe_migration.php
 * 
 * NEVER use database.sql directly - it will DELETE all your data!
 */

require_once 'config/Database.php';
require_once 'includes/functions.php';

$db = new Database();
$conn = $db->connect();

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

// Check if database exists
$database_name = 'si_manajemen_kampus';
$result = $conn->query("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$database_name'");

if ($result->num_rows === 0) {
    // Database doesn't exist, create it
    if ($conn->query("CREATE DATABASE $database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")) {
        echo json_encode(['success' => true, 'message' => 'Database created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to create database: ' . $conn->error]);
        exit;
    }
    
    // Re-connect to new database
    $conn->select_db($database_name);
}

// Use the database
$conn->select_db($database_name);

// Read schema file
$schema_sql = file_get_contents(__DIR__ . '/schema.sql');

if (!$schema_sql) {
    echo json_encode(['success' => false, 'message' => 'Failed to read schema.sql']);
    exit;
}

// Execute schema queries
if ($conn->multi_query($schema_sql)) {
    while ($conn->next_result());
    echo json_encode([
        'success' => true, 
        'message' => 'Database schema updated successfully (existing data preserved)'
    ]);
} else {
    echo json_encode([
        'success' => false, 
        'message' => 'Error executing schema: ' . $conn->error
    ]);
}

$db->close();
?>
