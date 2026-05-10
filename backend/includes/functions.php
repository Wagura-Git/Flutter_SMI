<?php
// Set header untuk JSON response
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight request
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

/**
 * Validate email format
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL);
}

/**
 * Hash password
 */
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT);
}

/**
 * Verify password
 */
function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}

/**
 * Generate JWT Token
 */
function generateToken($userId, $email, $role) {
    $secret = 'your_secret_key_here_change_this_in_production'; // Ganti dengan secret key yang aman
    $issuedAt = time();
    $expire = $issuedAt + (7 * 24 * 60 * 60); // Token berlaku 7 hari

    $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    $payload = json_encode([
        'iat' => $issuedAt,
        'exp' => $expire,
        'userId' => $userId,
        'email' => $email,
        'role' => $role
    ]);

    // Encode to base64
    $header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');

    // Create signature
    $signature = hash_hmac('sha256', $header . '.' . $payload, $secret, true);
    $signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    return $header . '.' . $payload . '.' . $signature;
}

/**
 * Verify JWT Token
 */
function verifyToken($token) {
    $secret = 'your_secret_key_here_change_this_in_production';
    
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }

    $header = $parts[0];
    $payload = $parts[1];
    $signature = $parts[2];

    // Verify signature
    $expected_signature = rtrim(strtr(base64_encode(hash_hmac('sha256', $header . '.' . $payload, $secret, true)), '+/', '-_'), '=');
    
    if ($signature !== $expected_signature) {
        return null;
    }

    // Decode payload
    $decoded = json_decode(base64_decode(strtr($payload, '-_', '+/')), true);
    
    // Check expiration
    if ($decoded['exp'] < time()) {
        return null;
    }

    return $decoded;
}

/**
 * Verify user via token and return decoded payload
 */
function verifyUserFromToken($token) {
    if (empty($token)) {
        return null;
    }

    $decoded = verifyToken($token);
    if (!$decoded) {
        return null;
    }

    // Normalize token payload fields for compatibility
    if (isset($decoded['userId']) && !isset($decoded['id'])) {
        $decoded['id'] = $decoded['userId'];
    }

    return $decoded;
}

/**
 * Get authorization header - FIXED VERSION
 */
function getAuthorizationHeader() {
    $headers = null;
    
    // Method 1: Check $_SERVER['Authorization']
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } 
    // Method 2: Check $_SERVER['HTTP_AUTHORIZATION']
    elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } 
    // Method 3: Use apache_request_headers() - case insensitive search
    elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        // Case-insensitive search for Authorization header
        foreach ($requestHeaders as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $headers = trim($value);
                break;
            }
        }
    }
    
    return $headers;
}

/**
 * Get bearer token from header
 */
function getBearerToken() {
    $header = getAuthorizationHeader();
    if (!empty($header)) {
        if (preg_match('/Bearer\s+(.*)$/i', $header, $matches)) {
            return $matches[1];
        }
    }
    return null;
}

/**
 * Send JSON response
 */
function sendResponse($success, $message, $data = null, $statusCode = 200) {
    http_response_code($statusCode);
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response);
    exit;
}
?>
