-- ==========================================
-- DATABASE SCHEMA (Structure Only - No Data)
-- USE THIS TO UPDATE TABLES WITHOUT LOSING DATA
-- ==========================================

USE si_manajemen_kampus;

-- 1. TABLE USERS
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik VARCHAR(50) UNIQUE, -- Nomor Induk Kepegawaian
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('pimpinan', 'admin', 'user') DEFAULT 'user',
    jabatan VARCHAR(100), -- Dekan, KTU, dsb
    phone VARCHAR(20),
    status ENUM('active', 'inactive') DEFAULT 'active',
    last_login TIMESTAMP NULL,
    profile_photo VARCHAR(255),
    department VARCHAR(255),
    position VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_nik (nik)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. TABLE DOCUMENTS
CREATE TABLE IF NOT EXISTS documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    doc_type ENUM('Surat Keputusan', 'Surat Tugas', 'Surat Personal', 'Lain-lain') NOT NULL,
    description TEXT,
    doc_date DATE NOT NULL,
    doc_time TIME,
    document_number VARCHAR(100),
    file_path VARCHAR(255),
    file_name VARCHAR(255),
    file_mime_type VARCHAR(100),
    file_size INT,
    file_data LONGBLOB,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    visibility ENUM('private', 'team', 'public') DEFAULT 'private',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_doc_type (doc_type),
    UNIQUE INDEX idx_document_number (document_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. TABLE DOCUMENT_RECIPIENTS
CREATE TABLE IF NOT EXISTS document_recipients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT NOT NULL,
    user_id INT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. TABLE DISPOSITIONS
CREATE TABLE IF NOT EXISTS dispositions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT NOT NULL,
    from_user_id INT NOT NULL,
    to_user_id INT NOT NULL,
    instruction TEXT,
    reply_instruction TEXT, -- Balasan dari penerima disposisi
    status ENUM('pending', 'processed', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. TABLE AGENDAS
CREATE TABLE IF NOT EXISTS agendas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    date_start DATE NOT NULL,
    date_end DATE,
    time_start TIME NOT NULL,
    time_end TIME,
    location VARCHAR(255),
    agenda_type ENUM('pribadi', 'umum') DEFAULT 'pribadi',
    notif_value INT DEFAULT 30,
    notif_unit VARCHAR(20) DEFAULT 'Menit',
    attachment_path VARCHAR(255),
    attachment_name VARCHAR(255),
    attachment_mime_type VARCHAR(100),
    attachment_size INT,
    attachment_data LONGBLOB,
    status ENUM('scheduled', 'completed', 'cancelled') DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_date (date_start),
    INDEX idx_type (agenda_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5b. TABLE AGENDA_UPLOADS
-- Temporary MySQL-backed uploads selected before an agenda row exists.
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

-- 6. TABLE AGENDA_INVITATIONS
CREATE TABLE IF NOT EXISTS agenda_invitations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    agenda_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (agenda_id) REFERENCES agendas(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. TABLE NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('agenda', 'surat', 'disposisi', 'system') DEFAULT 'system',
    related_id INT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. TABLE DOCUMENT_ACCESS (Optional: untuk sharing dokumen)
CREATE TABLE IF NOT EXISTS document_access (
    id INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT NOT NULL,
    user_id INT NOT NULL,
    access_type ENUM('view', 'edit') DEFAULT 'view',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_doc_user (document_id, user_id),
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
