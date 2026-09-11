# Food Cart App — Node.js + MySQL Server

Server สำหรับเชื่อมต่อฐานข้อมูล MySQL (`Mobile_app`) กับแอป Flutter ที่ทำไว้

## โครงสร้างไฟล์
```
food_cart_server/
├── config/
│   └── db.js              # การเชื่อมต่อ MySQL (connection pool)
├── routes/
│   ├── customers.js        # API สำหรับลูกค้า (buyer)
│   └── merchants.js        # API สำหรับผู้ค้า (merchant)
├── schema.sql               # โครงสร้างตารางฐานข้อมูล
├── server.js                # ไฟล์หลักของ server
├── package.json
└── .env.example             # ตัวอย่างไฟล์ตั้งค่า (คัดลอกเป็น .env)
```

## วิธีติดตั้งและรัน

### 1. ติดตั้ง Node.js
ถ้ายังไม่มี ดาวน์โหลดที่ https://nodejs.org (แนะนำเวอร์ชัน LTS)

### 2. ติดตั้ง dependencies
เปิด Terminal ในโฟลเดอร์นี้ แล้วรัน:
```bash
npm install
```

### 3. ตั้งค่าฐานข้อมูล
- เปิด MySQL Workbench (หรือ mysql CLI)
- รันไฟล์ `schema.sql` เพื่อสร้างฐานข้อมูล `Mobile_app` และตาราง `customer`, `merchant`
- **ถ้าคุณมีตาราง `customer` อยู่แล้ว** (ตามรูปที่เห็นใน Mobile_app) แต่ชื่อคอลัมน์ไม่ตรงกับที่ผมสมมติไว้ (name, email, password, phone) ให้แก้ชื่อคอลัมน์ใน `routes/customers.js` ให้ตรงกับของจริง

### 4. ตั้งค่าการเชื่อมต่อ
คัดลอกไฟล์ `.env.example` เป็น `.env`:
```bash
cp .env.example .env
```
แล้วแก้ค่าในไฟล์ `.env` ให้ตรงกับ MySQL ของคุณ:
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=รหัสผ่านmysqlของคุณ
DB_NAME=Mobile_app
PORT=3000
```

### 5. รัน server
```bash
npm start
```
หรือถ้าต้องการให้ server รีสตาร์ทอัตโนมัติเวลาแก้โค้ด:
```bash
npm run dev
```

ถ้าเชื่อมต่อสำเร็จจะเห็นข้อความ:
```
🚀 Server กำลังทำงานที่ http://localhost:3000
✅ เชื่อมต่อฐานข้อมูล MySQL สำเร็จ: Mobile_app
```

## API Endpoints

### ลูกค้า (Customer / Buyer)
| Method | Endpoint                  | คำอธิบาย                |
|--------|----------------------------|--------------------------|
| POST   | `/api/customers/register`  | สมัครสมาชิกลูกค้า       |
| POST   | `/api/customers/login`     | เข้าสู่ระบบ              |
| GET    | `/api/customers`           | ดูรายชื่อลูกค้าทั้งหมด   |
| GET    | `/api/customers/:id`       | ดูข้อมูลลูกค้ารายคน      |
| PUT    | `/api/customers/:id`       | แก้ไขข้อมูลลูกค้า        |
| DELETE | `/api/customers/:id`       | ลบข้อมูลลูกค้า           |

### ผู้ค้า (Merchant)
| Method | Endpoint                  | คำอธิบาย                |
|--------|----------------------------|--------------------------|
| POST   | `/api/merchants/register`  | สมัครสมาชิกผู้ค้า        |
| POST   | `/api/merchants/login`     | เข้าสู่ระบบ              |
| GET    | `/api/merchants`           | ดูรายชื่อผู้ค้าทั้งหมด    |
| GET    | `/api/merchants/:id`       | ดูข้อมูลผู้ค้ารายคน       |
| PUT    | `/api/merchants/:id`       | แก้ไขข้อมูลผู้ค้า         |
| DELETE | `/api/merchants/:id`       | ลบข้อมูลผู้ค้า            |

## ตัวอย่างการเรียก API จาก Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> registerCustomer() async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:3000/api/customers/register'), // 10.0.2.2 = localhost บน Android Emulator
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'ทดสอบ ระบบ',
      'email': 'test@mail.com',
      'password': '123456',
      'phone': '0812345678',
    }),
  );

  final data = jsonDecode(response.body);
  print(data);
}
```

**หมายเหตุสำคัญเรื่อง URL เวลาเรียกจาก Flutter:**
- **Android Emulator** ใช้ `http://10.0.2.2:3000` แทน `localhost`
- **iOS Simulator** ใช้ `http://localhost:3000` ได้ตรงๆ
- **มือถือจริง** ต้องใช้ IP ของคอมพิวเตอร์ในวง WiFi เดียวกัน เช่น `http://192.168.1.xx:3000`
