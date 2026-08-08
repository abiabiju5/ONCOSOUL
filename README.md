# oncosoul

<div align="center">

# 🩺 OncoSoul

### A Flutter-powered telemedicine platform built for compassionate oncology care

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](#-license)

*Connecting patients, doctors, medical staff, and administrators — in one seamless care ecosystem.*

</div>

---

## 📖 Table of Contents

- [About the Project](#-about-the-project)
- [Highlights](#-highlights)
- [Feature Breakdown](#-feature-breakdown)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [User Roles & Permissions](#-user-roles--permissions)
- [Getting Started](#-getting-started)
- [Environment & Service Setup](#-environment--service-setup)
- [Roadmap](#-roadmap)
- [License](#-license)

---

## 💡 About the Project

**OncoSoul** is a full-featured, cross-platform (mobile + web) telemedicine app designed specifically around the needs of **oncology patients** — a group that often needs frequent doctor contact, careful record-keeping, emotional support, and logistical help (like nearby accommodation during treatment).

Instead of bolting together generic appointment-booking software, OncoSoul is built around a **real care journey**: book a consultation → talk to your doctor face-to-face → get your prescription and summary instantly → track your reports over time → lean on a community that understands → stay informed with curated awareness content.

---

## ✨ Highlights

<table>
<tr>
<td width="50%" valign="top">

### 🎯 For Patients
- 📅 One-tap appointment booking
- 🎥 Live video consultations
- 📁 Medical report vault
- 💊 Digital prescriptions (PDF)
- 🤝 Peer community forum
- 🏨 Homestay discovery near treatment centers
- 🔔 Real-time notifications

</td>
<td width="50%" valign="top">

### 🩻 For Doctors & Staff
- 🗓️ Availability & schedule management
- 👥 Full patient history at a glance
- 📝 Consultation notes & history
- 📊 Practice analytics dashboard
- 🧾 One-click prescription generation
- 🌱 Data seeding tools for testing

</td>
</tr>
</table>

### 🛡️ For Admins
Centralized control over users, doctors, appointments, community moderation, awareness content, and homestay listings — plus a dedicated **Super Admin** command center for full platform oversight.

---

## 🚀 Feature Breakdown

### 🔐 Authentication & Role Management
- Secure Firebase Authentication with **role-based routing** (Patient / Doctor / Medical Staff / Admin / Super Admin)
- Auto-seeded Super Admin account on first launch
- Admin-driven password resets and user account management

### 📅 Smart Appointment System
- Patients book directly against **live doctor availability**
- A background **`AppointmentExpiryService`** silently sweeps Firestore every few minutes to auto-cancel stale, past-due appointments — no manual cleanup needed
- Doctors and medical staff get dedicated views to manage their queues

### 🎥 Integrated Video Consultations
- Each appointment can spin up a unique, on-demand **video consultation room** (persisted in Firestore, keyed to the appointment)
- Post-consultation, doctors can upload structured **consultation summaries** for the patient's records

### 📂 Medical Records, Reports & Prescriptions
- Patients securely upload and revisit medical reports anytime
- Built-in **cross-platform PDF viewer** (separate implementations for web and mobile) so reports and prescriptions open instantly, in-app
- Doctors generate **prescription PDFs** directly from consultation data using the `pdf` + `printing` packages

### ☁️ Hybrid Cloud Storage
- Media/document uploads flow through **Cloudinary** for fast, optimized delivery
- **Supabase Storage** and **Firebase Storage** provide redundancy/alternate storage paths
- Smart URL normalization handles Cloudinary's raw vs. image delivery quirks automatically (so PDFs always render correctly, even when mis-tagged)

### 🤝 Community & Awareness
- Moderated **community forum** for patient-to-patient support
- Admin-curated **awareness/education content** to keep patients informed

### 🏨 Homestay Support
- Location-aware homestay listings to help out-of-town patients find nearby stays during treatment cycles

### 🔔 Live Notifications
- A dedicated notification panel keeps every role updated on appointment changes, uploads, and admin actions in real time via Firestore listeners

### 📊 Analytics
- Doctors get a built-in analytics screen to track consultation volume and practice trends over time

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (cross-platform: Android, iOS, Web) |
| **Backend / Auth / DB** | Firebase (Core, Firestore, Authentication, Storage) |
| **Media Storage** | Cloudinary, Supabase Storage |
| **Video Consultations** | Firestore-backed dynamic room service |
| **PDF Generation & Viewing** | `pdf`, `printing`, custom web/mobile PDF viewers |
| **File Handling** | `file_picker`, `image_picker`, `path_provider` |
| **Networking** | `http` |
| **Permissions** | `permission_handler` |
| **Utilities** | `intl`, `url_launcher` |

---

## 🏗️ Architecture

OncoSoul follows a clean **service-oriented layered architecture**:

```
UI Layer (screens/, doctor/, widgets/)
        │
        ▼
Service Layer (services/) ── talks to ──► Firebase / Cloudinary / Supabase
        │
        ▼
Model Layer (models/) ── shared data contracts across UI & services
```

- **Screens** stay declarative and delegate all data logic to services
- **Services** encapsulate every external integration (Firestore reads/writes, storage uploads, PDF generation, notifications) so UI code never touches raw APIs directly
- **Models** define consistent data shapes (`fromMap` / `toMap` patterns) used across the whole app

---

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point, Firebase init, theming
├── splash_screen.dart            # Splash/loading screen
├── login.dart                    # Authentication screen
├── admin_dashboard.dart          # Admin dashboard entry
├── doctor_dashboard.dart         # Doctor dashboard entry
├── patient_dashboard.dart        # Patient dashboard entry
├── firebase_options.dart         # Firebase platform configuration
│
├── models/                       # 📦 Data models
│   ├── app_user_session.dart
│   ├── appointment_rules.dart
│   ├── awareness_model.dart
│   ├── community_model.dart
│   ├── consultation_summary_model.dart
│   ├── consultation_summary_store.dart
│   ├── homestay_model.dart
│   ├── patient_model.dart
│   ├── report_model.dart
│   └── user_model.dart
│
├── services/                     # ⚙️ Business logic & integrations
│   ├── admin_service.dart
│   ├── appointment_expiry_service.dart
│   ├── auth_service.dart
│   ├── awareness_service.dart
│   ├── cloudinary_service.dart
│   ├── consultation_room_service.dart
│   ├── doctor_service.dart
│   ├── firebase_storage_service.dart
│   ├── homestay_service.dart
│   ├── medical_staff_service.dart
│   ├── notification_service.dart
│   ├── patient_service.dart
│   ├── prescription_pdf_service.dart
│   ├── supabase_storage_service.dart
│   └── url_launcher_service.dart
│
├── screens/                      # 🖥️ Shared & role-specific screens
│   ├── admin_awareness_management_screen.dart
│   ├── admin_community_moderation_screen.dart
│   ├── admin_doctor_management_screen.dart
│   ├── admin_homestay_management_screen.dart
│   ├── admin_manage_appointments_screen.dart
│   ├── admin_reset_password_screen.dart
│   ├── admin_user_account_screen.dart
│   ├── admin_user_list_screen.dart
│   ├── awareness_screen.dart
│   ├── book_appointments_screen.dart
│   ├── community_forum_screen.dart
│   ├── homestay_screen.dart
│   ├── medical_staff_appointments_screen.dart
│   ├── medical_staff_view_appointments_screen.dart
│   ├── my_appointments_screen.dart
│   ├── online_consultation_screen.dart
│   ├── patient_prescriptions_screen.dart
│   ├── patient_profile_screen.dart
│   ├── pdf_viewer_screen.dart
│   ├── pdf_viewer_stub.dart
│   ├── pdf_viewer_web.dart
│   ├── super_admin_dashboard.dart
│   ├── upload_consultation_summary_screen.dart
│   ├── upload_medical_report_screen.dart
│   └── view_reports_screen.dart
│
├── doctor/                       # 🩺 Doctor-specific feature screens
│   ├── analytics_screen.dart
│   ├── appointment_details_page.dart
│   ├── appointments_screen.dart
│   ├── availability_screen.dart
│   ├── consultation_details_page.dart
│   ├── consultation_room_page.dart
│   ├── consultations_page.dart
│   ├── doctor_home_screen.dart
│   ├── doctor_profile_screen.dart
│   ├── medical_report_page.dart
│   ├── notes_history_screen.dart
│   ├── patients_page.dart
│   ├── patients_screen.dart
│   └── seed_data_screen.dart
│
└── widgets/
    └── notification_panel.dart   # 🔔 Live in-app notifications
```

---

## 👥 User Roles & Permissions

| Role | Capabilities |
|---|---|
| 🧑‍⚕️ **Patient** | Book appointments, join video consultations, upload/view reports & prescriptions, use community forum, browse awareness content and homestay listings |
| 👨‍⚕️ **Doctor** | Manage availability, view/manage appointments, conduct consultations, view patient records, add notes, view practice analytics |
| 🧑‍💼 **Medical Staff** | View and manage assigned appointments |
| 🛠️ **Admin** | Manage users, doctors, appointments, awareness content, community moderation, homestays |
| 👑 **Super Admin** | Full administrative oversight via a dedicated command center dashboard |

---

## 🏁 Getting Started

### Prerequisites

- ✅ [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- ✅ A configured [Firebase project](https://firebase.google.com/) (Firestore + Storage enabled)
- ✅ A [Cloudinary](https://cloudinary.com/) account (for media uploads)
- ✅ A [Supabase](https://supabase.com/) project (for supplementary storage)

### Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd oncosoul

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

---

## 🔧 Environment & Service Setup

| Service | Where to configure |
|---|---|
| **Firebase** | Run `flutterfire configure` to regenerate `lib/firebase_options.dart`, or swap in your own. Enable Firestore + Firebase Storage in the console. |
| **Cloudinary** | Update `_cloudName` / `_uploadPreset` in `lib/services/cloudinary_service.dart`. |
| **Supabase** | Update the project URL and anon key in `lib/services/supabase_storage_service.dart`. |

> ⚠️ **Security tip:** Move hardcoded keys (Cloudinary preset, Supabase anon key) into environment variables or a secrets manager before shipping to production.

---

## 🗺️ Roadmap

- [ ] Push notifications (FCM) for appointment reminders
- [ ] Multi-language support for awareness content
- [ ] Doctor rating & feedback system
- [ ] Offline-first support for medical report viewing
- [ ] Automated CI/CD pipeline

---



Made with ❤️ using Flutter — built to make oncology care a little easier to navigate.

</div>
