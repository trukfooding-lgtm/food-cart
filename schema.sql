-- ==========================================================
-- Schema สำหรับฐานข้อมูล Mobile_app
-- รันไฟล์นี้ใน MySQL Workbench (หรือ mysql CLI) เพื่อสร้างตาราง
-- ถ้าคุณมีตาราง customer อยู่แล้วแต่ชื่อคอลัมน์ไม่ตรงกัน
-- ให้แก้ชื่อคอลัมน์ในไฟล์ routes/customers.js และ routes/merchants.js ให้ตรงกับของจริง
-- ==========================================================

CREATE DATABASE IF NOT EXISTS Mobile_app;
USE Mobile_app;

-- ตารางลูกค้า/ผู้ซื้อ (buyer)
CREATE TABLE IF NOT EXISTS customer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ตารางผู้ค้า/ร้านรถเข็น (merchant)
CREATE TABLE IF NOT EXISTS merchant (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ข้อมูลตัวอย่าง (ลบออกได้ถ้าไม่ต้องการ)
-- หมายเหตุ: password ด้านล่างเป็น plain text เพื่อทดสอบเท่านั้น
-- ในระบบจริง server จะ hash รหัสผ่านให้อัตโนมัติตอนสมัครสมาชิกผ่าน API
INSERT INTO merchant (name, email, password, phone, type) VALUES
('สมชาย สายกิน', 'somchai@mail.com', '$2a$10$examplehashvalue', '0812345678', 'ร้านอาหารสตรีทฟู้ด'),
('สมศรี มีดี', 'somsri@mail.com', '$2a$10$examplehashvalue', '0898765432', 'ร้านเครื่องดื่ม / คาเฟ่');
