<?php
/**
 * Initial Database Setup Script
 * =============================
 * Run this ONLY on first deployment to set up the complete database with sample data.
 * 
 * After first setup, use safe_migration.php for schema updates.
 */

require_once 'config/Database.php';

$db = new Database();
$conn = $db->connect();

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Initial connection failed']));
}

// Drop and create database (this is intentional for fresh setup)
$database_name = 'si_manajemen_kampus';

$conn->query("DROP DATABASE IF EXISTS $database_name");

if (!$conn->query("CREATE DATABASE $database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")) {
    echo json_encode(['success' => false, 'message' => 'Failed to create database: ' . $conn->error]);
    exit;
}

// Select the database
$conn->select_db($database_name);

// Read and execute schema
$schema_sql = file_get_contents(__DIR__ . '/schema.sql');
if (!$schema_sql) {
    echo json_encode(['success' => false, 'message' => 'Failed to read schema.sql']);
    exit;
}

// Remove USE statement if present (we already selected the database)
$schema_sql = preg_replace('/^USE [^;]+;/m', '', $schema_sql);

if (!$conn->multi_query($schema_sql)) {
    echo json_encode(['success' => false, 'message' => 'Schema creation failed: ' . $conn->error]);
    exit;
}

// Clear any pending results
while ($conn->next_result());

// Read and execute seeds
$seeds_sql = file_get_contents(__DIR__ . '/seeds.sql');
if (!$seeds_sql) {
    echo json_encode(['success' => false, 'message' => 'Failed to read seeds.sql']);
    exit;
}

// Remove USE statement
$seeds_sql = preg_replace('/^USE [^;]+;/m', '', $seeds_sql);

if (!$conn->multi_query($seeds_sql)) {
    echo json_encode(['success' => false, 'message' => 'Seed insertion failed: ' . $conn->error]);
    exit;
}

// Clear any pending results
while ($conn->next_result());

echo json_encode([
    'success' => true, 
    'message' => 'Database initialized successfully with schema and sample data',
    'info' => [
        'database' => $database_name,
        'tables' => 'users, documents, document_recipients, dispositions, agendas, agenda_invitations, notifications, document_access',
        'sample_users' => [
            'email' => 'admin@example.com, pimpinan@example.com, user@example.com',
            'password' => 'password (before hashing)'
        ]
    ]
]);

$db->close();
?>
