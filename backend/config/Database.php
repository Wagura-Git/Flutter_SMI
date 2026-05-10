<?php
class Database {
    private $host = 'localhost';
    private $db_name = 'si_manajemen_kampus';
    private $username = 'root';
    private $password = '';
    private $port = 3306;
    private $conn;

    public function connect() {
        $this->conn = null;

        try {
            // Force mysqli to return false on errors instead of throwing HTML fatal exceptions.
            mysqli_report(MYSQLI_REPORT_OFF);
            $this->conn = new mysqli(
                $this->host,
                $this->username,
                $this->password,
                $this->db_name,
                $this->port
            );

            // Check connection
            if ($this->conn->connect_error) {
                throw new Exception("Connection Error: " . $this->conn->connect_error);
            }

            // Set charset to utf8
            $this->conn->set_charset("utf8mb4");

            return $this->conn;
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'message' => 'Database connection error: ' . $e->getMessage()
            ]);
            exit;
        }
    }

    public function close() {
        if ($this->conn) {
            $this->conn->close();
        }
    }
}
?>
