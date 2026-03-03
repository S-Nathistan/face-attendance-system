# 🧠 Face Attendance System (FAS)

An AI-powered employee attendance management system that uses **real-time face recognition** to automatically identify employees and record their attendance. Built with a **Flutter** mobile app and a **Python Flask** backend.

---

## 📌 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [High-Level Architecture](#high-level-architecture)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [1. Database Setup](#1-database-setup)
  - [2. Backend Setup](#2-backend-setup)
  - [3. Face Embeddings Setup](#3-face-embeddings-setup)
  - [4. Flutter App Setup](#4-flutter-app-setup)
- [Configuration](#configuration)

---

## Overview

The Face Attendance System (FAS) automates employee attendance tracking by combining:

- **`employee-kiosk/`** — A Flutter Android app deployed at an entrance (kiosk-style) that captures the employee's face via camera or reads a QR code.
- **`admin-dashboard/`** — A separate Flutter app for admins to manage employees, admins, and view attendance history.
- **`backend/`** — A Python Flask REST API that processes face images, compares them against stored embeddings using the **MobileFaceNet** deep learning model, and logs attendance to a **Microsoft SQL Server** database.

---

## Features

- ✅ **Real-time Face Recognition** — Identifies employees from a live camera feed using MobileFaceNet TFLite
- ✅ **QR Code Attendance** — Alternative check-in via employee QR code
- ✅ **Multiple Attendance Types** — Sign-in, Sign-out, Lunch-in, Lunch-out
- ✅ **Employee Management** — Add, update, delete, and search employees with profile photos
- ✅ **Admin Management** — Multi-admin support with role management
- ✅ **Attendance History** — View attendance records per employee by month/year
- ✅ **Face Embedding Registration** — Register multiple face embeddings per employee for higher accuracy
- ✅ **Auto-Restart Server** — Backend auto-restarts on crash for high availability
- ✅ **Response Compression** — Gzip compression for faster API responses

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌──────────────────┐  │
│  │  Camera     │   │  QR Scanner │   │  Admin Dashboard │  │
│  │  Screen     │   │  Screen     │   │  (CRUD, Reports) │  │
│  └──────┬──────┘   └──────┬──────┘   └────────┬─────────┘  │
│         │                 │                   │             │
│         └─────────────────┴───────────────────┘             │
│                           │  HTTP REST API                   │
└───────────────────────────┼─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               Python Flask Backend (Waitress)                │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              REST API (Flask-RESTful)                │   │
│  │   /api/processfaceattendance  /api/process_face      │   │
│  │   /api/add  /api/getall  /api/login  /api/upload ... │   │
│  └─────────────────────┬────────────────────────────────┘   │
│                        │                                     │
│  ┌─────────────────────▼────────────────────────────────┐   │
│  │         Face Recognition Engine                      │   │
│  │   MobileFaceNet TFLite  │  Cosine Similarity         │   │
│  │   Face Embeddings Cache │  OpenCV Pre-processing     │   │
│  └─────────────────────┬────────────────────────────────┘   │
│                        │                                     │
└────────────────────────┼────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            Microsoft SQL Server  (FAS_DB)                    │
│                                                             │
│   tblAdmin  │  tblEmployees  │  tblAttendance  │ tblEmbeddings│
└─────────────────────────────────────────────────────────────┘
```

---

## How It Works

### Face Attendance Flow

1. The **Flutter app** opens the camera and uses **Google ML Kit Face Detection** to detect a face in the frame.
2. Once a face is detected, the frame is captured, cropped, and encoded as a **Base64 image**.
3. The image is sent via HTTP POST to the `/api/processfaceattendance` endpoint.
4. The backend **decodes** the image and uses **OpenCV** to pre-process the face.
5. **MobileFaceNet TFLite** generates a 128-dimensional **face embedding** vector from the image.
6. The embedding is compared against all stored embeddings in the database using **cosine similarity**.
7. If the similarity score exceeds the threshold (0.55), the employee is identified and an attendance record is inserted into `tblAttendance` with the current timestamp and attendance type (Sign-in / Sign-out / Lunch-in / Lunch-out).
8. The app receives the result (employee name, ID, status) and displays a confirmation to the user.

### Face Registration Flow

1. Admin takes a photo (or multiple photos) of a new employee via the app.
2. The image is sent to `/api/process_face`.
3. The backend extracts the face embedding using MobileFaceNet and stores it in the `tblEmbeddings` table linked to the employee ID.
4. The in-memory embeddings cache is refreshed so the new employee can be recognized immediately.

### QR Code Attendance Flow

1. Employee scans their personal QR code (containing their employee ID) at the kiosk.
2. The app sends the employee ID to the backend.
3. Attendance is recorded directly without face verification.

---

## Project Structure

```
├── backend/                      # Python Flask Backend
│   ├── run.py                    # App entry point (Waitress server)
│   ├── app.py                    # Route registration (Blueprint)
│   ├── config.py                 # DB connection & app config
│   ├── Model.py                  # Database model helpers
│   ├── auto_restart.py           # Auto-restart watchdog script
│   ├── face_recognition/
│   │   └── detect.py             # WebSocket-based face recognition (legacy)
│   └── resources/
│       ├── processFaceAttendance.py   # Core face recognition + attendance logic
│       ├── ProcessFaceEmbedding.py    # Face embedding registration
│       ├── AddEmployee.py             # Add new employee
│       ├── UpdateEmployee.py          # Update employee details
│       ├── DeleteEmployee.py          # Delete employee
│       ├── All_Employees.py           # List all employees
│       ├── SearchEmployees.py         # Search employees
│       ├── EmployeeAttendance.py      # Attendance history per employee
│       ├── Login.py                   # Admin login
│       ├── Admin.py                   # Admin operations
│       ├── CreateAdmin.py             # Create new admin
│       ├── DeleteAdmin.py             # Delete admin
│       ├── UpdateAdmin.py             # Update admin
│       ├── GetAllAdmins.py            # List all admins
│       ├── Upload_photo.py            # Upload employee photo
│       └── assets/models/
│           └── mobilefacenet.tflite  # MobileFaceNet model
│
├── employee-kiosk/               # Flutter Kiosk App (for employees)
│   └── attendance_app/
│       ├── lib/
│       │   ├── main.dart         # App entry point
│       │   └── src/UI/home/      # Camera & QR screens
│       ├── assets/
│       │   ├── models/           # TFLite model (mobile-side)
│       │   ├── images/           # Static assets
│       │   └── fonts/            # Custom fonts
│       └── pubspec.yaml          # Flutter dependencies
│
├── admin-dashboard/              # Flutter Admin App (for managers)
│   └── face_app/
│       ├── lib/                  # Admin screens (employee & attendance management)
│       └── pubspec.yaml          # Flutter dependencies
│
├── support/
│   └── SQLQuery1.sql             # Full database schema + seed data
│
└── README.md
```

---

## Tech Stack

| Layer                  | Technology                   |
| ---------------------- | ---------------------------- |
| Mobile App             | Flutter (Dart)               |
| Face Detection (App)   | Google ML Kit Face Detection |
| QR Scanner             | Mobile Scanner               |
| Backend API            | Python, Flask, Flask-RESTful |
| WSGI Server            | Waitress                     |
| Face Recognition Model | MobileFaceNet (TFLite)       |
| Image Processing       | OpenCV, NumPy                |
| Similarity Matching    | Scipy (Cosine Similarity)    |
| ML Runtime             | TensorFlow Lite              |
| Database               | Microsoft SQL Server         |
| DB Driver              | pyodbc                       |
| Compression            | Flask-Compress               |

---

## Database Schema

The SQL Server database `FAS_DB` contains four main tables:

```sql
tblAdmin        -- Admin accounts (id, name, username, password, position)
tblEmployees    -- Employee records (emp_id, name, DOB, phone, address, photo, position)
tblAttendance   -- Attendance log (att_id, FK_emp_id, time_stamp, att_type)
tblEmbeddings   -- Face embeddings (id, emp_id, embedding VARBINARY, created_date)
```

`att_type` values: `Sign-in` | `Sign-out` | `Lunch-in` | `Lunch-out`

---

## API Endpoints

| Method | Endpoint                                          | Description                          |
| ------ | ------------------------------------------------- | ------------------------------------ |
| POST   | `/api/processfaceattendance`                      | Recognize face & record attendance   |
| POST   | `/api/process_face`                               | Register face embedding for employee |
| GET    | `/api/health`                                     | Health check                         |
| POST   | `/api/login`                                      | Admin login                          |
| GET    | `/api/getall`                                     | Get all employees                    |
| POST   | `/api/add`                                        | Add new employee                     |
| PUT    | `/api/update/<emp_id>`                            | Update employee                      |
| DELETE | `/api/delete/<emp_id>`                            | Delete employee                      |
| GET    | `/api/search`                                     | Search employees                     |
| POST   | `/api/upload`                                     | Upload employee photo                |
| GET    | `/api/EmployeeAttendance/<emp_id>/<year>/<month>` | Get attendance history               |
| GET    | `/api/getadmins`                                  | List all admins                      |
| POST   | `/api/createadmin`                                | Create admin                         |
| PUT    | `/api/updateadmin/<admin_id>`                     | Update admin                         |
| DELETE | `/api/deleteadmin/<admin_id>`                     | Delete admin                         |
| GET    | `/api/employee-detail/<emp_id>`                   | Get employee detail by ID            |

---

## Getting Started

### Prerequisites

- **Python** 3.9+
- **Flutter SDK** 3.x
- **Microsoft SQL Server** (Express or full)
- **SQL Server Native Client 11.0** driver installed
- **Android Studio** or a physical Android device

---

### 1. Database Setup

1. Open **SQL Server Management Studio (SSMS)**.
2. Run the full schema script located at:
   ```
   support/SQLQuery1.sql
   ```
   This will create the `FAS_DB` database, all tables, and insert default seed data (sample admin and employees).

---

### 2. Backend Setup

**a) Clone & navigate to the backend folder:**

```bash
cd backend
```

**b) Create and activate a virtual environment:**

```bash
python -m venv venv
venv\Scripts\activate
```

**c) Install dependencies:**

```bash
pip install flask flask-restful flask-compress waitress pyodbc opencv-python numpy tensorflow scipy face-recognition
```

**d) Configure the database connection:**

Open `config.py` and update the `Server` name to match your SQL Server instance:

```python
conn = odbc_con.connect(
    "Driver={SQL Server Native Client 11.0};"
    "Server=YOUR_SERVER_NAME;"        # <-- change this
    "Database=FAS_DB;"
    "Trusted_Connection=yes;"
)
```

**e) Place the MobileFaceNet model:**

Ensure the TFLite model file exists at:

```
backend/resources/assets/models/mobilefacenet.tflite
```

**f) Start the backend server:**

- **Recommended (with auto-restart on crash):**

  ```bash
  python auto_restart.py
  ```

- **Direct start:**
  ```bash
  python run.py
  ```

The server will start on `http://0.0.0.0:5000`.

---

### 3. Face Embeddings Setup

Before any employee can be recognized, you must register their face embeddings.

**Option A — Via the App (recommended):**

1. Log in as an admin in the Flutter app.
2. Navigate to an employee's profile.
3. Use the "Register Face" feature to capture and submit their face photo.

**Option B — Offline batch encoding:**

1. Place employee face images inside `backend/image_encoder/images/`.
2. Name each image file with the employee's ID (e.g., `OYS001.jpg`).
3. Run the encoder script:
   ```bash
   cd backend/image_encoder
   python encoder.py
   ```
   This generates `EncodedFile.p` with all face embeddings.

---

### 4. Flutter App Setup

**a) Navigate to the Flutter kiosk app directory:**

```bash
cd employee-kiosk/attendance_app
```

**b) Install Flutter dependencies:**

```bash
flutter pub get
```

**c) Configure the backend API URL:**

Create or update the `.env` file in the app root:

```
API_BASE_URL=http://YOUR_SERVER_IP:5000/api
```

**d) Run on a connected Android device or emulator:**

```bash
flutter run
```

**e) Build a release APK:**

```bash
flutter build apk --release
```

---

## Configuration

| File                                         | Purpose                                                                   |
| -------------------------------------------- | ------------------------------------------------------------------------- |
| `backend/config.py`                          | SQL Server connection string, compression settings                        |
| `backend/resources/processFaceAttendance.py` | `SIMILARITY_THRESHOLD` (default: `0.55`) — increase for stricter matching |
| `employee-kiosk/attendance_app/.env`         | Backend API base URL                                                      |

> **Tip:** If you get too many false positives or false negatives during face recognition, adjust `SIMILARITY_THRESHOLD` in `processFaceAttendance.py`. A lower value is more permissive; a higher value is stricter.
