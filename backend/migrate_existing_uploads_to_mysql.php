<?php
require_once __DIR__ . '/config/Database.php';

$database = new Database();
$conn = $database->connect();
$baseDir = realpath(__DIR__);

function migrateFilePath($conn, $baseDir, $table, $idColumn, $pathColumn, $nameColumn, $mimeColumn, $sizeColumn, $dataColumn, $dbPrefix) {
    $query = "SELECT $idColumn AS id, $pathColumn AS file_path
              FROM $table
              WHERE $pathColumn IS NOT NULL
              AND $pathColumn != ''
              AND $pathColumn NOT LIKE 'db:%'";
    $result = $conn->query($query);
    if (!$result) {
        echo "Query failed for $table: " . $conn->error . PHP_EOL;
        return;
    }

    $migrated = 0;
    $skipped = 0;

    while ($row = $result->fetch_assoc()) {
        $id = (int) $row['id'];
        $relativePath = preg_replace('/\.\./', '', trim($row['file_path'], '/'));
        $fullPath = $baseDir . DIRECTORY_SEPARATOR . str_replace(['/', '\\'], DIRECTORY_SEPARATOR, $relativePath);

        if (!is_file($fullPath)) {
            $skipped++;
            echo "Skipped missing file: $relativePath" . PHP_EOL;
            continue;
        }

        $fileData = file_get_contents($fullPath);
        if ($fileData === false) {
            $skipped++;
            echo "Skipped unreadable file: $relativePath" . PHP_EOL;
            continue;
        }

        $fileName = basename($fullPath);
        $mimeType = mime_content_type($fullPath) ?: 'application/octet-stream';
        $fileSize = filesize($fullPath);
        $dbPath = "$dbPrefix:$id";
        $blob = null;

        $updateQuery = "UPDATE $table
                        SET $pathColumn = ?, $nameColumn = ?, $mimeColumn = ?, $sizeColumn = ?, $dataColumn = ?
                        WHERE $idColumn = ?";
        $stmt = $conn->prepare($updateQuery);
        if (!$stmt) {
            $skipped++;
            echo "Prepare failed for $table id $id: " . $conn->error . PHP_EOL;
            continue;
        }

        $stmt->bind_param('sssibi', $dbPath, $fileName, $mimeType, $fileSize, $blob, $id);
        $stmt->send_long_data(4, $fileData);

        if ($stmt->execute()) {
            $migrated++;
        } else {
            $skipped++;
            echo "Update failed for $table id $id: " . $stmt->error . PHP_EOL;
        }
        $stmt->close();
    }

    echo "$table migrated: $migrated, skipped: $skipped" . PHP_EOL;
}

migrateFilePath($conn, $baseDir, 'documents', 'id', 'file_path', 'file_name', 'file_mime_type', 'file_size', 'file_data', 'db:document');
migrateFilePath($conn, $baseDir, 'agendas', 'id', 'attachment_path', 'attachment_name', 'attachment_mime_type', 'attachment_size', 'attachment_data', 'db:agenda');

$database->close();
?>
