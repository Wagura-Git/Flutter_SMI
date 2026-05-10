<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Test: Check what headers are being received
echo json_encode([
    'success' => true,
    'message' => 'Debug Authorization Header',
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'server_auth' => $_SERVER['Authorization'] ?? 'NOT SET',
    'http_auth' => $_SERVER['HTTP_AUTHORIZATION'] ?? 'NOT SET',
    'all_server_keys' => array_keys($_SERVER),
    'apache_headers' => function_exists('apache_request_headers') ? apache_request_headers() : 'N/A'
], JSON_PRETTY_PRINT);
?>
