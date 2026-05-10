USE si_manajemen_kampus;

ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS file_name VARCHAR(255) NULL AFTER file_path,
    ADD COLUMN IF NOT EXISTS file_mime_type VARCHAR(100) NULL AFTER file_name,
    ADD COLUMN IF NOT EXISTS file_size INT NULL AFTER file_mime_type,
    ADD COLUMN IF NOT EXISTS file_data LONGBLOB NULL AFTER file_size;

ALTER TABLE agendas
    ADD COLUMN IF NOT EXISTS attachment_name VARCHAR(255) NULL AFTER attachment_path,
    ADD COLUMN IF NOT EXISTS attachment_mime_type VARCHAR(100) NULL AFTER attachment_name,
    ADD COLUMN IF NOT EXISTS attachment_size INT NULL AFTER attachment_mime_type,
    ADD COLUMN IF NOT EXISTS attachment_data LONGBLOB NULL AFTER attachment_size;

CREATE TABLE IF NOT EXISTS agenda_uploads (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size INT NOT NULL,
    file_data LONGBLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
