<?php

function validateUploadedDocument($file, $maxFileSize = 10485760) {
    if (!$file || !isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'message' => 'File tidak ditemukan atau gagal diupload'];
    }

    if ((int) $file['size'] > $maxFileSize) {
        return ['success' => false, 'message' => 'Ukuran file tidak boleh lebih dari 10MB'];
    }

    $allowedExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'];
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

    if (!in_array($extension, $allowedExtensions, true)) {
        return [
            'success' => false,
            'message' => 'Format file tidak diizinkan. Format yang diperbolehkan: ' . implode(', ', $allowedExtensions)
        ];
    }

    $data = file_get_contents($file['tmp_name']);
    if ($data === false || $data === '') {
        return ['success' => false, 'message' => 'File tidak dapat dibaca'];
    }

    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mimeType = $finfo->file($file['tmp_name']) ?: ($file['type'] ?? 'application/octet-stream');
    $originalName = basename($file['name']);
    $safeName = preg_replace('/[^A-Za-z0-9._-]/', '_', $originalName);

    return [
        'success' => true,
        'original_name' => $originalName,
        'safe_name' => $safeName,
        'extension' => $extension,
        'mime_type' => $mimeType,
        'size' => (int) $file['size'],
        'data' => $data,
    ];
}

function sendBlobFile($fileName, $mimeType, $fileSize, $fileData, $inline = false) {
    $disposition = $inline ? 'inline' : 'attachment';
    $downloadName = $fileName ?: 'document.pdf';
    $contentType = $mimeType ?: 'application/octet-stream';

    header('Content-Type: ' . $contentType);
    header('Content-Disposition: ' . $disposition . '; filename="' . str_replace('"', '', $downloadName) . '"');
    header('Content-Length: ' . (int) $fileSize);
    header('Cache-Control: no-cache, no-store, must-revalidate');
    header('Pragma: no-cache');
    header('Expires: 0');

    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        echo $fileData;
    }
    exit;
}

function bindBlobAndExecute($stmt, $blobParamIndex, $blobData) {
    $stmt->send_long_data($blobParamIndex, $blobData);
    return $stmt->execute();
}

?>
