-- ==========================================
-- DATABASE SEEDS (Initial Test Data)
-- USE THIS ONLY ON FIRST SETUP
-- ==========================================

USE si_manajemen_kampus;

-- Insert sample users (only if table is empty)
INSERT INTO users (name, email, password, role, nik, jabatan, phone) 
SELECT 'William Agung', 'admin@example.com', '$2y$10$IIhO1mQaOCIh9dB0Ry4arOMIFtucnWltYFxV4d/Oa6J.VQRCJ2HTm', 'admin', '2481711011', 'Admin Sistem', '081949688889'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@example.com');

INSERT INTO users (name, email, password, role, nik, jabatan, phone)
SELECT 'Dr. Pimpinan', 'pimpinan@example.com', '$2y$10$IIhO1mQaOCIh9dB0Ry4arOMIFtucnWltYFxV4d/Oa6J.VQRCJ2HTm', 'pimpinan', '197501012000', 'Dekan', '08123456789'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'pimpinan@example.com');

INSERT INTO users (name, email, password, role, nik, jabatan, phone)
SELECT 'Staff User', 'user@example.com', '$2y$10$IIhO1mQaOCIh9dB0Ry4arOMIFtucnWltYFxV4d/Oa6J.VQRCJ2HTm', 'user', '199005052020', 'Dosen', '081111222333'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'user@example.com');

-- Sample documents (only if table is empty)
INSERT INTO documents (admin_id, title, doc_type, description, doc_date, doc_time)
SELECT 1, 'Surat Tugas PkM Desa Tonja', 'Surat Tugas', 'Pengabdian masyarakat semester genap', '2024-10-15', '08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM documents WHERE title = 'Surat Tugas PkM Desa Tonja');

INSERT INTO documents (admin_id, title, doc_type, description, doc_date, doc_time)
SELECT 1, 'Surat Kenaikan Jabatan', 'Surat Keputusan', 'SK Kenaikan jabatan fungsional', '2024-04-23', '09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM documents WHERE title = 'Surat Kenaikan Jabatan');

-- Sample document recipients
INSERT INTO document_recipients (document_id, user_id)
SELECT 1, 2 WHERE NOT EXISTS (SELECT 1 FROM document_recipients WHERE document_id = 1 AND user_id = 2);

INSERT INTO document_recipients (document_id, user_id)
SELECT 1, 3 WHERE NOT EXISTS (SELECT 1 FROM document_recipients WHERE document_id = 1 AND user_id = 3);

INSERT INTO document_recipients (document_id, user_id)
SELECT 2, 2 WHERE NOT EXISTS (SELECT 1 FROM document_recipients WHERE document_id = 2 AND user_id = 2);

-- Sample agendas
INSERT INTO agendas (user_id, title, date_start, time_start, location, agenda_type, notif_value, notif_unit, status)
SELECT 1, 'Rapat Rutin Pimpinan', '2026-05-17', '08:00:00', 'Ruang Rapat Rektor', 'pribadi', 30, 'Menit', 'scheduled'
WHERE NOT EXISTS (SELECT 1 FROM agendas WHERE title = 'Rapat Rutin Pimpinan');

INSERT INTO agendas (user_id, title, date_start, time_start, location, agenda_type, notif_value, notif_unit, status)
SELECT 2, 'Rapat Dekan Dengan Tim', '2026-05-18', '09:00:00', 'Ruang Rektor', 'pribadi', 30, 'Menit', 'scheduled'
WHERE NOT EXISTS (SELECT 1 FROM agendas WHERE title = 'Rapat Dekan Dengan Tim');

INSERT INTO agendas (user_id, title, date_start, time_start, location, agenda_type, notif_value, notif_unit, status)
SELECT 1, 'Seminar Internasional', '2026-05-20', '13:00:00', 'Aula Utama', 'umum', 60, 'Menit', 'scheduled'
WHERE NOT EXISTS (SELECT 1 FROM agendas WHERE title = 'Seminar Internasional');

-- Sample agenda invitations
INSERT INTO agenda_invitations (agenda_id, user_id)
SELECT 3, 2 WHERE NOT EXISTS (SELECT 1 FROM agenda_invitations WHERE agenda_id = 3 AND user_id = 2);

INSERT INTO agenda_invitations (agenda_id, user_id)
SELECT 3, 3 WHERE NOT EXISTS (SELECT 1 FROM agenda_invitations WHERE agenda_id = 3 AND user_id = 3);
